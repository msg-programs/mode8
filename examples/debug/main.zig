const mach = @import("mach");
const std = @import("std");

// The global list of Mach modules registered for use in our application.
pub const modules = .{
    mach.Core,
    @import("App.zig"),
};

pub var run: bool = true;

pub fn main() !void {
    // const start = std.time.nanoTimestamp();

    // Initialize mach.Core
    try mach.core.initModule();

    // Main loop
    while (run) {
        _ = try mach.core.tick();
    }

    // const end = std.time.nanoTimestamp();
    // std.debug.print("Took {} us to fast-forward through the debug program\n", .{@divFloor((end - start), 1000)});
}
