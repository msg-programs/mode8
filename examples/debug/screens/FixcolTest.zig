const mode8 = @import("mode8");
const bsp = mode8.bsp;
const rpa = bsp.RenderParams;
const reg = mode8.hardware.registers;
const util = @import("../util.zig");
const std = @import("std");

pub const TestFixcolDMA = struct {
    frame: u64 = 0,
    for_main: bool,
    flip_dma: bool,

    pub fn init(self: *TestFixcolDMA) void {
        std.debug.print("testing fixcol DMA (for main? {}, DMA flipped? {})\n", .{ self.flip_dma, self.for_main });

        reg.debug_mode = @intFromEnum(rpa.DebugMode.fixcol_setup);
        if (self.for_main) {
            reg.debug_arg = @intFromEnum(rpa.DebugArg.show_main);
        } else {
            reg.debug_arg = @intFromEnum(rpa.DebugArg.show_sub);
        }

        const not_dma_dir: bsp.RenderParams.DMADir = if (self.flip_dma) .top_to_bottom else .left_to_right;
        const dma_dir: bsp.RenderParams.DMADir = if (self.flip_dma) .left_to_right else .top_to_bottom;

        reg.dma_dir_fixcol[0] = @intFromEnum(if (self.flip_dma) dma_dir else not_dma_dir);
        reg.dma_dir_fixcol[1] = @intFromEnum(if (self.flip_dma) not_dma_dir else dma_dir);

        const start: [256]u16 = .{@as(u16, @bitCast(bsp.Color.of(0x000000, false)))} ** 256;

        reg.fixcol_main_do_dma = self.for_main;
        reg.fixcol_sub_do_dma = !self.for_main;

        reg.fixcol_main = start;
        reg.fixcol_sub = start;
    }

    pub fn tick(self: *TestFixcolDMA) bool {
        var start: u16 = 0;
        const step: u16 = (0xFFFF / (256 * 4));
        start += if (self.for_main) 2 else 0;
        start += if (self.flip_dma) 1 else 0;
        start *= (256 * step);

        const cyc: f32 = util.lerpCycleOf(self.frame, util.FULL_SECOND * 2);
        const startf: f32 = cyc * 255.0;
        const s: u8 = @intFromFloat(startf);

        for (0..256) |i| {
            if (i < s) {
                if (self.for_main) {
                    reg.fixcol_main[i] = (start + (@as(u16, @truncate(i)) * step)) | 0x8000;
                } else {
                    reg.fixcol_sub[i] = (start + (@as(u16, @truncate(i)) * step)) | 0x8000;
                }
            } else {
                if (self.for_main) {
                    reg.fixcol_main[i] = @bitCast(bsp.Color.of(0x000000, false));
                } else {
                    reg.fixcol_sub[i] = @bitCast(bsp.Color.of(0x000000, false));
                }
            }
        }

        return self.frame > util.FULL_SECOND * 2;
    }
};

pub const TestFixcol = struct {
    frame: u64 = 0,
    for_main: bool,

    pub fn init(self: *TestFixcol) void {
        std.debug.print("testing fixcols (for main? {})\n", .{self.for_main});

        reg.debug_mode = @intFromEnum(rpa.DebugMode.fixcol_setup);
        if (self.for_main) {
            reg.debug_arg = @intFromEnum(rpa.DebugArg.show_main);
        } else {
            reg.debug_arg = @intFromEnum(rpa.DebugArg.show_sub);
        }

        reg.fixcol_main_do_dma = false;
        reg.fixcol_sub_do_dma = false;

        reg.fixcol_main[0] = @bitCast(bsp.Color.of(0x000000, false));
        reg.fixcol_sub[0] = @bitCast(bsp.Color.of(0x000000, false));
    }

    pub fn tick(self: *TestFixcol) bool {
        const cyc: f32 = util.linCycleOf(self.frame, util.FULL_SECOND);
        const startf: f32 = cyc * 255.0;
        const s: u24 = @intFromFloat(startf);

        if (self.for_main) {
            const col: u16 = @as(u16, @bitCast(bsp.Color.of(0xFF0000 + s, false)));
            reg.fixcol_main[0] = col;
        } else {
            const col: u16 = @as(u16, @bitCast(bsp.Color.of(0x00FF00 + s, false)));
            reg.fixcol_sub[0] = col;
        }

        return self.frame > util.FULL_SECOND;
    }
};
