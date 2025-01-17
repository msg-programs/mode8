const mode8 = @import("../root.zig");
const con = mode8.hardware.constants;

/// move background 0-3 in x axis. DMA-able
pub var xscroll: [con.BG_NUM][con.DMA_NUM]i32 = .{.{0} ** con.DMA_NUM} ** con.BG_NUM;

/// bitfield xxxx3210: enable DMA for which backgrounds?
pub var xscroll_do_dma: u8 = 0;

/// move background 0-3 in y axis. DMA-able
pub var yscroll: [con.BG_NUM][con.DMA_NUM]i32 = .{.{0} ** con.DMA_NUM} ** con.BG_NUM;

/// bitfield xxxx3210: enable DMA for which backgrounds?
pub var yscroll_do_dma: u8 = 0;

/// affine transformation: origin x pos. DMA-able
pub var affine_x0: [con.BG_NUM][con.DMA_NUM]i32 = .{.{0} ** con.DMA_NUM} ** con.BG_NUM;

/// bitfield xxxx3210: enable DMA for which backgrounds?
pub var affine_x0_do_dma: u8 = 0;

/// affine transformation: origin y pos. DMA-able
pub var affine_y0: [con.BG_NUM][con.DMA_NUM]i32 = .{.{0} ** con.DMA_NUM} ** con.BG_NUM;

/// bitfield xxxx3210: enable DMA for which background?
pub var affine_y0_do_dma: u8 = 0;

/// affine transformation: 2x2 matrix top left value. DMA-able
pub var affine_a: [con.BG_NUM][con.DMA_NUM]f32 = .{.{1.0} ** con.DMA_NUM} ** con.BG_NUM;

/// bitfield xxxx3210: enable DMA for which background?
pub var affine_a_do_dma: u8 = 0;

/// affine transformation: 2x2 matrix top right value. DMA-able
pub var affine_b: [con.BG_NUM][con.DMA_NUM]f32 = .{.{0.0} ** con.DMA_NUM} ** con.BG_NUM;

/// bitfield xxxx3210: enable DMA for which background?
pub var affine_b_do_dma: u8 = 0;

/// affine transformation: 2x2 matrix bottom left value. DMA-able
pub var affine_c: [con.BG_NUM][con.DMA_NUM]f32 = .{.{0.0} ** con.DMA_NUM} ** con.BG_NUM;

/// bitfield xxxx3210: enable DMA for which background?
pub var affine_c_do_dma: u8 = 0;

/// affine transformation: 2x2 matrix bottom right value. DMA-able
pub var affine_d: [con.BG_NUM][con.DMA_NUM]f32 = .{.{1.0} ** con.DMA_NUM} ** con.BG_NUM;

/// bitfield xxxx3210: enable DMA for which background?
pub var affine_d_do_dma: u8 = 0;

/// bitfield {11110000, 33332222}: set mosiac effect strength for background 0-3
pub var mosiac: [con.BG_NUM / 2]u8 = .{0} ** (con.BG_NUM / 2);

/// set window 0-1 start. DMA-able
pub var win_start: [con.WINDOW_NUM][con.DMA_NUM]u8 = .{.{0} ** con.DMA_NUM} ** con.WINDOW_NUM;

/// set window 0-1 end. DMA-able
pub var win_end: [con.WINDOW_NUM][con.DMA_NUM]u8 = .{.{255} ** con.DMA_NUM} ** con.WINDOW_NUM;

/// bitfield xxxxEeSs: enable DMA for which window? for start, end, neither or both?
pub var win_bounds_do_dma: u8 = 0;

/// bitfield {ccccoooo, 22223333, 11110000}: how to compose windows 0-1 together
pub var win_compose: [3]u8 = .{0} ** 3;

/// bitfield xxxo3210: send this background to the main buffer
pub var to_main: u8 = 0;

/// bitfield xxxo3210: send this background to the sub buffer
pub var to_sub: u8 = 0;

/// bitfield xxxo3210: send the window data to the main buffer
pub var win_to_main: u8 = 0;

/// bitfield xxxo3210: send the window data to the sub buffer
pub var win_to_sub: u8 = 0;

/// fixed color for main buffer. DMA-able
pub var fixcol_main: [con.DMA_NUM]u16 = .{0} ** (con.DMA_NUM);

/// bool: enable DMA?
pub var fixcol_main_do_dma: u8 = 0;

/// fixed color for sub buffer. DMA-able
pub var fixcol_sub: [con.DMA_NUM]u16 = .{0} ** (con.DMA_NUM);

/// bool: enable DMA?
pub var fixcol_sub_do_dma: u8 = 0;

/// bitfield: low nybble = window apply mode for main buffer, high -> sub
pub var win_apply: u8 = 0;

/// bitfield xxxx3210: which of the high-prio background tiles to layer above all objs
pub var prio_remap: u8 = 0;

/// bool: should the sub buffer be overridden with the sub buffer fixed color?
pub var fix_sub: u8 = 0;

/// bitfield xxxx3210: should DMA be applied horizontally or vertically? (for BGs)
pub var dma_dir: u8 = 0;

/// bitfield xxxxsm10: should DMA be applied horizontally or vertically? (for wins and fixcols)
/// note: DMA for wins also flips how windows work
pub var dma_dir_ex: u8 = 0;

/// bitfield: for which BGs should color math be enabled?
pub var math_enable: u8 = 0;

/// bitfield: what algorithm is used for color math?
pub var math_algo: u8 = 0;

/// bitfield: what normalization should happen after color math?
pub var math_normalize: u8 = 0;

/// bitfield 33221100: how should OOB tilemap positions be handled?
pub var oob_setting: u8 = 0;

/// data to use when OOB tilemap pos is encountered
pub var oob_data: [con.BG_NUM][2]u8 = .{.{0} ** 2} ** con.BG_NUM;

/// background size / 2 - 1
pub var bgsz: [con.BG_NUM]u8 = .{15} ** con.BG_NUM;

/// background offset / 16
pub var bgoffs: [con.BG_NUM]u8 = .{0} ** con.BG_NUM;

/// bitfield {TrTdTlTu, TdTcTbTa, TSTsTRTL}: controller state
pub var controller: [3]u8 = .{ 0, 0, 0 };

// bitfield {aaaammmm}: debug mode settings
pub var debug: u8 = 0;
