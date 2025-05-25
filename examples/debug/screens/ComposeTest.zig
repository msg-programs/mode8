const mode8 = @import("mode8");
const bsp = mode8.bsp;
const mem = mode8.hardware.memory;
const reg = mode8.hardware.registers;
const rpa = bsp.RenderParams;
const util = @import("../util.zig");
const std = @import("std");
const data = @import("../assets/assets.zig");
const TiledMap = @import("sampleutils").TiledImporter.TiledMap;

pub const ComposeTestsDataSetup = struct {
    frame: u64 = 0,

    pub fn init(_: *ComposeTestsDataSetup) void {
        std.debug.print("setting up data for following compose tests...\n", .{});
        // try to show nothing
        reg.debug_mode = @intFromEnum(rpa.DebugMode.layer);
        reg.debug_arg = @intFromEnum(rpa.DebugArg.show_objs);

        // BG gfx, BG tilemap and obj gfx should be already loaded at this point by the BG data setup
        // windows should be setup by the window setup

        // move objects away from the visible area
        @memset(mem.OAM[0..], 0);

        // create a tiling for the obj layer
        var big = bsp.Obj{ .gfxid = 48, .size = .SQ_8, .prio = 3 };
        for (0..16) |row| {
            for (0..16) |col| {
                big.setPosXY(@intCast(col * 16 + 4), @intCast(row * 16 + 4));
                big.writeToOAM(@intCast(row * 16 + col));
            }
        }
    }

    pub fn tick(self: *ComposeTestsDataSetup) bool {
        // wait for a bit to reduce impact of loading lag on following animations
        // only tilemap loads should cause lag, but one can never be too sure...
        return self.frame > util.QURT_SECOND;
    }
};

pub const TestBuffer = struct {
    frame: u64 = 0,
    to_main: bool,

    pub fn init(self: *TestBuffer) void {
        std.debug.print("testing sending layers and windows to buffers (to main? {})\n", .{self.to_main});

        reg.xscroll_do_dma = @splat(false);
        reg.yscroll_do_dma = @splat(false);

        for (0..4) |i| {
            rpa.setBgSize(@intCast(i), 512);
            reg.xscroll[i][0] = 448 * 8;
            reg.yscroll[i][0] = 64 * 8;
        }

        reg.win_compose[0] = @bitCast(rpa.WinComposition{ .neither = false, .win0 = true, .win1 = false, .both = false });
        reg.win_compose[1] = @bitCast(rpa.WinComposition{ .neither = false, .win0 = false, .win1 = true, .both = false });
        reg.win_compose[2] = @bitCast(rpa.WinComposition{ .neither = true, .win0 = false, .win1 = false, .both = false });
        reg.win_compose[3] = @bitCast(rpa.WinComposition{ .neither = false, .win0 = false, .win1 = false, .both = true });
        reg.win_compose[4] = @bitCast(rpa.WinComposition{ .neither = false, .win0 = true, .win1 = true, .both = false });
        reg.win_compose[5] = @bitCast(rpa.WinComposition{ .neither = true, .win0 = false, .win1 = false, .both = true });

        reg.fixcol_main_do_dma = false;
        reg.fixcol_sub_do_dma = false;

        reg.fixcol_main[0] = @bitCast(bsp.Color{ .a = 1, .r = 6, .g = 5, .b = 5 });
        reg.fixcol_sub[0] = @bitCast(bsp.Color{ .a = 1, .r = 5, .g = 5, .b = 6 });
    }

    pub fn tick(self: *TestBuffer) bool {
        if (util.fullsecOf(self.frame) > 26) {
            return true;
        }

        reg.debug_mode = @intFromEnum(if (util.fullsecOf(self.frame) % 3 == 0) rpa.DebugMode.buf_pre_win else rpa.DebugMode.buf_post_win);
        reg.debug_arg = @intFromEnum(if (self.to_main) rpa.DebugArg.show_main else rpa.DebugArg.show_sub);

        const toggles: [5]bool = switch (util.fullsecOf(self.frame)) {
            0...2 => .{ true, false, false, false, false },
            3...5 => .{ false, true, false, false, false },
            6...8 => .{ false, false, true, false, false },
            9...11 => .{ false, false, false, true, false },
            12...14 => .{ false, false, false, false, true },
            15...17 => .{ false, false, false, true, true },
            18...20 => .{ false, false, true, true, true },
            21...23 => .{ false, true, true, true, true },
            24...26 => .{ true, true, true, true, true },
            else => unreachable,
        };

        if (self.to_main) {
            reg.to_main = toggles;
            if (util.fullsecOf(self.frame) % 3 != 1) {
                reg.win_to_main = toggles;
            } else {
                reg.win_to_main = @splat(false);
            }
        } else {
            reg.to_sub = toggles;
            if (util.fullsecOf(self.frame) % 3 != 1) {
                reg.win_to_sub = toggles;
            } else {
                reg.win_to_sub = @splat(false);
            }
        }
        return false;
    }
};

