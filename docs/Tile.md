# Tiles
A Tile is the 8x8 pixel unit from which BGs are constructed. The graphics for all tiles is stored in the TGM; the tilemaps that make up the BGs are stored in the TAM.

**Further reading:**
- Memory.md (for general info on the TAM, TGM, atlasses and graphics IDs)

## BSP Tile
The BSP provides a struct to handle Objs: `bsp.Tile`.

It contains the following fields:
- `atlid`: The atlas to use
- `gfxid`: The ID of the graphics in the specified atlas
- `prio`: Should this tile be treated as prioritized? (Used in composition)
- `vflip`: Should the tile graphic be mirrored vertically?
- `hflip`: Should the tile graphic be mirrored horizontally?
- `rot`: Should the tile graphic be rotated? (i.e. mirrored by the top-left/bottom-right diagonal)

It also contains the following functions:
- `bsp.Tile.writeToTAM(self: Tile, bg: u2, xpos: u9, ypos: u9) void`:
    - Writes the Tile `self` to the TAM so that it's on the tilemap for the `bg` at the `xpos` and `ypos`
- `bsp.Tile.writeToTGM(atlid: u2, gfxid: u10, gfx: [64]u8) void`:
    - Writes the data held by `gfx` into the specified atlas at the specified position (`atlid, gfxid`)
    - `gfx` contains the palette indices of the tile's pixels from left to right, top to bottom.

The Tile struct is defined as `packed` and may therefore be `@bitCast`ed to and from a `u16`