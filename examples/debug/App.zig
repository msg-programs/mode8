const std = @import("std");
const mach = @import("mach");
const gpu = mach.gpu;
const mode8 = @import("mode8");
const magic = mode8.magic;
const reg = mode8.hardware.registers;
const mem = mode8.hardware.memory;
const bsp = mode8.bsp;
const zigimg = @import("zigimg");
const main = @import("main.zig");

const Mgr = @import("ScreenMgr.zig");

pub const name = .app;
pub const Mod = mach.Mod(@This());

pub const systems = .{
    .init = .{ .handler = init },
    .after_init = .{ .handler = afterInit },
    .deinit = .{ .handler = deinit },
    .tick = .{ .handler = tick },
};

title_timer: mach.Timer,
screen: u64,
go_next: bool,
screens: []Mgr.ManagedScreen,

pub fn deinit(core: *mach.Core.Mod, game: *Mod) void {
    magic.poweroff();
    core.schedule(.deinit);
    _ = game;
}

fn init(game: *Mod, core: *mach.Core.Mod) !void {
    core.schedule(.init);
    game.schedule(.after_init);

    try core.set(core.state().main_window, .width, 256 * 3);
    try core.set(core.state().main_window, .height, 256 * 3);
}

fn afterInit(game: *Mod, core: *mach.Core.Mod) !void {
    try magic.poweron(core);

    // @constCast my beloved <3
    // I should really learn how this const business works...
    game.init(.{
        .title_timer = try mach.Timer.start(),
        .screen = 0,
        .go_next = true,
        .screens = @constCast(&[_]Mgr.ManagedScreen{
            .{ .test_win_nodma = @constCast(&.{ .win = 0, .flip_dma = false }) },
            .{ .test_win_nodma = @constCast(&.{ .win = 1, .flip_dma = false }) },
            .{ .test_win_nodma = @constCast(&.{ .win = 0, .flip_dma = true }) },
            .{ .test_win_nodma = @constCast(&.{ .win = 1, .flip_dma = true }) },
            .{ .test_win_dma = @constCast(&.{ .win = 0, .flip_dma = false }) },
            .{ .test_win_dma = @constCast(&.{ .win = 1, .flip_dma = false }) },
            .{ .test_win_dma = @constCast(&.{ .win = 0, .flip_dma = true }) },
            .{ .test_win_dma = @constCast(&.{ .win = 1, .flip_dma = true }) },
            .{ .win_tests_data_setup = @constCast(&.{}) },
            .{ .test_win_compose = @constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_0, .show_setup = false }) },
            .{ .test_win_compose = @constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_1, .show_setup = false }) },
            .{ .test_win_compose = @constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_2, .show_setup = false }) },
            .{ .test_win_compose = @constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_3, .show_setup = false }) },
            .{ .test_win_compose = @constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_OBJS, .show_setup = false }) },
            .{ .test_win_compose = @constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_COL, .show_setup = false }) },
            .{ .test_win_send = @constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_0, .to_main = true }) },
            .{ .test_win_send = @constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_1, .to_main = true }) },
            .{ .test_win_send = @constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_2, .to_main = true }) },
            .{ .test_win_send = @constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_3, .to_main = true }) },
            .{ .test_win_send = @constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_OBJS, .to_main = true }) },
            .{ .test_win_send = @constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_0, .to_main = false }) },
            .{ .test_win_send = @constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_1, .to_main = false }) },
            .{ .test_win_send = @constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_2, .to_main = false }) },
            .{ .test_win_send = @constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_BG_3, .to_main = false }) },
            .{ .test_win_send = @constCast(&.{ .for_layer = .DEBUG_ARG_SHOW_OBJS, .to_main = false }) },
            .{ .test_win_col = @constCast(&.{ .to_main = true }) },
            .{ .test_win_col = @constCast(&.{ .to_main = false }) },
            .{ .test_fixcol = @constCast(&.{ .for_main = true }) },
            .{ .test_fixcol = @constCast(&.{ .for_main = false }) },
            .{ .test_fixcol_dma = @constCast(&.{ .for_main = false, .flip_dma = false }) },
            .{ .test_fixcol_dma = @constCast(&.{ .for_main = true, .flip_dma = false }) },
            .{ .test_fixcol_dma = @constCast(&.{ .for_main = false, .flip_dma = true }) },
            .{ .test_fixcol_dma = @constCast(&.{ .for_main = true, .flip_dma = true }) },
            .{ .bg_tests_data_setup = @constCast(&.{}) },
            .{ .bg_pos_fixup = @constCast(&.{ .xnow = 0, .ynow = 0, .xtarget = -32, .ytarget = -32 }) },
            .{ .test_bg_oob = @constCast(&.{ .bg = 0 }) },
            .{ .test_bg_oob = @constCast(&.{ .bg = 1 }) },
            .{ .test_bg_oob = @constCast(&.{ .bg = 2 }) },
            .{ .test_bg_oob = @constCast(&.{ .bg = 3 }) },
            .{ .bg_pos_fixup = @constCast(&.{ .xnow = -32, .ynow = -32, .xtarget = 0, .ytarget = 0 }) },
            .{ .test_bg_scroll_dma = @constCast(&.{ .bg = 0, .flip_dma = false }) },
            .{ .test_bg_scroll_dma = @constCast(&.{ .bg = 1, .flip_dma = false }) },
            .{ .test_bg_scroll_dma = @constCast(&.{ .bg = 2, .flip_dma = false }) },
            .{ .test_bg_scroll_dma = @constCast(&.{ .bg = 3, .flip_dma = false }) },
            .{ .test_bg_scroll_dma = @constCast(&.{ .bg = 0, .flip_dma = true }) },
            .{ .test_bg_scroll_dma = @constCast(&.{ .bg = 1, .flip_dma = true }) },
            .{ .test_bg_scroll_dma = @constCast(&.{ .bg = 2, .flip_dma = true }) },
            .{ .test_bg_scroll_dma = @constCast(&.{ .bg = 3, .flip_dma = true }) },
            .{ .bg_pos_fixup = @constCast(&.{ .xnow = 0, .ynow = 0, .xtarget = -64, .ytarget = -64 }) },
            .{ .test_bg_size = @constCast(&.{ .bg = 0 }) },
            .{ .test_bg_size = @constCast(&.{ .bg = 1 }) },
            .{ .test_bg_size = @constCast(&.{ .bg = 2 }) },
            .{ .test_bg_size = @constCast(&.{ .bg = 3 }) },
            .{ .test_bg_mosiac = @constCast(&.{ .bg = 0 }) },
            .{ .test_bg_mosiac = @constCast(&.{ .bg = 1 }) },
            .{ .test_bg_mosiac = @constCast(&.{ .bg = 2 }) },
            .{ .test_bg_mosiac = @constCast(&.{ .bg = 3 }) },
            .{ .bg_pos_fixup = @constCast(&.{ .xnow = -64, .ynow = -64, .xtarget = 0, .ytarget = 0 }) },
            .{ .test_bg_affine = @constCast(&.{ .bg = 0 }) },
            .{ .test_bg_affine = @constCast(&.{ .bg = 1 }) },
            .{ .test_bg_affine = @constCast(&.{ .bg = 2 }) },
            .{ .test_bg_affine = @constCast(&.{ .bg = 3 }) },
            .{ .test_bg_affine_dma = @constCast(&.{ .bg = 0, .flip_dma = false }) },
            .{ .test_bg_affine_dma = @constCast(&.{ .bg = 1, .flip_dma = false }) },
            .{ .test_bg_affine_dma = @constCast(&.{ .bg = 2, .flip_dma = false }) },
            .{ .test_bg_affine_dma = @constCast(&.{ .bg = 3, .flip_dma = false }) },
            .{ .test_bg_affine_dma = @constCast(&.{ .bg = 0, .flip_dma = true }) },
            .{ .test_bg_affine_dma = @constCast(&.{ .bg = 1, .flip_dma = true }) },
            .{ .test_bg_affine_dma = @constCast(&.{ .bg = 2, .flip_dma = true }) },
            .{ .test_bg_affine_dma = @constCast(&.{ .bg = 3, .flip_dma = true }) },
            .{ .test_bg_prio_feat = @constCast(&.{}) },
            .{ .test_obj_attrs = @constCast(&.{}) },
            .{ .test_obj_wrap = @constCast(&.{}) },
            .{ .compose_tests_data_setup = @constCast(&.{}) },
            .{ .test_buffer = @constCast(&.{ .to_main = true }) },
            .{ .test_buffer = @constCast(&.{ .to_main = false }) },
            .{ .test_colwin = @constCast(&.{ .is_main = true }) },
            .{ .test_colwin = @constCast(&.{ .is_main = false }) },
            .{ .test_cmath_enable = @constCast(&.{}) },
            .{ .test_cmath_sett = @constCast(&.{}) },
        }),
    });
    core.schedule(.start);
}

fn tick(core: *mach.Core.Mod, game: *Mod) !void {
    try magic.tick(core);

    if (game.state().go_next) {
        game.state().go_next = false;
        game.state().screens[game.state().screen].init();
    }

    if (game.state().title_timer.read() >= 1.0) {
        game.state().title_timer.reset();
        try mach.Core.printTitle(
            core,
            core.state().main_window,
            "Mode8 | {d}fps | Input {d}hz",
            .{
                mach.core.frameRate(),
                mach.core.inputRate(),
            },
        );
        core.schedule(.update);
    }

    if (game.state().screens[game.state().screen].tick()) {
        game.state().screen += 1;
        game.state().go_next = true;
    }

    if (game.state().screen >= game.state().screens.len) {
        main.run = false;
    }
}
