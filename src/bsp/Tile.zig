const mode8 = @import("../root.zig");
const mem = mode8.hardware.memory;
const con = mode8.hardware.constants;
const std = @import("std");

pub const Tile = packed struct {
    gfxid: u10 = 0,
    atlid: u2 = 0,
    prio: u1 = 0,
    vflip: u1 = 0,
    hflip: u1 = 0,
    rot: u1 = 0,

    pub fn writeToTAM(self: Tile, bg: u2, xpos: u9, ypos: u9) void {
        const data: u16 = @bitCast(self);
        const bgoffset: u32 = 2 * con.BG_DIM_TIL * con.BG_DIM_TIL * @as(u32, bg);
        mem.TAM[bgoffset + (2 * (@as(u64, xpos) + con.BG_DIM_TIL * @as(u64, ypos))) + 0] = @truncate((data & 0x00FF) >> 0);
        mem.TAM[bgoffset + (2 * (@as(u64, xpos) + con.BG_DIM_TIL * @as(u64, ypos))) + 1] = @truncate((data & 0xFF00) >> 8);
    }

    pub fn writeToTGM(atlid: u2, gfxid: u10, gfx: [64]u8) void {
        // tile offset (atlas + gfx) --> binary offset (tile offs * tile sze)
        // const atloffset: u32 = con.TILE_ATL_DIM_TIL * con.TILE_ATL_DIM_TIL * @as(u32, atlid);
        // const gfxoffset: u32 = atloffset + (gfxid * con.TILE_ATL_DIM_TIL);
        // const binoffset: u32 = con.TILE_GFX_SZE_BIT * gfxoffset / 8;
        const offset: u32 = (gfxid | (@as(u32, atlid) << 10)) * con.TILE_GFX_PIX_NUM;
        for (0..con.TILE_GFX_PIX_NUM) |idx| {
            // mem.TGM[binoffset + idx] = gfx[idx] | (@as(u8, gfx[idx + 1]) << 4);
            mem.TGM[offset + idx] = gfx[idx];
        }
    }
};
