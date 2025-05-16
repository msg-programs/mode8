const std = @import("std");
const m8 = @import("../root.zig");
const con = m8.hardware.constants;
const bsp = m8.bsp;
const mem = m8.hardware.memory;
const reg = m8.hardware.registers;
const rpa = bsp.RenderParams;

const mach = @import("mach");
const math = mach.math;
const gpu = mach.gpu;

const ScreenPos = struct {
    x: u8,
    y: u8,
};

const ViewPos = struct {
    x: i32,
    y: i32,
};

const Color = packed struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8 = 255,
};

pub var BUFFER: [con.SCREEN_DIM_PIX][con.SCREEN_DIM_PIX]Color = @splat(@splat(Color{ .r = 0, .g = 0, .b = 0 }));

// ok this is way worse for the CPU than it ever was for the GPU but... eh gotta start somewhere

// ///////////////////////////////////////////////////////////////////////////////////////////////////
// // STRUCT TYPES
// ///////////////////////////////////////////////////////////////////////////////////////////////////

// struct Tile {
//     gfxid: u32,
//     prio: bool,
//     vflip: bool,
//     hflip: bool,
//     rot: bool,
// };

// struct Obj {
//     pos: vec2u,
//     gfxid: u32,
//     vflip: bool,
//     hflip: bool,
//     prio: u32,
//     size: u32,
//     rot: bool,
// };

const BGPixel = struct {
    p_col: u16,
    is_prio: bool,
};

const ObjPixel = struct {
    p_col: u16,
    prio: u2,
};

const BufferPixel = struct {
    p_col: u16,
    origin: u8,
};

// ///////////////////////////////////////////////////////////////////////////////////////////////////
// // COLOR FUNCTIONS
// ///////////////////////////////////////////////////////////////////////////////////////////////////

// given a packed color, unpack it
fn unpackColor(p_col: u16) Color {
    const col: bsp.Color = @bitCast(p_col);
    return .{
        .r = @intFromFloat(@as(f32, @floatFromInt(col.r)) / 31.0 * 255.0),
        .g = @intFromFloat(@as(f32, @floatFromInt(col.g)) / 31.0 * 255.0),
        .b = @intFromFloat(@as(f32, @floatFromInt(col.b)) / 31.0 * 255.0),
        .a = 255,
    };
}

// given a packed color, check if it's opaque
fn isPackedColorOpaque(p_col: u16) bool {
    return (p_col & 0x8000) != 0;
}

