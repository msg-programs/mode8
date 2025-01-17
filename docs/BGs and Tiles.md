
# BGs
mode8 uses four seperate BGs. Every BG is 512x512 tiles in size.

# Tiles
Every tile of every BG can be configured as such:
* gfxid/atlid: The graphics ID and Atlas ID referencing graphics for this Tile, see the Atlasses document.
* prio: Mark this tile as prioritized. Relevant for composition.
* vflip: Mirror around the vertical axis.
* hflip: Mirror around the horizontal axis.
* rot: Mirror around the top-left/bottom-right axis.

Note: (rot = true) + (vflip = true) => 90° clockwise rotation