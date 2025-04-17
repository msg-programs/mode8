# Windows
Windows are masks that are applied to layers at various points. All pixels inside a window are treated as transparent.

## The Window Pipeline

### 1. Definition
Windows are defined by a start value and an end value. If a pixel's coordinate is between the start and the end (both inclusive), it's inside the window, else it's not.

When the `dma_dir_win` register is set to `.top_to_bottom`, the start and end values refer to columns and the pixel's X coord is used; if it's set to `.left_to_right`, the values refer to rows and the Y coord is used.

**Relevant Registers:**
- `win_start`: Window 0/1 start value(s). DMA-able
- `win_end`: Window 0/1 end value(s). DMA-able
- `win_start_do_dma`: Should window 0/1's start value use DMA?.
- `win_end_do_dma`: Should window 0/1's end value use DMA?.
- `dma_dir_win`: Change the DMA direction for the windows.

### 2. Composition
The two windows are then merged into a single, more complex window. The register that defines how this should happen supplies a value for every layer. The result is therefore six seperate windows, one for each BG, for the Objs and for the Fixcol.

**Relevant Registers:**
`win_compose`: Controls how the windows should be merged for a specific layer.

**Relevant BSP definitions:**
- `bsp.RenderParams.Layer`: Can be `@intFromEnum`ed to an index for the `win_compose` register.
- `bsp.RenderParams.WinComposition`: Can be `@bitCast`ed to a value for the `win_compose` register.

### 3. Buffer application
The composite windows are applied to the respective layer. As the layers are cloned to the main and sub buffer, the windows are also cloned any applied to the main/sub buffer seperately.

**Relevant Registers:**
- `win_to_main`: Should the window be applied to the layer's clone in the main buffer?
- `win_to_sub`: Should the window be applied to the layer's clone in the sub buffer?
