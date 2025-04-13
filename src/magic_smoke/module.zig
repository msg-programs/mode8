const mach = @import("mach");
const std = @import("std");
const gpu = mach.gpu;
const opp = @import("output_pipeline.zig");
const ppu = @import("ppu.zig");
const reg = @import("../hardware/registers.zig");
const bits = @import("../bsp/bits.zig");

// const Magic = @This();

// pub const mach_module = .mode8_module;
// pub const mach_systems = .{ .poweron, .poweroff, .tick };

var window: mach.ObjectID = undefined;
// title_timer: mach.time.Timer,

pub fn poweron(core: *mach.Core, w: mach.ObjectID) !void {
    // core.setFrameRateLimit(0);
    // core.windows.getValue(w).setFrameRateLimit(60);

    window = w;

    std.debug.print("poweron\n", .{});

    // magic.* = .{
    //     .window = window,
    //     .title_timer = try mach.time.Timer.start(),
    // };

    // ppup.init(core, window);
    opp.init(core, window);
}

pub fn poweroff() void {
    std.debug.print("poweroff\n", .{});
    // ppup.deinit();
    opp.deinit();
}

pub fn tick(core: *mach.Core) !void {
    const then = std.time.nanoTimestamp();

    // meh. TODO: make better
    // reg.controller[0] = bits.sto1x8in8(
    //     if (reg.controller[0] & 0x02 != 0) 0 else @intFromBool(core.keyPressed(.w)),
    //     @intFromBool(core.keyPressed(.w)),
    //     if (reg.controller[0] & 0x08 != 0) 0 else @intFromBool(core.keyPressed(.a)),
    //     @intFromBool(core.keyPressed(.a)),
    //     if (reg.controller[0] & 0x20 != 0) 0 else @intFromBool(core.keyPressed(.s)),
    //     @intFromBool(core.keyPressed(.s)),
    //     if (reg.controller[0] & 0x80 != 0) 0 else @intFromBool(core.keyPressed(.d)),
    //     @intFromBool(core.keyPressed(.d)),
    // );
    // reg.controller[1] = bits.sto1x8in8(
    //     if (reg.controller[0] & 0x02 != 0) 0 else @intFromBool(core.keyPressed(.o)),
    //     @intFromBool(core.keyPressed(.o)),
    //     if (reg.controller[0] & 0x08 != 0) 0 else @intFromBool(core.keyPressed(.k)),
    //     @intFromBool(core.keyPressed(.k)),
    //     if (reg.controller[0] & 0x20 != 0) 0 else @intFromBool(core.keyPressed(.l)),
    //     @intFromBool(core.keyPressed(.l)),
    //     if (reg.controller[0] & 0x80 != 0) 0 else @intFromBool(core.keyPressed(.semicolon)),
    //     @intFromBool(core.keyPressed(.semicolon)),
    // );
    // reg.controller[2] = bits.sto1x8in8(
    //     if (reg.controller[0] & 0x02 != 0) 0 else @intFromBool(core.keyPressed(.left_shift)),
    //     @intFromBool(core.keyPressed(.left_shift)),
    //     if (reg.controller[0] & 0x08 != 0) 0 else @intFromBool(core.keyPressed(.right_shift)),
    //     @intFromBool(core.keyPressed(.right_shift)),
    //     if (reg.controller[0] & 0x20 != 0) 0 else @intFromBool(core.keyPressed(.tab)),
    //     @intFromBool(core.keyPressed(.tab)),
    //     if (reg.controller[0] & 0x80 != 0) 0 else @intFromBool(core.keyPressed(.enter)),
    //     @intFromBool(core.keyPressed(.enter)),
    // );

    // var lookup = .{0} ** @as(u7, @intFromEnum(mach.Core.Key.max));
    // lookup[@intFromEnum(mach.Core.Key.w)] = 0;
    // lookup[@intFromEnum(mach.Core.Key.a)] = 2;
    // lookup[@intFromEnum(mach.Core.Key.s)] = 4;
    // lookup[@intFromEnum(mach.Core.Key.d)] = 6;
    // lookup[@intFromEnum(mach.Core.Key.o)] = 0;
    // lookup[@intFromEnum(mach.Core.Key.k)] = 2;
    // lookup[@intFromEnum(mach.Core.Key.l)] = 4;
    // lookup[@intFromEnum(mach.Core.Key.semicolon)] = 6;
    // lookup[@intFromEnum(mach.Core.Key.left_shift)] = 0;
    // lookup[@intFromEnum(mach.Core.Key.right_shift)] = 2;
    // lookup[@intFromEnum(mach.Core.Key.space)] = 4;
    // lookup[@intFromEnum(mach.Core.Key.enter)] = 6;

    // var iter = core.pollEvents();
    // while (iter.next()) |event| {
    //     switch (event) {
    //         .close => core.schedule(.exit),
    //         .key_press => |kev| {
    //             switch (kev.key) {
    //                 .w, .a, .s, .d => |key| {
    //                     reg.controller[0] |= @as(u8, 1) << lookup[@intFromEnum(key)] + 0;
    //                     reg.controller[0] |= @as(u8, 1) << lookup[@intFromEnum(key)] + 1;
    //                 },
    //                 .o, .k, .l, .semicolon => |key| {
    //                     reg.controller[1] |= @as(u8, 1) << lookup[@intFromEnum(key)] + 0;
    //                     reg.controller[1] |= @as(u8, 1) << lookup[@intFromEnum(key)] + 1;
    //                 },
    //                 .left_shift, .right_shift, .space, .enter => |key| {
    //                     reg.controller[2] |= @as(u8, 1) << lookup[@intFromEnum(key)] + 0;
    //                     reg.controller[2] |= @as(u8, 1) << lookup[@intFromEnum(key)] + 1;
    //                 },
    //                 else => {},
    //             }
    //         },
    //         .key_release => |kev| {
    //             switch (kev.key) {
    //                 .w, .a, .s, .d => |key| {
    //                     reg.controller[0] &= ~(@as(u8, 1) << lookup[@intFromEnum(key)] + 0);
    //                     reg.controller[0] |= @as(u8, 1) << lookup[@intFromEnum(key)] + 1;
    //                 },
    //                 .o, .k, .l, .semicolon => |key| {
    //                     reg.controller[1] &= ~(@as(u8, 1) << lookup[@intFromEnum(key)] + 0);
    //                     reg.controller[1] |= @as(u8, 1) << lookup[@intFromEnum(key)] + 1;
    //                 },
    //                 .left_shift, .right_shift, .space, .enter => |key| {
    //                     reg.controller[2] &= ~(@as(u8, 1) << lookup[@intFromEnum(key)] + 0);
    //                     reg.controller[2] |= @as(u8, 1) << lookup[@intFromEnum(key)] + 1;
    //                 },
    //                 else => {},
    //             }
    //         },
    //         else => {},
    //     }
    // }

    const win = core.windows.getValue(window);

    const encoder = win.device.createCommandEncoder(null);
    defer encoder.release();

    // ppup.doComputePass(win, encoder);
    ppu.tick();
    opp.doRenderPass(win, encoder);

    var command = encoder.finish(null);
    defer command.release();

    win.queue.submit(&[_]*gpu.CommandBuffer{command});

    // if (magic.title_timer.read() >= 1.0) {
    //     magic.title_timer.reset();
    // try mach.Core.printTitle(
    //     core,
    //     core.state().main_window,
    //     "Mode8 | {d}fps | Input {d}hz",
    //     .{
    //         mach.core.frameRate(),
    //         mach.core.inputRate(),
    //     },
    // );
    // }

    // hackily force ~60 fps until there's a framerate limiter again
    const now = std.time.nanoTimestamp();
    const delta = now - then;
    const delay = (16 * std.time.ns_per_ms) - delta;
    std.Thread.sleep(@truncate(@abs(delay)));
}
