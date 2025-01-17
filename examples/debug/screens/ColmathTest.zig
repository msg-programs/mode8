const mode8 = @import("mode8");
const bsp = mode8.bsp;
const util = @import("../util.zig");
const std = @import("std");

pub const TestFixcolDMA = struct {
    frame: u64 = 0,
    for_main: bool,
    flip_dma: bool,

    pub fn init(self: *TestFixcolDMA) void {
        // something is off here... but only like this printing and visuals work together.
        // might just be overlooking something, it's late again...
        std.debug.print("testing fixcol DMA (for main? {}, DMA flipped? {})\n", .{ self.flip_dma, self.for_main });

        if (self.for_main) {
            bsp.RenderParams.setDebugMode(.DEBUG_MODE_FIXCOL_SETUP, .DEBUG_ARG_SHOW_MAIN);
        } else {
            bsp.RenderParams.setDebugMode(.DEBUG_MODE_FIXCOL_SETUP, .DEBUG_ARG_SHOW_SUB);
        }

        const not_dma_dir: bsp.RenderParams.DMADir = if (self.flip_dma) .X else .Y;
        const dma_dir: bsp.RenderParams.DMADir = if (self.flip_dma) .Y else .X;

        if (self.flip_dma) {
            bsp.RenderParams.setDMADirOther(not_dma_dir, not_dma_dir, dma_dir, not_dma_dir);
        } else {
            bsp.RenderParams.setDMADirOther(not_dma_dir, not_dma_dir, not_dma_dir, dma_dir);
        }
        const start: [256]u16 = .{@as(u16, @bitCast(bsp.Color.of(0x000000, false)))} ** 256;
        bsp.RenderParams.setFixcolMain(.{ .dma = start });
        bsp.RenderParams.setFixcolSub(.{ .dma = start });
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

        var cols: [256]u16 = undefined;
        for (0..256) |i| {
            if (i < s) {
                cols[i] = (start + (@as(u16, @truncate(i)) * step)) | 0x8000;
            } else {
                cols[i] = @bitCast(bsp.Color.of(0x000000, false));
            }
        }

        if (self.for_main) {
            bsp.RenderParams.setFixcolMain(.{ .dma = cols });
        } else {
            bsp.RenderParams.setFixcolSub(.{ .dma = cols });
        }

        return self.frame > util.FULL_SECOND * 2;
    }
};

pub const TestFixcol = struct {
    frame: u64 = 0,
    for_main: bool,

    pub fn init(self: *TestFixcol) void {
        std.debug.print("testing fixcols (for main? {})\n", .{self.for_main});
        if (self.for_main) {
            bsp.RenderParams.setDebugMode(.DEBUG_MODE_FIXCOL_SETUP, .DEBUG_ARG_SHOW_MAIN);
        } else {
            bsp.RenderParams.setDebugMode(.DEBUG_MODE_FIXCOL_SETUP, .DEBUG_ARG_SHOW_SUB);
        }

        const black: u16 = @bitCast(bsp.Color.of(0x000000, false));
        bsp.RenderParams.setFixcolMain(.{ .direct = black });
        bsp.RenderParams.setFixcolSub(.{ .direct = black });
    }

    pub fn tick(self: *TestFixcol) bool {
        const cyc: f32 = util.linCycleOf(self.frame, util.FULL_SECOND);
        const startf: f32 = cyc * 255.0;
        const s: u24 = @intFromFloat(startf);

        if (self.for_main) {
            const col: u16 = @as(u16, @bitCast(bsp.Color.of(0xFF0000 + s, false)));
            bsp.RenderParams.setFixcolMain(.{ .direct = col });
        } else {
            const col: u16 = @as(u16, @bitCast(bsp.Color.of(0x00FF00 + s, false)));
            bsp.RenderParams.setFixcolSub(.{ .direct = col });
        }

        return self.frame > util.FULL_SECOND;
    }
};