// given a palette index, return the packed color stored there
fn lookupPaletteColor(idx: u8) u16 {
    return mem.GCM[idx * 2] | (@as(u16, mem.GCM[idx * 2 + 1]) << 8);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// BG TILE FUNCTIONS
///////////////////////////////////////////////////////////////////////////////////////////////////

// given a viewpos and a Tile struct, find the palette index of the pixel that is at that position.
// this implements flipping and rotation.
fn fetchTilePixel(viewpos: ViewPos, tile_attrs: bsp.Tile) u8 {
    std.debug.assert(viewpos.x >= 0);
    std.debug.assert(viewpos.y >= 0);

    const view_x: u32 = @intCast(viewpos.x);
    const view_y: u32 = @intCast(viewpos.y);

    // viewpos to pos inside tile
    var pixpos_x = @mod(view_x, con.TILE_GFX_DIM_PIX);
    var pixpos_y = @mod(view_y, con.TILE_GFX_DIM_PIX);

    // do mirroring of tile
    if (tile_attrs.vflip) {
        pixpos_x = 7 - pixpos_x;
    }
    if (tile_attrs.hflip) {
        pixpos_y = 7 - pixpos_y;
    }

    if (tile_attrs.rot) {
        const tmp = pixpos_y;
        pixpos_y = pixpos_x;
        pixpos_x = tmp;
    }

    const gfxid = tile_attrs.gfxid | (@as(u12, tile_attrs.atlid) << 10);

    // 2D pixpos to 1D pix array index
    const pixidx: u32 = @as(u32, pixpos_y) * con.TILE_GFX_DIM_PIX + @as(u32, pixpos_x) + @as(u32, gfxid) * con.TILE_GFX_PIX_NUM;
    return mem.TGM[pixidx];
}

// given a viewpos and a BG, get the tile that is being viewed from the TAM
fn fetchTileAttrs(bg: u2, bgoffs_x: u32, bgoffs_y: u32, viewpos: ViewPos) bsp.Tile {
    std.debug.assert(viewpos.x >= 0);
    std.debug.assert(viewpos.y >= 0);

    const view_x: u32 = @intCast(viewpos.x);
    const view_y: u32 = @intCast(viewpos.y);

    // viewpos to tilepos
    const tilepos_x = @divFloor(view_x, con.TILE_GFX_DIM_PIX) + bgoffs_x;
    const tilepos_y = @divFloor(view_y, con.TILE_GFX_DIM_PIX) + bgoffs_y;

    // 2D tilepos to 1D tile array index
    const tileidx = @as(u32, @intCast((tilepos_y * con.BG_DIM_TIL) + tilepos_x)) + (@as(u32, bg) * con.BG_DIM_TIL * con.BG_DIM_TIL);

    const dat: u16 = mem.TAM[tileidx * 2] | (@as(u16, mem.TAM[tileidx * 2 + 1]) << 8);
    return @bitCast(dat);
}

// normally, the pos of a pixel on the screen is == the position to look up in the TAM.
// mosiac, affine xform and scrolling are implemented by remapping the screenpos into a viewpos
fn toTileAttrViewPos(bg: u32, screenpos: ScreenPos) ViewPos {
    var viewpos = ViewPos{ .x = screenpos.x, .y = screenpos.y };
    viewpos.x = @divFloor(viewpos.x, @as(u5, reg.mosiac[bg]) + 1) * (@as(u5, reg.mosiac[bg]) + 1);
    viewpos.y = @divFloor(viewpos.y, @as(u5, reg.mosiac[bg]) + 1) * (@as(u5, reg.mosiac[bg]) + 1);

    const index: u32 = if (@as(rpa.DmaDir, @enumFromInt(reg.dma_dir_bg[bg])) == .top_to_bottom) screenpos.y else screenpos.x;

    const xscroll: i32 = if (reg.xscroll_do_dma[bg]) reg.xscroll[bg][index] else reg.xscroll[bg][0];
    const yscroll: i32 = if (reg.yscroll_do_dma[bg]) reg.yscroll[bg][index] else reg.yscroll[bg][0];

    const x0: i32 = if (reg.affine_x0_do_dma[bg]) reg.affine_x0[bg][index] else reg.affine_x0[bg][0];
    const y0: i32 = if (reg.affine_y0_do_dma[bg]) reg.affine_y0[bg][index] else reg.affine_y0[bg][0];
    const a: f32 = if (reg.affine_a_do_dma[bg]) reg.affine_a[bg][index] else reg.affine_a[bg][0];
    const b: f32 = if (reg.affine_b_do_dma[bg]) reg.affine_b[bg][index] else reg.affine_b[bg][0];
    const c: f32 = if (reg.affine_c_do_dma[bg]) reg.affine_c[bg][index] else reg.affine_c[bg][0];
    const d: f32 = if (reg.affine_d_do_dma[bg]) reg.affine_d[bg][index] else reg.affine_d[bg][0];

    const affine_mat = math.mat2x2(&math.vec2(a, b), &math.vec2(c, d));
    const affine_vec1: math.Vec2 = math.vec2(@floatFromInt(viewpos.x), @floatFromInt(viewpos.y)).add(&math.vec2(@floatFromInt(xscroll), @floatFromInt(yscroll))).sub(&math.vec2(@floatFromInt(x0), @floatFromInt(y0)));
    const affine_vec2: math.Vec2 = math.vec2(@floatFromInt(x0), @floatFromInt(y0));

    const viewpos_pre: math.Vec2 = affine_mat.mulVec(&affine_vec1).add(&affine_vec2);

    return .{
        .x = @intFromFloat(viewpos_pre.x()),
        .y = @intFromFloat(viewpos_pre.y()),
    };
}

// given the screenpos, calculate the packed color for that pixel based on the specified BG.
fn calcBGPixel(screenpos: ScreenPos, bg: u2) BGPixel {
    const viewpos_pre = toTileAttrViewPos(bg, screenpos);

    const bgsz = (@as(u32, reg.bgsz[bg]) + 1) * 2 * con.TILE_GFX_DIM_PIX;
    const bgoffs_x = @as(u32, reg.bgoffs_x[bg]) * 32;
    const bgoffs_y = @as(u32, reg.bgoffs_y[bg]) * 32;

    const viewpos_pre_oob: bool = (viewpos_pre.x < 0 or viewpos_pre.y < 0 or viewpos_pre.x >= bgsz or viewpos_pre.y >= bgsz);

    if (!viewpos_pre_oob) {
        const viewpos = ViewPos{ .x = viewpos_pre.x, .y = viewpos_pre.y };
        const tile_attrs = fetchTileAttrs(bg, bgoffs_x, bgoffs_y, viewpos);
        const tilecol_idx = fetchTilePixel(viewpos, tile_attrs);
        return BGPixel{
            .p_col = lookupPaletteColor(tilecol_idx),
            .is_prio = tile_attrs.prio,
        };
    }

    switch (@as(rpa.OobSetting, @enumFromInt(reg.oob_setting[bg]))) {
        .mirror => {
            const mult_x = @divFloor(viewpos_pre.x, @as(i32, @intCast(bgsz)));
            const mult_y = @divFloor(viewpos_pre.y, @as(i32, @intCast(bgsz)));

            var view_x = @mod(viewpos_pre.x, @as(i32, @intCast(bgsz)));
            var view_y = @mod(viewpos_pre.y, @as(i32, @intCast(bgsz)));

            if (@abs(mult_x) % 2 == 1) {
                view_x = @as(i32, @intCast(bgsz)) - 1 - view_x;
            }
            if (@abs(mult_y) % 2 == 1) {
                view_y = @as(i32, @intCast(bgsz)) - 1 - view_y;
            }

            const viewpos: ViewPos = .{ .x = view_x, .y = view_y };

            const tile_attrs = fetchTileAttrs(bg, bgoffs_x, bgoffs_y, viewpos);
            const tilecol_idx = fetchTilePixel(viewpos, tile_attrs);
            return .{ .p_col = lookupPaletteColor(tilecol_idx), .is_prio = tile_attrs.prio };
        },
        .color => {
            return .{ .p_col = reg.oob_data[bg], .is_prio = false };
        },
        .tile => {
            const dummy: bsp.Tile = @bitCast(reg.oob_data[bg]);

            const tilecol_idx = fetchTilePixel(.{ .x = @mod(viewpos_pre.x, con.TILE_GFX_DIM_PIX), .y = @mod(viewpos_pre.y, con.TILE_GFX_DIM_PIX) }, dummy);

            return .{ .p_col = lookupPaletteColor(tilecol_idx), .is_prio = dummy.prio };
        },
        .wrap => {
            const viewpos: ViewPos = .{ .x = @mod(viewpos_pre.x, @as(i32, @intCast(bgsz))), .y = @mod(viewpos_pre.y, @as(i32, @intCast(bgsz))) };
            const tile_attrs = fetchTileAttrs(bg, bgoffs_x, bgoffs_y, viewpos);
            const tilecol_idx = fetchTilePixel(viewpos, tile_attrs);
            return .{ .p_col = lookupPaletteColor(tilecol_idx), .is_prio = tile_attrs.prio };
        },
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// WINDOW FUNCTIONS
///////////////////////////////////////////////////////////////////////////////////////////////////

// given the screenpos, check if it's inside the specified window
fn isPixelInWin(screenpos: ScreenPos, win: u32) bool {
    const do_start_dma = reg.win_start_do_dma[win];
    const do_end_dma = reg.win_end_do_dma[win];
    const dma_dir: rpa.DmaDir = @enumFromInt(reg.dma_dir_win[win]);

    const index = if (dma_dir == .left_to_right)
        screenpos.x
    else
        screenpos.y;

    const start = if (do_start_dma)
        reg.win_start[win][index]
    else
        reg.win_start[win][0];

    const end = if (do_end_dma)
        reg.win_end[win][index]
    else
        reg.win_end[win][0];

    return if (dma_dir == .left_to_right)
        (start <= screenpos.y and screenpos.y <= end)
    else
        (start <= screenpos.x and screenpos.x <= end);
}

// combine the window data obtained above (valid for all layers) according to a layer's setting.
fn combineWinsForLayer(layer: rpa.Layer, w0: bool, w1: bool) bool {
    // panics on bad layer arg, should never happen as the user can't control this
    return switch (reg.win_compose[@intFromEnum(layer)]) { // over   1   0 out
        0 => false, //    0   0   0   0
        1 => (!w0) and (!w1), //    0   0   0   1
        2 => w0 and !(w1), //    0   0   1   0
        3 => !w1, //    0   0   1   1
        4 => (!w0) and w1, //    0   1   0   0
        5 => !w0, //    0   1   0   1
        6 => (w0 or w1) and (!(w0 and w1)), //    0   1   1   0
        7 => (!w0) or (!w1), //    0   1   1   1
        8 => w0 and w1, //    1   0   0   0
        9 => !((w0 or w1) and (!(w0 and w1))), //    1   0   0   1
        10 => w0, //    1   0   1   0
        11 => w0 or (!w1), //    1   0   1   1
        12 => w1, //    1   1   0   0
        13 => (!w0) or w1, //    1   1   0   1
        14 => w0 or w1, //    1   1   1   0
        15 => true, //    1   1   1   1
    };
}

fn isPixelInColWin(is_main: bool, data_in: bool) bool {
    const idx: usize = if (is_main) 0 else 1;
    const setting: rpa.ColWinApplyAlgo = @enumFromInt(reg.col_win_apply[idx]);

    return switch (setting) {
        .always_on => true,
        .direct => data_in,
        .inverted => !data_in,
        .always_off => false,
    };
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// THE LONG ONE
///////////////////////////////////////////////////////////////////////////////////////////////////

// resolve BG and obj prios to produce the final color for a pixel
fn resolvePrios(cols: [5]u16, bg_is_prio: [4]bool, obj_prio: u2, fixcol: u16) BufferPixel {

    // what a horrible day to be a GPU 3: revenge of the if chain (something something yandere simulator. ha ha.)

    // precalc this. the compiler will probably figure this out itself but it feels right.
    const is_opaque: [5]bool = .{
        isPackedColorOpaque(cols[0]),
        isPackedColorOpaque(cols[1]),
        isPackedColorOpaque(cols[2]),
        isPackedColorOpaque(cols[3]),
        isPackedColorOpaque(cols[4]),
    };

    // this could probably be reduced using some analysis.
    // if you want do that for some reason, open a PR :)

    if (reg.prio_remap[3] and bg_is_prio[3] and is_opaque[3]) {
        return .{ .p_col = cols[3], .origin = 3 };
    }

    if (reg.prio_remap[2] and bg_is_prio[2] and is_opaque[2]) {
        return .{ .p_col = cols[2], .origin = 2 };
    }

    if (reg.prio_remap[1] and bg_is_prio[1] and is_opaque[1]) {
        return .{ .p_col = cols[1], .origin = 1 };
    }

    if (reg.prio_remap[0] and bg_is_prio[0] and is_opaque[0]) {
        return .{ .p_col = cols[0], .origin = 0 };
    }

    if (obj_prio == 3 and is_opaque[4]) {
        return .{ .p_col = cols[4], .origin = 4 };
    }

    if (bg_is_prio[3] and is_opaque[3]) {
        return .{ .p_col = cols[3], .origin = 3 };
    }

    if (bg_is_prio[2] and is_opaque[2]) {
        return .{ .p_col = cols[2], .origin = 2 };
    }

    if (obj_prio == 2 and is_opaque[4]) {
        return .{ .p_col = cols[4], .origin = 4 };
    }

    if (!bg_is_prio[3] and is_opaque[3]) {
        return .{ .p_col = cols[3], .origin = 3 };
    }

    if (!bg_is_prio[2] and is_opaque[2]) {
        return .{ .p_col = cols[2], .origin = 2 };
    }

    if (obj_prio == 1 and is_opaque[4]) {
        return .{ .p_col = cols[4], .origin = 4 };
    }

    if (bg_is_prio[1] and is_opaque[1]) {
        return .{ .p_col = cols[1], .origin = 1 };
    }

    if (bg_is_prio[0] and is_opaque[0]) {
        return .{ .p_col = cols[0], .origin = 0 };
    }

    if (obj_prio == 0 and is_opaque[4]) {
        return .{ .p_col = cols[4], .origin = 4 };
    }

    if (!bg_is_prio[1] and is_opaque[1]) {
        return .{ .p_col = cols[1], .origin = 1 };
    }

    if (!bg_is_prio[0] and is_opaque[0]) {
        return .{ .p_col = cols[0], .origin = 0 };
    }

    // fallthrough: set to fixcol
    return .{ .p_col = fixcol, .origin = 5 };
}

// ///////////////////////////////////////////////////////////////////////////////////////////////////
// // FIXCOL FUNCTION
// ///////////////////////////////////////////////////////////////////////////////////////////////////

fn getFixcol(screenpos: ScreenPos, for_main: bool) u16 {
    const magic_num: u32 = if (for_main) 0 else 1;
    const do_dma_switch: bool = if (for_main) reg.fixcol_main_do_dma else reg.fixcol_sub_do_dma;

    const dma_dir: rpa.DmaDir = @enumFromInt(reg.dma_dir_fixcol[magic_num]);
    const index_raw = if (dma_dir == .top_to_bottom) screenpos.y else screenpos.x;
    const index: u32 = if (do_dma_switch) index_raw else 0;

    return if (for_main)
        reg.fixcol_main[index]
    else
        reg.fixcol_sub[index];
}

// ///////////////////////////////////////////////////////////////////////////////////////////////////
// // COLOR MATH
// ///////////////////////////////////////////////////////////////////////////////////////////////////

// fn brightness(col: Color) f32 {
//     // SO says that this is incorrect, but it should be good enough tbh.
//     return col.x() * 0.2126 + col.y() * 0.7152 + col.z() * 0.0722;
// }

// fn luma(col: Color) f32 {
//     // SO says that this is incorrect, but it should be good enough tbh.
//     return col.x() * 0.299 + col.y() * 0.298 + col.z() * 0.114;
// }

// fn mixPinlight(main: Color, sub: Color) Color {
//     const lm = brightness(main);
//     const ls = brightness(sub);
//     if (ls > 0.5) {
//         if (lm < ls) {
//             return sub;
//         } else {
//             return main;
//         }
//     } else {
//         if (lm > ls) {
//             return sub;
//         } else {
//             return main;
//         }
//     }
// }

// fn mixOverlay(main: Color, sub: Color) Color {
//     if (brightness(sub) > 0.5) {
//         return main.mul(sub);
//     } else {
//         const one = Color.init(1.0, 1.0, 1.0, 1.0);
//         const unmain = Color.sub(one, main);
//         const unsub = Color.sub(one, sub);
//         return one.sub(unmain.mul(unsub));
//     }
// }

// fn mixSoftlight(main: Color, sub: Color) Color {
//     if (brightness(sub) > 0.5) {
//         return Color.max(main, sub);
//     } else {
//         return Color.min(main, sub);
//     }
// }

// fn doColorMath(main: BufferPixel, sub: u32) Color {
//     const is_main_opaque: bool = isPackedColorOpaque(main.p_col);
//     const is_sub_opaque: bool = isPackedColorOpaque(sub);

//     if (!is_main_opaque and !is_sub_opaque) {
//         return Color.init(0, 0, 0, 1);
//     }
//     if (!is_main_opaque) {
//         return unpackColor(sub);
//     }
//     if (!is_sub_opaque) {
//         return unpackColor(main.p_col);
//     }

//     if (!((reg.math_enable & (1 << main.origin)) != 0)) {
//         return unpackColor(main.p_col);
//     }

//     const a: Color = unpackColor(main.p_col);
//     const b: Color = unpackColor(sub);

//     const rescol = switch (reg.math_algo) {
//         .ADD => b + a,
//         .SUBTRACT => b - a,
//         .MULTIPLY => (b * a),
//         .DIVIDE => b / a,
//         .DIFFERENCE => @max(b, a) - @min(b, a),
//         .PINLIGHT => mixPinlight(b, a),
//         .SCREEN => 1.0 - ((1.0 - b) * (1.0 - a)),
//         .DARKEN => @min(b, a),
//         .LIGHTEN => @max(b, a),
//         .OVERLAY => mixOverlay(b, a),
//         .SOFTLIGHT => mixSoftlight(b, a),
//         else => a,
//     };

//     return switch (reg.math_normalize) {
//         .CLAMP_RESULT => rescol.max(Color.init(0, 0, 0, 0)).min(Color.init(1, 1, 1, 1)),
//         .HALF_RESULT => rescol.divScalar(2).max(Color.init(0, 0, 0, 0)).min(Color.init(1, 1, 1, 1)),
//         .DOUBLE_RESULT => rescol.mulScalar(2).max(Color.init(0, 0, 0, 0)).min(Color.init(1, 1, 1, 1)),
//         .BLEED_RESULT => {
//             // https://www.quizcanners.com/single-post/2018/04/02/Color-Bleeding-in-Shader
//             // value 0f 0.01 determined by testing with the debug example
//             const mix = rescol.gbra + rescol.brga;
//             rescol = rescol + (mix * mix * 0.01);
//         },
//     };
// }

// ///////////////////////////////////////////////////////////////////////////////////////////////////
// // UTIL
// ///////////////////////////////////////////////////////////////////////////////////////////////////

// array select x5
fn arrselx5(T: type, no: [5]T, yes: [5]T, decide: [5]bool) [5]T {
    return .{
        if (decide[0]) yes[0] else no[0],
        if (decide[1]) yes[1] else no[1],
        if (decide[2]) yes[2] else no[2],
        if (decide[3]) yes[3] else no[3],
        if (decide[4]) yes[4] else no[4],
    };
}

// ///////////////////////////////////////////////////////////////////////////////////////////////////
// // MAIN
// ///////////////////////////////////////////////////////////////////////////////////////////////////

fn setPx(screenpos: ScreenPos, color: Color) void {
    BUFFER[screenpos.x][screenpos.y] = color;
}

fn debugArgToLayer(da: rpa.DebugArg) ?rpa.Layer {
    return switch (da) {
        .show_bg_0 => rpa.Layer.bg_0,
        .show_bg_1 => rpa.Layer.bg_1,
        .show_bg_2 => rpa.Layer.bg_2,
        .show_bg_3 => rpa.Layer.bg_3,
        .show_objs => rpa.Layer.obj,
        .show_col => rpa.Layer.color,
        else => null,
    };
}

fn shaderMain(screenpos: ScreenPos) void {

    // // SETUP
    // /////////////////////////////////////////////

    // used for vector select() calls
    const no_p_cols: [5]u16 = .{ 0x0000, 0x0000, 0x0000, 0x0000, 0x0000 };
    const no_wins: [5]bool = .{ false, false, false, false, false };

    // used for bad debug config
    const errcol = Color{ .r = 255, .g = 0, .b = 255 };

    // WINDOW PREPARATION
    /////////////////////////////////////////////

    // is the pixel in window 0/1?
    const px_in_win0: bool = isPixelInWin(screenpos, 0);
    const px_in_win1: bool = isPixelInWin(screenpos, 1);

    // combine win 0/1 according to the layer's merging rules:
    // is a layer's pixel inside the layer windows?
    const layer_wins: [5]bool = .{
        combineWinsForLayer(.bg_0, px_in_win0, px_in_win1),
        combineWinsForLayer(.bg_1, px_in_win0, px_in_win1),
        combineWinsForLayer(.bg_2, px_in_win0, px_in_win1),
        combineWinsForLayer(.bg_3, px_in_win0, px_in_win1),
        combineWinsForLayer(.obj, px_in_win0, px_in_win1),
    };

    // does a window apply to a layer sent to the main/sub buffer?
    const main_wins: [5]bool = @select(bool, reg.win_to_main, layer_wins, no_wins);
    const sub_wins: [5]bool = @select(bool, reg.win_to_sub, layer_wins, no_wins);

    // color window is used in a different way than the others, combine seperately
    const col_win: bool = combineWinsForLayer(.color, px_in_win0, px_in_win1);

    // is a buffer's pixel inside the color window?
    const col_win_main: bool = isPixelInColWin(true, col_win);
    const col_win_sub: bool = isPixelInColWin(false, col_win);

    // // COLOR MAIN/SUB BUFFER
    // /////////////////////////////////////////////

    // // BG and obj data: color and prio of the color's source
    const bg0_data: BGPixel = calcBGPixel(screenpos, 0);
    const bg1_data: BGPixel = calcBGPixel(screenpos, 1);
    const bg2_data: BGPixel = calcBGPixel(screenpos, 2);
    const bg3_data: BGPixel = calcBGPixel(screenpos, 3);
    const obj_data: ObjPixel = .{ .p_col = lookupPaletteColor(obj_step.palcols[screenpos.x][screenpos.y]), .prio = obj_step.prios[screenpos.x][screenpos.y] };

    // colors array for efficient processing later
    const p_cols: [5]u16 = .{ bg0_data.p_col, bg1_data.p_col, bg2_data.p_col, bg3_data.p_col, obj_data.p_col };

    // prio array for use in priority calculation later
    // objs have 4 prio settings, so handle them differently.
    const bg_prios: [4]bool = .{ bg0_data.is_prio, bg1_data.is_prio, bg2_data.is_prio, bg3_data.is_prio };
    const obj_prio = obj_data.prio;

    // should the color be sent to the main/sub buffer?
    const p_cols_main: [5]u16 = arrselx5(u16, no_p_cols, p_cols, reg.to_main);
    const p_cols_sub: [5]u16 = arrselx5(u16, no_p_cols, p_cols, reg.to_sub);

    // apply windows to buffers layer-wise
    const wind_p_cols_main: [5]u16 = arrselx5(u16, p_cols_main, no_p_cols, main_wins);
    const wind_p_cols_sub: [5]u16 = arrselx5(u16, p_cols_sub, no_p_cols, sub_wins);

    // get fallback color ("fixcol") for buffers
    // fixcol is always a packed color, but the consistent naming feels wrong...
    // TODO: ignore feelings, make consistent
    const fixcol_main: u16 = getFixcol(screenpos, true);
    const fixcol_sub: u16 = getFixcol(screenpos, false);

    // apply priority logic.
    // result: the final color for this buffer + its source layer
    const main_result: BufferPixel = resolvePrios(wind_p_cols_main, bg_prios, obj_prio, fixcol_main);
    const sub_result_pre: BufferPixel = resolvePrios(wind_p_cols_sub, bg_prios, obj_prio, fixcol_sub);

    // MAIN/SUB BUFFER AFTER PRIO RESOLVE
    /////////////////////////////////////////////

    // replace transparent pixels with fixcol. unsure if actually needed as resolvePrios does this,
    // but better safe than sorry...
    // also discard unneeded origin value for sub buffer
    const main_result_fixed: BufferPixel = .{
        .p_col = if (isPackedColorOpaque(main_result.p_col)) main_result.p_col else fixcol_main,
        .origin = main_result.origin,
    };
    const sub_result_pre_fixed: u16 = if (isPackedColorOpaque(sub_result_pre.p_col)) sub_result_pre.p_col else fixcol_sub;

    // // apply fixcol override
    // const sub_result: u16 = if (reg.fix_sub != 0) fixcol_sub else sub_result_pre_fixed;

    // // apply color window
    // const wind_main_result: BufferPixel = BufferPixel(if (col_win_main) 0x0000 else main_result_fixed.p_col, main_result_fixed.origin);
    // const wind_sub_result: u32 = if (col_win_sub) 0x0000 else sub_result;

    // // COLOR MATH AND OUTPUT
    // /////////////////////////////////////////////

    // // do color math
    // const fincol: math.Vec4 = doColorMath(wind_main_result, wind_sub_result);

    // DEBUG AND OUTPUT
    /////////////////////////////////////////////

    const debug_mode: rpa.DebugMode = @enumFromInt(reg.debug_mode);
    const debug_arg: rpa.DebugArg = @enumFromInt(reg.debug_arg);

    switch (debug_mode) {
        else => unreachable,
        // rpa.DebugMode.DEBUG_MODE_NONE => {
        //     // normal case: no debug, just output
        //     setPx(screen_x, screen_y, fincol);
        //     return;
        // },
        .layer => {
            // show just a single layer before entering the composition pipeline,
            // i.e. transformation, size, affine, mosaic
            // or, show just the objs
            const col = switch (debug_arg) {
                else => errcol,
                .show_bg_0 => unpackColor(p_cols[0]),
                .show_bg_1 => unpackColor(p_cols[1]),
                .show_bg_2 => unpackColor(p_cols[2]),
                .show_bg_3 => unpackColor(p_cols[3]),
                .show_objs => unpackColor(obj_data.p_col),
            };
            setPx(screenpos, col);
            return;
        },
        .windows_setup => {
            // show how the windows are set up based on the start/end data
            const col = Color{
                .r = if (px_in_win0) 255 else 0,
                .g = if (px_in_win1) 255 else 0,
                .b = if (!px_in_win0 and !px_in_win1) 64 else 0,
            };
            setPx(screenpos, col);
            return;
        },
        .window_comp => {
            const w = switch (debug_arg) {
                .show_bg_0 => layer_wins[@intFromEnum(rpa.Layer.bg_0)],
                .show_bg_1 => layer_wins[@intFromEnum(rpa.Layer.bg_1)],
                .show_bg_2 => layer_wins[@intFromEnum(rpa.Layer.bg_2)],
                .show_bg_3 => layer_wins[@intFromEnum(rpa.Layer.bg_3)],
                .show_objs => layer_wins[@intFromEnum(rpa.Layer.obj)],
                .show_col => col_win,
                else => {
                    setPx(screenpos, errcol);
                    return;
                },
            };

            const v: u8 = if (w) 255 else 0;
            setPx(screenpos, Color{ .r = v, .g = v, .b = v });
            return;
        },
        .windows_main => {
            const layer: rpa.Layer = debugArgToLayer(debug_arg) orelse {
                setPx(screenpos, errcol);
                return;
            };

            if (layer == .color) {
                setPx(screenpos, errcol);
                return;
            }

            if (reg.win_to_main[@intFromEnum(layer)]) {
                if (main_wins[@intFromEnum(layer)]) {
                    setPx(screenpos, Color{ .r = 255, .g = 255, .b = 255 });
                } else {
                    setPx(screenpos, Color{ .r = 0, .g = 0, .b = 0 });
                }
            } else {
                setPx(screenpos, Color{ .r = 128, .g = 0, .b = 0 });
            }
        },
        .windows_sub => {
            const layer: rpa.Layer = debugArgToLayer(debug_arg) orelse {
                setPx(screenpos, errcol);
                return;
            };

            if (layer == .color) {
                setPx(screenpos, errcol);
                return;
            }

            if (reg.win_to_sub[@intFromEnum(layer)]) {
                if (sub_wins[@intFromEnum(layer)]) {
                    setPx(screenpos, Color{ .r = 255, .g = 255, .b = 255 });
                } else {
                    setPx(screenpos, Color{ .r = 0, .g = 0, .b = 0 });
                }
            } else {
                setPx(screenpos, Color{ .r = 128, .g = 0, .b = 0 });
            }
        },
        .col_window => {
            // same as above, but for the color window
            // useful, as the col window has an additional setting

            const in_colwin = switch (debug_arg) {
                else => {
                    setPx(screenpos, errcol);
                    return;
                },
                .show_main => col_win_main,
                .show_sub => col_win_sub,
            };

            if (in_colwin) {
                setPx(screenpos, Color{ .r = 255, .b = 255, .g = 255 });
            } else {
                setPx(screenpos, Color{ .r = 0, .b = 0, .g = 0 });
            }
            return;
        },
        .buf_pre_win => {
            // main/sub buffer layers combined by priority, without the windows applied
            if (debug_arg == .show_main) {
                const pcol = resolvePrios(p_cols_main, bg_prios, obj_prio, fixcol_main).p_col;
                setPx(screenpos, unpackColor(pcol));
            } else if (debug_arg == .show_sub) {
                const pcol = resolvePrios(p_cols_sub, bg_prios, obj_prio, fixcol_sub).p_col;
                setPx(screenpos, unpackColor(pcol));
            } else {
                setPx(screenpos, errcol);
            }
            return;
        },
        .buf_post_win => {
            // main/sub buffer layers combined by priority, with the windows applied
            if (debug_arg == .show_main) {
                setPx(screenpos, unpackColor(main_result_fixed.p_col));
            } else if (debug_arg == .show_sub) {
                setPx(screenpos, unpackColor(sub_result_pre_fixed));
            } else {
                setPx(screenpos, errcol);
            }
            return;
        },
        // rpa.DebugMode.DEBUG_MODE_BUF_COLMATH_IN => {
        //     // main/sub buffer data to be fed into color math
        //     // post-win step + transparency fixed + color window applied
        //     if (reg.debug_arg == .DEBUG_ARG_SHOW_MAIN) {
        //         setPx(screen_x, screen_y, unpackColor(wind_main_result.p_col));
        //     } else if (reg.debug_arg == .DEBUG_ARG_SHOW_SUB) {
        //         setPx(screen_x, screen_y, unpackColor(wind_sub_result));
        //     } else {
        //         setPx(screen_x, screen_y, errcol);
        //     }
        //     return;
        // },
        .fixcol_setup => {
            // show fixcols for main and sub buffer
            if (debug_arg == .show_main) {
                setPx(screenpos, unpackColor(fixcol_main));
            } else if (debug_arg == .show_sub) {
                setPx(screenpos, unpackColor(fixcol_sub));
            } else {
                setPx(screenpos, errcol);
            }
            return;
        },
    }
}

const obj_step = struct {
    pub var palcols: [con.SCREEN_DIM_PIX][con.SCREEN_DIM_PIX]u8 = @splat(@splat(0));
    pub var prios: [con.SCREEN_DIM_PIX][con.SCREEN_DIM_PIX]u2 = @splat(@splat(0));

    fn getObj(obj_id: usize) bsp.Obj {
        std.debug.assert(obj_id < con.MAX_OBJS_NUM);

        const Helper = packed struct {
            a: u8,
            b: u8,
            c: u8,
            d: u8,
            z: u4,
        };

        const oamoffs2 = obj_id / 2;
        const oam2shift = 4 * (obj_id % 2);

        return @bitCast(Helper{
            .a = mem.OAM[(obj_id * 4) + 0],
            .b = mem.OAM[(obj_id * 4) + 1],
            .c = mem.OAM[(obj_id * 4) + 2],
            .d = mem.OAM[(obj_id * 4) + 3],
            .z = @truncate((mem.OAM[(256 * 4) + oamoffs2] >> @intCast(oam2shift))),
        });
    }

    fn drawObj(obj: bsp.Obj, obj_x: i32, obj_y: i32, obj_w: u8, obj_h: u8) void {
        const ow = if (obj.rot) obj_h else obj_w;
        const oh = if (obj.rot) obj_w else obj_h;

        for (0..ow) |ox| {
            for (0..oh) |oy| {
                const screen_x = @as(i32, @intCast(ox)) + obj_x;
                const screen_y = @as(i32, @intCast(oy)) + obj_y;

                if (screen_x < 0) continue;
                if (screen_y < 0) continue;
                if (screen_x >= con.SCREEN_DIM_PIX) continue;
                if (screen_y >= con.SCREEN_DIM_PIX) continue;

                var rx = ox;
                var ry = oy;

                if (obj.rot) {
                    const t = rx;
                    rx = ry;
                    ry = t;
                }

                if (obj.vflip) {
                    rx = obj_w - 1 - rx;
                }
                if (obj.hflip) {
                    ry = obj_h - 1 - ry;
                }

                const tilepos_x = rx / 8;
                const tilepos_y = ry / 8;
                const pixpos_x = rx % 8;
                const pixpos_y = ry % 8;

                const gfxid_offs = tilepos_x + tilepos_y * 16;
                const pixidx = pixpos_y * con.OBJ_GFX_UNIT_DIM_PIX + pixpos_x + ((@as(u32, obj.gfxid) | @as(u32, obj.atlid) << 9) + gfxid_offs) * con.OBJ_GFX_UNIT_PIX_NUM;
                if (isPackedColorOpaque(lookupPaletteColor(mem.OGM[pixidx]))) {
                    obj_step.prios[@intCast(screen_x)][@intCast(screen_y)] = obj.prio;
                    obj_step.palcols[@intCast(screen_x)][@intCast(screen_y)] = mem.OGM[pixidx];
                }
            }
        }
    }

    fn tick() void {
        palcols = @splat(@splat(0));
        for (0..con.MAX_OBJS_NUM) |obj_id| {
            const obj = getObj(obj_id);

            // coords are in screen space
            const obj_x: i32 = @as(i32, @intCast(obj.pos % con.OBJ_POS_DIM_PIX)) - con.OBJ_DEADZONE_N_DIM_PIX;
            const obj_y: i32 = @as(i32, @intCast(obj.pos / con.OBJ_POS_DIM_PIX)) - con.OBJ_DEADZONE_N_DIM_PIX;

            const obj_dims: [8][2]u8 = .{
                .{ 8, 8 },
                .{ 16, 16 },
                .{ 32, 32 },
                .{ 64, 64 },
                .{ 8, 16 },
                .{ 16, 8 },
                .{ 16, 32 },
                .{ 32, 16 },
            };
            const obj_dim = obj_dims[@intFromEnum(obj.size)];
            drawObj(obj, obj_x, obj_y, obj_dim[0], obj_dim[1]);
        }
    }
};

pub fn tick() void {
    obj_step.tick();
    for (0..con.SCREEN_DIM_PIX) |y| {
        for (0..con.SCREEN_DIM_PIX) |x| {
            shaderMain(.{ .x = @intCast(x), .y = @intCast(y) });
        }
    }
}
