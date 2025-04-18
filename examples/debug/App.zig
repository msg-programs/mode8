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
const FixcolTest = @import("screens/FixcolTest.zig");

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
var wsm0 = WinSetupTest.TestWinSend{ .for_layer = .show_bg_0, .to_main = true };
var wsm1 = WinSetupTest.TestWinSend{ .for_layer = .show_bg_1, .to_main = true };
var wsm2 = WinSetupTest.TestWinSend{ .for_layer = .show_bg_2, .to_main = true };
var wsm3 = WinSetupTest.TestWinSend{ .for_layer = .show_bg_3, .to_main = true };
var wsmc = WinSetupTest.TestWinSend{ .for_layer = .show_objs, .to_main = true };
var wss0 = WinSetupTest.TestWinSend{ .for_layer = .show_bg_0, .to_main = false };
var wss1 = WinSetupTest.TestWinSend{ .for_layer = .show_bg_1, .to_main = false };
var wss2 = WinSetupTest.TestWinSend{ .for_layer = .show_bg_2, .to_main = false };
var wss3 = WinSetupTest.TestWinSend{ .for_layer = .show_bg_3, .to_main = false };
var wssc = WinSetupTest.TestWinSend{ .for_layer = .show_objs, .to_main = false };
var wcm = WinSetupTest.TestColWin{ .to_main = true };
var wcs = WinSetupTest.TestColWin{ .to_main = false };
var fcm = FixcolTest.TestFixcol{ .for_main = true };
var fcs = FixcolTest.TestFixcol{ .for_main = false };
var fcmd = FixcolTest.TestFixcolDMA{ .for_main = false, .flip_dma = false };
var fcsd = FixcolTest.TestFixcolDMA{ .for_main = true, .flip_dma = false };
var fcmdf = FixcolTest.TestFixcolDMA{ .for_main = false, .flip_dma = true };
var fcsdf = FixcolTest.TestFixcolDMA{ .for_main = true, .flip_dma = true };
// var ... = .{};
// var ... = .{ .xnow = 0, .ynow = 0, .xtarget = -32, .ytarget = -32 };
// var ... = .{ .bg = 0 };
// var ... = .{ .bg = 1 };
// var ... = .{ .bg = 2 };
// var ... = .{ .bg = 3 };
// var ... = .{ .xnow = -32, .ynow = -32, .xtarget = 0, .ytarget = 0 };
// var ... = .{ .bg = 0, .flip_dma = false };
// var ... = .{ .bg = 1, .flip_dma = false };
// var ... = .{ .bg = 2, .flip_dma = false };
// var ... = .{ .bg = 3, .flip_dma = false };
// var ... = .{ .bg = 0, .flip_dma = true };
// var ... = .{ .bg = 1, .flip_dma = true };
// var ... = .{ .bg = 2, .flip_dma = true };
// var ... = .{ .bg = 3, .flip_dma = true };
// var ... = .{ .xnow = 0, .ynow = 0, .xtarget = -64, .ytarget = -64 };
// var ... = .{ .bg = 0 };
// var ... = .{ .bg = 1 };
// var ... = .{ .bg = 2 };
// var ... = .{ .bg = 3 };
// var ... = .{ .bg = 0 };
// var ... = .{ .bg = 1 };
// var ... = .{ .bg = 2 };
// var ... = .{ .bg = 3 };
// var ... = .{ .xnow = -64, .ynow = -64, .xtarget = 0, .ytarget = 0 };
// var ... = .{ .bg = 0 };
// var ... = .{ .bg = 1 };
// var ... = .{ .bg = 2 };
// var ... = .{ .bg = 3 };
// var ... = .{ .bg = 0, .flip_dma = false };
// var ... = .{ .bg = 1, .flip_dma = false };
// var ... = .{ .bg = 2, .flip_dma = false };
// var ... = .{ .bg = 3, .flip_dma = false };
// var ... = .{ .bg = 0, .flip_dma = true };
// var ... = .{ .bg = 1, .flip_dma = true };
// var ... = .{ .bg = 2, .flip_dma = true };
// var ... = .{ .bg = 3, .flip_dma = true };
// var ... = .{};
// var ... = .{};
// var ... = .{};
// var ... = .{};
// var ... = .{ .to_main = true };
// var ... = .{ .to_main = false };
// var ... = .{ .is_main = true };
// var ... = .{ .is_main = false };
// var ... = .{};
// var ... = .{};

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
    .{ .test_win_send = &wsm0 },
    .{ .test_win_send = &wsm1 },
    .{ .test_win_send = &wsm2 },
    .{ .test_win_send = &wsm3 },
    .{ .test_win_send = &wsmc },
    .{ .test_win_send = &wss0 },
    .{ .test_win_send = &wss1 },
    .{ .test_win_send = &wss2 },
    .{ .test_win_send = &wss3 },
    .{ .test_win_send = &wssc },
    .{ .test_win_col = &wcm },
    .{ .test_win_col = &wcs },
    .{ .test_fixcol = &fcm },
    .{ .test_fixcol = &fcs },
    .{ .test_fixcol_dma = &fcmd },
    .{ .test_fixcol_dma = &fcsd },
    .{ .test_fixcol_dma = &fcmdf },
    .{ .test_fixcol_dma = &fcsdf },
    // .{ .bg_tests_data_setup = &},
    // .{ .bg_pos_fixup = &},
    // .{ .test_bg_oob = &},
    // .{ .test_bg_oob = &},
    // .{ .test_bg_oob = &},
    // .{ .test_bg_oob = &},
    // .{ .bg_pos_fixup = &},
    // .{ .test_bg_scroll_dma = &},
    // .{ .test_bg_scroll_dma = &},
    // .{ .test_bg_scroll_dma = &},
    // .{ .test_bg_scroll_dma = &},
    // .{ .test_bg_scroll_dma = &},
    // .{ .test_bg_scroll_dma = &},
    // .{ .test_bg_scroll_dma = &},
    // .{ .test_bg_scroll_dma = &},
    // .{ .bg_pos_fixup = &},
    // .{ .test_bg_size = &},
    // .{ .test_bg_size = &},
    // .{ .test_bg_size = &},
    // .{ .test_bg_size = &},
    // .{ .test_bg_mosiac = &},
    // .{ .test_bg_mosiac = &},
    // .{ .test_bg_mosiac = &},
    // .{ .test_bg_mosiac = &},
    // .{ .bg_pos_fixup = &},
    // .{ .test_bg_affine = &},
    // .{ .test_bg_affine = &},
    // .{ .test_bg_affine = &},
    // .{ .test_bg_affine = &},
    // .{ .test_bg_affine_dma = &},
    // .{ .test_bg_affine_dma = &},
    // .{ .test_bg_affine_dma = &},
    // .{ .test_bg_affine_dma = &},
    // .{ .test_bg_affine_dma = &},
    // .{ .test_bg_affine_dma = &},
    // .{ .test_bg_affine_dma = &},
    // .{ .test_bg_affine_dma = &},
    // .{ .test_bg_prio_feat = &},
    // .{ .test_obj_attrs = &},
    // .{ .test_obj_wrap = &},
    // .{ .compose_tests_data_setup = &},
    // .{ .test_buffer = &},
    // .{ .test_buffer = &},
    // .{ .test_colwin = &},
    // .{ .test_colwin = &},
    // .{ .test_cmath_enable = &},
    // .{ .test_cmath_sett = &},
};

screen: u64,
go_next: bool,
timer: std.time.Timer,
frames: u64,

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
        .timer = try std.time.Timer.start(),
        .frames = 0,
    };
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
        app.timer.reset();
        app.frames = 0;
    }
    if (screens[app.screen].tick()) {
        app.screen += 1;
        app.go_next = true;
        const lap = @as(f32, @floatFromInt(app.timer.lap()));
        const mslap = lap / @as(f32, std.time.ns_per_ms);
        const slap = mslap / @as(f32, std.time.ms_per_s);
        std.debug.print("{} frames in {d:.0} ms = {d:.2} fps\n", .{ app.frames, mslap, @as(f32, @floatFromInt(app.frames)) / slap });
    }
    app.frames += 1;

    if (app.screen >= screens.len) {
        core.exit();
    }
    try mode8.magic_smoke.tick(core);
}
