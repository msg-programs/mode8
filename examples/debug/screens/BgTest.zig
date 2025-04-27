const mode8 = @import("mode8");
const bsp = mode8.bsp;
const reg = mode8.hardware.registers;
const rpa = mode8.bsp.RenderParams;
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

        reg.debug_mode = @intFromEnum(rpa.DebugMode.layer);
        reg.debug_arg = @intFromEnum(rpa.DebugArg.show_bg_0);

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
            reg.xscroll[bg][0] = self.xnow;
            reg.xscroll_do_dma[bg] = false;
            reg.yscroll[bg][0] = self.ynow;
            reg.yscroll_do_dma[bg] = false;
            if (bg != 0) {
                reg.xscroll[bg][0] = self.xtarget;
                reg.yscroll[bg][0] = self.ytarget;
            }
        }
        reg.debug_mode = @intFromEnum(rpa.DebugMode.layer);
        reg.debug_arg = @intFromEnum(rpa.DebugArg.show_bg_0);
    }

    pub fn tick(self: *BgPosFixup) bool {
        const cyc: f32 = util.linCycleOf(self.frame, util.HALF_SECOND * 1);
        const scrollfx: f32 = cyc * @as(f32, @floatFromInt(self.xtarget - self.xnow));
        const scrollfy: f32 = cyc * @as(f32, @floatFromInt(self.ytarget - self.ynow));
        const scrollx: i16 = @intFromFloat(scrollfx);
        const scrolly: i16 = @intFromFloat(scrollfy);
        reg.xscroll[0][0] = self.xnow + scrollx;
        reg.yscroll[0][0] = self.ynow + scrolly;
        return self.frame >= util.HALF_SECOND;
    }
};

