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

const Color = packed struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8 = 255,
};

pub var BUFFER: [con.SCREEN_DIM_PIX][con.SCREEN_DIM_PIX]Color = @splat(@splat(Color{ .r = 0, .g = 0, .b = 0 }));

// ok this is way worse for the CPU than it ever was for the GPU but... eh gotta start somewhere

const OBJ_DIMS_PIX: [8][2]u32 = .{
    .{ 8, 8 },
    .{ 16, 16 },
    .{ 32, 32 },
    .{ 64, 64 },
    .{ 8, 16 },
    .{ 16, 8 },
    .{ 16, 32 },
    .{ 32, 16 },
};

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
    isprio: bool,
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

// // given a packed color, unpack it into a vec4f
// fn unpackColor(p_col: u16) Color {
//     return Color.init(
//         @as(f32, @floatFromInt((p_col & 0x001F) >> 0)) / 31.0,
//         @as(f32, @floatFromInt((p_col & 0x03E0) >> 5)) / 31.0,
//         @as(f32, @floatFromInt((p_col & 0x7C00) >> 10)) / 31.0,
//         @as(f32, @floatFromInt((p_col & 0x8000) >> 15)),
//     );
// }

// // given a packed color, check if it's opaque
// fn isPackedColorOpaque(p_col: u16) bool {
//     return (p_col & 0x8000) != 0;
// }

// // given a palette index, return the packed color stored there
// fn lookupPaletteColor(idx: u8) u16 {
//     return mem.GCM[idx] | (mem.GCM[idx + 1] << 8);
// }

// ///////////////////////////////////////////////////////////////////////////////////////////////////
// // BG TILE FUNCTIONS
// ///////////////////////////////////////////////////////////////////////////////////////////////////

// // given a viewpos and a Tile struct, find the palette index of the pixel that is at that position.
// // this implements flipping and rotation.
// fn fetchTilePixel(viewpos: Vec2u, tile_attrs: bsp.Tile) u8 {
//     // viewpos to pos inside tile
//     var pixpos: Vec2u = Vec2u.init(
//         viewpos.x() % con.TILE_GFX_DIM_PIX,
//         viewpos.y() % con.TILE_GFX_DIM_PIX,
//     );

//     // do mirroring of tile
//     if (tile_attrs.vflip) {
//         pixpos.v[0] = 7 - pixpos.x();
//     }
//     if (tile_attrs.hflip) {
//         pixpos.v[1] = 7 - pixpos.y();
//     }

//     if (tile_attrs.rot) {
//         const tmp = pixpos.x();
//         pixpos.v[0] = pixpos.y();
//         pixpos.v[1] = tmp;
//     }

//     const gfxid = tile_attrs.gfxid | (tile_attrs.atlid << 10);

//     // 2D pixpos to 1D pix array index
//     const pixidx = pixpos.y() * con.TILE_GFX_DIM_PIX + pixpos.x() + gfxid * con.TILE_GFX_PIX_NUM;
//     return mem.TGM[pixidx];
// }

// // given a viewpos and a BG, get the tile that is being viewed from the TAM
// fn fetchTileAttrs(bg: u32, bgoffs: Vec2u, viewpos: Vec2u) bsp.Tile {
//     // viewpos to tilepos
//     const tilepos: Vec2u = Vec2u.divScalar(viewpos, con.TILE_GFX_DIM_PIX).add(bgoffs);
//     // 2D tilepos to 1D tile array index
//     const tileidx = (tilepos.y() * con.BG_DIM_TIL) + tilepos.x() + (bg * con.BG_DIM_TIL * con.BG_DIM_TIL);

//     const dat: u16 = mem.TAM[tileidx] | (mem.TAM[tileidx + 1] << 8);
//     return @bitCast(dat);
// }

// // normally, the pos of a pixel on the screen is == the position to look up in the TAM.
// // mosiac, affine xform and scrolling are implemented by remapping the screenpos into a viewpos
// fn toTileAttrViewPos(bg: u32, screenpos: Vec2u) Vec2i {
//     var viewpos = Vec2i.init(screenpos.x(), screenpos.y());
//     viewpos = (viewpos / i32(reg.mosiac[bg])) * i32(reg.mosiac[bg]);

//     const index: u32 = if (reg.dma_dir_bg[bg]) screenpos.x() else screenpos.y();