pub const TestColwin = struct {
    frame: u64 = 0,
    is_main: bool,

    pub fn init(self: *TestColwin) void {
        std.debug.print("testing color window and fix/sub (for main? {})\n", .{self.is_main});

        reg.xscroll_do_dma = @splat(false);
        reg.yscroll_do_dma = @splat(false);

        for (0..4) |i| {
            rpa.setBgSize(@intCast(i), 512);
            reg.xscroll[i][0] = 448 * 8;
            reg.yscroll[i][0] = 64 * 8;
        }

        reg.win_compose[0] = @bitCast(rpa.WinComposition{ .neither = false, .win0 = true, .win1 = false, .both = false });
        reg.win_compose[1] = @bitCast(rpa.WinComposition{ .neither = false, .win0 = false, .win1 = true, .both = false });
        reg.win_compose[2] = @bitCast(rpa.WinComposition{ .neither = true, .win0 = false, .win1 = false, .both = false });
        reg.win_compose[3] = @bitCast(rpa.WinComposition{ .neither = false, .win0 = false, .win1 = false, .both = true });
        reg.win_compose[4] = @bitCast(rpa.WinComposition{ .neither = false, .win0 = true, .win1 = true, .both = false });
        reg.win_compose[5] = @bitCast(rpa.WinComposition{ .neither = true, .win0 = false, .win1 = false, .both = true });

        reg.fixcol_main_do_dma = false;
        reg.fixcol_sub_do_dma = false;

        reg.fixcol_main[0] = @bitCast(bsp.Color{ .a = 1, .r = 6, .g = 5, .b = 5 });
        reg.fixcol_sub[0] = @bitCast(bsp.Color{ .a = 1, .r = 5, .g = 5, .b = 6 });

        reg.debug_mode = @intFromEnum(rpa.DebugMode.buf_colmath_in);
        reg.debug_arg = @intFromEnum(if (self.is_main) rpa.DebugArg.show_main else rpa.DebugArg.show_sub);

        reg.win_to_main = @splat(true);
        reg.win_to_sub = @splat(true);
        reg.to_main = @splat(true);
        reg.to_sub = @splat(true);
    }

    pub fn tick(self: *TestColwin) bool {
        if (util.fullsecOf(self.frame) > 3) {
            return true;
        }

        const algo: rpa.ColWinApplyAlgo = switch (util.fullsecOf(self.frame)) {
            0 => .always_on,
            1 => .direct,
            2 => .inverted,
            3 => .always_off,
            else => unreachable,
        };

        if (self.is_main) {
            reg.col_win_apply = .{ @intFromEnum(algo), @intFromEnum(rpa.ColWinApplyAlgo.always_off) };
        } else {
            if (util.halfsecOf(self.frame) % 2 == 0) {
                reg.fix_sub = false;
            } else {
                reg.fix_sub = true;
            }
            reg.col_win_apply = .{ @intFromEnum(rpa.ColWinApplyAlgo.always_off), @intFromEnum(algo) };
        }
        return false;
    }
};

