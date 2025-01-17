const mode8 = @import("../root.zig");
const mem = mode8.hardware.memory;

pub const Color = packed struct {
    r: u5,
    g: u5,
    b: u5,
    a: u1,

    pub fn writeToGCM(self: Color, idx: u8) void {
        const data: u16 = @bitCast(self);
        mem.GCM[@as(u16, idx) * 2 + 0] = @truncate((data & 0x00FF) >> 0);
        mem.GCM[@as(u16, idx) * 2 + 1] = @truncate((data & 0xFF00) >> 8);
    }

    pub fn of(color: u24, trans: bool) Color {
        return Color{
            .a = if (trans) 0 else 1,
            .r = @intFromFloat(@as(f32, @floatFromInt((color & 0xFF0000) >> 16)) / 255.0 * 31.0),
            .g = @intFromFloat(@as(f32, @floatFromInt((color & 0x00FF00) >> 8)) / 255.0 * 31.0),
            .b = @intFromFloat(@as(f32, @floatFromInt((color & 0x0000FF) >> 0)) / 255.0 * 31.0),
        };
    }
};
