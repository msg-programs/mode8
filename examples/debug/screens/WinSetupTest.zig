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
            reg.dma_dir_win[0] = dma_dir.asBool();
            reg.dma_dir_win[1] = not_dma_dir.asBool();
        } else {
            reg.dma_dir_win[0] = not_dma_dir.asBool();
            reg.dma_dir_win[1] = dma_dir.asBool();
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
            reg.dma_dir_win[0] = dma_dir.asBool();
            reg.dma_dir_win[1] = not_dma_dir.asBool();
        } else {
            reg.dma_dir_win[0] = not_dma_dir.asBool();
            reg.dma_dir_win[1] = dma_dir.asBool();
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

// pub const TestWinCompose = struct {
//     frame: u64 = 0,
//     show_setup: bool,
//     for_layer: bsp.RenderParams.DebugArg,

//     pub fn init(self: *TestWinCompose) void {
//         reg.debug_mode = @intFromEnum(rpa.DebugMode.window_comp);
//         reg.debug_arg = @intFromEnum(self.for_layer);
//         std.debug.print("Testing per-layer compose (showing with {})\n", .{self.for_layer});
//     }

//     pub fn tick(self: *TestWinCompose) bool {
//         const nocomp: bsp.RenderParams.WinComposition = .{
//             .neither = false,
//             .both = false,
//             .win0 = false,
//             .win1 = false,
//         };

//         const comp: bsp.RenderParams.WinComposition = switch (util.halfsecOf(self.frame)) {
//             0 => .{ .neither = true, .both = false, .win0 = false, .win1 = false },
//             1 => .{ .neither = false, .both = true, .win0 = false, .win1 = false },
//             2 => .{ .neither = false, .both = false, .win0 = true, .win1 = false },
//             3 => .{ .neither = false, .both = false, .win0 = false, .win1 = true },
//             else => return true,
//         };

//         rpa.setWinCompose(.bg_0, if (self.for_layer == .show_bg_0) comp else nocomp);
//         rpa.setWinCompose(.bg_1, if (self.for_layer == .show_bg_1) comp else nocomp);
//         rpa.setWinCompose(.bg_2, if (self.for_layer == .show_bg_2) comp else nocomp);
//         rpa.setWinCompose(.bg_3, if (self.for_layer == .show_bg_3) comp else nocomp);
//         rpa.setWinCompose(.obj, if (self.for_layer == .show_objs) comp else nocomp);
//         rpa.setWinCompose(.color, if (self.for_layer == .show_col) comp else nocomp);
//         return false;
//     }
// };

// pub const TestWinSend = struct {
//     frame: u64 = 0,
//     to_main: bool,
//     for_layer: bsp.RenderParams.DebugArg,

//     pub fn init(self: *TestWinSend) void {
//         if (self.to_main) {
//             bsp.RenderParams.setDebugMode(.DEBUG_MODE_WINDOWS_MAIN, self.for_layer);
//         } else {
//             bsp.RenderParams.setDebugMode(.DEBUG_MODE_WINDOWS_SUB, self.for_layer);
//         }

//         const comp: bsp.RenderParams.WinComposition = switch (self.for_layer) {
//             .DEBUG_ARG_SHOW_BG_0 => .{ .neither = true, .both = false, .win0 = false, .win1 = false },
//             .DEBUG_ARG_SHOW_BG_1 => .{ .neither = false, .both = true, .win0 = false, .win1 = false },
//             .DEBUG_ARG_SHOW_BG_2 => .{ .neither = false, .both = false, .win0 = true, .win1 = false },
//             .DEBUG_ARG_SHOW_BG_3 => .{ .neither = false, .both = false, .win0 = false, .win1 = true },
//             .DEBUG_ARG_SHOW_OBJS => .{ .neither = false, .both = false, .win0 = true, .win1 = true },
//             else => unreachable,
//         };
//         const nocomp: bsp.RenderParams.WinComposition = .{
//             .neither = false,
//             .both = false,
//             .win0 = false,
//             .win1 = false,
//         };

//         switch (self.for_layer) {
//             .DEBUG_ARG_SHOW_BG_0 => bsp.RenderParams.setWinCompose(comp, nocomp, nocomp, nocomp, nocomp, nocomp),
//             .DEBUG_ARG_SHOW_BG_1 => bsp.RenderParams.setWinCompose(nocomp, comp, nocomp, nocomp, nocomp, nocomp),
//             .DEBUG_ARG_SHOW_BG_2 => bsp.RenderParams.setWinCompose(nocomp, nocomp, comp, nocomp, nocomp, nocomp),
//             .DEBUG_ARG_SHOW_BG_3 => bsp.RenderParams.setWinCompose(nocomp, nocomp, nocomp, comp, nocomp, nocomp),
//             .DEBUG_ARG_SHOW_OBJS => bsp.RenderParams.setWinCompose(nocomp, nocomp, nocomp, nocomp, comp, nocomp),
//             .DEBUG_ARG_SHOW_COL => bsp.RenderParams.setWinCompose(nocomp, nocomp, nocomp, nocomp, nocomp, comp),
//             else => unreachable,
//         }

//         std.debug.print("Testing window send to buffer (to main? {} showing with {})\n", .{ self.to_main, self.for_layer });
//     }

//     pub fn tick(self: *TestWinSend) bool {
//         if (util.halfsecOf(self.frame) == 0) {
//             bsp.RenderParams.setWinToMain(false, false, false, false, false);
//             bsp.RenderParams.setWinToSub(false, false, false, false, false);
//             return false;
//         }
//         if (self.to_main) {
//             switch (self.for_layer) {
//                 .DEBUG_ARG_SHOW_BG_0 => bsp.RenderParams.setWinToMain(true, false, false, false, false),
//                 .DEBUG_ARG_SHOW_BG_1 => bsp.RenderParams.setWinToMain(false, true, false, false, false),
//                 .DEBUG_ARG_SHOW_BG_2 => bsp.RenderParams.setWinToMain(false, false, true, false, false),
//                 .DEBUG_ARG_SHOW_BG_3 => bsp.RenderParams.setWinToMain(false, false, false, true, false),
//                 .DEBUG_ARG_SHOW_OBJS => bsp.RenderParams.setWinToMain(false, false, false, false, true),
//                 else => unreachable,
//             }
//         } else {
//             switch (self.for_layer) {
//                 .DEBUG_ARG_SHOW_BG_0 => bsp.RenderParams.setWinToSub(true, false, false, false, false),
//                 .DEBUG_ARG_SHOW_BG_1 => bsp.RenderParams.setWinToSub(false, true, false, false, false),
//                 .DEBUG_ARG_SHOW_BG_2 => bsp.RenderParams.setWinToSub(false, false, true, false, false),
//                 .DEBUG_ARG_SHOW_BG_3 => bsp.RenderParams.setWinToSub(false, false, false, true, false),
//                 .DEBUG_ARG_SHOW_OBJS => bsp.RenderParams.setWinToSub(false, false, false, false, true),
//                 else => unreachable,
//             }
//         }
//         return util.halfsecOf(self.frame) == 2;
//     }
// };

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

// pub const WinTestsDataSetup = struct {
//     frame: u64 = 0,

//     pub fn init(_: *WinTestsDataSetup) void {
//         var s0: [256]u8 = undefined;
//         var e0: [256]u8 = undefined;
//         var s1: [256]u8 = undefined;
//         var e1: [256]u8 = undefined;

//         for (0..256) |i| {
//             switch (i) {
//                 72...107 => {
//                     s0[i] = 72;
//                     e0[i] = 144;
//                     s1[i] = 255;
//                     e1[i] = 0;
//                 },
//                 108...143 => {
//                     s0[i] = 72;
//                     e0[i] = 144;
//                     s1[i] = 108;
//                     e1[i] = 180;
//                 },
//                 144...179 => {
//                     s0[i] = 255;
//                     e0[i] = 0;
//                     s1[i] = 108;
//                     e1[i] = 180;
//                 },
//                 else => {
//                     s0[i] = 255;
//                     e0[i] = 0;
//                     s1[i] = 255;
//                     e1[i] = 0;
//                 },
//             }
//         }

//         bsp.RenderParams.setWinStart(0, .{ .dma = s0 });
//         bsp.RenderParams.setWinEnd(0, .{ .dma = e0 });
//         bsp.RenderParams.setWinStart(1, .{ .dma = s1 });
//         bsp.RenderParams.setWinEnd(1, .{ .dma = e1 });

//         bsp.RenderParams.setDMADirOther(.X, .X, .Y, .Y);

//         reg.debug_mode = @intFromEnum(rpa.DebugMode.windows_setup);
//         reg.debug_arg = @intFromEnum(rpa.DebugArg.none);
//         std.debug.print("Showing window setup for following tests...\n", .{});
//     }

//     pub fn tick(self: *WinTestsDataSetup) bool {
//         return self.frame > (util.FULL_SECOND * 2);
//     }
// };
