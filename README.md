**NOTE: MASTER IS NOT UP-TO-DATE WITH CURRENT PROGRESS. SEE update-mach BRANCH FOR CURRENT STATUS**

# mode8 Retro Fantasy Video Processing Unit

> mode8 is a graphics engine designed to feel like an old 16-bit console.
> it is loosely based on the snes rendering pipeline, but not compatible with it.

mode8 is currently in beta. It's working, but some more polishing is needed before it could be considered fit for use. See below for a roadmap.

### Goals
* Emulate the feel of poking hardware to configure a graphics pipeline.
* Impose constraints on the graphics, but don't make programming and asset creation overly complicated.

# Documentation
See the `docs` directory. Currently WIP.

`zig build run-debug` to build and run the feature debug program. Minor epilepsy warning!

# Roadmap
* Before the full release:
    * Update to the current mach/zig version.
    * Review everything (except the examples).
    * Make BSP `RenderParam` functions more ergonomic to use.
    * Make BSP structs (`Color`, `Obj`, `Tile`) more ergonomic to use.
* Near future:
    * Finish/polish documentation. Add images.
    * Clean up compute shader buffers, use uniforms where feasible.
    * Integrate more nicely into the Mach object system.
    * Skip updating big buffers when nothing has changed.
    * Remove `std.mem.copyForwards` from BSP functions if possible.
* Eventually:
    * Actually write a game using mode8.

mode8 is built on top of the [Mach game engine](https://machengine.org/).
Many thanks to the folks on the [Mach Discord server](https://discord.gg/XNG3NZgCqp)!