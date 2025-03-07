const std = @import("std");
const zigimg = @import("zigimg");
const mach = @import("mach");
const mode8 = @import("mode8");

const gpu = mach.gpu;
const reg = mode8.hardware.registers;
const mem = mode8.hardware.memory;
const bsp = mode8.bsp;

const Mgr = @import("ScreenMgr.zig");
const WinSetupTest = @import("screens/WinSetupTest.zig");

const App = @This();
pub const mach_module = .app;
pub const mach_systems = .{ .start, .run, .stop, .init, .tick };

pub const start = mach.schedule(.{
    .{ mach.Core, .init },
    // .{ mode8.magic_smoke, .poweron },
    .{ App, .init },
    .{ mach.Core, .main },
});

pub const run = mach.schedule(.{
    .{ App, .tick },
    // .{ mode8.magic_smoke, .tick },
});

pub const stop = mach.schedule(.{
    // .{ mode8.magic_smoke, .poweroff },
    .{ mach.Core, .deinit },
});

screen: u64,
go_next: bool,
screens: []const Mgr.ManagedScreen,

var window: mach.ObjectID = undefined;

pub fn init(app: *App, core: *mach.Core, app_mod: mach.Mod(App)) !void {
    core.on_tick = app_mod.id.run;
    core.on_exit = app_mod.id.stop;

    window = try core.windows.new(.{
        .title = "mode8",
        // .width = 256 * 3,
        // .height = 256 * 3,
    });

    var wn1 = WinSetupTest.TestWinNoDMA{ .win = 0, .flip_dma = false };
    const t1 = Mgr.ManagedScreen{ .test_win_nodma = &wn1 };

    // hooooo boy
    // fix this ASAP, this can't be the way to do it now can it
    app.* = .{
        .screen = 0,
        .go_next = true,
        .screens = &.{
            t1,
        },
        // .screens = @constCast(&[_]Mgr.ManagedScreen{
        //     .{ .test_win_nodma = @alignCast(@ptrCast(@constCast(&.{ .win = 0, .flip_dma = false }))) },
        //     .{ .test_win_nodma = @alignCast(@ptrCast(@constCast(&.{ .win = 1, .flip_dma = false }))) },
        //     .{ .test_win_nodma = @alignCast(@ptrCast(@constCast(&.{ .win = 0, .flip_dma = true }))) },
        //     .{ .test_win_nodma = @alignCast(@ptrCast(@constCast(&.{ .win = 1, .flip_dma = true }))) },
        //     .{ .test_win_dma = @alignCast(@ptrCast(@constCast(&.{ .win = 0, .flip_dma = false }))) },
        //     .{ .test_win_dma = @alignCast(@ptrCast(@constCast(&.{ .win = 1, .flip_dma = false }))) },
        //     .{ .test_win_dma = @alignCast(@ptrCast(@constCast(&.{ .win = 0, .flip_dma = true }))) },
        //     .{ .test_win_dma = @alignCast(@ptrCast(@constCast(&.{ .win = 1, .flip_dma = true }))) },
        //     .{ .win_tests_data_setup = @alignCast(@ptrCast(@constCast(&.{}))) },
        //     .{ .test_win_compose = @alignCast(@ptrCast(@constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_0, .show_setup = false }))) },
        //     .{ .test_win_compose = @alignCast(@ptrCast(@constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_1, .show_setup = false }))) },
        //     .{ .test_win_compose = @alignCast(@ptrCast(@constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_2, .show_setup = false }))) },
        //     .{ .test_win_compose = @alignCast(@ptrCast(@constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_3, .show_setup = false }))) },
        //     .{ .test_win_compose = @alignCast(@ptrCast(@constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_OBJS, .show_setup = false }))) },
        //     .{ .test_win_compose = @alignCast(@ptrCast(@constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_COL, .show_setup = false }))) },
        //     .{ .test_win_send = @alignCast(@ptrCast(@constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_0, .to_main = true }))) },
        //     .{ .test_win_send = @alignCast(@ptrCast(@constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_1, .to_main = true }))) },
        //     .{ .test_win_send = @alignCast(@ptrCast(@constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_2, .to_main = true }))) },
        //     .{ .test_win_send = @alignCast(@ptrCast(@constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_3, .to_main = true }))) },
        //     .{ .test_win_send = @alignCast(@ptrCast(@constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_OBJS, .to_main = true }))) },
        //     .{ .test_win_send = @alignCast(@ptrCast(@constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_0, .to_main = false }))) },
        //     .{ .test_win_send = @alignCast(@ptrCast(@constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_1, .to_main = false }))) },
        //     .{ .test_win_send = @alignCast(@ptrCast(@constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_2, .to_main = false }))) },
        //     .{ .test_win_send = @alignCast(@ptrCast(@constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_3, .to_main = false }))) },
        //     .{ .test_win_send = @alignCast(@ptrCast(@constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_OBJS, .to_main = false }))) },
        //     .{ .test_win_col = @alignCast(@ptrCast(@constCast(&.{ .to_main = true }))) },
        //     .{ .test_win_col = @alignCast(@ptrCast(@constCast(&.{ .to_main = false }))) },
        //     .{ .test_fixcol = @alignCast(@ptrCast(@constCast(&.{ .for_main = true }))) },
        //     .{ .test_fixcol = @alignCast(@ptrCast(@constCast(&.{ .for_main = false }))) },
        //     .{ .test_fixcol_dma = @alignCast(@ptrCast(@constCast(&.{ .for_main = false, .flip_dma = false }))) },
        //     .{ .test_fixcol_dma = @alignCast(@ptrCast(@constCast(&.{ .for_main = true, .flip_dma = false }))) },
        //     .{ .test_fixcol_dma = @alignCast(@ptrCast(@constCast(&.{ .for_main = false, .flip_dma = true }))) },
        //     .{ .test_fixcol_dma = @alignCast(@ptrCast(@constCast(&.{ .for_main = true, .flip_dma = true }))) },
        //     .{ .bg_tests_data_setup = @alignCast(@ptrCast(@constCast(&.{}))) },
        //     .{ .bg_pos_fixup = @alignCast(@ptrCast(@constCast(&.{ .xnow = 0, .ynow = 0, .xtarget = -32, .ytarget = -32 }))) },
        //     .{ .test_bg_oob = @alignCast(@ptrCast(@constCast(&.{ .bg = 0 }))) },
        //     .{ .test_bg_oob = @alignCast(@ptrCast(@constCast(&.{ .bg = 1 }))) },
        //     .{ .test_bg_oob = @alignCast(@ptrCast(@constCast(&.{ .bg = 2 }))) },
        //     .{ .test_bg_oob = @alignCast(@ptrCast(@constCast(&.{ .bg = 3 }))) },
        //     .{ .bg_pos_fixup = @alignCast(@ptrCast(@constCast(&.{ .xnow = -32, .ynow = -32, .xtarget = 0, .ytarget = 0 }))) },
        //     .{ .test_bg_scroll_dma = @alignCast(@ptrCast(@constCast(&.{ .bg = 0, .flip_dma = false }))) },
        //     .{ .test_bg_scroll_dma = @alignCast(@ptrCast(@constCast(&.{ .bg = 1, .flip_dma = false }))) },
        //     .{ .test_bg_scroll_dma = @alignCast(@ptrCast(@constCast(&.{ .bg = 2, .flip_dma = false }))) },
        //     .{ .test_bg_scroll_dma = @alignCast(@ptrCast(@constCast(&.{ .bg = 3, .flip_dma = false }))) },
        //     .{ .test_bg_scroll_dma = @alignCast(@ptrCast(@constCast(&.{ .bg = 0, .flip_dma = true }))) },
        //     .{ .test_bg_scroll_dma = @alignCast(@ptrCast(@constCast(&.{ .bg = 1, .flip_dma = true }))) },
        //     .{ .test_bg_scroll_dma = @alignCast(@ptrCast(@constCast(&.{ .bg = 2, .flip_dma = true }))) },
        //     .{ .test_bg_scroll_dma = @alignCast(@ptrCast(@constCast(&.{ .bg = 3, .flip_dma = true }))) },
        //     .{ .bg_pos_fixup = @alignCast(@ptrCast(@constCast(&.{ .xnow = 0, .ynow = 0, .xtarget = -64, .ytarget = -64 }))) },
        //     .{ .test_bg_size = @alignCast(@ptrCast(@constCast(&.{ .bg = 0 }))) },
        //     .{ .test_bg_size = @alignCast(@ptrCast(@constCast(&.{ .bg = 1 }))) },
        //     .{ .test_bg_size = @alignCast(@ptrCast(@constCast(&.{ .bg = 2 }))) },
        //     .{ .test_bg_size = @alignCast(@ptrCast(@constCast(&.{ .bg = 3 }))) },
        //     .{ .test_bg_mosiac = @alignCast(@ptrCast(@constCast(&.{ .bg = 0 }))) },
        //     .{ .test_bg_mosiac = @alignCast(@ptrCast(@constCast(&.{ .bg = 1 }))) },
        //     .{ .test_bg_mosiac = @alignCast(@ptrCast(@constCast(&.{ .bg = 2 }))) },
        //     .{ .test_bg_mosiac = @alignCast(@ptrCast(@constCast(&.{ .bg = 3 }))) },
        //     .{ .bg_pos_fixup = @alignCast(@ptrCast(@constCast(&.{ .xnow = -64, .ynow = -64, .xtarget = 0, .ytarget = 0 }))) },
        //     .{ .test_bg_affine = @alignCast(@ptrCast(@constCast(&.{ .bg = 0 }))) },
        //     .{ .test_bg_affine = @alignCast(@ptrCast(@constCast(&.{ .bg = 1 }))) },
        //     .{ .test_bg_affine = @alignCast(@ptrCast(@constCast(&.{ .bg = 2 }))) },
        //     .{ .test_bg_affine = @alignCast(@ptrCast(@constCast(&.{ .bg = 3 }))) },
        //     .{ .test_bg_affine_dma = @alignCast(@ptrCast(@constCast(&.{ .bg = 0, .flip_dma = false }))) },
        //     .{ .test_bg_affine_dma = @alignCast(@ptrCast(@constCast(&.{ .bg = 1, .flip_dma = false }))) },
        //     .{ .test_bg_affine_dma = @alignCast(@ptrCast(@constCast(&.{ .bg = 2, .flip_dma = false }))) },
        //     .{ .test_bg_affine_dma = @alignCast(@ptrCast(@constCast(&.{ .bg = 3, .flip_dma = false }))) },
        //     .{ .test_bg_affine_dma = @alignCast(@ptrCast(@constCast(&.{ .bg = 0, .flip_dma = true }))) },
        //     .{ .test_bg_affine_dma = @alignCast(@ptrCast(@constCast(&.{ .bg = 1, .flip_dma = true }))) },
        //     .{ .test_bg_affine_dma = @alignCast(@ptrCast(@constCast(&.{ .bg = 2, .flip_dma = true }))) },
        //     .{ .test_bg_affine_dma = @alignCast(@ptrCast(@constCast(&.{ .bg = 3, .flip_dma = true }))) },
        //     .{ .test_bg_prio_feat = @alignCast(@ptrCast(@constCast(&.{}))) },
        //     .{ .test_obj_attrs = @alignCast(@ptrCast(@constCast(&.{}))) },
        //     .{ .test_obj_wrap = @alignCast(@ptrCast(@constCast(&.{}))) },
        //     .{ .compose_tests_data_setup = @alignCast(@ptrCast(@constCast(&.{}))) },
        //     .{ .test_buffer = @alignCast(@ptrCast(@constCast(&.{ .to_main = true }))) },
        //     .{ .test_buffer = @alignCast(@ptrCast(@constCast(&.{ .to_main = false }))) },
        //     .{ .test_colwin = @alignCast(@ptrCast(@constCast(&.{ .is_main = true }))) },
        //     .{ .test_colwin = @alignCast(@ptrCast(@constCast(&.{ .is_main = false }))) },
        //     .{ .test_cmath_enable = @alignCast(@ptrCast(@constCast(&.{}))) },
        //     .{ .test_cmath_sett = @alignCast(@ptrCast(@constCast(&.{}))) },
        // }),
    };
}

pub fn tick(app: *App, core: *mach.Core) !void {
    while (core.nextEvent()) |event| {
        switch (event) {
            .window_open => |ev| {
                try mode8.magic_smoke.poweron(core, ev.window_id);
                core.windows.set(ev.window_id, .width, 256 * 3);
                core.windows.set(ev.window_id, .height, 256 * 3);
            },
            .close => core.exit(),
            else => {},
        }
    }

    if (app.go_next) {
        app.go_next = false;
        app.screens[app.screen].init();
    }

    if (app.screens[app.screen].tick()) {
        app.screen += 1;
        app.go_next = true;
    }

    if (app.screen >= app.screens.len) {
        core.exit();
    }
    try mode8.magic_smoke.tick(core);
}
