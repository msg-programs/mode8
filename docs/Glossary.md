
# Glossary
mode8's source and documentation uses the following terminology:

## Namespace names
- Registers: `mode8.hardware.registers.*`
- Constants: `mode8.hardware.constants.*`
- Memory: `mode8.hardware.memory.*`

## Memory

## Basics
- Tile: Unit of BG construction, see Tile.md
- BG (Background): Tilemap made from Tiles, see BG.md
- DMA: = Direct memory access, see DMA.md
- Obj (Object): Small, freely moveable graphic independent of all BGs, see Obj.md

## Render pipeline
- Window: A mask applied to layers, see Windows.md
- Layer: Umbrella term for the four BGs + the Objs + the Fixcols (6 layers in total).
- Buffer: The rendering pipeline uses two framebuffers (main and sub) at one point, see Compositing.md
- Fixcol: Fixed fallback color used in the rendering pipeline, see Compositing.md
- Color Math: The final step of the rendering pipeline, see Color Math.md

# Memory
See Memory.md
- TAM (Tile Attribute Memory): Holds the configuration for all Tiles that can be displayed.
- OAM (Object Attribute Memory): Holds the configuration for all Objects that can be displayed.
- TGM (Tile Graphics Memory): Holds the texture atlases used by Tiles.
- OGM (Object Graphics Memory): Holds the texture atlases used by Objects
- GCM (Global Color Memory): Holds the palette used by all graphics.
