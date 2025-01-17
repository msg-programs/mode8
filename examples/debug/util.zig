const std = @import("std");

pub const FULL_SECOND: u64 = 60;
pub const HALF_SECOND: u64 = 30;
pub const THRT_SECOND: u64 = 20;
pub const QURT_SECOND: u64 = 15;
pub const FITH_SECOND: u64 = 12;

pub fn fullsecOf(frame: u64) u64 {
    return frame / FULL_SECOND;
}

pub fn halfsecOf(frame: u64) u64 {
    return frame / HALF_SECOND;
}

pub fn percentOfDim(part: u64, full: u64) f32 {
    return @as(f32, @floatFromInt(part)) / @as(f32, @floatFromInt(full));
}

pub fn linCycleOf(frame: u64, frames: u64) f32 {
    return @as(f32, @floatFromInt(frame % ((frames) + 1))) / @as(f32, @floatFromInt(frames));
}

pub fn lerpCycleOf(frame: u64, frames: u64) f32 {
    const x: f32 = linCycleOf(frame, frames);
    return if (x < 0.5) 2 * x * x else 1 - std.math.pow(f32, -2 * x + 2, 2) / 2;
}
