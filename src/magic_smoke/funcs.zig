const mach = @import("mach");
const std = @import("std");
const gpu = mach.gpu;
const opp = @import("output_pipeline.zig");
const ppup = @import("ppu_pipeline.zig");
const reg = @import("../hardware/registers.zig");

pub fn poweron(core: *mach.Core.Mod) !void {
    // mach.core.setFrameRateLimit(0);
    mach.core.setFrameRateLimit(60);
    ppup.init(core);
    opp.init(core);
}

pub fn poweroff() void {
    ppup.deinit();
    opp.deinit();
}

pub fn tick(core: *mach.Core.Mod) !void {
    reg.controller[0] &= 0b01010101;
    reg.controller[1] &= 0b01010101;
    reg.controller[2] &= 0b01010101;

    var lookup: [@intFromEnum(mach.core.Key.max)]u3 = .{0} ** @intFromEnum(mach.core.Key.max);
    lookup[@intFromEnum(mach.core.Key.w)] = 0;
    lookup[@intFromEnum(mach.core.Key.a)] = 2;
    lookup[@intFromEnum(mach.core.Key.s)] = 4;
    lookup[@intFromEnum(mach.core.Key.d)] = 6;
    lookup[@intFromEnum(mach.core.Key.o)] = 0;
    lookup[@intFromEnum(mach.core.Key.k)] = 2;
    lookup[@intFromEnum(mach.core.Key.l)] = 4;
    lookup[@intFromEnum(mach.core.Key.semicolon)] = 6;
    lookup[@intFromEnum(mach.core.Key.left_shift)] = 0;
    lookup[@intFromEnum(mach.core.Key.right_shift)] = 2;
    lookup[@intFromEnum(mach.core.Key.space)] = 4;
    lookup[@intFromEnum(mach.core.Key.enter)] = 6;

    var iter = mach.core.pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .close => core.schedule(.exit),
            .key_press => |kev| {
                switch (kev.key) {
                    .w, .a, .s, .d => |key| {
                        reg.controller[0] |= @as(u8, 1) << lookup[@intFromEnum(key)] + 0;
                        reg.controller[0] |= @as(u8, 1) << lookup[@intFromEnum(key)] + 1;
                    },
                    .o, .k, .l, .semicolon => |key| {
                        reg.controller[1] |= @as(u8, 1) << lookup[@intFromEnum(key)] + 0;
                        reg.controller[1] |= @as(u8, 1) << lookup[@intFromEnum(key)] + 1;
                    },
                    .left_shift, .right_shift, .space, .enter => |key| {
                        reg.controller[2] |= @as(u8, 1) << lookup[@intFromEnum(key)] + 0;
                        reg.controller[2] |= @as(u8, 1) << lookup[@intFromEnum(key)] + 1;
                    },
                    else => {},
                }
            },
            .key_release => |kev| {
                switch (kev.key) {
                    .w, .a, .s, .d => |key| {
                        reg.controller[0] &= ~(@as(u8, 1) << lookup[@intFromEnum(key)] + 0);
                        reg.controller[0] |= @as(u8, 1) << lookup[@intFromEnum(key)] + 1;
                    },
                    .o, .k, .l, .semicolon => |key| {
                        reg.controller[1] &= ~(@as(u8, 1) << lookup[@intFromEnum(key)] + 0);
                        reg.controller[1] |= @as(u8, 1) << lookup[@intFromEnum(key)] + 1;
                    },
                    .left_shift, .right_shift, .space, .enter => |key| {
                        reg.controller[2] &= ~(@as(u8, 1) << lookup[@intFromEnum(key)] + 0);
                        reg.controller[2] |= @as(u8, 1) << lookup[@intFromEnum(key)] + 1;
                    },
                    else => {},
                }
            },
            else => {},
        }
    }

    const encoder = core.state().device.createCommandEncoder(null);
    defer encoder.release();

    ppup.doComputePass(encoder);
    opp.doRenderPass(encoder);

    var command = encoder.finish(null);
    defer command.release();

    core.state().queue.submit(&[_]*gpu.CommandBuffer{command});

    core.schedule(.present_frame);
}