//     const xscroll: i32 = if (reg.xscroll_do_dma[bg]) reg.xscroll[bg][index] else reg.xscroll[bg][0];
//     const yscroll: i32 = if (reg.yscroll_do_dma[bg]) reg.yscroll[bg][index] else reg.yscroll[bg][0];

//     const x0: i32 = if (reg.affine_x0_do_dma[bg]) reg.affine_x0[bg][index] else reg.affine_x0[bg][0];
//     const y0: i32 = if (reg.affine_y0_do_dma[bg]) reg.affine_y0[bg][index] else reg.affine_y0[bg][0];
//     const a: f32 = if (reg.affine_a_do_dma[bg]) reg.affine_a[bg][index] else reg.affine_a[bg][0];
//     const b: f32 = if (reg.affine_b_do_dma[bg]) reg.affine_b[bg][index] else reg.affine_b[bg][0];
//     const c: f32 = if (reg.affine_c_do_dma[bg]) reg.affine_c[bg][index] else reg.affine_c[bg][0];
//     const d: f32 = if (reg.affine_d_do_dma[bg]) reg.affine_d[bg][index] else reg.affine_d[bg][0];

//     const affine_mat = math.mat2x2(.{ a, b }, .{ c, d });
//     const affine_vec1: math.Vec2 = math.vec2(@floatFromInt(viewpos.x()), @floatFromInt(viewpos.y())).add(math.vec2(@floatFromInt(xscroll), @floatFromInt(yscroll))).sub(math.vec2(@floatFromInt(x0), @floatFromInt(y0)));
//     const affine_vec2: math.Vec2 = math.vec2.init(x0, y0);

//     const viewpos_pre: math.Vec2 = affine_mat.mulVec(affine_vec1).add(affine_vec2);
//     viewpos = Vec2u.init(@intFromFloat(viewpos_pre.x()), @intFromFloat(viewpos_pre.y()));

//     return viewpos;
// }

// // given the screenpos, calculate the packed color for that pixel based on the specified BG.
// fn calcBGPixel(screenpos: Vec2u, bg: u2) BGPixel {
//     var viewpos_pre = toTileAttrViewPos(bg, screenpos);

//     const bgsz = reg.bgsz[bg] * 8;

//     const viewpos_pre_in_bounds: bool = (viewpos_pre.x < 0 or viewpos_pre.y < 0 or viewpos_pre.x >= i32(bgsz) or viewpos_pre.y >= i32(bgsz));

//     if (!viewpos_pre_in_bounds) {
//         const viewpos = Vec2u.init(viewpos_pre.x(), viewpos_pre.y());
//         const tile_attrs = fetchTileAttrs(bg, reg.bg_sz[bg], reg.bg_offs[bg], viewpos);
//         const tilecol_idx = fetchTilePixel(viewpos, tile_attrs);
//         return BGPixel{
//             .p_col = lookupPaletteColor(tilecol_idx),
//             .isprio = tile_attrs.prio == 1,
//         };
//     }
//     switch (reg.oob_setting[bg]) {
//         .OOB_SETTING_CLAMP => {
//             viewpos_pre = Vec2i.clamp(Vec2i.init(0, 0), viewpos_pre, Vec2i.init(i32(bgsz), i32(bgsz)));
//             var viewpos = Vec2u.init(viewpos_pre.x(), viewpos_pre.y());
//             // else color is taken from "next" tile instead of the one on the border
//             if (viewpos.x >= bgsz) {
//                 viewpos.x -= 1;
//             }
//             if (viewpos.y >= bgsz) {
//                 viewpos.y -= 1;
//             }
//             const tile_attrs = fetchTileAttrs(bg, reg.bg_sz[bg], reg.bg_offs[bg], viewpos);
//             const tilecol_idx = fetchTilePixel(viewpos, tile_attrs);
//             return BGPixel(lookupPaletteColor(tilecol_idx), tile_attrs.prio);
//         },
//         .OOB_SETTING_COLOR => {
//             return BGPixel(reg.oob_data[bg] & 0xFFFF, false);
//         },
//         .OOB_SETTING_TILE => {
//             const dummy = bsp.Tile{
//                 (reg.oob_data[bg] & 0x0FFF) >> 0,
//                 (reg.oob_data[bg] & 0x1000) != 0,
//                 (reg.oob_data[bg] & 0x2000) != 0,
//                 (reg.oob_data[bg] & 0x4000) != 0,
//                 (reg.oob_data[bg] & 0x8000) != 0,
//             };
//             const viewpos = Vec2u.init(viewpos_pre.x(), viewpos_pre.y());
//             const tilecol_idx = fetchTilePixel(viewpos, dummy);

