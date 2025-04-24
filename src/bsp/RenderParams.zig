const mode8 = @import("../root.zig");
const std = @import("std");
const con = mode8.hardware.constants;
const reg = mode8.hardware.registers;
const bsp = mode8.bsp;
const bits = mode8.bsp.bits;
const Color = mode8.bsp.Color;

pub const RenderParams = struct {
    // pub const BG = enum(u2) {
    //     bg_0,
    //     bg_1,
    //     bg_2,
    //     bg_3,
    // };

    pub const Layer = enum(u3) {
        bg_0,
        bg_1,
        bg_2,
        bg_3,
        obj,
        color,
    };

    pub const DmaDir = enum(u1) {
        top_to_bottom,
        left_to_right,
    };

    pub const WinComposition = packed struct {
        neither: bool,
        win0: bool,
        win1: bool,
        both: bool,
    };

    pub const ColWinApplyAlgo = enum(u2) {
        always_on,
        direct,
        inverted,
        always_off,
    };

    // pub const MathComposeAlgo = enum(u4) {
    //     /// highest priority color is used directly
    //     normal,

    //     /// add colors together component-wise
    //     add,

    //     /// subtract sub buffer color from main buffer color component-wise
    //     subtract,

    //     /// multiply colors together and then divides by maximum value component-wise
    //     multiply,

    //     /// divice main buffer color by sub-buffer color component-wise
    //     divide,

    //     /// subtract larger value from smaller value component-wise
    //     difference,

    //     /// if sub buffer is light/dark, replace darker/lighter colors in the main buffer with sub buffer color
    //     pinlight,

    //     /// multiply compliments and take compliment of result component-wise
    //     screen,

    //     /// use darker color component-wise
    //     darken,

    //     /// use lighter color component-wise
    //     lighten,

    //     /// MULTIPLY if sub buffer is light, else SCREEN
    //     overlay,

    //     /// LIGHTEN if sub buffer is light, else DARKEN
    //     softlight,

    //     /// reserved
    //     _,
    // };

    // pub const MathNormalizeFunc = enum(u2) {
    //     /// clamp result to 0..31 component-wise
    //     clamp,

    //     /// half result and clamp to 0..31 component-wise
    //     half,

    //     /// double result and clamp to 0..31 component-wise
    //     double,

    //     /// bleed excess to other color channels
    //     bleed,
    // };

    pub const OobSetting = enum(u2) {
        wrap,
        tile,
        color,
        mirror,
    };

    pub const DebugMode = enum(u4) {
        off,
        layer,
        windows_setup,
        windows_main,
        windows_sub,
        col_window,
        window_comp,
        fixcol_setup,
        buf_pre_win,
        buf_post_win,
        buf_colmath_in,
        _,
    };

    pub const DebugArg = enum(u4) {
        none,
        show_bg_0,
        show_bg_1,
        show_bg_2,
        show_bg_3,
        show_objs,
        show_col,
        show_main,
        show_sub,
    };

    pub fn setBgSize(bg: u2, size: u10) void {
        const sz: u10 = std.math.clamp(size, 2, 512);
        // note: int cast is safe, as 512/2 = 256 -> 256-1 = 255 = 0xFF
        // design decision: panic if the BG is set to a size that can't be divided by 2, as this isn't supported.
        std.debug.assert(sz % 2 == 0);
        reg.bgsz[bg] = @intCast(sz / 2 - 1);
    }

    // pub fn setToMain(bg0: bool, bg1: bool, bg2: bool, bg3: bool, obj: bool) void {
    //     reg.to_main = bsp.bits.stoBoolx8in8(false, false, false, obj, bg3, bg2, bg1, bg0);
    // }

    // pub fn setToSub(bg0: bool, bg1: bool, bg2: bool, bg3: bool, obj: bool) void {
    //     reg.to_sub = bsp.bits.stoBoolx8in8(false, false, false, obj, bg3, bg2, bg1, bg0);
    // }

    // pub fn setFixcolMain(val: DMAData(u16)) void {
    //     switch (val) {
    //         .direct => |v| {
    //             reg.fixcol_main_do_dma = 0;
    //             reg.fixcol_main[0] = v;
    //         },
    //         .dma => |v| {
    //             reg.fixcol_main_do_dma = 1;
    //             std.mem.copyForwards(u16, &reg.fixcol_main, &v);
    //         },
    //     }
    // }

    // pub fn setFixcolSub(val: DMAData(u16)) void {
    //     switch (val) {
    //         .direct => |v| {
    //             reg.fixcol_sub_do_dma = 0;
    //             reg.fixcol_sub[0] = v;
    //         },
    //         .dma => |v| {
    //             reg.fixcol_sub_do_dma = 1;
    //             std.mem.copyForwards(u16, &reg.fixcol_sub, &v);
    //         },
    //     }
    // }

    // pub fn setMosiac(bg0_str: u4, bg1_str: u4, bg2_str: u4, bg3_str: u4) void {
    //     reg.mosiac[0] = bg0_str | (@as(u8, bg1_str) << @as(u8, 4));
    //     reg.mosiac[1] = bg2_str | (@as(u8, bg3_str) << @as(u8, 4));
    // }

    // pub fn setPrioRemap(bg0: bool, bg1: bool, bg2: bool, bg3: bool) void {
    //     reg.prio_remap = 0;
    //     reg.prio_remap |= if (bg0) 1 << 0 else 0;
    //     reg.prio_remap |= if (bg1) 1 << 1 else 0;
    //     reg.prio_remap |= if (bg2) 1 << 2 else 0;
    //     reg.prio_remap |= if (bg3) 1 << 3 else 0;
    // }

    // pub fn setDMADirBG(bg0: DMADir, bg1: DMADir, bg2: DMADir, bg3: DMADir) void {
    //     reg.dma_dir = 0;
    //     reg.dma_dir |= (@as(u8, @intFromEnum(bg0)) << @as(u8, 0));
    //     reg.dma_dir |= (@as(u8, @intFromEnum(bg1)) << @as(u8, 1));
    //     reg.dma_dir |= (@as(u8, @intFromEnum(bg2)) << @as(u8, 2));
    //     reg.dma_dir |= (@as(u8, @intFromEnum(bg3)) << @as(u8, 3));
    // }

    // pub fn setDMADirOther(win0: DMADir, win1: DMADir, fixcol_main: DMADir, fixcol_sub: DMADir) void {
    //     reg.dma_dir_ex = 0;
    //     reg.dma_dir_ex |= (@as(u8, @intFromEnum(win0)) << @as(u8, 0));
    //     reg.dma_dir_ex |= (@as(u8, @intFromEnum(win1)) << @as(u8, 1));
    //     reg.dma_dir_ex |= (@as(u8, @intFromEnum(fixcol_main)) << @as(u8, 2));
    //     reg.dma_dir_ex |= (@as(u8, @intFromEnum(fixcol_sub)) << @as(u8, 3));
    // }

    // pub fn setFixSub(yes: bool) void {
    //     reg.fix_sub = if (yes) 1 else 0;
    // }

    // pub fn setMathEnable(bg0: bool, bg1: bool, bg2: bool, bg3: bool, obj: bool, col: bool) void {
    //     reg.math_enable = bsp.bits.sto1x8in8(
    //         0,
    //         0,
    //         @intFromBool(col),
    //         @intFromBool(obj),
    //         @intFromBool(bg3),
    //         @intFromBool(bg2),
    //         @intFromBool(bg1),
    //         @intFromBool(bg0),
    //     );
    // }

    // pub fn setMathAlgo(algo: MathComposeAlgo) void {
    //     reg.math_algo = @intFromEnum(algo);
    // }

    // pub fn setMathNormalize(func: MathNormalizeFunc) void {
    //     reg.math_normalize = @intFromEnum(func);
    // }

    // pub fn setDebugMode(mode: DebugMode, arg: DebugArg) void {
    //     reg.debug = bsp.bits.sto2x4in8(@intFromEnum(mode), @intFromEnum(arg));
    // }
};
