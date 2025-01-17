const mode8 = @import("mode8");
const bsp = mode8.bsp;
const PaletteImporter = @import("sampleutils").PaletteImporter;
const TiledMap = @import("sampleutils").TiledImporter.TiledMap;
const util = @import("../util.zig");
const std = @import("std");
const data = @import("../assets/assets.zig");

pub const BgTestsDataSetup = struct {
    frame: u64 = 0,

    pub fn init(_: *BgTestsDataSetup) void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const alloc = gpa.allocator();

        std.debug.print("bg tests: loading tilemaps, palettes and graphics\n", .{});

        // don't sully the screenmgr interface because this data setup might fail.
        // instead, call skill issue and crash.
        // no but for real, this should always work unless you're OOM or something is very wrong...

        const tiled = TiledMap.init(alloc, data.map) catch unreachable;
        defer tiled.deinit();

        PaletteImporter.importPalAndAtlas(alloc, data.pal, 0, data.gfx, 0) catch unreachable;
        PaletteImporter.importPalAndAtlas(alloc, data.pal, 0, data.gfx2, 1) catch unreachable;
        PaletteImporter.importPalAndAtlas(alloc, data.pal, 0, data.gfx3, 2) catch unreachable;
        PaletteImporter.importPalAndAtlas(alloc, data.pal, 0, data.gfx4, 3) catch unreachable;
        tiled.loadLayer("checkers", "checkers_0", 0, false, 0) catch unreachable;
        tiled.loadLayer("checkers", "checkers_1", 1, false, 0) catch unreachable;
        tiled.loadLayer("checkers", "checkers_2", 2, false, 0) catch unreachable;
        tiled.loadLayer("checkers", "checkers_3", 3, false, 0) catch unreachable;
        tiled.loadLayer("checkers", "checkers_0p", 0, true, 0) catch unreachable;
        tiled.loadLayer("checkers", "checkers_1p", 1, true, 0) catch unreachable;
        tiled.loadLayer("checkers", "checkers_2p", 2, true, 0) catch unreachable;
        tiled.loadLayer("checkers", "checkers_3p", 3, true, 0) catch unreachable;

        PaletteImporter.importPalAndObjects(alloc, data.pal, 0, data.gfx_obj, 0) catch unreachable;
        PaletteImporter.importPalAndObjects(alloc, data.pal, 0, data.gfx_obj2, 1) catch unreachable;
        PaletteImporter.importPalAndObjects(alloc, data.pal, 0, data.gfx_obj3, 2) catch unreachable;
        PaletteImporter.importPalAndObjects(alloc, data.pal, 0, data.gfx_obj4, 3) catch unreachable;

        // move objects away from the visible area
        for (0..256) |i| {
            var obj = bsp.Obj{};
            obj.setPosXY(260, 260);
            obj.writeToOAM(@truncate(i));
        }
    }

    pub fn tick(self: *BgTestsDataSetup) bool {
        // wait for a bit to reduce impact of loading lag on following animations
        return self.frame > util.QURT_SECOND;
    }
};

pub const BgPosFixup = struct {
    frame: u64 = 0,
    xnow: i16,
    ynow: i16,
    xtarget: i16,
    ytarget: i16,

    pub fn init(self: *BgPosFixup) void {
        // only shows first screen, the movement is only for visual coherency anyways
        std.debug.print("moving bgs to position for next test\n", .{});
        for (0..4) |bg| {
            bsp.RenderParams.setXScroll(@truncate(bg), .{ .direct = self.xnow });
            bsp.RenderParams.setYScroll(@truncate(bg), .{ .direct = self.xnow });
            if (bg != 0) {
                bsp.RenderParams.setXScroll(@truncate(bg), .{ .direct = self.xtarget });
                bsp.RenderParams.setYScroll(@truncate(bg), .{ .direct = self.ytarget });
            }
        }
        bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_0);
    }

    pub fn tick(self: *BgPosFixup) bool {
        const cyc: f32 = util.linCycleOf(self.frame, util.HALF_SECOND * 1);
        const scrollfx: f32 = cyc * @as(f32, @floatFromInt(self.xtarget - self.xnow));
        const scrollfy: f32 = cyc * @as(f32, @floatFromInt(self.ytarget - self.ynow));
        const scrollx: i16 = @intFromFloat(scrollfx);
        const scrolly: i16 = @intFromFloat(scrollfy);
        bsp.RenderParams.setXScroll(0, .{ .direct = self.xnow + scrollx });
        bsp.RenderParams.setYScroll(0, .{ .direct = self.ynow + scrolly });
        return self.frame >= util.HALF_SECOND;
    }
};

