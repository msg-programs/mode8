const mode8 = @import("../root.zig");
const std = @import("std");
const con = mode8.hardware.constants;
const reg = mode8.hardware.registers;
const bsp = mode8.bsp;
const bits = mode8.bsp.bits;
const Color = mode8.bsp.Color;

pub const RenderParams = struct {
    pub const DMADir = enum(u1) {
        X,
        Y,
    };

    pub fn DMAData(comptime T: type) type {
        return union(enum) {
            direct: T,
            dma: [con.DMA_NUM]T,
        };
    }

    pub const WinComposition = packed struct {
        neither: bool,
        win0: bool,
        win1: bool,
        both: bool,
    };

    pub const ColWinApplyAlgo = enum(u2) {
        ALWAYS_ON,
        DIRECT,
        INVERTED,
        ALWAYS_OFF,
    };

    pub const MathComposeAlgo = enum(u4) {
        /// highest priority color is used directly
        NORMAL,

        /// add colors together component-wise
        ADD,

        /// subtract sub buffer color from main buffer color component-wise
        SUBTRACT,

        /// multiply colors together and then divides by maximum value component-wise
        MULTIPLY,

        /// divice main buffer color by sub-buffer color component-wise
        DIVIDE,

        /// subtract larger value from smaller value component-wise
        DIFFERENCE,

        /// if sub buffer is light/dark, replace darker/lighter colors in the main buffer with sub buffer color
        PINLIGHT,

        /// multiply compliments and take compliment of result component-wise
        SCREEN,

        /// use darker color component-wise
        DARKEN,

        /// use lighter color component-wise
        LIGHTEN,

        /// MULTIPLY if sub buffer is light, else SCREEN
        OVERLAY,

        /// LIGHTEN if sub buffer is light, else DARKEN
        SOFTLIGHT,

        /// reserved
        RESERVED_1,
        RESERVED_2,
        RESERVED_3,
        RESERVED_4,
    };

    pub const MathNormalizeFunc = enum(u2) {
        /// clamp result to 0..31 component-wise
        CLAMP_RESULT,

        /// half result and clamp to 0..31 component-wise
        HALF_RESULT,

        /// double result and clamp to 0..31 component-wise
        DOUBLE_RESULT,

        /// bleed excess to other color channels
        BLEED_RESULT,
    };

    pub const OOBSetting = enum(u2) {
        WRAP,
        TILE,
        COLOR,
        CLAMP,
    };

    pub const OOBData = union(OOBSetting) {
        WRAP: bool,
        TILE: bsp.Tile,
        COLOR: u16,
        CLAMP: bool,
    };

    pub const DebugMode = enum(u4) {
        DEBUG_MODE_NONE = 0,
        DEBUG_MODE_LAYER = 1,
        DEBUG_MODE_WINDOWS_SETUP = 2,
        DEBUG_MODE_WINDOWS_MAIN = 3,
        DEBUG_MODE_WINDOWS_SUB = 4,
        DEBUG_MODE_COL_WINDOW = 5,
        DEBUG_MODE_WINDOW_COMP = 7,
        DEBUG_MODE_FIXCOL_SETUP = 8,
        DEBUG_MODE_BUF_PRE_WIN = 9,
        DEBUG_MODE_BUF_POST_WIN = 11,
        DEBUG_MODE_BUF_COLMATH_IN = 13,
    };

    pub const DebugArg = enum(u4) {
        DEBUG_ARG_SHOW_BG_0 = 0,
        DEBUG_ARG_SHOW_BG_1 = 1,
        DEBUG_ARG_SHOW_BG_2 = 2,
        DEBUG_ARG_SHOW_BG_3 = 3,
        DEBUG_ARG_SHOW_OBJS = 4,
        DEBUG_ARG_SHOW_COL = 5,
        DEBUG_ARG_SHOW_MAIN = 6,
        DEBUG_ARG_SHOW_SUB = 7,
        DEBUG_ARG_NONE = 15,
    };

    pub fn setBGSize(bg0_size: u10, bg1_size: u10, bg2_size: u10, bg3_size: u10) void {
        const bg0: u10 = std.math.clamp(bg0_size, 2, 512);
        const bg1: u10 = std.math.clamp(bg1_size, 2, 512);
        const bg2: u10 = std.math.clamp(bg2_size, 2, 512);
        const bg3: u10 = std.math.clamp(bg3_size, 2, 512);
        reg.bgsz[0] = @truncate((bg0 / 2) - 1);
        reg.bgsz[1] = @truncate((bg1 / 2) - 1);
        reg.bgsz[2] = @truncate((bg2 / 2) - 1);
        reg.bgsz[3] = @truncate((bg3 / 2) - 1);
    }

    pub fn setBGTAMOffset(bg: u2, x: u4, y: u4) void {
        reg.bgoffs[bg] = bits.sto2x4in8(x, y);
    }

    pub fn setOOBSetting(bg0_data: OOBData, bg1_data: OOBData, bg2_data: OOBData, bg3_data: OOBData) void {
        const arr: [4]OOBData = .{
            bg0_data, bg1_data, bg2_data, bg3_data,
        };
        reg.oob_setting = 0;
        for (arr, 0..) |dat, bg| {
            switch (dat) {
                .WRAP => {
                    reg.oob_data[bg][0] = 0;
                    reg.oob_data[bg][1] = 0;
                    reg.oob_setting |= (@as(u8, @intFromEnum(OOBSetting.WRAP)) << (@as(u3, @truncate(bg)) * 2));
                },
                .TILE => |v| {
                    const t: u16 = @bitCast(v);
                    reg.oob_data[bg][0] = @truncate(t & 0xFF);
                    reg.oob_data[bg][1] = @truncate((t & 0xFF00) >> 8);
                    reg.oob_setting |= (@as(u8, @intFromEnum(OOBSetting.TILE)) << (@as(u3, @truncate(bg)) * 2));
                },
                .COLOR => |v| {
                    reg.oob_data[bg][0] = @truncate(v & 0xFF);
                    reg.oob_data[bg][1] = @truncate((v & 0xFF00) >> 8);
                    reg.oob_setting |= (@as(u8, @intFromEnum(OOBSetting.COLOR)) << (@as(u3, @truncate(bg)) * 2));
                },
                .CLAMP => {
                    reg.oob_data[bg][0] = 0;
                    reg.oob_data[bg][1] = 0;
                    reg.oob_setting |= (@as(u8, @intFromEnum(OOBSetting.CLAMP)) << (@as(u3, @truncate(bg)) * 2));
                },
            }
        }
    }

    pub fn setXScroll(bg: u2, val: DMAData(i32)) void {
        switch (val) {
            .direct => |v| {
                reg.xscroll_do_dma &= ~(@as(u8, 1) << bg);
                reg.xscroll[bg][0] = v;
            },
            .dma => |v| {
                reg.xscroll_do_dma |= (@as(u8, 1) << bg);
                std.mem.copyForwards(i32, &reg.xscroll[bg], &v);
            },
        }
    }

    pub fn setYScroll(bg: u2, val: DMAData(i32)) void {
        switch (val) {
            .direct => |v| {
                reg.yscroll_do_dma &= ~(@as(u8, 1) << bg);
                reg.yscroll[bg][0] = v;
            },
            .dma => |v| {
                reg.yscroll_do_dma |= (@as(u8, 1) << bg);
                std.mem.copyForwards(i32, &reg.yscroll[bg], &v);
            },
        }
    }

    pub fn setAffineX0(bg: u2, val: DMAData(i32)) void {
        switch (val) {
            .direct => |v| {
                reg.affine_x0_do_dma &= ~(@as(u8, 1) << bg);
                reg.affine_x0[bg][0] = v;
            },
            .dma => |v| {
                reg.affine_x0_do_dma |= (@as(u8, 1) << bg);
                std.mem.copyForwards(i32, &reg.affine_x0[bg], &v);
            },
        }
    }

    pub fn setAffineY0(bg: u2, val: DMAData(i32)) void {
        switch (val) {
            .direct => |v| {
                reg.affine_y0_do_dma &= ~(@as(u8, 1) << bg);
                reg.affine_y0[bg][0] = v;
            },
            .dma => |v| {
                reg.affine_y0_do_dma |= (@as(u8, 1) << bg);
                std.mem.copyForwards(i32, &reg.affine_y0[bg], &v);
            },
        }
    }

    pub fn setAffineA(bg: u2, val: DMAData(f32)) void {
        switch (val) {
            .direct => |v| {
                reg.affine_a_do_dma &= ~(@as(u8, 1) << bg);
                reg.affine_a[bg][0] = v;
            },
            .dma => |v| {
                reg.affine_a_do_dma |= (@as(u8, 1) << bg);
                std.mem.copyForwards(f32, &reg.affine_a[bg], &v);
            },
        }
    }

    pub fn setAffineB(bg: u2, val: DMAData(f32)) void {
        switch (val) {
            .direct => |v| {
                reg.affine_b_do_dma &= ~(@as(u8, 1) << bg);
                reg.affine_b[bg][0] = v;
            },
            .dma => |v| {
                reg.affine_b_do_dma |= (@as(u8, 1) << bg);
                std.mem.copyForwards(f32, &reg.affine_b[bg], &v);
            },
        }
    }

    pub fn setAffineC(bg: u2, val: DMAData(f32)) void {
        switch (val) {
            .direct => |v| {
                reg.affine_c_do_dma &= ~(@as(u8, 1) << bg);
                reg.affine_c[bg][0] = v;
            },
            .dma => |v| {
                reg.affine_c_do_dma |= (@as(u8, 1) << bg);
                std.mem.copyForwards(f32, &reg.affine_c[bg], &v);
            },
        }
    }

    pub fn setAffineD(bg: u2, val: DMAData(f32)) void {
        switch (val) {
            .direct => |v| {
                reg.affine_d_do_dma &= ~(@as(u8, 1) << bg);
                reg.affine_d[bg][0] = v;
            },
            .dma => |v| {
                reg.affine_d_do_dma |= (@as(u8, 1) << bg);
                std.mem.copyForwards(f32, &reg.affine_d[bg], &v);
            },
        }
    }

    pub fn setWinStart(win: u1, val: DMAData(u8)) void {
        switch (val) {
            .direct => |v| {
                reg.win_bounds_do_dma &= ~(@as(u8, 1) << win);
                reg.win_start[win][0] = v;
            },
            .dma => |v| {
                reg.win_bounds_do_dma |= (@as(u8, 1) << win);
                std.mem.copyForwards(u8, &reg.win_start[win], &v);
            },
        }
    }

    pub fn setWinEnd(win: u1, val: DMAData(u8)) void {
        switch (val) {
            .direct => |v| {
                reg.win_bounds_do_dma &= ~(@as(u8, 1) << (win + @as(u3, 2)));
                reg.win_end[win][0] = v;
            },
            .dma => |v| {
                reg.win_bounds_do_dma |= (@as(u8, 1) << (win + @as(u3, 2)));
                std.mem.copyForwards(u8, &reg.win_end[win], &v);
            },
        }
    }

    pub fn setWinCompose(bg0: WinComposition, bg1: WinComposition, bg2: WinComposition, bg3: WinComposition, obj: WinComposition, col: WinComposition) void {
        reg.win_compose[0] = bsp.bits.sto2x4in8(@bitCast(bg0), @bitCast(bg1));
        reg.win_compose[1] = bsp.bits.sto2x4in8(@bitCast(bg2), @bitCast(bg3));
        reg.win_compose[2] = bsp.bits.sto2x4in8(@bitCast(obj), @bitCast(col));
    }

    pub fn setToMain(bg0: bool, bg1: bool, bg2: bool, bg3: bool, obj: bool) void {
        reg.to_main = bsp.bits.stoBoolx8in8(false, false, false, obj, bg3, bg2, bg1, bg0);
    }

    pub fn setToSub(bg0: bool, bg1: bool, bg2: bool, bg3: bool, obj: bool) void {
        reg.to_sub = bsp.bits.stoBoolx8in8(false, false, false, obj, bg3, bg2, bg1, bg0);
    }

    pub fn setWinToMain(bg0: bool, bg1: bool, bg2: bool, bg3: bool, obj: bool) void {
        reg.win_to_main = bsp.bits.stoBoolx8in8(false, false, false, obj, bg3, bg2, bg1, bg0);
    }

    pub fn setWinToSub(bg0: bool, bg1: bool, bg2: bool, bg3: bool, obj: bool) void {
        reg.win_to_sub = bsp.bits.stoBoolx8in8(false, false, false, obj, bg3, bg2, bg1, bg0);
    }

    pub fn setFixcolMain(val: DMAData(u16)) void {
        switch (val) {
            .direct => |v| {
                reg.fixcol_main_do_dma = 0;
                reg.fixcol_main[0] = v;
            },
            .dma => |v| {
                reg.fixcol_main_do_dma = 1;
                std.mem.copyForwards(u16, &reg.fixcol_main, &v);
            },
        }
    }

    pub fn setFixcolSub(val: DMAData(u16)) void {
        switch (val) {
            .direct => |v| {
                reg.fixcol_sub_do_dma = 0;
                reg.fixcol_sub[0] = v;
            },
            .dma => |v| {
                reg.fixcol_sub_do_dma = 1;
                std.mem.copyForwards(u16, &reg.fixcol_sub, &v);
            },
        }
    }

    pub fn setColWinApply(algo_main: ColWinApplyAlgo, algo_sub: ColWinApplyAlgo) void {
        reg.win_apply = bsp.bits.sto2x4in8(@intFromEnum(algo_main), @intFromEnum(algo_sub));
    }

    pub fn setMosiac(bg0_str: u4, bg1_str: u4, bg2_str: u4, bg3_str: u4) void {
        reg.mosiac[0] = bg0_str | (@as(u8, bg1_str) << @as(u8, 4));
        reg.mosiac[1] = bg2_str | (@as(u8, bg3_str) << @as(u8, 4));
    }

    pub fn setPrioRemap(bg0: bool, bg1: bool, bg2: bool, bg3: bool) void {
        reg.prio_remap = 0;
        reg.prio_remap |= if (bg0) 1 << 0 else 0;
        reg.prio_remap |= if (bg1) 1 << 1 else 0;
        reg.prio_remap |= if (bg2) 1 << 2 else 0;
        reg.prio_remap |= if (bg3) 1 << 3 else 0;
    }

    pub fn setDMADirBG(bg0: DMADir, bg1: DMADir, bg2: DMADir, bg3: DMADir) void {
        reg.dma_dir = 0;
        reg.dma_dir |= (@as(u8, @intFromEnum(bg0)) << @as(u8, 0));
        reg.dma_dir |= (@as(u8, @intFromEnum(bg1)) << @as(u8, 1));
        reg.dma_dir |= (@as(u8, @intFromEnum(bg2)) << @as(u8, 2));
        reg.dma_dir |= (@as(u8, @intFromEnum(bg3)) << @as(u8, 3));
    }

    pub fn setDMADirOther(win0: DMADir, win1: DMADir, fixcol_main: DMADir, fixcol_sub: DMADir) void {
        reg.dma_dir_ex = 0;
        reg.dma_dir_ex |= (@as(u8, @intFromEnum(win0)) << @as(u8, 0));
        reg.dma_dir_ex |= (@as(u8, @intFromEnum(win1)) << @as(u8, 1));
        reg.dma_dir_ex |= (@as(u8, @intFromEnum(fixcol_main)) << @as(u8, 2));
        reg.dma_dir_ex |= (@as(u8, @intFromEnum(fixcol_sub)) << @as(u8, 3));
    }

    pub fn setFixSub(yes: bool) void {
        reg.fix_sub = if (yes) 1 else 0;
    }

    pub fn setMathEnable(bg0: bool, bg1: bool, bg2: bool, bg3: bool, obj: bool, col: bool) void {
        reg.math_enable = bsp.bits.sto1x8in8(
            0,
            0,
            @intFromBool(col),
            @intFromBool(obj),
            @intFromBool(bg3),
            @intFromBool(bg2),
            @intFromBool(bg1),
            @intFromBool(bg0),
        );
    }

    pub fn setMathAlgo(algo: MathComposeAlgo) void {
        reg.math_algo = @intFromEnum(algo);
    }

    pub fn setMathNormalize(func: MathNormalizeFunc) void {
        reg.math_normalize = @intFromEnum(func);
    }

    pub fn setDebugMode(mode: DebugMode, arg: DebugArg) void {
        reg.debug = bsp.bits.sto2x4in8(@intFromEnum(mode), @intFromEnum(arg));
    }
};
