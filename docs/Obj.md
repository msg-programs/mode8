# Objs
An Obj (object) is a freely moveable graphic, independent of the BGs. The graphics for all Objs is stored in the OGM; the data for the Objs is stored in the OAM. mode8 supports up to 256 Objs at one time.

**Further reading:**
- Compositing.md (for more info on how the prio setting interacts with BGs)

## Positioning
Objs are internally positioned on a 320x320 playfield, with the screen being in the bottom right corner with a marigin of one pixel. This allows Objs to be moved partially or fully out of view in every direction. Objs can't be disabled or made invisible, so the only way of not displaying them is to move them away from the visible screen. The origin point for drawing is the top left corner.

## Priorities
Objs have four different priority settings, determining over which other Objs and BGs they are displayed. If two Objs have the same priority, the one later in the OAM (i.e. with the lager index) is prioritised.

## Graphics
The Obj graphics atlasses works in the same way as the ones used for tiles. If the Obj is configured to be larger than 8x8 pixels, the graphics ID references the top left 8x8 unit and nearby graphics in the atlas are used for the rest of the Obj as such (ex: size 16x16):

gfxid      gfxid + 1
gfxid + 16 gfxid + 17

## BSP Obj
The BSP provides a struct to handle Objs: `bsp.Obj`.

It contains the following fields:
- `pos`: The position of the Obj in the Obj playfield.
    - Note: Not trivial to set, use the function described below
- `atlid`: The atlas to use
- `gfxid`: The ID of the graphics in the specified atlas
    - Note: References the top left corner, see section above
- `prio`: The priority of this Obj
- `size`: The size of the Obj. See the `bsp.Obj.Size` enum for possible values
    - Note: Obj sizes are given in pixels
- `vflip`: Should the Obj be mirrored vertically?
- `hflip`: Should the Obj be mirrored horizontally?
- `rot`: Should the Obj be rotated? (i.e. mirrored by the top-left/bottom-right diagonal)
    - Note: rectangular Objs will change their shape accordingly
    - Note: the position of the top left corner does not change when rotating

It also contains the following functions:
- `bsp.Obj.writeToOAM(self: Obj, i: u8) void`:
    - Writes the Obj `self` to the OAM at the specified index
    - Note that the same Obj struct may be written to multiple indices with modifications inbetween
- `bsp.Obj.writeToOGM(atlid: u2, gfxid: u9, gfx: [64]u8) void`:
    - Writes the data held by `gfx` into the specified atlas at the specified position (`atlid, gfxid`)
    - As the OGM doesn't know about how the graphics are used by Objs, this can only happen in 8x8 chunks. This is equivalent to how tile graphics are written.
- `bsp.Obj. setPosXY(self: *Obj, x: i10, y: i10) void `:
    - Updates the magic `pos` field so that the Obj appears at the given location
    - As the internal playfield coordinates can be awkward to use, this uses coordinates relative to the screen:
        - The top left corner of the screen is at 0/0
        - The bottom right corner of the screen is at 255/255
        - The top left corner of the playfield is at -63/-63
        - The bottom right corner of the playfield is at 256/256
    - Note that coords outside the range [-63, 256] inclusive are clamped

The Obj struct is defined as `packed` and may therefore be `@bitCast`ed to and from a `u36`. Note that this isn't helpful for interacting with the OAM directly, see below.

## Graphics
Every Obj may use one of the four atlasses stored in the OGM to define its graphics. Atlasses for Objs are divided into 8x8 chunks and measure 16x32 chunks (128x256 px). The `gfxid` determines which chunks to use for the Obj by specifying the respective chunk. For larger Objs, nearby chunks are used. An Obj of size `SQ_16` with the `gfxid` set to 2 would use chunks 2, 3, 18 and 19 (i.e. the ones to the right and below the top left chunk).

Note that certain combinations of Obj sizes and graphics IDs can cause mode8 to access the OGM in unexpected ways (wrappping, showing graphics from other atlasses). mode8 can and will also attempt to read past the end of the OGM in extrame cases. This is not considered to be a bug.