pub const TestBgOOB = struct {
    frame: u64 = 0,
    bg: u2,

    pub fn init(self: *TestBgOOB) void {
        std.debug.print("testing OOB settings and TAM offset for bg {}\n", .{self.bg});
        switch (self.bg) {
            0 => bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_0),
            1 => bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_1),
            2 => bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_2),
            3 => bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_3),
        }
        bsp.RenderParams.setBGSize(32, 32, 32, 32);
    }

    pub fn tick(self: *TestBgOOB) bool {
        const side: u64 = util.fullsecOf(self.frame);
        if (side > 3) {
            bsp.RenderParams.setBGTAMOffset(self.bg, 0, 0);
            return true;
        }

        const badsett = bsp.RenderParams.OOBData{
            .COLOR = 0,
        };

        const sett: bsp.RenderParams.OOBData = switch (side) {
            0 => .{ .WRAP = true },
            1 => .{ .TILE = bsp.Tile{ .gfxid = 256 } },
            2 => .{ .COLOR = @bitCast(bsp.Color.of(0xBF3445, false)) },
            3 => .{ .CLAMP = true },
            else => unreachable,
        };

        switch (util.fullsecOf(self.frame)) {
            0 => bsp.RenderParams.setBGTAMOffset(self.bg, 0, 0),
            1 => bsp.RenderParams.setBGTAMOffset(self.bg, 1, 0),
            2 => bsp.RenderParams.setBGTAMOffset(self.bg, 0, 1),
            3 => bsp.RenderParams.setBGTAMOffset(self.bg, 1, 1),
            else => unreachable,
        }

        switch (self.bg) {
            0 => bsp.RenderParams.setOOBSetting(sett, badsett, badsett, badsett),
            1 => bsp.RenderParams.setOOBSetting(badsett, sett, badsett, badsett),
            2 => bsp.RenderParams.setOOBSetting(badsett, badsett, sett, badsett),
            3 => bsp.RenderParams.setOOBSetting(badsett, badsett, badsett, sett),
        }
        const delta: i16 = 8 * 8;
        const start: i16 = -(4 * 8);
        const end: i16 = (4 * 8);
        const cyc: f32 = util.linCycleOf(self.frame, util.FULL_SECOND * 1 - 1);
        const scrollf: f32 = cyc * delta;
        const scroll: i16 = @intFromFloat(scrollf);

        switch (side) {
            0 => {
                bsp.RenderParams.setXScroll(self.bg, .{ .direct = start + scroll });
                bsp.RenderParams.setYScroll(self.bg, .{ .direct = start });
            },
            1 => {
                bsp.RenderParams.setXScroll(self.bg, .{ .direct = end });
                bsp.RenderParams.setYScroll(self.bg, .{ .direct = start + scroll });
            },
            2 => {
                bsp.RenderParams.setXScroll(self.bg, .{ .direct = end - scroll });
                bsp.RenderParams.setYScroll(self.bg, .{ .direct = end });
            },
            3 => {
                bsp.RenderParams.setXScroll(self.bg, .{ .direct = start });
                bsp.RenderParams.setYScroll(self.bg, .{ .direct = end - scroll });
            },
            else => unreachable,
        }

        return false;
    }
};

