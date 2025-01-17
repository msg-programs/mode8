const mode8 = @import("../root.zig");
const con = mode8.hardware.constants;

/// Graphics Color Memory (GCM)
/// holds the global palette of 256 colors currently used.
/// see bsp/Color.zig for how a color is stored.
pub var GCM = [_]u8{0} ** con.GCM_SZE_BYT;

/// Object Graphics Memory (OGM)
/// holds 4 texture atlasses for objs.
/// each atlas holds 128x128 pixels (16x16 tiles), at indexed 4 bbp.
pub var OGM = [_]u8{0} ** con.OGM_SZE_BYT;

/// Object Attribute Memory (OAM)
/// contains data about up to 256 objects to be rendered to the screen.
/// logically, a list of 32-bit entries, followed by a list of 4 bit entries.
/// see bsp/Obj.zig for how the data is stored in there.
pub var OAM = [_]u8{0} ** con.OAM_SZE_BYT;

/// Tile Graphics Memory (TGM)
/// holds 4 texture atlasses for tiles.
/// each atlas is 128x128 pixels (16x16 tiles) large, at indexed 4 bbp.
pub var TGM = [_]u8{0} ** con.TGM_SZE_BYT;

/// Tile Attribute Memory (TAM)
/// contains data about four backgrounds, containing 512x512 tiles each,
/// logically, a list of 16-bit entries.
/// see bsp/Obj.zig for how the data is stored in there.
pub var TAM = [_]u8{0} ** con.TAM_SZE_BYT;
