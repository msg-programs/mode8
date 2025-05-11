const mode8 = @import("../root.zig");
const std = @import("std");
const mem = mode8.hardware.memory;
const con = mode8.hardware.constants;

pub const Obj = packed struct {
    pos: u17 = 0,
    gfxid: u9 = 0,
    atlid: u2 = 0,
    vflip: bool = false,
    hflip: bool = false,
    prio: u2 = 0,
    size: Size = .SQ_8,
    rot: bool = false,

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

    pub fn setPosXY(self: *Obj, x: i10, y: i10) void {
        const clamp_x = std.math.clamp(x, -con.OBJ_DEADZONE_N_DIM_PIX, con.SCREEN_DIM_PIX - 1 + con.OBJ_DEADZONE_P_DIM_PIX);
        const clamp_y = std.math.clamp(y, -con.OBJ_DEADZONE_N_DIM_PIX, con.SCREEN_DIM_PIX - 1 + con.OBJ_DEADZONE_P_DIM_PIX);

        const obj_x: u17 = @intCast(clamp_x + con.OBJ_DEADZONE_N_DIM_PIX);
        const obj_y: u17 = @intCast(clamp_y + con.OBJ_DEADZONE_N_DIM_PIX);

        self.pos = @intCast(obj_x + con.OBJ_POS_DIM_PIX * obj_y);
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
        const offset: u32 = (gfxid | (@as(u32, atlid) << 9)) * con.OBJ_GFX_UNIT_PIX_NUM;
        for (0..con.OBJ_GFX_UNIT_PIX_NUM) |idx| {
            mem.OGM[offset + idx] = gfx[idx];
        }
    }
};
