# mode8 Retro Fantasy Video Processing Unit

> mode8 is a graphics engine designed to feel like an old 16-bit console.
> it is loosely based on the snes rendering pipeline, but not compatible with it.

mode8 is currently in beta. The current master is based on Mach v0.4 and the respective nominated Zig version, which is working, but severely out of date at this point. The "update-mach" branch uses the Mach master and a current Zig version, but isn't useable, as a major rewrite is taking place at the moment. mode8's main logic is currently rewritten in Zig to run on the CPU instead.

See the roadmap below for more info.

### Goals
* Emulate the feel of poking hardware to configure a graphics pipeline.
* Impose constraints on the graphics, but don't make programming and asset creation overly complicated.

# Documentation
See the `docs` directory. UP to date with the current state of the rewrite.

`zig build run-debug` to build and run the feature debug program. Minor epilepsy warning!

# Roadmap
* Before the full release:
    * Finish the rewrite
    * Optimize heavily.
    * Integrate more nicely into the Mach object system.
* Near future:
    * Review the API:
        * Use enums from BSP `RenderParam` whereever it makes sense.
        * Make BSP structs (`Color`, `Obj`, `Tile`) more ergonomic to use.
    * Polish documentation. Add images.
    * Optimize some more.
    * Skip updating big buffers when nothing has changed.
* Eventually:
    * Actually write a game using mode8.
    * Move PPU code to the compute shader where feasible (only when Zig can be used as a shading lang).

mode8 is built on top of the [Mach game engine](https://machengine.org/).
Many thanks to the folks on the [Mach Discord server](https://discord.gg/XNG3NZgCqp)!