pub const TestBgSize = struct {
    frame: u64 = 0,
    bg: u2,

    pub fn init(self: *TestBgSize) void {
        std.debug.print("testing size setting for bg {} (using wrapping)\n", .{self.bg});
        switch (self.bg) {
            0 => bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_0),
            1 => bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_1),
            2 => bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_2),
            3 => bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_3),
        }
        const sett = bsp.RenderParams.OOBData{ .WRAP = true };
        bsp.RenderParams.setOOBSetting(sett, sett, sett, sett);
        bsp.RenderParams.setBGSize(32, 32, 32, 32);
    }

    pub fn tick(self: *TestBgSize) bool {
        const sizes = [_]u10{ 64, 128, 256, 512, 4, 8, 16, 32 };

        if (util.halfsecOf(self.frame) >= sizes.len) {
            return true;
        }

        const sze = sizes[util.halfsecOf(self.frame)];

        switch (self.bg) {
            0 => bsp.RenderParams.setBGSize(sze, 32, 32, 32),
            1 => bsp.RenderParams.setBGSize(32, sze, 32, 32),
            2 => bsp.RenderParams.setBGSize(32, 32, sze, 32),
            3 => bsp.RenderParams.setBGSize(32, 32, 32, sze),
        }

        return false;
    }
};

pub const TestBgMosiac = struct {
    frame: u64 = 0,
    bg: u2,

    pub fn init(self: *TestBgMosiac) void {
        std.debug.print("testing mosiac setting for bg {}\n", .{self.bg});
        switch (self.bg) {
            0 => bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_0),
            1 => bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_1),
            2 => bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_2),
            3 => bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_3),
        }
        const sett = bsp.RenderParams.OOBData{ .WRAP = true };
        bsp.RenderParams.setOOBSetting(sett, sett, sett, sett);
        bsp.RenderParams.setBGSize(32, 32, 32, 32);
    }

    pub fn tick(self: *TestBgMosiac) bool {
        if (self.frame >= 16 * 4) {
            return true;
        }

        const stren_a: u4 = 15 - @as(u4, @truncate(self.frame / 4));
        const stren_b: u4 = @as(u4, @truncate(self.frame / 4));

        switch (self.bg) {
            0 => bsp.RenderParams.setMosiac(stren_b, 0, 0, 0),
            1 => bsp.RenderParams.setMosiac(0, stren_a, 0, 0),
            2 => bsp.RenderParams.setMosiac(0, 0, stren_b, 0),
            3 => bsp.RenderParams.setMosiac(0, 0, 0, stren_a),
        }

        return false;
    }
};

pub const TestBgAffine = struct {
    frame: u64 = 0,
    bg: u2,

    pub fn init(self: *TestBgAffine) void {
        std.debug.print("testing affine settings for bg {}\n", .{self.bg});
        switch (self.bg) {
            0 => {
                bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_0);
            },
            1 => {
                bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_1);
            },
            2 => {
                bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_2);
            },
            3 => {
                bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_3);
            },
        }
        const sett = bsp.RenderParams.OOBData{ .COLOR = 0x8000 };
        bsp.RenderParams.setOOBSetting(sett, sett, sett, sett);
        bsp.RenderParams.setBGSize(32, 32, 32, 32);

        bsp.RenderParams.setAffineX0(self.bg, .{ .direct = 128 });
        bsp.RenderParams.setAffineY0(self.bg, .{ .direct = 128 });
    }

    pub fn tick(self: *TestBgAffine) bool {
        const cyc: f32 = util.lerpCycleOf(self.frame, util.FULL_SECOND * 1 - 1);
        const scrollf: f32 = cyc * 0.5;
        const unscrollf: f32 = 0.5 - (cyc * 0.5);

        const val = if (util.fullsecOf(self.frame) % 2 == 0) scrollf else unscrollf;

        switch (@divFloor(util.fullsecOf(self.frame), 2)) {
            0 => {
                bsp.RenderParams.setAffineA(self.bg, .{ .direct = 1.0 - val });
            },
            1 => {
                bsp.RenderParams.setAffineB(self.bg, .{ .direct = val });
            },
            2 => {
                bsp.RenderParams.setAffineC(self.bg, .{ .direct = val });
            },
            3 => {
                bsp.RenderParams.setAffineD(self.bg, .{ .direct = 1.0 - val });
            },
            else => return true,
        }

        return false;
    }
};