//             return BGPixel(lookupPaletteColor(tilecol_idx), dummy.prio);
//         },
//         .OOB_SETTING_WRAP => { // OOB_SETTING_WRAP
//             // manual modulo for negative values
//             if (viewpos_pre.x < 0 or viewpos_pre.y < 0) {
//                 const diff = -viewpos_pre;
//                 const mult = (diff / i32(bgsz)) + 1;
//                 viewpos_pre += i32(bgsz) * mult;
//             }
//             const viewpos = Vec2u.init(viewpos_pre.x() % bgsz, viewpos_pre.y() % bgsz);
//             const tile_attrs = fetchTileAttrs(bg, reg.bg_sz[bg], reg.bg_offs[bg], viewpos);
//             const tilecol_idx = fetchTilePixel(viewpos, tile_attrs);
//             return BGPixel(lookupPaletteColor(tilecol_idx), tile_attrs.prio);
//         },
//     }
// }

// ///////////////////////////////////////////////////////////////////////////////////////////////////
// // OBJ FUNCTIONS
// ///////////////////////////////////////////////////////////////////////////////////////////////////

// // given an object's index, get its attributes from the OAM
// fn fetchObjAttrs(obj_idx: u32) bsp.Obj {
//     const packed_1 = mem.OAM[obj_idx] | (mem.OAM[obj_idx + 1] << 8) | (mem.OAM[obj_idx + 2] << 16) | (mem.OAM[obj_idx + 3] << 24);
//     const oamoffs2 = obj_idx / 2;
//     const oam2shift = 4 * (obj_idx % 2);
//     const packed_2 = (mem.OAM[256 + oamoffs2] >> oam2shift) & 0xF; // argh

//     return .{
//         // correct for obj playfield (360^2) vs screen dim (256^2)
//         (packed_1 & 0x01FFFF),
//         (packed_1 & 0x0FFE0000) >> 17,
//         (packed_1 & 0x10000000) != 0,
//         (packed_1 & 0x20000000) != 0,
//         (packed_1 & 0xC0000000) >> 30,
//         (packed_2 & 0x7),
//         (packed_2 & 0x8) != 0,
//     };
// }

// // given the screenpos and an Obj struct, find the packed color of the pixel at that position.
// // this implements flipping and rotation.
// // note that this uses the screenpos as the obj playfield is independent of the BGs.
// fn fetchObjPixel(screenpos: Vec2u, obj_attrs: bsp.Obj) ?u16 {
//     // what a horrible day to be a GPU 2: electric boogaloo

//     // shift obj to top right corner, move screenpos accordingly
//     const objpos = Vec2u.init((obj_attrs.pos % con.OBJ_POS_DIM_PIX), (obj_attrs.pos / con.OBJ_POS_DIM_PIX));

//     var relpos = screenpos.sub(objpos);
//     if (screenpos.x() < obj_attrs.pos.x) {
//         relpos.v[0] = screenpos.x() + con.OBJ_POS_DIM_PIX - objpos.x();
//     }
//     if (screenpos.y() < obj_attrs.pos.y) {
//         relpos.v[1] = screenpos.y() + con.OBJ_POS_DIM_PIX - objpos.y();
//     }

//     const objsize = OBJ_DIMS_PIX[obj_attrs.size];

//     if (obj_attrs.rot) {
//         const t = relpos.x;
//         relpos.x = relpos.y;
//         relpos.y = t;
//     }
//     if (obj_attrs.vflip) {
//         relpos.x = objsize.x - 1 - relpos.x;
//     }
//     if (obj_attrs.hflip) {
//         relpos.y = objsize.y - 1 - relpos.y;
//     }

//     if (relpos.x < 0 or relpos.y < 0) {
//         return null;
//     }
//     if (relpos.x >= objsize.x or relpos.y >= objsize.y) {
//         return null;
//     }

//     const tilepos: Vec2u = relpos / 8;
//     const gfxid_offset = tilepos.x + tilepos.y * 16;

