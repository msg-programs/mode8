const mach = @import("mach");
const std = @import("std");

// The global list of Mach modules registered for use in our application.
const Modules = mach.Modules(.{
    mach.Core,
    @import("App.zig"),
    // @import("mode8").magic_smoke,
});

pub fn main() !void {
    // const start = std.time.nanoTimestamp();

    const alloc = std.heap.c_allocator;

    var mods: Modules = undefined;
    try mods.init(alloc);

    const app = mods.get(.app);
    app.run(.start);

    // const end = std.time.nanoTimestamp();
    // std.debug.print("Took {} us to fast-forward through the debug program\n", .{@divFloor((end - start), 1000)});
}
