const mode8 = @import("../root.zig");
const std = @import("std");
const mem = mode8.hardware.memory;
const con = mode8.hardware.constants;

pub const Obj = packed struct {
    pos: u17 = 260,
    gfxid: u9 = 0,
    atlid: u2 = 0,
    vflip: u1 = 0,
    hflip: u1 = 0,
    prio: u2 = 0,
    size: u3 = 0,
    rot: u1 = 0,

    pub const Size = enum(u3) {
        SQ_8,
        SQ_16,
        SQ_32,
        SQ_64,
        RC_8x16,
        RC_16x8,
        RC_16x32,
        RC_32x16,
    };

    pub fn setPosXY(self: *Obj, x: u9, y: u9) void {
        const corr_x: u32 = std.math.clamp(x, 0, 360);
        const corr_y: u32 = std.math.clamp(y, 0, 360);

        self.pos = @truncate(corr_x + con.OBJ_POS_DIM_PIX * corr_y);
    }

    pub fn writeToOAM(self: Obj, i: u8) void {
        const idx: u32 = i;
        const data: u36 = @bitCast(self);
        const a: u8 = @truncate((data & 0x00000000FF) >> 0);
        const b: u8 = @truncate((data & 0x000000FF00) >> 8);
        const c: u8 = @truncate((data & 0x0000FF0000) >> 16);
        const d: u8 = @truncate((data & 0x00FF000000) >> 24);
        const z: u8 = @truncate((data & 0x0F00000000) >> 32);

        mem.OAM[idx * 4 + 0] = a;
        mem.OAM[idx * 4 + 1] = b;
        mem.OAM[idx * 4 + 2] = c;
        mem.OAM[idx * 4 + 3] = d;

        const static_offs: usize = 256 * 4;
        const byte_offs: usize = idx / 2;
        const shift: u3 = @truncate((idx % 2) * 4);
        const unshift: u3 = @truncate((1 - (idx % 2)) * 4);
        const prev_val = (mem.OAM[static_offs + byte_offs] >> unshift) & 0xF;
        mem.OAM[static_offs + byte_offs] = (prev_val << unshift) | @as(u8, @truncate(z << shift));
    }

    pub fn writeToOGM(atlid: u2, gfxid: u9, gfx: [64]u8) void {
        // tile offset (atlas + gfx) --> binary offset (tile offs * tile sze)
        // const atloffset: u32 = con.TILE_ATL_DIM_TIL * con.TILE_ATL_DIM_TIL * @as(u32, atlid);
        // const gfxoffset: u32 = atloffset + (gfxid * con.TILE_ATL_DIM_TIL);
        // const binoffset: u32 = con.TILE_GFX_SZE_BIT * gfxoffset / 8;
        const offset: u32 = (gfxid | (@as(u32, atlid) << 9)) * con.OBJ_GFX_UNIT_PIX_NUM;
        for (0..con.OBJ_GFX_UNIT_PIX_NUM) |idx| {
            // mem.TGM[binoffset + idx] = gfx[idx] | (@as(u8, gfx[idx + 1]) << 4);
            mem.OGM[offset + idx] = gfx[idx];
        }
    }
};
