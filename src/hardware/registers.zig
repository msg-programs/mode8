const mode8 = @import("../root.zig");
const con = mode8.hardware.constants;

// /// move background 0-3 in x axis. DMA-able
// pub var xscroll: [con.BG_NUM][con.DMA_NUM]i32 = @splat(@splat(0));

// /// enable DMA for which backgrounds?
// pub var xscroll_do_dma: [con.BG_NUM]bool = @splat(false);

// /// move background 0-3 in y axis. DMA-able
// pub var yscroll: [con.BG_NUM][con.DMA_NUM]i32 = @splat(@splat(0));

// /// enable DMA for which backgrounds?
// pub var yscroll_do_dma: [con.BG_NUM]bool = @splat(false);

// /// affine transformation: origin x pos. DMA-able
// pub var affine_x0: [con.BG_NUM][con.DMA_NUM]i32 = @splat(@splat(0));

// /// enable DMA for which backgrounds?
// pub var affine_x0_do_dma: [con.BG_NUM]bool = @splat(false);

// /// affine transformation: origin y pos. DMA-able
// pub var affine_y0: [con.BG_NUM][con.DMA_NUM]i32 = @splat(@splat(0));

// /// enable DMA for which background?
// pub var affine_y0_do_dma: [con.BG_NUM]bool = @splat(false);

// /// affine transformation: 2x2 matrix top left value. DMA-able
// pub var affine_a: [con.BG_NUM][con.DMA_NUM]f32 = @splat(@splat(1));

// /// enable DMA for which background?
// pub var affine_a_do_dma: [con.BG_NUM]bool = @splat(false);

// /// affine transformation: 2x2 matrix top right value. DMA-able
// pub var affine_b: [con.BG_NUM][con.DMA_NUM]f32 = @splat(@splat(0));

// /// enable DMA for which background?
// pub var affine_b_do_dma: [con.BG_NUM]bool = @splat(false);

// /// affine transformation: 2x2 matrix bottom left value. DMA-able
// pub var affine_c: [con.BG_NUM][con.DMA_NUM]f32 = @splat(@splat(0));

// /// enable DMA for which background?
// pub var affine_c_do_dma: [con.BG_NUM]bool = @splat(false);

// /// affine transformation: 2x2 matrix bottom right value. DMA-able
// pub var affine_d: [con.BG_NUM][con.DMA_NUM]f32 = @splat(@splat(1));

// /// enable DMA for which background?
// pub var affine_d_do_dma: [con.BG_NUM]bool = @splat(false);

// /// set mosiac effect strength for background 0-3
// pub var mosiac: [con.BG_NUM]u4 = @splat(0);

/// set window 0-1 start. DMA-able
pub var win_start: [con.WINDOW_NUM][con.DMA_NUM]u8 = @splat(@splat(0));

/// set window 0-1 end. DMA-able
pub var win_end: [con.WINDOW_NUM][con.DMA_NUM]u8 = @splat(@splat(255));

/// enable DMA for which window's start?
pub var win_start_do_dma: [con.WINDOW_NUM]bool = @splat(false);

/// enable DMA for which window's end?
pub var win_end_do_dma: [con.WINDOW_NUM]bool = @splat(false);

// /// how to compose windows 0-1 together
// pub var win_compose: [6]u4 = @splat(0);

// /// send this background to the main buffer
// pub var to_main: [5]bool = @splat(false);

// /// send this background to the sub buffer
// pub var to_sub: [5]bool = @splat(false);

// /// send the window data to the main buffer
// pub var win_to_main: [5]bool = @splat(false);

// /// send the window data to the sub buffer
// pub var win_to_sub: [5]bool = @splat(false);

// /// fixed color for main buffer. DMA-able
// pub var fixcol_main: [con.DMA_NUM]u16 = .{0} ** (con.DMA_NUM);

// /// bool: enable DMA?
// pub var fixcol_main_do_dma: bool = false;

// /// fixed color for sub buffer. DMA-able
// pub var fixcol_sub: [con.DMA_NUM]u16 = @splat(0);

// /// bool: enable DMA?
// pub var fixcol_sub_do_dma: bool = false;

// /// window apply mode for buffers, 0 = main 1 = sub
// pub var win_apply: [2]u4 = @splat(0);

// /// which of the high-prio background tiles to layer above all objs
// pub var prio_remap: [4]bool = @splat(false);

// /// bool: should the sub buffer be overridden with the sub buffer fixed color?
// pub var fix_sub: bool = 0;

// /// should DMA be applied horizontally or vertically? (for BGs)
// pub var dma_dir_bg: [4]bool = @splat(false);

/// should DMA for windows be applied horizontally or vertically?
/// note: also flips how windows work
pub var dma_dir_win: [con.WINDOW_NUM]u1 = @splat(0);

// /// should DMA for fixcols be applied horizontally or vertically?
// pub var dma_dir_fixcol: [2]bool = @splat(false);

// /// for which layers should color math be enabled?
// pub var math_enable: [6]bool = @splat(false);

// /// what algorithm is used for color math?
// pub var math_algo: u4 = 0;

// /// what normalization should happen after color math?
// pub var math_normalize: u2 = 0;

// /// how should OOB tilemap positions be handled?
// pub var oob_setting: [4]u2 = @splat(0);

// /// data to use when OOB tilemap pos is encountered
// pub var oob_data: [con.BG_NUM]u16 = @splat(0);

// /// background size / 2 - 1
// pub var bgsz: [con.BG_NUM]u8 = @splat(15);

// /// background offset / 16
// pub var bgoffs: [con.BG_NUM]u8 = @splat(0);

// /// bitfield {TrTdTlTu, TdTcTbTa, TSTsTRTL}: controller state
// pub var controller: [3]u8 = .{ 0, 0, 0 };

// debug mode
pub var debug_mode: u4 = 0;

// debug argument
pub var debug_arg: u4 = 0;
