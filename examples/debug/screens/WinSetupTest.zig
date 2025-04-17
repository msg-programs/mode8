const mode8 = @import("mode8");
const bsp = mode8.bsp;
const rpa = bsp.RenderParams;
const reg = mode8.hardware.registers;
const util = @import("../util.zig");
const std = @import("std");

pub const TestWinNoDMA = struct {
    frame: u64 = 0,
    win: u1,
    flip_dma: bool,

    pub fn init(self: *TestWinNoDMA) void {
        const notwin: u1 = if (self.win == 0) 1 else 0;
        std.debug.print("sweeping window start/end (win {}, DMA flipped? {})\n", .{ self.win, self.flip_dma });

        reg.debug_mode = @intFromEnum(rpa.DebugMode.windows_setup);
        reg.debug_arg = @intFromEnum(rpa.DebugArg.none);

        reg.win_start_do_dma[self.win] = false;
        reg.win_end_do_dma[self.win] = false;

        reg.win_start[self.win][0] = 0;
        reg.win_end[self.win][0] = 255;
        reg.win_start[notwin][0] = 255;
        reg.win_end[notwin][0] = 0;

        const not_dma_dir: rpa.DMADir = if (self.flip_dma) .top_to_bottom else .left_to_right;
        const dma_dir: rpa.DMADir = if (self.flip_dma) .left_to_right else .top_to_bottom;
        if (self.win == 0) {
            reg.dma_dir_win[0] = @intFromEnum(dma_dir);
            reg.dma_dir_win[1] = @intFromEnum(not_dma_dir);
        } else {
            reg.dma_dir_win[0] = @intFromEnum(not_dma_dir);
            reg.dma_dir_win[1] = @intFromEnum(dma_dir);
        }
    }

    pub fn tick(self: *TestWinNoDMA) bool {
        const frame_end = @min(self.frame, util.FULL_SECOND);
        const frame_start = @min(self.frame -| util.HALF_SECOND, util.FULL_SECOND);

        const cyc_e: f32 = util.lerpCycleOf(frame_end, util.FULL_SECOND);
        const cyc_s: f32 = util.lerpCycleOf(frame_start, util.FULL_SECOND);
        const endf: f32 = cyc_e * 255.0;
        const startf: f32 = cyc_s * 255.0;
        const end: u8 = @intFromFloat(endf);
        const start: u8 = @intFromFloat(startf);
        reg.win_start[self.win][0] = start;
        reg.win_end[self.win][0] = end;
        return self.frame > (util.FULL_SECOND + util.HALF_SECOND);
    }
};

pub const TestWinDMA = struct {
    frame: u64 = 0,
    win: u1,
    flip_dma: bool,

    pub fn init(self: *TestWinDMA) void {
        const notwin: u1 = if (self.win == 0) 1 else 0;
        std.debug.print("DMAing window start/end (win {}, DMA flipped? {})\n", .{ self.win, self.flip_dma });

        reg.debug_mode = @intFromEnum(rpa.DebugMode.windows_setup);
        reg.debug_arg = @intFromEnum(rpa.DebugArg.none);

        reg.win_start_do_dma[self.win] = true;
        reg.win_end_do_dma[self.win] = true;

        reg.win_start_do_dma[notwin] = false;
        reg.win_end_do_dma[notwin] = false;

        reg.win_start[self.win][0] = 0;
        reg.win_end[self.win][0] = 255;
        reg.win_start[notwin][0] = 255;
        reg.win_end[notwin][0] = 0;

        const not_dma_dir: rpa.DMADir = if (self.flip_dma) .top_to_bottom else .left_to_right;
        const dma_dir: rpa.DMADir = if (self.flip_dma) .left_to_right else .top_to_bottom;
        if (self.win == 0) {
            reg.dma_dir_win[0] = @intFromEnum(dma_dir);
            reg.dma_dir_win[1] = @intFromEnum(not_dma_dir);
        } else {
            reg.dma_dir_win[0] = @intFromEnum(not_dma_dir);
            reg.dma_dir_win[1] = @intFromEnum(dma_dir);
        }
    }

    pub fn tick(self: *TestWinDMA) bool {
        const frame_end = @min(self.frame, util.FULL_SECOND);
        const frame_start = @min(self.frame -| util.HALF_SECOND, util.FULL_SECOND);

        const cyc_e: f32 = util.lerpCycleOf(frame_end, util.FULL_SECOND);
        const cyc_s: f32 = util.lerpCycleOf(frame_start, util.FULL_SECOND);
        const endf: f32 = cyc_e * 255.0;
        const startf: f32 = cyc_s * 255.0;
        const end: u8 = @intFromFloat(endf);
        const start: u8 = @intFromFloat(startf);

        for (0..256) |i| {
            if (i > end or i < start) {
                reg.win_start[self.win][i] = 255;
                reg.win_end[self.win][i] = 0;
                continue;
            }
            if (self.win == 0) {
                reg.win_start[self.win][i] = @as(u8, @intFromFloat(@sin(util.percentOfDim(i, 256) * 10) * 10 + 10)) + 64;
                reg.win_end[self.win][i] = @as(u8, @intFromFloat(@sin(util.percentOfDim(i, 256) * 10) * 10 + 10)) + (256 - 64);
            } else {
                reg.win_start[self.win][i] = @as(u8, @intFromFloat(@cos(util.percentOfDim(i, 256) * 10) * 10 + 10)) + 64;
                reg.win_end[self.win][i] = @as(u8, @intFromFloat(@cos(util.percentOfDim(i, 256) * 10) * 10 + 10)) + (256 - 64);
            }
        }

        return self.frame > (util.FULL_SECOND + util.HALF_SECOND);
    }
};