//     const pixpos: Vec2u = relpos % 8;
//     const pixidx = pixpos.y * con.OBJ_GFX_UNIT_DIM_PIX + pixpos.x + (obj_attrs.gfxid + gfxid_offset) * con.OBJ_GFX_UNIT_PIX_NUM;
//     const ogmoffs_u32 = pixidx / 4;
//     const ogmshift = 8 * (pixidx % 4);
//     return (mem.OGM[ogmoffs_u32] >> ogmshift) & 0xFF;
// }

// // given the screenpos, search for the obj with the highest prio (highest OAM index == tiebreaker).
// // get the obj's prio and the packed color at that screenpos.
// fn calcObjsPixel(screenpos: Vec2u) ObjPixel {
//     var candidate = ObjPixel{
//         0x0000,
//         0,
//     };

//     // what a horrible day to be a GPU
//     for (0..con.MAX_OBJS_NUM) |i| {
//         const oam_data = fetchObjAttrs(i);

//         const objcol_index = fetchObjPixel(screenpos, oam_data);
//         if (objcol_index == null) {
//             continue;
//         }
//         const col = lookupPaletteColor(objcol_index);

//         if (!isPackedColorOpaque(col)) {
//             continue;
//         }
//         if (oam_data.prio < candidate.prio) {
//             continue;
//         }
//         candidate.p_col = col;
//         candidate.prio = oam_data.prio;
//     }
//     return candidate;
// }

///////////////////////////////////////////////////////////////////////////////////////////////////
// WINDOW FUNCTIONS
///////////////////////////////////////////////////////////////////////////////////////////////////

