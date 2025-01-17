
# Glossary
mode8's source and documentation uses the following terminology:

# Rendering Primitives
* Tile: The unit from which BGs are constructed.
* BG/Background: A tilemap constructed from Tiles.
* Obj/Object: A freely moveable graphic independent of all BGs.

# Memory
* TAM: Tile Attribute Memory. Holds the configuration for all Tiles that can be displayed.
* OAM: Object Attribute Memory. Holds the configuration for all Objects that can be displayed..
* TGM: Tile Graphics Memory. Holds the texture atlases used by Tiles.
* OGM: Object Graphics Memory. Holds the texture atlases used by Objects
* GCM: Global Color Memory. Holds the palette used by all graphics.

# Composition
* Fixcol: A fallback color that replaces transparency during composition.
* Layer: Unit of composition. There are six Layers: four BGs, the Objs and the Fixcol
* Window: A mask. Pixels inside the window are discarded.