pub const TestWinCompose = struct {
    frame: u64 = 0,
    for_layer: bsp.RenderParams.DebugArg,

    pub fn init(self: *TestWinCompose) void {
        reg.debug_mode = @intFromEnum(rpa.DebugMode.window_comp);
        reg.debug_arg = @intFromEnum(self.for_layer);
        std.debug.print("Testing per-layer compose (showing with {})\n", .{self.for_layer});
    }

    pub fn tick(self: *TestWinCompose) bool {
        const nocomp: bsp.RenderParams.WinComposition = .{
            .neither = false,
            .both = false,
            .win0 = false,
            .win1 = false,
        };

        const comp: bsp.RenderParams.WinComposition = switch (util.halfsecOf(self.frame)) {
            0 => .{ .neither = true, .both = false, .win0 = false, .win1 = false },
            1 => .{ .neither = false, .both = true, .win0 = false, .win1 = false },
            2 => .{ .neither = false, .both = false, .win0 = true, .win1 = false },
            3 => .{ .neither = false, .both = false, .win0 = false, .win1 = true },
            else => return true,
        };

        reg.win_compose[0] = @bitCast(if (self.for_layer == .show_bg_0) comp else nocomp);
        reg.win_compose[1] = @bitCast(if (self.for_layer == .show_bg_1) comp else nocomp);
        reg.win_compose[2] = @bitCast(if (self.for_layer == .show_bg_2) comp else nocomp);
        reg.win_compose[3] = @bitCast(if (self.for_layer == .show_bg_3) comp else nocomp);
        reg.win_compose[4] = @bitCast(if (self.for_layer == .show_objs) comp else nocomp);
        reg.win_compose[5] = @bitCast(if (self.for_layer == .show_col) comp else nocomp);

        return false;
    }
};

pub const TestWinSend = struct {
    frame: u64 = 0,
    to_main: bool,
    for_layer: bsp.RenderParams.DebugArg,

    pub fn init(self: *TestWinSend) void {
        reg.debug_mode = @intFromEnum(if (self.to_main) rpa.DebugMode.windows_main else rpa.DebugMode.windows_sub);
        reg.debug_arg = @intFromEnum(self.for_layer);

        const t = self.to_main;
        const f = !self.to_main;

        const comp: bsp.RenderParams.WinComposition = switch (self.for_layer) {
            .show_bg_0 => .{ .neither = t, .both = f, .win0 = f, .win1 = f },
            .show_bg_1 => .{ .neither = f, .both = t, .win0 = f, .win1 = f },
            .show_bg_2 => .{ .neither = f, .both = f, .win0 = t, .win1 = f },
            .show_bg_3 => .{ .neither = f, .both = f, .win0 = f, .win1 = t },
            .show_objs => .{ .neither = f, .both = f, .win0 = t, .win1 = t },
            else => unreachable,
        };
        const nocomp: bsp.RenderParams.WinComposition = .{
            .neither = false,
            .both = false,
            .win0 = false,
            .win1 = false,
        };

        reg.win_compose[0] = @bitCast(if (self.for_layer == .show_bg_0) comp else nocomp);
        reg.win_compose[1] = @bitCast(if (self.for_layer == .show_bg_1) comp else nocomp);
        reg.win_compose[2] = @bitCast(if (self.for_layer == .show_bg_2) comp else nocomp);
        reg.win_compose[3] = @bitCast(if (self.for_layer == .show_bg_3) comp else nocomp);
        reg.win_compose[4] = @bitCast(if (self.for_layer == .show_objs) comp else nocomp);

        std.debug.print("Testing window send to buffer (to main? {} showing with {})\n", .{ self.to_main, self.for_layer });
    }

    pub fn tick(self: *TestWinSend) bool {
        if (util.halfsecOf(self.frame) == 0) {
            reg.win_to_main = @splat(false);
            reg.win_to_sub = @splat(false);
            return false;
        }
        if (self.to_main) {
            reg.win_to_main[0] = if (self.for_layer == .show_bg_0) true else false;
            reg.win_to_main[1] = if (self.for_layer == .show_bg_1) true else false;
            reg.win_to_main[2] = if (self.for_layer == .show_bg_2) true else false;
            reg.win_to_main[3] = if (self.for_layer == .show_bg_3) true else false;
            reg.win_to_main[4] = if (self.for_layer == .show_objs) true else false;
        } else {
            reg.win_to_sub[0] = if (self.for_layer == .show_bg_0) true else false;
            reg.win_to_sub[1] = if (self.for_layer == .show_bg_1) true else false;
            reg.win_to_sub[2] = if (self.for_layer == .show_bg_2) true else false;
            reg.win_to_sub[3] = if (self.for_layer == .show_bg_3) true else false;
            reg.win_to_sub[4] = if (self.for_layer == .show_objs) true else false;
        }
        return util.halfsecOf(self.frame) == 2;
    }
};