pub const TestBgAffineDMA = struct {
    frame: u64 = 0,
    bg: u2,
    flip_dma: bool,

    pub fn init(self: *TestBgAffineDMA) void {
        std.debug.print("testing affine settings with DMA for bg {} (dma flipped? {})\n", .{ self.bg, self.flip_dma });

        const dma: bsp.RenderParams.DMADir = if (self.flip_dma) .Y else .X;
        const undma: bsp.RenderParams.DMADir = if (self.flip_dma) .X else .Y;

        switch (self.bg) {
            0 => {
                bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_0);
                bsp.RenderParams.setDMADirBG(dma, undma, undma, undma);
            },
            1 => {
                bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_1);
                bsp.RenderParams.setDMADirBG(undma, dma, undma, undma);
            },
            2 => {
                bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_2);
                bsp.RenderParams.setDMADirBG(undma, undma, dma, undma);
            },
            3 => {
                bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_3);
                bsp.RenderParams.setDMADirBG(undma, undma, undma, dma);
            },
        }
        const sett = bsp.RenderParams.OOBData{ .WRAP = true };
        bsp.RenderParams.setOOBSetting(sett, sett, sett, sett);
        bsp.RenderParams.setBGSize(32, 32, 32, 32);

        for (0..4) |i| {
            bsp.RenderParams.setAffineA(@truncate(i), .{ .direct = -10 });
            bsp.RenderParams.setAffineB(@truncate(i), .{ .direct = -10 });
            bsp.RenderParams.setAffineC(@truncate(i), .{ .direct = -10 });
            bsp.RenderParams.setAffineD(@truncate(i), .{ .direct = -10 });
            bsp.RenderParams.setAffineX0(@truncate(i), .{ .direct = -10 });
            bsp.RenderParams.setAffineY0(@truncate(i), .{ .direct = -10 });
        }
    }

    pub fn tick(self: *TestBgAffineDMA) bool {
        const cyc1: f32 = util.linCycleOf(self.frame, util.FULL_SECOND * 2) * 0.5 * std.math.pi + (@as(f32, @floatFromInt(self.bg)) * 0.5 * std.math.pi);

        bsp.RenderParams.setAffineA(self.bg, .{ .dma = .{@cos(cyc1)} ** 85 ++ .{@cos(-cyc1)} ** 85 ++ .{@cos(cyc1)} ** 86 });
        bsp.RenderParams.setAffineB(self.bg, .{ .dma = .{-@sin(cyc1)} ** 85 ++ .{-@sin(-cyc1)} ** 85 ++ .{-@sin(cyc1)} ** 86 });
        bsp.RenderParams.setAffineC(self.bg, .{ .dma = .{@sin(cyc1)} ** 85 ++ .{@sin(-cyc1)} ** 85 ++ .{@sin(cyc1)} ** 86 });
        bsp.RenderParams.setAffineD(self.bg, .{ .dma = .{@cos(cyc1)} ** 85 ++ .{@cos(-cyc1)} ** 85 ++ .{@cos(cyc1)} ** 86 });

        bsp.RenderParams.setAffineX0(self.bg, .{ .dma = .{32} ** 85 ++ .{128} ** 85 ++ .{256} ** 86 });
        bsp.RenderParams.setAffineY0(self.bg, .{ .dma = .{32} ** 85 ++ .{128} ** 85 ++ .{256} ** 86 });

        return util.fullsecOf(self.frame) == 2;
    }
};

