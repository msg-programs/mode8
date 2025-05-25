# BG
mode8 renders four independent tilemap layers, referred to as BGs 0-3 (BackGround). Each BG consists of up to 512 by 512 Tiles, as stored in the TAM. BGs may be transformed, ...

**Further reading:**
- Tile.md (for general info on Tiles)
- Color.md (for general info on colors)

**Relevant registers:**
Note that all register values here and in the follwing paragraphs are per-BG.
- `dma_dir_bg`: DMA direction for all DMA-able BG registers

## BG transformation
BGs may be moved ("scrolled") in the x/y directions. Aditionally, an affine transformation as defined by a 2x2 matrix and an origin point may be applied to the BGs.

This is done by mapping the screen position to a tilemap view position, as defined by the following equation:

|view_x|   |affine_a affine_b|   |screen_x + xscroll - affine_x0|   |affine_x0|
|view_y| = |affine_c affine_d| * |screen_y + yscroll - affine_y0| + |affine_y0|

**Relevant registers:**
- `xscroll, yscroll`: Move the BG in the x/y direction (in pixel)
- `affine_x0, affine_y0`: Affine transformation origin point (in pixel)
- `affine_a`: Affine matrix parameter (horizontal scale)
- `affine_b`: Affine matrix parameter (horizontal shear)
- `affine_c`: Affine matrix parameter (vertical shear)
- `affine_d`: Affine matrix parameter (vertical scale)
- `xscroll_do_dma, yscroll_do_dma`: Should the `xscroll/yscroll` registers use DMA?
- `affine_x0_do_dma, affine_y0_do_dma`: Should the affine origin use DMA?
- `affine_a_do_dma, affine_b_do_dma, affine_c_do_dma, affine_d_do_dma`: Should the affine parameters use DMA?

## BG sizes
The tilemap is always 512x512 tiles, but the area that is actually rendered may be limited. Note that the BG always stays square. Due to the register size, the size is always a multiple of 2. The smallest size is 2x2.

**Relevant registers:**
- `bgsz`: Size of the BG. Should be set using the respective BSP function.

**Relevant BSP definitions**:
- Functions:
    - `bsp.RenderParams.setBgSize(bg: u2, size: u10)`
        - Sets the size of `bg` to `size`x`size`. Returns nothing.
        - Silently enforces that 2 <= `size` <= 512 and that `size % 2 == 0`

## BG offset
Tile (0,0) of every BG is the top left corner. This normally corresponds to the tile at (0,0) of the full tilemap, but this origin may be moved across the tilemap.

This may be used to e.g. fill the tilemap with many small rooms and then only showing one of them at a time using the BG size and offset. Rooms adjacent in the tilemap will never be rendered.

Care must be taken when offsetting to near the edges of the tilemap. If the BG's size is too large, the TAM is accessed in unexpected ways (wrapping, showing data for other BGs). mode8 can and will also attempt to read past the end of the TAM in extreme scenarios. This is not considered to be a bug.

**Relevant registers:**
`bgoffs_x, bgoffs_y`: BG offset in the x/y direction; in steps of 16 tiles.

## Out-of-bounds behaviour
BG transformations and small BG sizes can result in the BG not covering the full screen. In this case, the OOB setting and OOB data registers are used to determine how the remaining area should be filled.

### List of settings
- Wrap
    - OOB data register is ignored
    - OOB area is tiled with the BG. Assuming a 1D tilemap ABCD with width 4, the OOB is tiled ABCDABCDABCD
- Color
    - OOB data register is treated as 16 bit Color
    - OOB area is filled with the color
- Tile
    - OOB data register is treated as a Tile
    - OOB area is filled with this Tile
- Mirror
    - OOB data register is ignored
    - BG is repeatedly mirrored along the edges. Assuming a 1D tilemap ABCD with width 4, the OOB is tiled ABCDDCBAABCD

**Relevant registers:**
- `oob_setting`: Determines how the remaining area should be filled
- `oob_data`: Additional data for settings that require it. Use `@bitCast` to set to a color or tile where needed

**Relevant BSP definitions**:
- Enums:
    - `bsp.RenderParams.OobSetting`
- Structs:
    - `bsp.Color`
    - `bsp.Tile`

## Mosiac effect
Every BG may have a mosiac effect applied to it, where the BG is rendered in square tiles larger than 1 pixel. Every mosiac tile is filled with the color of the pixel at the top right corner of this tile and no average is calculated.

**Relevant registers:**
- `mosiac`: Size of the mosiac tiles - 1: 0 is off, 15 represents mosiac tiles of size 16x16