// given the screenpos, check if it's inside the specified window
fn isPixelInWin(screenpos: ScreenPos, win: u32) bool {
    const do_start_dma = reg.win_start_do_dma[win];
    const do_end_dma = reg.win_end_do_dma[win];
    const dma_dir: rpa.DMADir = @enumFromInt(reg.dma_dir_win[win]);

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

// fn isPixelInColWin(is_main: bool, data_in: bool) bool {
//     const Helper = packed struct {
//         lo: u4,
//         hi: u4,
//     };
//     const val: Helper = @bitCast(reg.win_apply);

//     const setting: u2 = if (is_main) @intCast(val.lo & 0x3) else @intCast(val.hi & 0x3);

//     return switch (setting) {
//         0 => true, // ALWAYS ON
//         1 => data_in, // DIRECT
//         2 => !data_in, // INVERTED
//         3 => false, // ALWAYS OFF
//     };
// }

// ///////////////////////////////////////////////////////////////////////////////////////////////////
// // THE LONG ONE
// ///////////////////////////////////////////////////////////////////////////////////////////////////

// // resolve BG and obj prios to produce the final color for a pixel
// fn resolvePrios(cols: [5]u32, bg_is_prio: [4]bool, obj_prio: u32, fixcol: u32) BufferPixel {

//     // what a horrible day to be a GPU 3: revenge of the if chain (something something yandere simulator. ha ha.)

//     // precalc this. the compiler will probably figure this out itself but it feels right.
//     const is_opaque: [5]bool = .{
//         isPackedColorOpaque(cols[0]),
//         isPackedColorOpaque(cols[1]),
//         isPackedColorOpaque(cols[2]),
//         isPackedColorOpaque(cols[3]),
//         isPackedColorOpaque(cols[4]),
//     };

//     // this could probably be reduced using some analysis.
//     // if you want do that for some reason, open a PR :)

//     if (reg.prio_remap[3] and bg_is_prio[3] and is_opaque[3]) {
//         return .{ cols[3], 3 };
//     }

//     if (reg.prio_remap[2] and bg_is_prio[2] and is_opaque[2]) {
//         return .{ cols[2], 2 };
//     }

//     if (reg.prio_remap[1] and bg_is_prio[1] and is_opaque[1]) {
//         return .{ cols[1], 1 };
//     }

//     if (reg.prio_remap[0] and bg_is_prio[0] and is_opaque[0]) {
//         return .{ cols[0], 0 };
//     }

//     if (obj_prio == 3 and is_opaque[4]) {
//         return .{ cols[4], 4 };
//     }

//     if (bg_is_prio[3] and is_opaque[3]) {
//         return .{ cols[3], 3 };
//     }

//     if (bg_is_prio[2] and is_opaque[2]) {
//         return .{ cols[2], 2 };
//     }

//     if (obj_prio == 2 and is_opaque[4]) {
//         return .{ cols[4], 4 };
//     }

//     if (!bg_is_prio[3] and is_opaque[3]) {
//         return .{ cols[3], 3 };
//     }

//     if (!bg_is_prio[2] and is_opaque[2]) {
//         return .{ cols[2], 2 };
//     }

//     if (obj_prio == 1 and is_opaque[4]) {
//         return .{ cols[4], 4 };
//     }

//     if (bg_is_prio[1] and is_opaque[1]) {
//         return .{ cols[1], 1 };
//     }

//     if (bg_is_prio[0] and is_opaque[0]) {
//         return .{ cols[0], 0 };
//     }

//     if (obj_prio == 0 and is_opaque[4]) {
//         return .{ cols[4], 4 };
//     }

//     if (!bg_is_prio[1] and is_opaque[1]) {
//         return .{ cols[1], 1 };
//     }

//     if (!bg_is_prio[0] and is_opaque[0]) {
//         return .{ cols[0], 0 };
//     }

//     // fallthrough: set to fixcol
//     return .{ fixcol, 5 };
// }

// ///////////////////////////////////////////////////////////////////////////////////////////////////
// // FIXCOL FUNCTION
// ///////////////////////////////////////////////////////////////////////////////////////////////////

// fn getFixcol(screenpos: Vec2u, for_main: bool) u16 {
//     const magic_num: u32 = if (for_main) 2 else 3;
//     const do_dma_switch: bool = if (for_main) reg.fixcol_main_do_dma != 0 else reg.fixcol_sub_do_dma != 0;

//     const index_raw: u32 = if (reg.dma_dir_ex & (1 << magic_num)) screenpos.x() else screenpos.y();
//     const index: u32 = if (do_dma_switch) index_raw else 0;

//     return if (for_main)
//         reg.fixcol_main[index * 2] | (reg.fixcol_main[index * 2 + 1] << 8)
//     else
//         reg.fixcol_sub[index * 2] | (reg.fixcol_sub[index * 2 + 1] << 8);
// }

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

// // array select x5
// fn arrselx5(T: type, no: [5]T, yes: [5]T, decide: [5]bool) [5]T {
//     return .{
//         if (decide[0]) yes[0] else no[0],
//         if (decide[1]) yes[1] else no[1],
//         if (decide[2]) yes[2] else no[2],
//         if (decide[3]) yes[3] else no[3],
//         if (decide[4]) yes[4] else no[4],
//     };
// }

// ///////////////////////////////////////////////////////////////////////////////////////////////////
// // MAIN
// ///////////////////////////////////////////////////////////////////////////////////////////////////

fn setPx(screenpos: ScreenPos, color: Color) void {
    BUFFER[screenpos.x][screenpos.y] = color;
}

fn shaderMain(screenpos: ScreenPos) void {

    // // SETUP
    // /////////////////////////////////////////////

    // // used for vector select() calls
    // const no_p_cols: [5]u16 = .{ 0x0000, 0x0000, 0x0000, 0x0000, 0x0000 };
    // const no_wins: [5]bool = .{ false, false, false, false, false };

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

    // const Helper = packed struct {
    //     bits: [8]bool,
    // };

    // // does a window apply to a layer sent to the main/sub buffer?
    // const main_wins: [5]bool = arrselx5(bool, no_wins, layer_wins, @as(Helper, @bitCast(reg.win_to_main)).bits[0..6]);
    // const sub_wins: [5]bool = arrselx5(bool, no_wins, layer_wins, @as(Helper, @bitCast(reg.win_to_sub)).bits[0..6]);

    // color window is used in a different way than the others, combine seperately
    const col_win: bool = combineWinsForLayer(.color, px_in_win0, px_in_win1);

    // // is a buffer's pixel inside the color window?
    // const col_win_main: bool = isPixelInColWin(true, col_win);
    // const col_win_sub: bool = isPixelInColWin(false, col_win);

    // // COLOR MAIN/SUB BUFFER
    // /////////////////////////////////////////////

    // // BG and obj data: color and prio of the color's source
    // const bg0_data: BGPixel = calcBGPixel(screen_x, screen_y, 0);
    // const bg1_data: BGPixel = calcBGPixel(screen_x, screen_y, 1);
    // const bg2_data: BGPixel = calcBGPixel(screen_x, screen_y, 2);
    // const bg3_data: BGPixel = calcBGPixel(screen_x, screen_y, 3);
    // const obj_data: ObjPixel = calcObjsPixel(screen_x, screen_y);

    // // colors array for efficient processing later
    // const p_cols: [5]u16 = .{ bg0_data.p_col, bg1_data.p_col, bg2_data.p_col, bg3_data.p_col, obj_data.p_col };

    // // prio array for use in priority calculation later
    // // objs have 4 prio settings, so handle them differently.
    // const bg_prios: [4]bool = .{ bg0_data.isprio, bg1_data.isprio, bg2_data.isprio, bg3_data.isprio };
    // const obj_prio: u32 = obj_data.prio;

    // // should the color be sent to the main/sub buffer?
    // const tm: Helper = @bitCast(reg.to_main);
    // const sm: Helper = @bitCast(reg.to_sub);

    // const p_cols_main: [5]u16 = arrselx5(u16, no_p_cols, p_cols, tm[0..6]);
    // const p_cols_sub: [5]u16 = arrselx5(u16, no_p_cols, p_cols, sm[0..6]);

    // // apply windows to buffers layer-wise
    // const wind_p_cols_main: [5]u16 = arrselx5(u16, p_cols_main, no_p_cols, main_wins);
    // const wind_p_cols_sub: [5]u16 = arrselx5(u16, p_cols_sub, no_p_cols, sub_wins);

    // // get fallback color ("fixcol") for buffers
    // // fixcol is always a packed color, but the consistent naming feels wrong...
    // // TODO: ignore feelings, make consistent
    // const fixcol_main: u16 = getFixcol(screen_x, screen_y, true);
    // const fixcol_sub: u16 = getFixcol(screen_x, screen_y, false);

    // // apply priority logic.
    // // result: the final color for this buffer + its source layer
    // const main_result: BufferPixel = resolvePrios(wind_p_cols_main, bg_prios, obj_prio, fixcol_main);
    // const sub_result_pre: BufferPixel = resolvePrios(wind_p_cols_sub, bg_prios, obj_prio, fixcol_sub);

    // // MAIN/SUB BUFFER AFTER PRIO RESOLVE
    // /////////////////////////////////////////////

    // // replace transparent pixels with fixcol. unsure if actually needed as resolvePrios does this,
    // // but better safe than sorry...
    // // also discard unneeded origin value for sub buffer
    // const main_result_fixed: BufferPixel = .{
    //     .p_col = if (isPackedColorOpaque(main_result.p_col)) main_result.p_col else fixcol_main,
    //     .origin = main_result.origin,
    // };
    // const sub_result_pre_fixed: u16 = if (isPackedColorOpaque(sub_result_pre.p_col)) sub_result_pre.p_col else fixcol_sub;

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

    switch (@as(rpa.DebugMode, @enumFromInt(reg.debug_mode))) {
        else => unreachable,
        // rpa.DebugMode.DEBUG_MODE_NONE => {
        //     // normal case: no debug, just output
        //     setPx(screen_x, screen_y, fincol);
        //     return;
        // },
        // rpa.DebugMode.DEBUG_MODE_LAYER => {
        //     // show just a single layer before entering the composition pipeline,
        //     // i.e. transformation, size, affine, mosaic
        //     if (reg.debug_arg > .DEBUG_ARG_SHOW_OBJS) {
        //         setPx(screen_x, screen_y, errcol);
        //         return;
        //     }
        //     setPx(screen_x, screen_y, unpackColor(p_cols[@intFromEnum(reg.debug_arg)]));
        //     return;
        // },
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
            const w = switch (@as(rpa.DebugArg, @enumFromInt(reg.debug_arg))) {
                .show_bg_0 => layer_wins[0],
                .show_bg_1 => layer_wins[1],
                .show_bg_2 => layer_wins[2],
                .show_bg_3 => layer_wins[3],
                .show_objs => layer_wins[4],
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
        // rpa.DebugMode.DEBUG_MODE_WINDOWS_MAIN => {
        //     // show how the windows apply to a certain layer in the main buffer.
        //     // useful for checking if the win is applied to the layer.
        //     if (reg.debug_arg > .DEBUG_ARG_SHOW_OBJS) {
        //         setPx(screen_x, screen_y, errcol);
        //         return;
        //     }

        //     if (reg.win_to_main[@intFromEnum(reg.debug_arg)]) {
        //         if (main_wins[@intFromEnum(reg.debug_arg)]) {
        //             setPx(screen_x, screen_y, Color.init(0, 1, 0, 1));
        //         } else {
        //             setPx(screen_x, screen_y, Color.init(0, 0, 0, 1));
        //         }
        //         return;
        //     } else {
        //         setPx(screen_x, screen_y, Color.init(0.5, 0, 0, 1));
        //         return;
        //     }
        // },
        // rpa.DebugMode.DEBUG_MODE_WINDOWS_SUB => {
        //     // same as above, but for the sub buffers
        //     if (reg.debug_arg > .DEBUG_ARG_SHOW_OBJS) {
        //         setPx(screen_x, screen_y, errcol);
        //         return;
        //     }

        //     if (reg.win_to_sub[@intFromEnum(reg.debug_arg)]) {
        //         if (sub_wins[@intFromEnum(reg.debug_arg)]) {
        //             setPx(screen_x, screen_y, Color.init(0, 1, 0, 1));
        //         } else {
        //             setPx(screen_x, screen_y, Color.init(0, 0, 0, 1));
        //         }
        //         return;
        //     } else {
        //         setPx(screen_x, screen_y, Color.init(0.5, 0, 0, 1));
        //         return;
        //     }
        // },
        // rpa.DebugMode.DEBUG_MODE_COL_WINDOW => {
        //     // same as above, but for the color window
        //     // useful, as the col window has an additional setting

        //     var trig: bool = undefined;
        //     if (reg.debug_arg == .DEBUG_ARG_SHOW_MAIN) {
        //         trig = col_win_main;
        //     } else if (reg.debug_arg == .DEBUG_ARG_SHOW_SUB) {
        //         trig = col_win_sub;
        //     } else {
        //         setPx(screen_x, screen_y, errcol);
        //         return;
        //     }

        //     if (trig) {
        //         setPx(screen_x, screen_y, Color.init(1, 1, 1, 1));
        //     } else {
        //         setPx(screen_x, screen_y, Color.init(0, 0, 0, 1));
        //     }
        //     return;
        // },
        // rpa.DebugMode.DEBUG_MODE_BUF_PRE_WIN => {
        //     // main/sub buffer layers combined by priority, without the windows applied
        //     if (reg.debug_arg == .DEBUG_ARG_SHOW_MAIN) {
        //         const pcol: u32 = resolvePrios(p_cols_main, bg_prios, obj_prio, fixcol_main).p_col;
        //         setPx(screen_x, screen_y, unpackColor(pcol));
        //     } else if (reg.debug_arg == .DEBUG_ARG_SHOW_SUB) {
        //         const pcol: u32 = resolvePrios(p_cols_sub, bg_prios, obj_prio, fixcol_sub).p_col;
        //         setPx(screen_x, screen_y, unpackColor(pcol));
        //     } else {
        //         setPx(screen_x, screen_y, errcol);
        //     }
        //     return;
        // },
        // rpa.DebugMode.DEBUG_MODE_BUF_POST_WIN => {
        //     // main/sub buffer layers combined by priority, with the windows applied
        //     if (reg.debug_arg == .DEBUG_ARG_SHOW_MAIN) {
        //         setPx(screen_x, screen_y, unpackColor(main_result_fixed.p_col));
        //     } else if (reg.debug_arg == .DEBUG_ARG_SHOW_SUB) {
        //         setPx(screen_x, screen_y, unpackColor(sub_result_pre_fixed));
        //     } else {
        //         setPx(screen_x, screen_y, errcol);
        //     }
        //     return;
        // },
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
        // rpa.DebugMode.DEBUG_MODE_FIXCOL_SETUP => {
        //     // show fixcols for main and sub buffer
        //     if (reg.debug_arg == .DEBUG_ARG_SHOW_MAIN) {
        //         setPx(screen_x, screen_y, unpackColor(fixcol_main));
        //     } else if (reg.debug_arg == .DEBUG_ARG_SHOW_SUB) {
        //         setPx(screen_x, screen_y, unpackColor(fixcol_sub));
        //     } else {
        //         setPx(screen_x, screen_y, errcol);
        //     }
        //     return;
        // },
    }
}

pub fn tick() void {
    for (0..con.SCREEN_DIM_PIX) |y| {
        for (0..con.SCREEN_DIM_PIX) |x| {
            shaderMain(.{ .x = @intCast(x), .y = @intCast(y) });
        }
    }
}