pub const TestBgScrollDMA = struct {
    frame: u64 = 0,
    bg: u2,
    flip_dma: bool,

    pub fn init(self: *TestBgScrollDMA) void {
        std.debug.print("testing scroll settings with DMA for bg {} (dma flipped? {})\n", .{ self.bg, self.flip_dma });

        const dma: bsp.RenderParams.DMADir = if (self.flip_dma) .Y else .X;
        const undma: bsp.RenderParams.DMADir = if (self.flip_dma) .X else .Y;

        switch (self.bg) {
            0 => {
                bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_0);
                bsp.RenderParams.setDMADirBG(dma, undma, undma, undma);
            },
            1 => {
                bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_1);
                bsp.RenderParams.setDMADirBG(undma, dma, undma, undma);
            },
            2 => {
                bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_2);
                bsp.RenderParams.setDMADirBG(undma, undma, dma, undma);
            },
            3 => {
                bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_BG_3);
                bsp.RenderParams.setDMADirBG(undma, undma, undma, dma);
            },
        }
        const sett = bsp.RenderParams.OOBData{ .WRAP = true };
        bsp.RenderParams.setOOBSetting(sett, sett, sett, sett);
        bsp.RenderParams.setBGSize(32, 32, 32, 32);
        for (0..4) |i| {
            bsp.RenderParams.setXScroll(@truncate(i), .{ .direct = -256 });
            bsp.RenderParams.setYScroll(@truncate(i), .{ .direct = -256 });
        }
    }

    pub fn tick(self: *TestBgScrollDMA) bool {
        const cyc: f32 = util.linCycleOf(self.frame, util.FULL_SECOND * 1) * 2 * std.math.pi;
        const delta: f32 = 2.0 * std.math.pi * 4.0 / 256.0;
        const mag: f32 = 2.0;

        var values: [256]i32 = undefined;

        switch (util.fullsecOf(self.frame)) {
            0, 1 => {
                for (0..256) |i| {
                    values[i] = @intFromFloat(@sin(delta * @as(f32, @floatFromInt(i)) + cyc) * mag * 2);
                }
                bsp.RenderParams.setXScroll(self.bg, .{ .dma = values });
                bsp.RenderParams.setYScroll(self.bg, .{ .direct = 0 });
            },
            2, 3 => {
                for (0..256) |i| {
                    values[i] = @intFromFloat(@cos(delta * @as(f32, @floatFromInt(i)) + cyc) * mag * 3);
                }
                bsp.RenderParams.setXScroll(self.bg, .{ .direct = 0 });
                bsp.RenderParams.setYScroll(self.bg, .{ .dma = values });
            },
            else => {
                return true;
            },
        }
        return false;
    }
};

