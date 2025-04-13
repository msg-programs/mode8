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

var wn0 = WinSetupTest.TestWinNoDMA{ .win = 0, .flip_dma = false };
var wn1 = WinSetupTest.TestWinNoDMA{ .win = 1, .flip_dma = false };
var wn0f = WinSetupTest.TestWinNoDMA{ .win = 0, .flip_dma = true };
var wn1f = WinSetupTest.TestWinNoDMA{ .win = 1, .flip_dma = true };
var wnd0 = WinSetupTest.TestWinDMA{ .win = 0, .flip_dma = false };
var wnd1 = WinSetupTest.TestWinDMA{ .win = 1, .flip_dma = false };
var wnd0f = WinSetupTest.TestWinDMA{ .win = 0, .flip_dma = true };
var wnd1f = WinSetupTest.TestWinDMA{ .win = 1, .flip_dma = true };
var wtds = WinSetupTest.WinTestsDataSetup{};
var wc0 = WinSetupTest.TestWinCompose{ .for_layer = .show_bg_0 };
var wc1 = WinSetupTest.TestWinCompose{ .for_layer = .show_bg_1 };
var wc2 = WinSetupTest.TestWinCompose{ .for_layer = .show_bg_2 };
var wc3 = WinSetupTest.TestWinCompose{ .for_layer = .show_bg_3 };
var wc4 = WinSetupTest.TestWinCompose{ .for_layer = .show_objs };
var wc5 = WinSetupTest.TestWinCompose{ .for_layer = .show_col };

const screens = [_]Mgr.ManagedScreen{
    .{ .test_win_nodma = &wn0 },
    .{ .test_win_nodma = &wn1 },
    .{ .test_win_nodma = &wn0f },
    .{ .test_win_nodma = &wn1f },
    .{ .test_win_dma = &wnd0 },
    .{ .test_win_dma = &wnd1 },
    .{ .test_win_dma = &wnd0f },
    .{ .test_win_dma = &wnd1f },
    .{ .win_tests_data_setup = &wtds },
    .{ .test_win_compose = &wc0 },
    .{ .test_win_compose = &wc1 },
    .{ .test_win_compose = &wc2 },
    .{ .test_win_compose = &wc3 },
    .{ .test_win_compose = &wc4 },
    .{ .test_win_compose = &wc5 },
};

screen: u64,
go_next: bool,

var window: mach.ObjectID = undefined;

pub fn init(app: *App, core: *mach.Core, app_mod: mach.Mod(App)) !void {
    core.on_tick = app_mod.id.run;
    core.on_exit = app_mod.id.stop;

    window = try core.windows.new(.{
        .title = "mode8",
        // .width = 256 * 3,
        // .height = 256 * 3,
    });

    app.* = .{
        .screen = 0,
        .go_next = true,
    };
    // .screens = @constCast(&[_]Mgr.ManagedScreen{
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
}

pub fn tick(app: *App, core: *mach.Core) !void {
    while (core.nextEvent()) |event| {
        switch (event) {
            .window_open => |ev| {
                try mode8.magic_smoke.poweron(core, ev.window_id);
                core.windows.set(ev.window_id, .width, 256 * 2);
                core.windows.set(ev.window_id, .height, 256 * 2);
            },
            .close => core.exit(),
            else => {},
        }
    }

    if (app.go_next) {
        app.go_next = false;
        screens[app.screen].init();
    }

    if (screens[app.screen].tick()) {
        app.screen += 1;
        app.go_next = true;
    }

    if (app.screen >= screens.len) {
        core.exit();
    }
    try mode8.magic_smoke.tick(core);
}
