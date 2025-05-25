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
const BgTest = @import("screens/BgTest.zig");
const ObjTest = @import("screens/ObjTest.zig");
const ComTest = @import("screens/ComposeTest.zig");

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
var bgds = BgTest.BgTestsDataSetup{};
var bgmv1 = BgTest.BgPosFixup{ .xnow = 0, .ynow = 0, .xtarget = -32, .ytarget = -32 };
var bgoob0 = BgTest.TestBgOOB{ .bg = 0 };
var bgoob1 = BgTest.TestBgOOB{ .bg = 1 };
var bgoob2 = BgTest.TestBgOOB{ .bg = 2 };
var bgoob3 = BgTest.TestBgOOB{ .bg = 3 };
var bgmv2 = BgTest.BgPosFixup{ .xnow = -32, .ynow = -32, .xtarget = 0, .ytarget = 0 };
var bgscd0 = BgTest.TestBgScrollDMA{ .bg = 0, .flip_dma = false };
var bgscd1 = BgTest.TestBgScrollDMA{ .bg = 1, .flip_dma = false };
var bgscd2 = BgTest.TestBgScrollDMA{ .bg = 2, .flip_dma = false };
var bgscd3 = BgTest.TestBgScrollDMA{ .bg = 3, .flip_dma = false };
var bgscd0f = BgTest.TestBgScrollDMA{ .bg = 0, .flip_dma = true };
var bgscd1f = BgTest.TestBgScrollDMA{ .bg = 1, .flip_dma = true };
var bgscd2f = BgTest.TestBgScrollDMA{ .bg = 2, .flip_dma = true };
var bgscd3f = BgTest.TestBgScrollDMA{ .bg = 3, .flip_dma = true };
var bgmv3 = BgTest.BgPosFixup{ .xnow = 0, .ynow = 0, .xtarget = -64, .ytarget = -64 };
var bgsz0 = BgTest.TestBgSize{ .bg = 0 };
var bgsz1 = BgTest.TestBgSize{ .bg = 1 };
var bgsz2 = BgTest.TestBgSize{ .bg = 2 };
var bgsz3 = BgTest.TestBgSize{ .bg = 3 };
var bgm0 = BgTest.TestBgMosiac{ .bg = 0 };
var bgm1 = BgTest.TestBgMosiac{ .bg = 1 };
var bgm2 = BgTest.TestBgMosiac{ .bg = 2 };
var bgm3 = BgTest.TestBgMosiac{ .bg = 3 };
var bgmv4 = BgTest.BgPosFixup{ .xnow = -64, .ynow = -64, .xtarget = 0, .ytarget = 0 };
var bgaff0 = BgTest.TestBgAffine{ .bg = 0 };
var bgaff1 = BgTest.TestBgAffine{ .bg = 1 };
var bgaff2 = BgTest.TestBgAffine{ .bg = 2 };
var bgaff3 = BgTest.TestBgAffine{ .bg = 3 };
var bgaffd0 = BgTest.TestBgAffineDMA{ .bg = 0, .flip_dma = false };
var bgaffd1 = BgTest.TestBgAffineDMA{ .bg = 1, .flip_dma = false };
var bgaffd2 = BgTest.TestBgAffineDMA{ .bg = 2, .flip_dma = false };
var bgaffd3 = BgTest.TestBgAffineDMA{ .bg = 3, .flip_dma = false };
var bgaffd0f = BgTest.TestBgAffineDMA{ .bg = 0, .flip_dma = true };
var bgaffd1f = BgTest.TestBgAffineDMA{ .bg = 1, .flip_dma = true };
var bgaffd2f = BgTest.TestBgAffineDMA{ .bg = 2, .flip_dma = true };
var bgaffd3f = BgTest.TestBgAffineDMA{ .bg = 3, .flip_dma = true };
var bgpf = BgTest.TestBgPrioFeat{};
var oa = ObjTest.TestObjAttrs{};
var ow = ObjTest.TestObjPos{};
var ctds = ComTest.ComposeTestsDataSetup{};
var bm = ComTest.TestBuffer{ .to_main = true };
var bs = ComTest.TestBuffer{ .to_main = false };
var cwm = ComTest.TestColwin{ .is_main = true };
var cws = ComTest.TestColwin{ .is_main = false };
var cme = ComTest.TestColorMathEnable{};
var cms = ComTest.TestColorMathSettings{};
// var ... = .{};