pub const TestBgPrioFeat = struct {
    frame: u64 = 0,
    x: i32 = 0,
    y: i32 = 0,

    pub fn init(_: *TestBgPrioFeat) void {
        std.debug.print("testing BG tilemap features, prios and obj/tile gfx atlases\n", .{});

        bsp.RenderParams.setBGSize(512, 512, 512, 512);
        bsp.RenderParams.setDebugMode(.DEBUG_MODE_BUF_PRE_WIN, .DEBUG_ARG_SHOW_MAIN);
        bsp.RenderParams.setToMain(true, true, true, true, true);

        for (0..4) |i| {
            bsp.RenderParams.setXScroll(@truncate(i), .{ .direct = 448 * 8 });
            bsp.RenderParams.setYScroll(@truncate(i), .{ .direct = 32 * 8 });
            bsp.RenderParams.setAffineA(@truncate(i), .{ .direct = 1 });
            bsp.RenderParams.setAffineB(@truncate(i), .{ .direct = 0 });
            bsp.RenderParams.setAffineC(@truncate(i), .{ .direct = 0 });
            bsp.RenderParams.setAffineD(@truncate(i), .{ .direct = 1 });
            bsp.RenderParams.setAffineX0(@truncate(i), .{ .direct = 0 });
            bsp.RenderParams.setAffineY0(@truncate(i), .{ .direct = 0 });
        }

        var start = bsp.Obj{
            .gfxid = 160,
            .size = @intFromEnum(bsp.Obj.Size.SQ_8),
        };
        var end = bsp.Obj{
            .gfxid = 162,
            .size = @intFromEnum(bsp.Obj.Size.SQ_8),
        };
        var mid = bsp.Obj{
            .gfxid = 161,
            .size = @intFromEnum(bsp.Obj.Size.SQ_8),
        };

        var nums = [_]bsp.Obj{
            bsp.Obj{
                .gfxid = 144,
                .size = @intFromEnum(bsp.Obj.Size.SQ_8),
                .prio = 0,
            },
            bsp.Obj{
                .gfxid = 145,
                .size = @intFromEnum(bsp.Obj.Size.SQ_8),
                .prio = 1,
            },
            bsp.Obj{
                .gfxid = 146,
                .size = @intFromEnum(bsp.Obj.Size.SQ_8),
                .prio = 2,
            },
            bsp.Obj{
                .gfxid = 147,
                .size = @intFromEnum(bsp.Obj.Size.SQ_8),
                .prio = 3,
            },
        };

        for (0..4) |prio| {
            const yoffs: u9 = @truncate(2 * prio + 8);

            start.prio = @truncate(prio);
            start.setPosXY(14 * 8 - 4, yoffs * 8 + 4);
            start.writeToOAM(@truncate(0 + prio * 20));

            nums[prio].setPosXY(15 * 8 - 4, yoffs * 8 + 4);
            nums[prio].writeToOAM(@truncate(1 + prio * 20));

            end.prio = @truncate(prio);
            end.setPosXY(31 * 8 - 4, yoffs * 8 + 4);
            end.writeToOAM(@truncate(2 + prio * 20));

            mid.prio = @truncate(prio);
            for (16..31, 3..) |xoffs, idx| {
                mid.setPosXY(@truncate(xoffs * 8 - 4), yoffs * 8 + 4);
                mid.writeToOAM(@truncate(idx + prio * 20));
            }
        }

        for (1..4) |i| {
            var obj_first = bsp.Obj{
                .gfxid = 0,
                .atlid = @truncate(i),
                .size = @intFromEnum(bsp.Obj.Size.SQ_8),
            };
            var obj_last = bsp.Obj{
                .gfxid = 511,
                .atlid = @truncate(i),
                .size = @intFromEnum(bsp.Obj.Size.SQ_8),
            };
            obj_first.setPosXY((1 + @as(u9, @truncate(i))) * 8, 29 * 8);
            obj_last.setPosXY((1 + @as(u9, @truncate(i))) * 8, 30 * 8);
            obj_first.writeToOAM(255 - (@as(u8, @truncate(i)) * 2));
            obj_last.writeToOAM(255 - ((@as(u8, @truncate(i)) * 2) - 1));
        }
        for (1..4) |i| {
            const tile_first = bsp.Tile{
                .gfxid = 0,
                .atlid = @truncate(i),
            };
            const tile_last = bsp.Tile{
                .gfxid = 1023,
                .atlid = @truncate(i),
            };
            tile_first.writeToTAM(0, (449 + @as(u9, @truncate(i))), 27 + 32);
            tile_last.writeToTAM(0, (449 + @as(u9, @truncate(i))), 28 + 32);
        }
    }

    pub fn tick(self: *TestBgPrioFeat) bool {
        switch (util.fullsecOf(self.frame)) {
            0 => bsp.RenderParams.setPrioRemap(false, false, false, false),
            1 => bsp.RenderParams.setPrioRemap(true, false, false, false),
            2 => bsp.RenderParams.setPrioRemap(false, true, false, false),
            3 => bsp.RenderParams.setPrioRemap(false, false, true, false),
            4 => bsp.RenderParams.setPrioRemap(false, false, false, true),
            5 => bsp.RenderParams.setPrioRemap(false, false, true, true),
            6 => bsp.RenderParams.setPrioRemap(false, true, true, true),
            7 => bsp.RenderParams.setPrioRemap(true, true, true, true),
            else => return true,
        }

        return false;
    }
};
