
# API Overview
After importing mode8, the following namespaces may be accessed:

* `.hardware`: The virtual hardware.
    * `.constants`: Useful constants used everywhere else.
    * `.memory`: Big buffers that hold graphics, tilemaps, Object information and palettes.
    * `.registers`: Smaller buffers and variables that control rendering.
* `.bsp`: The builtin Board Support Package to make the hardware easier to use.
    * `bits`: Helper functions to make working with bit fields easier.
    * `Color`: Simpler definition and loading of colors.
    * `Controller`: Query the state of the virtual controller.
    * `Obj`: Simpler definition and manipulation of Objects and loading of Object graphics.
    * `RenderParams`: Functions used for manipulating the hardware registers that control rendering.
    * `Tile`: Simpler definition and loading of Tiles and Tile graphics.
* `.magic`: Contains the init (poweron), deinit (poweroff) and tick functions used to drive everything.