const mode8 = @import("../root.zig");
const reg = mode8.hardware.registers;
const std = @import("std");

pub const Button = enum(u8) {
    DPAD_UP = 0,
    DPAD_LEFT,
    DPAD_DOWN,
    DPAD_RIGHT,

    ALPHA_A = 10,
    ALPHA_D,
    ALPHA_C,
    ALPHA_B,

    TRIG_LEFT = 20,
    TRIG_RIGHT,
    SELECT,
    START,
};

pub const Timing = enum(u1) {
    IS,
    JUST,
};

pub const State = enum(u1) {
    UP,
    DOWN,
};

pub fn checkIf(b: Button, t: Timing, s: State) bool {
    const idx = @intFromEnum(b) / 10;
    const offs = @intFromEnum(b) % 10;

    const constate = reg.controller[idx];
    const butstate = (constate >> @truncate(offs * 2)) & 0x3;

    const timing = butstate >> 1;
    const state = butstate % 2;

    return (timing == @intFromEnum(t) and state == @intFromEnum(s));
}
