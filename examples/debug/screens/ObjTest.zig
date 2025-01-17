const mode8 = @import("mode8");
const bsp = mode8.bsp;
const util = @import("../util.zig");
const std = @import("std");

pub const TestObjAttrs = struct {
    frame: u64 = 0,

    pub fn init(_: *TestObjAttrs) void {
        std.debug.print("testing objects\n", .{});
        bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_OBJS);
        // move objects away from the visible area
        for (0..256) |i| {
            var obj = bsp.Obj{};
            obj.setPosXY(260, 260);
            obj.writeToOAM(@truncate(i));
        }
    }

    pub fn tick(self: *TestObjAttrs) bool {
        const gfxids: [8]u9 = .{ 0, 1, 3, 7, 479, 510, 456, 490 };

        if (util.fullsecOf(self.frame) >= gfxids.len) {
            return true;
        }

        for (0..8) |i| {
            var obj = bsp.Obj{
                .gfxid = gfxids[util.fullsecOf(self.frame)],
                .size = @truncate(util.fullsecOf(self.frame)),
                .vflip = if (i & 1 == 0) 1 else 0,
                .hflip = if (i & 2 == 0) 1 else 0,
                .rot = if (i & 4 == 0) 1 else 0,
            };
            obj.setPosXY(@truncate((5 + ((8 + 6) * (i & 1))) * 8), @truncate((8 * (i / 2)) * 8));
            obj.writeToOAM(@truncate(i));
        }

        return false;
    }
};

pub const TestObjWrap = struct {
    frame: u64 = 0,
    obj1: bsp.Obj = .{ .gfxid = 456, .size = @intFromEnum(bsp.Obj.Size.RC_16x32) },
    obj2: bsp.Obj = .{ .gfxid = 490, .size = @intFromEnum(bsp.Obj.Size.RC_32x16) },

    pub fn init(_: *TestObjWrap) void {
        std.debug.print("testing object wrap (no obj's position is negative here)\n", .{});
        bsp.RenderParams.setDebugMode(.DEBUG_MODE_LAYER, .DEBUG_ARG_SHOW_OBJS);
        // move objects away from the visible area
        for (0..256) |i| {
            var o = bsp.Obj{};
            o.setPosXY(260, 260);
            o.writeToOAM(@truncate(i));
        }
        var obj: bsp.Obj = .{ .gfxid = 1, .size = @intFromEnum(bsp.Obj.Size.SQ_16) };
        obj.setPosXY(352, 352);
        obj.writeToOAM(2);
    }

    pub fn tick(self: *TestObjWrap) bool {
        const cyc: f32 = util.linCycleOf(self.frame, (util.FULL_SECOND * 2) - 1);
        switch (util.fullsecOf(self.frame)) {
            0, 1 => {
                const posf: f32 = cyc * @as(f32, @floatFromInt(256));
                const pos: u9 = @intFromFloat(posf);
                const c: u9 = 360 - 16;
                const v: u9 = pos;
                self.obj1.setPosXY(v, c);
                self.obj2.setPosXY(c, v);
            },
            else => return true,
        }
        self.obj1.writeToOAM(0);
        self.obj2.writeToOAM(1);
        return false;
    }
};