pub const TestBgOOB = struct {
    frame: u64 = 0,
    bg: u2,

    pub fn init(self: *TestBgOOB) void {
        std.debug.print("testing OOB settings and TAM offset for bg {}\n", .{self.bg});
        reg.debug_mode = @intFromEnum(rpa.DebugMode.layer);
        reg.debug_arg = switch (self.bg) {
            0 => @intFromEnum(rpa.DebugArg.show_bg_0),
            1 => @intFromEnum(rpa.DebugArg.show_bg_1),
            2 => @intFromEnum(rpa.DebugArg.show_bg_2),
            3 => @intFromEnum(rpa.DebugArg.show_bg_3),
        };
        bsp.RenderParams.setBgSize(self.bg, 32);
        reg.xscroll_do_dma = @splat(false);
        reg.yscroll_do_dma = @splat(false);
    }

    pub fn tick(self: *TestBgOOB) bool {
        const side: u64 = util.fullsecOf(self.frame);
        if (side > 3) {
            reg.bgoffs_x[self.bg] = 0;
            reg.bgoffs_y[self.bg] = 0;
            return true;
        }

        const noset: u2 = @intFromEnum(bsp.RenderParams.OobSetting.color);
        const nodat: u16 = 0;

        const set: u2, const dat: u16 = switch (side) {
            0 => .{ @intFromEnum(bsp.RenderParams.OobSetting.wrap), 0 },
            1 => .{ @intFromEnum(bsp.RenderParams.OobSetting.tile), @bitCast(bsp.Tile{ .gfxid = 256 }) },
            2 => .{ @intFromEnum(bsp.RenderParams.OobSetting.color), @bitCast(bsp.Color.of(0xBF3445, false)) },
            3 => .{ @intFromEnum(bsp.RenderParams.OobSetting.mirror), 0 },
            else => unreachable,
        };

        switch (util.fullsecOf(self.frame)) {
            0 => {
                reg.bgoffs_x[self.bg] = 0;
                reg.bgoffs_y[self.bg] = 0;
            },
            1 => {
                reg.bgoffs_x[self.bg] = 1;
                reg.bgoffs_y[self.bg] = 0;
            },
            2 => {
                reg.bgoffs_x[self.bg] = 0;
                reg.bgoffs_y[self.bg] = 1;
            },
            3 => {
                reg.bgoffs_x[self.bg] = 1;
                reg.bgoffs_y[self.bg] = 1;
            },
            else => unreachable,
        }

        for (0..4) |bg| {
            reg.oob_setting[bg] = if (self.bg == bg) set else noset;
            reg.oob_data[bg] = if (self.bg == bg) dat else nodat;
        }

        const delta: i16 = 8 * 8;
        const start: i16 = -(4 * 8);
        const end: i16 = (4 * 8);
        const cyc: f32 = util.linCycleOf(self.frame, util.FULL_SECOND * 1 - 1);
        const scrollf: f32 = cyc * delta;
        const scroll: i16 = @intFromFloat(scrollf);

        switch (side) {
            0 => {
                reg.xscroll[self.bg][0] = start + scroll;
                reg.yscroll[self.bg][0] = start;
            },
            1 => {
                reg.xscroll[self.bg][0] = end;
                reg.yscroll[self.bg][0] = start + scroll;
            },
            2 => {
                reg.xscroll[self.bg][0] = end - scroll;
                reg.yscroll[self.bg][0] = end;
            },
            3 => {
                reg.xscroll[self.bg][0] = start;
                reg.yscroll[self.bg][0] = end - scroll;
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
        reg.debug_mode = @intFromEnum(rpa.DebugMode.layer);
        reg.debug_arg = switch (self.bg) {
            0 => @intFromEnum(rpa.DebugArg.show_bg_0),
            1 => @intFromEnum(rpa.DebugArg.show_bg_1),
            2 => @intFromEnum(rpa.DebugArg.show_bg_2),
            3 => @intFromEnum(rpa.DebugArg.show_bg_3),
        };
        reg.oob_setting = @splat(@intFromEnum(rpa.OobSetting.wrap));
        rpa.setBgSize(0, 32);
        rpa.setBgSize(1, 32);
        rpa.setBgSize(2, 32);
        rpa.setBgSize(3, 32);
    }

    pub fn tick(self: *TestBgSize) bool {
        const sizes = [_]u10{ 64, 128, 256, 512, 4, 8, 16, 32 };

        if (util.halfsecOf(self.frame) >= sizes.len) {
            return true;
        }

        const sze = sizes[util.halfsecOf(self.frame)];

        rpa.setBgSize(0, if (self.bg == 0) sze else 32);
        rpa.setBgSize(1, if (self.bg == 1) sze else 32);
        rpa.setBgSize(2, if (self.bg == 2) sze else 32);
        rpa.setBgSize(3, if (self.bg == 3) sze else 32);

        return false;
    }
};

pub const TestBgMosiac = struct {
    frame: u64 = 0,
    bg: u2,

    pub fn init(self: *TestBgMosiac) void {
        std.debug.print("testing mosiac setting for bg {}\n", .{self.bg});
        reg.debug_mode = @intFromEnum(rpa.DebugMode.layer);
        reg.debug_arg = switch (self.bg) {
            0 => @intFromEnum(rpa.DebugArg.show_bg_0),
            1 => @intFromEnum(rpa.DebugArg.show_bg_1),
            2 => @intFromEnum(rpa.DebugArg.show_bg_2),
            3 => @intFromEnum(rpa.DebugArg.show_bg_3),
        };

        reg.oob_setting = @splat(@intFromEnum(rpa.OobSetting.wrap));
        bsp.RenderParams.setBgSize(0, 32);
        bsp.RenderParams.setBgSize(1, 32);
        bsp.RenderParams.setBgSize(2, 32);
        bsp.RenderParams.setBgSize(3, 32);
    }

    pub fn tick(self: *TestBgMosiac) bool {
        if (self.frame >= 16 * 4) {
            return true;
        }

        const stren_a: u4 = 15 - @as(u4, @truncate(self.frame / 4));
        const stren_b: u4 = @as(u4, @truncate(self.frame / 4));

        reg.mosiac[0] = if (self.bg == 0) stren_b else 0;
        reg.mosiac[1] = if (self.bg == 1) stren_a else 0;
        reg.mosiac[2] = if (self.bg == 2) stren_b else 0;
        reg.mosiac[3] = if (self.bg == 3) stren_a else 0;

        return false;
    }
};

pub const TestBgAffine = struct {
    frame: u64 = 0,
    bg: u2,

    pub fn init(self: *TestBgAffine) void {
        std.debug.print("testing affine settings for bg {}\n", .{self.bg});
        reg.debug_mode = @intFromEnum(rpa.DebugMode.layer);
        reg.debug_arg = switch (self.bg) {
            0 => @intFromEnum(rpa.DebugArg.show_bg_0),
            1 => @intFromEnum(rpa.DebugArg.show_bg_1),
            2 => @intFromEnum(rpa.DebugArg.show_bg_2),
            3 => @intFromEnum(rpa.DebugArg.show_bg_3),
        };
        reg.oob_setting = @splat(@intFromEnum(rpa.OobSetting.color));
        reg.oob_data = @splat(0x8000);
        bsp.RenderParams.setBgSize(0, 32);
        bsp.RenderParams.setBgSize(1, 32);
        bsp.RenderParams.setBgSize(2, 32);
        bsp.RenderParams.setBgSize(3, 32);

        reg.affine_x0_do_dma[self.bg] = false;
        reg.affine_y0_do_dma[self.bg] = false;
        reg.affine_a_do_dma[self.bg] = false;
        reg.affine_b_do_dma[self.bg] = false;
        reg.affine_c_do_dma[self.bg] = false;
        reg.affine_d_do_dma[self.bg] = false;
        reg.affine_x0[self.bg][0] = 128;
        reg.affine_y0[self.bg][0] = 128;
    }

    pub fn tick(self: *TestBgAffine) bool {
        const cyc: f32 = util.lerpCycleOf(self.frame, util.FULL_SECOND * 1 - 1);
        const scrollf: f32 = cyc * 0.5;
        const unscrollf: f32 = 0.5 - (cyc * 0.5);

        const val = if (util.fullsecOf(self.frame) % 2 == 0) scrollf else unscrollf;

        switch (@divFloor(util.fullsecOf(self.frame), 2)) {
            0 => reg.affine_a[self.bg][0] = 1.0 - val,
            1 => reg.affine_b[self.bg][0] = val,
            2 => reg.affine_c[self.bg][0] = val,
            3 => reg.affine_d[self.bg][0] = 1.0 - val,
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

        const dma: bsp.RenderParams.DmaDir = if (self.flip_dma) .left_to_right else .top_to_bottom;
        const undma: bsp.RenderParams.DmaDir = if (self.flip_dma) .top_to_bottom else .left_to_right;

        reg.debug_mode = @intFromEnum(rpa.DebugMode.layer);
        reg.debug_arg = switch (self.bg) {
            0 => @intFromEnum(rpa.DebugArg.show_bg_0),
            1 => @intFromEnum(rpa.DebugArg.show_bg_1),
            2 => @intFromEnum(rpa.DebugArg.show_bg_2),
            3 => @intFromEnum(rpa.DebugArg.show_bg_3),
        };

        reg.dma_dir_bg[0] = @intFromEnum(if (self.bg == 0) dma else undma);
        reg.dma_dir_bg[1] = @intFromEnum(if (self.bg == 1) dma else undma);
        reg.dma_dir_bg[2] = @intFromEnum(if (self.bg == 2) dma else undma);
        reg.dma_dir_bg[3] = @intFromEnum(if (self.bg == 3) dma else undma);

        reg.oob_setting = @splat(@intFromEnum(rpa.OobSetting.wrap));
        rpa.setBgSize(0, 32);
        rpa.setBgSize(1, 32);
        rpa.setBgSize(2, 32);
        rpa.setBgSize(3, 32);

        for (0..4) |i| {
            reg.affine_a[i][0] = -10;
            reg.affine_b[i][0] = -10;
            reg.affine_c[i][0] = -10;
            reg.affine_d[i][0] = -10;
            reg.affine_x0[i][0] = -10;
            reg.affine_y0[i][0] = -10;

            reg.affine_a_do_dma[i] = (self.bg == i);
            reg.affine_b_do_dma[i] = (self.bg == i);
            reg.affine_c_do_dma[i] = (self.bg == i);
            reg.affine_d_do_dma[i] = (self.bg == i);
            reg.affine_x0_do_dma[i] = (self.bg == i);
            reg.affine_y0_do_dma[i] = (self.bg == i);
        }
    }

    pub fn tick(self: *TestBgAffineDMA) bool {
        const cyc1: f32 = util.linCycleOf(self.frame, util.FULL_SECOND * 2) * 0.5 * std.math.pi + (@as(f32, @floatFromInt(self.bg)) * 0.5 * std.math.pi);

        reg.affine_a[self.bg] = .{@cos(cyc1)} ** 85 ++ .{@cos(-cyc1)} ** 85 ++ .{@cos(cyc1)} ** 86;
        reg.affine_b[self.bg] = .{-@sin(cyc1)} ** 85 ++ .{-@sin(-cyc1)} ** 85 ++ .{-@sin(cyc1)} ** 86;
        reg.affine_c[self.bg] = .{@sin(cyc1)} ** 85 ++ .{@sin(-cyc1)} ** 85 ++ .{@sin(cyc1)} ** 86;
        reg.affine_d[self.bg] = .{@cos(cyc1)} ** 85 ++ .{@cos(-cyc1)} ** 85 ++ .{@cos(cyc1)} ** 86;
        reg.affine_x0[self.bg] = .{32} ** 85 ++ .{128} ** 85 ++ .{256} ** 86;
        reg.affine_y0[self.bg] = .{32} ** 85 ++ .{128} ** 85 ++ .{256} ** 86;

        return util.fullsecOf(self.frame) == 2;
    }
};

pub const TestBgScrollDMA = struct {
    frame: u64 = 0,
    bg: u2,
    flip_dma: bool,

    pub fn init(self: *TestBgScrollDMA) void {
        std.debug.print("testing scroll settings with DMA for bg {} (dma flipped? {})\n", .{ self.bg, self.flip_dma });

        const dma: bsp.RenderParams.DmaDir = if (self.flip_dma) .left_to_right else .top_to_bottom;
        const undma: bsp.RenderParams.DmaDir = if (self.flip_dma) .top_to_bottom else .left_to_right;

        reg.debug_mode = @intFromEnum(rpa.DebugMode.layer);
        reg.debug_arg = switch (self.bg) {
            0 => @intFromEnum(rpa.DebugArg.show_bg_0),
            1 => @intFromEnum(rpa.DebugArg.show_bg_1),
            2 => @intFromEnum(rpa.DebugArg.show_bg_2),
            3 => @intFromEnum(rpa.DebugArg.show_bg_3),
        };

        reg.dma_dir_bg[0] = @intFromEnum(if (self.bg == 0) dma else undma);
        reg.dma_dir_bg[1] = @intFromEnum(if (self.bg == 1) dma else undma);
        reg.dma_dir_bg[2] = @intFromEnum(if (self.bg == 2) dma else undma);
        reg.dma_dir_bg[3] = @intFromEnum(if (self.bg == 3) dma else undma);

        reg.oob_setting = @splat(@intFromEnum(rpa.OobSetting.wrap));
        rpa.setBgSize(0, 32);
        rpa.setBgSize(1, 32);
        rpa.setBgSize(2, 32);
        rpa.setBgSize(3, 32);

        for (0..4) |i| {
            reg.xscroll[i][0] = -256;
            reg.yscroll[i][0] = -256;
            reg.xscroll_do_dma[i] = false;
            reg.yscroll_do_dma[i] = false;
        }
    }

    pub fn tick(self: *TestBgScrollDMA) bool {
        const cyc: f32 = util.linCycleOf(self.frame, util.FULL_SECOND * 1) * 2 * std.math.pi;
        const delta: f32 = 2.0 * std.math.pi * 4.0 / 256.0;
        const mag: f32 = 2.0;

        switch (util.fullsecOf(self.frame)) {
            0, 1 => {
                reg.xscroll_do_dma[self.bg] = true;
                reg.yscroll_do_dma[self.bg] = false;
                for (0..256) |i| {
                    reg.xscroll[self.bg][i] = @intFromFloat(@sin(delta * @as(f32, @floatFromInt(i)) + cyc) * mag * 2);
                }
                reg.yscroll[self.bg][0] = 0;
            },
            2, 3 => {
                reg.xscroll_do_dma[self.bg] = false;
                reg.yscroll_do_dma[self.bg] = true;
                reg.xscroll[self.bg][0] = 0;
                for (0..256) |i| {
                    reg.yscroll[self.bg][i] = @intFromFloat(@cos(delta * @as(f32, @floatFromInt(i)) + cyc) * mag * 3);
                }
            },
            else => {
                return true;
            },
        }
        return false;
    }
};

// pub const TestBgPrioFeat = struct {
//     frame: u64 = 0,
//     x: i32 = 0,
//     y: i32 = 0,

//     pub fn init(_: *TestBgPrioFeat) void {
//         std.debug.print("testing BG tilemap features, prios and obj/tile gfx atlases\n", .{});

//         bsp.RenderParams.setBGSize(512, 512, 512, 512);
//         bsp.RenderParams.setDebugMode(.DEBUG_MODE_BUF_PRE_WIN, .DEBUG_ARG_SHOW_MAIN);
//         bsp.RenderParams.setToMain(true, true, true, true, true);

//         for (0..4) |i| {
//             bsp.RenderParams.setXScroll(@truncate(i), .{ .direct = 448 * 8 });
//             bsp.RenderParams.setYScroll(@truncate(i), .{ .direct = 32 * 8 });
//             bsp.RenderParams.setAffineA(@truncate(i), .{ .direct = 1 });
//             bsp.RenderParams.setAffineB(@truncate(i), .{ .direct = 0 });
//             bsp.RenderParams.setAffineC(@truncate(i), .{ .direct = 0 });
//             bsp.RenderParams.setAffineD(@truncate(i), .{ .direct = 1 });
//             bsp.RenderParams.setAffineX0(@truncate(i), .{ .direct = 0 });
//             bsp.RenderParams.setAffineY0(@truncate(i), .{ .direct = 0 });
//         }

//         var start = bsp.Obj{
//             .gfxid = 160,
//             .size = @intFromEnum(bsp.Obj.Size.SQ_8),
//         };
//         var end = bsp.Obj{
//             .gfxid = 162,
//             .size = @intFromEnum(bsp.Obj.Size.SQ_8),
//         };
//         var mid = bsp.Obj{
//             .gfxid = 161,
//             .size = @intFromEnum(bsp.Obj.Size.SQ_8),
//         };

//         var nums = [_]bsp.Obj{
//             bsp.Obj{
//                 .gfxid = 144,
//                 .size = @intFromEnum(bsp.Obj.Size.SQ_8),
//                 .prio = 0,
//             },
//             bsp.Obj{
//                 .gfxid = 145,
//                 .size = @intFromEnum(bsp.Obj.Size.SQ_8),
//                 .prio = 1,
//             },
//             bsp.Obj{
//                 .gfxid = 146,
//                 .size = @intFromEnum(bsp.Obj.Size.SQ_8),
//                 .prio = 2,
//             },
//             bsp.Obj{
//                 .gfxid = 147,
//                 .size = @intFromEnum(bsp.Obj.Size.SQ_8),
//                 .prio = 3,
//             },
//         };

//         for (0..4) |prio| {
//             const yoffs: u9 = @truncate(2 * prio + 8);

//             start.prio = @truncate(prio);
//             start.setPosXY(14 * 8 - 4, yoffs * 8 + 4);
//             start.writeToOAM(@truncate(0 + prio * 20));

//             nums[prio].setPosXY(15 * 8 - 4, yoffs * 8 + 4);
//             nums[prio].writeToOAM(@truncate(1 + prio * 20));

//             end.prio = @truncate(prio);
//             end.setPosXY(31 * 8 - 4, yoffs * 8 + 4);
//             end.writeToOAM(@truncate(2 + prio * 20));

//             mid.prio = @truncate(prio);
//             for (16..31, 3..) |xoffs, idx| {
//                 mid.setPosXY(@truncate(xoffs * 8 - 4), yoffs * 8 + 4);
//                 mid.writeToOAM(@truncate(idx + prio * 20));
//             }
//         }

//         for (1..4) |i| {
//             var obj_first = bsp.Obj{
//                 .gfxid = 0,
//                 .atlid = @truncate(i),
//                 .size = @intFromEnum(bsp.Obj.Size.SQ_8),
//             };
//             var obj_last = bsp.Obj{
//                 .gfxid = 511,
//                 .atlid = @truncate(i),
//                 .size = @intFromEnum(bsp.Obj.Size.SQ_8),
//             };
//             obj_first.setPosXY((1 + @as(u9, @truncate(i))) * 8, 29 * 8);
//             obj_last.setPosXY((1 + @as(u9, @truncate(i))) * 8, 30 * 8);
//             obj_first.writeToOAM(255 - (@as(u8, @truncate(i)) * 2));
//             obj_last.writeToOAM(255 - ((@as(u8, @truncate(i)) * 2) - 1));
//         }
//         for (1..4) |i| {
//             const tile_first = bsp.Tile{
//                 .gfxid = 0,
//                 .atlid = @truncate(i),
//             };
//             const tile_last = bsp.Tile{
//                 .gfxid = 1023,
//                 .atlid = @truncate(i),
//             };
//             tile_first.writeToTAM(0, (449 + @as(u9, @truncate(i))), 27 + 32);
//             tile_last.writeToTAM(0, (449 + @as(u9, @truncate(i))), 28 + 32);
//         }
//     }

//     pub fn tick(self: *TestBgPrioFeat) bool {
//         switch (util.fullsecOf(self.frame)) {
//             0 => bsp.RenderParams.setPrioRemap(false, false, false, false),
//             1 => bsp.RenderParams.setPrioRemap(true, false, false, false),
//             2 => bsp.RenderParams.setPrioRemap(false, true, false, false),
//             3 => bsp.RenderParams.setPrioRemap(false, false, true, false),
//             4 => bsp.RenderParams.setPrioRemap(false, false, false, true),
//             5 => bsp.RenderParams.setPrioRemap(false, false, true, true),
//             6 => bsp.RenderParams.setPrioRemap(false, true, true, true),
//             7 => bsp.RenderParams.setPrioRemap(true, true, true, true),
//             else => return true,
//         }

//         return false;
//     }
// };
