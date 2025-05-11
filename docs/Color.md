# Colors
mode8 uses palettes of 16-bit colors for Tiles, Objs and Fixcols. A color consists of 3 color channels (each 5 bits) and 1 alpha channel (1 bit; either transparent or opaque with no inbetweens).

Tile and Obj graphics don't use colors directly; instead, they reference a global color palette containing 256 colors.

# BSP Color

The BSP provides a struct to handle colors: `bsp.Color`. It contains the following functions:
- `bsp.Color.writeToGCM(self: Color, idx: u8) void`:
    - Writes the Color `self` to the GCM as palette color number `idx`
- `bsp.Color.of(color: u24, trans: bool) bsp.Color`:
    - Creates a Color from a 24 bit RGB value `color` and the transparency info `trans`
    - This is useful if the desired value is present as RGB hex code, as provided by e.g. color pickers.
    - Note: mode8's colors can't represent all colors that a `u24` can. The function will silently adjust the color to a similar one that can be used.

The Color struct is defined as `packed` and may therefore be `@bitCast`ed to and from a `u16`