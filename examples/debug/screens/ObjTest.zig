const mode8 = @import("mode8");
const bsp = mode8.bsp;
const rpa = mode8.bsp.RenderParams;
const mem = mode8.hardware.memory;
const reg = mode8.hardware.registers;
const util = @import("../util.zig");
const std = @import("std");

pub const TestObjAttrs = struct {
    frame: u64 = 0,

    pub fn init(_: *TestObjAttrs) void {
        std.debug.print("testing objects\n", .{});
        reg.debug_mode = @intFromEnum(rpa.DebugMode.layer);
        reg.debug_arg = @intFromEnum(rpa.DebugArg.show_objs);
        // move objects away from the visible area
        // make sure all objs are away from the visible area
        @memset(mem.OAM[0..], 0);
    }

    pub fn tick(self: *TestObjAttrs) bool {
        const gfxids: [8]u9 = .{ 0, 1, 3, 7, 479, 510, 456, 490 };

        if (util.fullsecOf(self.frame) >= gfxids.len) {
            return true;
        }

        for (0..8) |i| {
            var obj = bsp.Obj{
                .gfxid = gfxids[util.fullsecOf(self.frame)],
                .size = @enumFromInt(@as(u3, @truncate(util.fullsecOf(self.frame)))),
                .vflip = (i & 1 != 0),
                .hflip = (i & 2 != 0),
                .rot = (i & 4 != 0),
            };
            obj.setPosXY(@intCast((5 + ((8 + 6) * (i & 1))) * 8), @intCast((8 * (i / 2)) * 8));
            obj.writeToOAM(@truncate(i));
        }

        return false;
    }
};

pub const TestObjPos = struct {
    frame: u64 = 0,
    obj1: bsp.Obj = .{ .gfxid = 456, .size = .RC_16x32 },
    obj2: bsp.Obj = .{ .gfxid = 490, .size = .RC_32x16 },

    pub fn init(_: *TestObjPos) void {
        std.debug.print("testing object positioning\n", .{});
        reg.debug_mode = @intFromEnum(rpa.DebugMode.layer);
        reg.debug_arg = @intFromEnum(rpa.DebugArg.show_objs);

        // move objects away from the visible area
        // make sure all objs are away from the visible area
        @memset(mem.OAM[0..], 0);

        var obj: bsp.Obj = .{ .gfxid = 0, .size = .SQ_8 };
        obj.setPosXY(0, 0); // top left
        obj.writeToOAM(2);
        obj.setPosXY(256 - 8, 256 - 8); // bot right
        obj.writeToOAM(3);

        obj.gfxid = 7;
        obj.size = .SQ_64;
        obj.setPosXY(-62, -62); // barely top left
        obj.writeToOAM(4);
        obj.setPosXY(254, 254); // barely bot right
        obj.writeToOAM(5);
    }

    pub fn tick(self: *TestObjPos) bool {
        const cyc: f32 = util.linCycleOf(self.frame, (util.FULL_SECOND * 2) - 1);
        switch (util.fullsecOf(self.frame)) {
            0, 1 => {
                const posf: f32 = cyc * @as(f32, @floatFromInt(256 + 16));
                const pos: i10 = @intFromFloat(posf);
                self.obj1.setPosXY(pos - 16, -16);
                self.obj2.setPosXY(-16, pos - 16);
            },
            2, 3 => {
                const posf: f32 = cyc * @as(f32, @floatFromInt(256 + 16));
                const pos: i10 = @intFromFloat(posf);
                self.obj1.setPosXY(pos - 16, 256 - 16);
                self.obj2.setPosXY(256 - 16, pos - 16);
            },
            else => return true,
        }
        self.obj1.writeToOAM(0);
        self.obj2.writeToOAM(1);
        return false;
    }
};