// pub const TestColWin = struct {
//     frame: u64 = 0,
//     to_main: bool,

//     pub fn init(self: *TestColWin) void {
//         bsp.RenderParams.setDebugMode(
//             .DEBUG_MODE_COL_WINDOW,
//             if (self.to_main)
//                 .DEBUG_ARG_SHOW_MAIN
//             else
//                 .DEBUG_ARG_SHOW_SUB,
//         );

//         const comp: bsp.RenderParams.WinComposition = .{
//             .neither = true,
//             .both = true,
//             .win0 = false,
//             .win1 = false,
//         };

//         const nocomp: bsp.RenderParams.WinComposition = .{
//             .neither = false,
//             .both = false,
//             .win0 = false,
//             .win1 = false,
//         };

//         bsp.RenderParams.setWinCompose(nocomp, nocomp, nocomp, nocomp, nocomp, comp);

//         std.debug.print("Testing color window apply algorithms (to main? {})\n", .{self.to_main});
//     }

//     pub fn tick(self: *TestColWin) bool {
//         if (util.halfsecOf(self.frame) == 4) {
//             return true;
//         }

//         const apply: bsp.RenderParams.ColWinApplyAlgo = switch (util.halfsecOf(self.frame)) {
//             0 => .ALWAYS_ON,
//             1 => .ALWAYS_OFF,
//             2 => .DIRECT,
//             3 => .INVERTED,
//             else => .ALWAYS_ON,
//         };

//         if (self.to_main) {
//             bsp.RenderParams.setColWinApply(apply, .ALWAYS_OFF);
//         } else {
//             bsp.RenderParams.setColWinApply(.ALWAYS_OFF, apply);
//         }
//         return false;
//     }
// };

pub const WinTestsDataSetup = struct {
    frame: u64 = 0,

    pub fn init(_: *WinTestsDataSetup) void {
        for (0..256) |i| {
            switch (i) {
                72...107 => {
                    reg.win_start[0][i] = 72;
                    reg.win_end[0][i] = 144;
                    reg.win_start[1][i] = 255;
                    reg.win_end[1][i] = 0;
                },
                108...143 => {
                    reg.win_start[0][i] = 72;
                    reg.win_end[0][i] = 144;
                    reg.win_start[1][i] = 108;
                    reg.win_end[1][i] = 180;
                },
                144...179 => {
                    reg.win_start[0][i] = 255;
                    reg.win_end[0][i] = 0;
                    reg.win_start[1][i] = 108;
                    reg.win_end[1][i] = 180;
                },
                else => {
                    reg.win_start[0][i] = 255;
                    reg.win_end[0][i] = 0;
                    reg.win_start[1][i] = 255;
                    reg.win_end[1][i] = 0;
                },
            }
        }

        reg.win_start_do_dma = .{ true, true };
        reg.win_end_do_dma = .{ true, true };

        reg.dma_dir_win[0] = @intFromEnum(rpa.DMADir.top_to_bottom);
        reg.dma_dir_win[1] = @intFromEnum(rpa.DMADir.top_to_bottom);

        reg.debug_mode = @intFromEnum(rpa.DebugMode.windows_setup);
        reg.debug_arg = @intFromEnum(rpa.DebugArg.none);
        std.debug.print("Showing window setup for following tests...\n", .{});
    }

    pub fn tick(self: *WinTestsDataSetup) bool {
        return self.frame > (util.FULL_SECOND * 2);
    }
};