const screens = [_]Mgr.ManagedScreen{
    // .{ .test_win_nodma = &wn0 },
    // .{ .test_win_nodma = &wn1 },
    // .{ .test_win_nodma = &wn0f },
    // .{ .test_win_nodma = &wn1f },
    // .{ .test_win_dma = &wnd0 },
    // .{ .test_win_dma = &wnd1 },
    // .{ .test_win_dma = &wnd0f },
    // .{ .test_win_dma = &wnd1f },
    .{ .win_tests_data_setup = &wtds },
    // .{ .test_win_compose = &wc0 },
    // .{ .test_win_compose = &wc1 }, // 10
    // .{ .test_win_compose = &wc2 },
    // .{ .test_win_compose = &wc3 },
    // .{ .test_win_compose = &wc4 },
    // .{ .test_win_compose = &wc5 },
    // .{ .test_win_send = &wsm0 },
    // .{ .test_win_send = &wsm1 },
    // .{ .test_win_send = &wsm2 },
    // .{ .test_win_send = &wsm3 },
    // .{ .test_win_send = &wsmc },
    // .{ .test_win_send = &wss0 }, // 20
    // .{ .test_win_send = &wss1 },
    // .{ .test_win_send = &wss2 },
    // .{ .test_win_send = &wss3 },
    // .{ .test_win_send = &wssc },
    // .{ .test_win_col = &wcm },
    // .{ .test_win_col = &wcs },
    // .{ .test_fixcol = &fcm },
    // .{ .test_fixcol = &fcs },
    // .{ .test_fixcol_dma = &fcmd },
    // .{ .test_fixcol_dma = &fcsd }, // 30
    // .{ .test_fixcol_dma = &fcmdf },
    // .{ .test_fixcol_dma = &fcsdf },
    .{ .bg_tests_data_setup = &bgds },
    // .{ .bg_pos_fixup = &bgmv1 },
    // .{ .test_bg_oob = &bgoob0 },
    // .{ .test_bg_oob = &bgoob1 },
    // .{ .test_bg_oob = &bgoob2 },
    // .{ .test_bg_oob = &bgoob3 },
    // .{ .bg_pos_fixup = &bgmv2 },
    // .{ .test_bg_scroll_dma = &bgscd0 }, // 40
    // .{ .test_bg_scroll_dma = &bgscd1 },
    // .{ .test_bg_scroll_dma = &bgscd2 },
    // .{ .test_bg_scroll_dma = &bgscd3 },
    // .{ .test_bg_scroll_dma = &bgscd0f },
    // .{ .test_bg_scroll_dma = &bgscd1f },
    // .{ .test_bg_scroll_dma = &bgscd2f },
    // .{ .test_bg_scroll_dma = &bgscd3f },
    // .{ .bg_pos_fixup = &bgmv3 },
    // .{ .test_bg_size = &bgsz0 },
    // .{ .test_bg_size = &bgsz1 }, // 50
    // .{ .test_bg_size = &bgsz2 },
    // .{ .test_bg_size = &bgsz3 },
    // .{ .test_bg_mosiac = &bgm0 },
    // .{ .test_bg_mosiac = &bgm1 },
    // .{ .test_bg_mosiac = &bgm2 },
    // .{ .test_bg_mosiac = &bgm3 },
    // .{ .bg_pos_fixup = &bgmv4 },
    // .{ .test_bg_affine = &bgaff0 },
    // .{ .test_bg_affine = &bgaff1 },
    // .{ .test_bg_affine = &bgaff2 }, // 60
    // .{ .test_bg_affine = &bgaff3 },
    // .{ .test_bg_affine_dma = &bgaffd0 },
    // .{ .test_bg_affine_dma = &bgaffd1 },
    // .{ .test_bg_affine_dma = &bgaffd2 },
    // .{ .test_bg_affine_dma = &bgaffd3 },
    // .{ .test_bg_affine_dma = &bgaffd0f },
    // .{ .test_bg_affine_dma = &bgaffd1f },
    // .{ .test_bg_affine_dma = &bgaffd2f },
    // .{ .test_bg_affine_dma = &bgaffd3f },
    // .{ .test_bg_prio_feat = &bgpf }, // 70
    // .{ .test_obj_attrs = &oa },
    // .{ .test_obj_wrap = &ow },
    .{ .compose_tests_data_setup = &ctds },
    // .{ .test_buffer = &bm },
    // .{ .test_buffer = &bs },
    // .{ .test_colwin = &cwm },
    // .{ .test_colwin = &cws },
    .{ .test_cmath_enable = &cme },
    .{ .test_cmath_sett = &cms }, // 79
    // .{ .final = &}, // 80
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