pub const TestColorMathEnable = struct {
    frame: u64 = 0,

    pub fn init(_: *TestColorMathEnable) void {
        std.debug.print("testing color math enable\n", .{});

        reg.debug_arg = @intFromEnum(rpa.DebugArg.none);
        reg.debug_mode = @intFromEnum(rpa.DebugMode.off);

        // load tilemap
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const alloc = gpa.allocator();

        const tiled = TiledMap.init(alloc, data.map) catch unreachable;
        defer tiled.deinit();

        tiled.loadLayer("colors", "A", 0, false, 0) catch unreachable;
        tiled.loadLayer("colors", "A", 1, false, 0) catch unreachable;
        tiled.loadLayer("colors", "A", 2, false, 0) catch unreachable;
        tiled.loadLayer("colors", "A", 3, false, 0) catch unreachable;

        for (0..4) |i| {
            reg.xscroll[i][0] = 0;
            reg.yscroll[i][0] = 0;
            reg.xscroll_do_dma[i] = false;
            reg.yscroll_do_dma[i] = false;
            rpa.setBgSize(@intCast(i), 32);
        }

        reg.oob_setting = @splat(@intFromEnum(rpa.OobSetting.wrap));
        reg.oob_data = @splat(0);

        // setup tilemap windows so that a 5 tile wide strip of every BG is shown as such:
        // 00000111112222233333ooooooffffff
        // 00000111112222233333ooooooffffff
        // 00000111112222233333ooooooffffff
        // 00000111112222233333ooooooffffff
        // 00000111112222233333ooooooffffff
        // objs and fixcols are shown on the transparent bit of the tilemap next to the strips
        reg.win_start_do_dma = @splat(false);
        reg.win_end_do_dma = @splat(false);
        reg.win_start[0][0] = 5 * 8;
        reg.win_end[0][0] = 15 * 8;
        reg.win_start[1][0] = 10 * 8;
        reg.win_end[1][0] = 20 * 8;

        reg.win_compose[0] = @bitCast(bsp.RenderParams.WinComposition{ .neither = !true, .win0 = !false, .win1 = !false, .both = !false });
        reg.win_compose[1] = @bitCast(bsp.RenderParams.WinComposition{ .neither = !false, .win0 = !true, .win1 = !false, .both = !false });
        reg.win_compose[2] = @bitCast(bsp.RenderParams.WinComposition{ .neither = !false, .win0 = !false, .win1 = !false, .both = !true });
        reg.win_compose[3] = @bitCast(bsp.RenderParams.WinComposition{ .neither = !false, .win0 = !false, .win1 = !true, .both = !false });
        reg.win_compose[4] = @bitCast(bsp.RenderParams.WinComposition{ .neither = !false, .win0 = !false, .win1 = !false, .both = !false });
        reg.win_compose[5] = @bitCast(bsp.RenderParams.WinComposition{ .neither = !false, .win0 = !false, .win1 = !false, .both = !false });

        reg.win_to_main = .{ true, true, true, true, false };
        reg.win_to_sub = .{ false, false, false, false, false };

        reg.col_win_apply = @splat(@intFromEnum(rpa.ColWinApplyAlgo.always_off));

        // setup the object strip
        var big = bsp.Obj{ .gfxid = 490, .size = .RC_32x16 };
        var small = bsp.Obj{ .gfxid = 1, .size = .SQ_16 };
        @memset(mem.OAM[0..], 0);
        for (0..16) |i| {
            if (i % 2 == 0) {
                big.setPosXY(20 * 8, @intCast(i * 16));
                small.setPosXY(24 * 8, @intCast(i * 16));
            } else {
                big.setPosXY(22 * 8, @intCast(i * 16));
                small.setPosXY(20 * 8, @intCast(i * 16));
            }
            big.writeToOAM(@truncate(i * 2));
            small.writeToOAM(@truncate(i * 2 + 1));
        }

        reg.dma_dir_fixcol = @splat(@intFromEnum(rpa.DmaDir.top_to_bottom));
        reg.dma_dir_win = @splat(@intFromEnum(rpa.DmaDir.top_to_bottom));

        reg.fixcol_main_do_dma = false;
        reg.fixcol_main[0] = @bitCast(bsp.Color{ .a = 1, .r = 4, .g = 6, .b = 8 });

        reg.fixcol_sub_do_dma = true;
        reg.fixcol_sub = .{} ++
            .{@as(u16, @bitCast(bsp.Color.of(0xFF478E, false)))} ** 16 ++
            .{@as(u16, @bitCast(bsp.Color.of(0x141414, false)))} ** 16 ++
            .{@as(u16, @bitCast(bsp.Color.of(0xE747FF, false)))} ** 16 ++
            .{@as(u16, @bitCast(bsp.Color.of(0x282828, false)))} ** 16 ++
            .{@as(u16, @bitCast(bsp.Color.of(0x5D47FF, false)))} ** 16 ++
            .{@as(u16, @bitCast(bsp.Color.of(0x424242, false)))} ** 16 ++
            .{@as(u16, @bitCast(bsp.Color.of(0x47BCFF, false)))} ** 16 ++
            .{@as(u16, @bitCast(bsp.Color.of(0x707070, false)))} ** 16 ++
            .{@as(u16, @bitCast(bsp.Color.of(0x47FFB9, false)))} ** 16 ++
            .{@as(u16, @bitCast(bsp.Color.of(0x565656, false)))} ** 16 ++
            .{@as(u16, @bitCast(bsp.Color.of(0x60FF47, false)))} ** 16 ++
            .{@as(u16, @bitCast(bsp.Color.of(0x848484, false)))} ** 16 ++
            .{@as(u16, @bitCast(bsp.Color.of(0xEAFF47, false)))} ** 16 ++
            .{@as(u16, @bitCast(bsp.Color.of(0x989898, false)))} ** 16 ++
            .{@as(u16, @bitCast(bsp.Color.of(0xFF8B47, false)))} ** 16 ++
            .{@as(u16, @bitCast(bsp.Color.of(0xACACAC, false)))} ** 16;

        reg.to_main = @splat(true);
        reg.fix_sub = true;

        reg.math_enable = @splat(false);
        reg.math_algo = @intFromEnum(rpa.MathComposeAlgo.add);
        reg.math_normalize = @intFromEnum(rpa.MathNormalizeFunc.half);
    }

    pub fn tick(self: *TestColorMathEnable) bool {
        switch (util.fullsecOf(self.frame)) {
            0 => reg.math_enable = .{ false, false, false, false, false, false },
            1 => reg.math_enable = .{ true, false, false, false, false, false },
            2 => reg.math_enable = .{ false, true, false, false, false, false },
            3 => reg.math_enable = .{ false, false, true, false, false, false },
            4 => reg.math_enable = .{ false, false, false, true, false, false },
            5 => reg.math_enable = .{ false, false, false, false, true, false },
            6 => reg.math_enable = .{ false, false, false, false, false, true },
            7 => reg.math_enable = .{ false, false, false, false, true, true },
            8 => reg.math_enable = .{ false, false, false, true, true, true },
            9 => reg.math_enable = .{ false, false, true, true, true, true },
            10 => reg.math_enable = .{ false, true, true, true, true, true },
            11 => reg.math_enable = .{ true, true, true, true, true, true },
            else => return true,
        }
        return false;
    }
};

pub const TestColorMathSettings = struct {
    frame: u64 = 0,

    pub fn init(_: *TestColorMathSettings) void {
        std.debug.print("testing color math settings\n", .{});

        reg.debug_arg = @intFromEnum(rpa.DebugArg.none);
        reg.debug_mode = @intFromEnum(rpa.DebugMode.off);

        // "inherit" setup from previous test
        reg.math_enable = @splat(true);
    }

    pub fn tick(self: *TestColorMathSettings) bool {
        const i: usize = util.fullsecOf(self.frame / 2) % 4;
        const j: usize = util.fullsecOf(self.frame / 2) / 4;

        if (j >= 12) {
            return true;
        }

        reg.math_normalize = @intCast(i);
        reg.math_algo = @intCast(j);

        return false;
    }
};
