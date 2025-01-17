
# Objects
mode8 uses four seperate BGs. Every BG is 512x512 tiles in size.

Every Object can be configured as such:
* gfxid/atlid: The graphics ID and Atlas ID referencing graphics for this Tile, see the Atlasses document.
* pos: The position of this Object, see below.
* prio: The priority of this Object. Relevant for composition.
* vflip: Mirror around the vertical axis.
* hflip: Mirror around the horizontal axis.
* rot: Mirror around the top-left/bottom-right axis.
* size: The size of this Object, see below.

Note: (rot = true) + (vflip = true) => 90° clockwise rotation

#### Position
Objects use an area of 360x360 pixels that is independent of BGs for positioning.
The origin of the Object is the top-left pixel; and (0,0) of the area is the top left pixel of the visible window.

If an Object is so close to the right and/or bottom edge of the area that its graphics go outside the 360x360 area, the graphics wrap around to the left and/or top of the area.

#### Size
Unlike Tiles, Objects may be larger than 8x8 pixels. As Atlasses are organized in 8x8 pixel "tiles", a graphics ID can only reference one such "tile". This is the top left "tile", the rest of the graphic is taken from adjacent datalike one would expect from a classic texture atlas.

Example for a 16x16 Object:
```
(gfxid +  0) (gfxid +  1)
(gfxid + 16) (gfxid + 17)
```
