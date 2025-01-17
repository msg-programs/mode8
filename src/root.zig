const std = @import("std");
const testing = std.testing;

pub const bsp = struct {
    pub const Obj = @import("bsp/Obj.zig").Obj;
    pub const Color = @import("bsp/Color.zig").Color;
    pub const RenderParams = @import("bsp/RenderParams.zig").RenderParams;
    pub const Tile = @import("bsp/Tile.zig").Tile;
    pub const Controller = @import("bsp/Controller.zig");
    pub const bits = @import("bsp/bits.zig");
};
pub const hardware = struct {
    pub const memory = @import("hardware/memory.zig");
    pub const constants = @import("hardware/constants.zig");
    pub const registers = @import("hardware/registers.zig");
};
pub const magic = @import("magic_smoke/funcs.zig");
