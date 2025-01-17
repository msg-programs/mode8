const mode8 = @import("mode8");
const bsp = mode8.bsp;
const util = @import("../util.zig");
const std = @import("std");
const data = @import("../assets/assets.zig");
const TiledMap = @import("sampleutils").TiledImporter.TiledMap;

pub const ComposeTestsDataSetup = struct {
    frame: u64 = 0,

    pub fn init(_: *ComposeTestsDataSetup) void {
        std.debug.print("setting up data for following compose tests...\n", .{});
        // try to show nothing
        bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_OBJS);

        // BG gfx, BG tilemap and obj gfx should be already loaded at this point by the BG data setup
        // windows should be setup by the window setup

        // move objects away from the visible area
        for (0..256) |i| {
            var obj = bsp.Obj{};
            obj.setPosXY(260, 260);
            obj.writeToOAM(@truncate(i));
        }

        // create a tiling for the obj layer
        var big = bsp.Obj{ .gfxid = 48, .size = @intFromEnum(bsp.Obj.Size.SQ_8), .prio = 3 };
        for (0..16) |row| {
            for (0..16) |col| {
                big.setPosXY(@truncate(col * 16 + 4), @truncate(row * 16 + 4));
                big.writeToOAM(@truncate(row * 16 + col));
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

        for (0..4) |i| {
            bsp.RenderParams.setXScroll(@truncate(i), .{ .direct = 448 * 8 });
            bsp.RenderParams.setYScroll(@truncate(i), .{ .direct = 64 * 8 });
        }

        const c0 = bsp.RenderParams.WinComposition{ .neither = false, .win0 = true, .win1 = false, .both = false };
        const c1 = bsp.RenderParams.WinComposition{ .neither = false, .win0 = false, .win1 = true, .both = false };
        const c2 = bsp.RenderParams.WinComposition{ .neither = true, .win0 = false, .win1 = false, .both = false };
        const c3 = bsp.RenderParams.WinComposition{ .neither = false, .win0 = false, .win1 = false, .both = true };
        const c4 = bsp.RenderParams.WinComposition{ .neither = false, .win0 = true, .win1 = true, .both = false };
        const c5 = bsp.RenderParams.WinComposition{ .neither = true, .win0 = false, .win1 = false, .both = true };

        bsp.RenderParams.setWinCompose(c0, c1, c2, c3, c4, c5);

        bsp.RenderParams.setFixcolMain(.{ .direct = @bitCast(bsp.Color{ .a = 1, .r = 6, .g = 5, .b = 5 }) });
        bsp.RenderParams.setFixcolSub(.{ .direct = @bitCast(bsp.Color{ .a = 1, .r = 5, .g = 5, .b = 6 }) });
    }

    pub fn tick(self: *TestBuffer) bool {
        if (util.fullsecOf(self.frame) > 26) {
            return true;
        }

        const dmode: bsp.RenderParams.DebugMode = if (util.fullsecOf(self.frame) % 3 == 0) .DEBUG_MODE_BUF_PRE_WIN else .DEBUG_MODE_BUF_POST_WIN;
        const darg: bsp.RenderParams.DebugArg = if (self.to_main) .DEBUG_ARG_SHOW_MAIN else .DEBUG_ARG_SHOW_SUB;
        bsp.RenderParams.setDebugMode(dmode, darg);

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
            bsp.RenderParams.setToMain(toggles[0], toggles[1], toggles[2], toggles[3], toggles[4]);
            if (util.fullsecOf(self.frame) % 3 != 1) {
                bsp.RenderParams.setWinToMain(toggles[0], toggles[1], toggles[2], toggles[3], toggles[4]);
            } else {
                bsp.RenderParams.setWinToMain(false, false, false, false, false);
            }
        } else {
            bsp.RenderParams.setToSub(toggles[0], toggles[1], toggles[2], toggles[3], toggles[4]);
            if (util.fullsecOf(self.frame) % 3 != 1) {
                bsp.RenderParams.setWinToSub(toggles[0], toggles[1], toggles[2], toggles[3], toggles[4]);
            } else {
                bsp.RenderParams.setWinToSub(false, false, false, false, false);
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

        for (0..4) |i| {
            bsp.RenderParams.setXScroll(@truncate(i), .{ .direct = 448 * 8 });
            bsp.RenderParams.setYScroll(@truncate(i), .{ .direct = 64 * 8 });
        }

        const c0 = bsp.RenderParams.WinComposition{ .neither = false, .win0 = true, .win1 = false, .both = false };
        const c1 = bsp.RenderParams.WinComposition{ .neither = false, .win0 = false, .win1 = true, .both = false };
        const c2 = bsp.RenderParams.WinComposition{ .neither = true, .win0 = false, .win1 = false, .both = false };
        const c3 = bsp.RenderParams.WinComposition{ .neither = false, .win0 = false, .win1 = false, .both = true };
        const c4 = bsp.RenderParams.WinComposition{ .neither = false, .win0 = true, .win1 = true, .both = false };
        const c5 = bsp.RenderParams.WinComposition{ .neither = true, .win0 = false, .win1 = false, .both = true };

        bsp.RenderParams.setWinCompose(c0, c1, c2, c3, c4, c5);

        bsp.RenderParams.setFixcolMain(.{ .direct = @bitCast(bsp.Color{ .a = 1, .r = 6, .g = 5, .b = 5 }) });
        bsp.RenderParams.setFixcolSub(.{ .direct = @bitCast(bsp.Color{ .a = 1, .r = 5, .g = 5, .b = 6 }) });
        bsp.RenderParams.setDebugMode(.DEBUG_MODE_BUF_COLMATH_IN, if (self.is_main) .DEBUG_ARG_SHOW_MAIN else .DEBUG_ARG_SHOW_SUB);
        bsp.RenderParams.setToMain(true, true, true, true, true);
        bsp.RenderParams.setToSub(true, true, true, true, true);
        bsp.RenderParams.setWinToMain(true, true, true, true, true);
        bsp.RenderParams.setWinToSub(true, true, true, true, true);
    }

    pub fn tick(self: *TestColwin) bool {
        if (util.fullsecOf(self.frame) > 3) {
            return true;
        }

        const algo: bsp.RenderParams.ColWinApplyAlgo = switch (util.fullsecOf(self.frame)) {
            0 => .ALWAYS_ON,
            1 => .DIRECT,
            2 => .INVERTED,
            3 => .ALWAYS_OFF,
            else => unreachable,
        };

        if (self.is_main) {
            bsp.RenderParams.setColWinApply(algo, .ALWAYS_OFF);
        } else {
            if (util.halfsecOf(self.frame) % 2 == 0) {
                bsp.RenderParams.setFixSub(false);
            } else {
                bsp.RenderParams.setFixSub(true);
            }
            bsp.RenderParams.setColWinApply(.ALWAYS_OFF, algo);
        }
        return false;
    }
};

pub const TestColorMathEnable = struct {
    frame: u64 = 0,

    pub fn init(_: *TestColorMathEnable) void {
        std.debug.print("testing color math enable\n", .{});

        // bsp.RenderParams.setDebugMode(.DEBUG_MODE_BUF_COLMATH_IN, .DEBUG_ARG_SHOW_SUB);
        bsp.RenderParams.setDebugMode(.DEBUG_MODE_NONE, .DEBUG_ARG_NONE);

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
            bsp.RenderParams.setXScroll(@truncate(i), .{ .direct = 0 });
            bsp.RenderParams.setYScroll(@truncate(i), .{ .direct = 0 });
        }

        bsp.RenderParams.setOOBSetting(.{ .WRAP = true }, .{ .WRAP = true }, .{ .WRAP = true }, .{ .WRAP = true });
        bsp.RenderParams.setBGSize(32, 32, 32, 32);

        // setup tilemap windows so that a 5 tile wide strip of every BG is shown as such:
        // 00000111112222233333ooooooffffff
        // 00000111112222233333ooooooffffff
        // 00000111112222233333ooooooffffff
        // 00000111112222233333ooooooffffff
        // 00000111112222233333ooooooffffff
        // objs and fixcols are shown on the transparent bit of the tilemap next to the strips
        bsp.RenderParams.setWinStart(0, .{ .direct = 5 * 8 });
        bsp.RenderParams.setWinEnd(0, .{ .direct = 15 * 8 });
        bsp.RenderParams.setWinStart(1, .{ .direct = 10 * 8 });
        bsp.RenderParams.setWinEnd(1, .{ .direct = 20 * 8 });

        const c0 = bsp.RenderParams.WinComposition{ .neither = !true, .win0 = !false, .win1 = !false, .both = !false };
        const c1 = bsp.RenderParams.WinComposition{ .neither = !false, .win0 = !true, .win1 = !false, .both = !false };
        const c2 = bsp.RenderParams.WinComposition{ .neither = !false, .win0 = !false, .win1 = !false, .both = !true };
        const c3 = bsp.RenderParams.WinComposition{ .neither = !false, .win0 = !false, .win1 = !true, .both = !false };
        const c4 = bsp.RenderParams.WinComposition{ .neither = !false, .win0 = !false, .win1 = !false, .both = !false };
        const c5 = bsp.RenderParams.WinComposition{ .neither = !false, .win0 = !false, .win1 = !false, .both = !false };

        bsp.RenderParams.setWinCompose(c0, c1, c2, c3, c4, c5);
        bsp.RenderParams.setWinToMain(true, true, true, true, false);
        bsp.RenderParams.setWinToSub(false, false, false, false, false);
        bsp.RenderParams.setColWinApply(.ALWAYS_OFF, .ALWAYS_OFF);

        // setup the object strip
        var big = bsp.Obj{ .gfxid = 490, .size = @intFromEnum(bsp.Obj.Size.RC_32x16) };
        var small = bsp.Obj{ .gfxid = 1, .size = @intFromEnum(bsp.Obj.Size.SQ_16) };
        for (0..256) |i| {
            var o = bsp.Obj{};
            o.setPosXY(260, 260);
            o.writeToOAM(@truncate(i));
        }
        for (0..16) |i| {
            if (i % 2 == 0) {
                big.setPosXY(20 * 8, @truncate(i * 16));
                small.setPosXY(24 * 8, @truncate(i * 16));
            } else {
                big.setPosXY(22 * 8, @truncate(i * 16));
                small.setPosXY(20 * 8, @truncate(i * 16));
            }
            big.writeToOAM(@truncate(i * 2));
            small.writeToOAM(@truncate(i * 2 + 1));
        }

        // setup the fixcol
        const fixcol: [256]u16 = .{} ++
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

        bsp.RenderParams.setDMADirOther(.X, .X, .X, .X);

        bsp.RenderParams.setFixcolMain(.{ .direct = @bitCast(bsp.Color{ .a = 1, .r = 4, .g = 6, .b = 8 }) });
        bsp.RenderParams.setFixcolSub(.{ .dma = fixcol });

        bsp.RenderParams.setToMain(true, true, true, true, true);
        bsp.RenderParams.setFixSub(true);

        bsp.RenderParams.setMathEnable(false, false, false, false, false, false);
        bsp.RenderParams.setMathAlgo(.ADD);
        bsp.RenderParams.setMathNormalize(.HALF_RESULT);
    }

    pub fn tick(self: *TestColorMathEnable) bool {
        switch (util.fullsecOf(self.frame)) {
            0 => bsp.RenderParams.setMathEnable(false, false, false, false, false, false),
            1 => bsp.RenderParams.setMathEnable(true, false, false, false, false, false),
            2 => bsp.RenderParams.setMathEnable(false, true, false, false, false, false),
            3 => bsp.RenderParams.setMathEnable(false, false, true, false, false, false),
            4 => bsp.RenderParams.setMathEnable(false, false, false, true, false, false),
            5 => bsp.RenderParams.setMathEnable(false, false, false, false, true, false),
            6 => bsp.RenderParams.setMathEnable(false, false, false, false, false, true),
            7 => bsp.RenderParams.setMathEnable(false, false, false, false, true, true),
            8 => bsp.RenderParams.setMathEnable(false, false, false, true, true, true),
            9 => bsp.RenderParams.setMathEnable(false, false, true, true, true, true),
            10 => bsp.RenderParams.setMathEnable(false, true, true, true, true, true),
            11 => bsp.RenderParams.setMathEnable(true, true, true, true, true, true),
            else => return true,
        }
        return false;
    }
};

pub const TestColorMathSettings = struct {
    frame: u64 = 0,

    pub fn init(_: *TestColorMathSettings) void {
        std.debug.print("testing color math settings\n", .{});

        bsp.RenderParams.setDebugMode(.DEBUG_MODE_NONE, .DEBUG_ARG_NONE);

        // "inherit" setup from previous test
        bsp.RenderParams.setMathEnable(true, true, true, true, true, true);
        bsp.RenderParams.setMathAlgo(.ADD);
        bsp.RenderParams.setMathNormalize(.HALF_RESULT);
    }

    pub fn tick(self: *TestColorMathSettings) bool {
        const i: usize = util.fullsecOf(self.frame / 2) % 4;
        const j: usize = util.fullsecOf(self.frame / 2) / 4;

        if (j >= 12) {
            return true;
        }

        const m: bsp.RenderParams.MathNormalizeFunc = @enumFromInt(i);
        const n: bsp.RenderParams.MathComposeAlgo = @enumFromInt(j);

        bsp.RenderParams.setMathNormalize(m);
        bsp.RenderParams.setMathAlgo(n);
        return false;
    }
};
