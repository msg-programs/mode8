
# Atlasses
Graphics for Tiles and Objs are managed in Atlasses. In both cases, up to four Atlasses may be loaded and referenced. Atlasses are divided into "tiles" 8x8 pixels in size.

Atlasses for Tile graphics are 256x256 pixels in size, therefore holding up to 1024 unique graphics.
Atlasses for Obj graphics are 128x256 pixels in size, therefore holding up to 512 unique graphics.

Objs and Tiles use a graphics ID and an Atlas ID to find the graphics to display.
The Atlas ID is used to select the Atlas, and the graphics ID is used to select the "tile" within this Atlas to use.
The graphics ID increases in right-down order.
