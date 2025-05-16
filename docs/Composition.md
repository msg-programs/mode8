# Composition
BGs and Objs aren't rendered to the screen directly. Instead, the layers' color (and priority) data is sent through the composition pipeline first.

**Further reading:**
- Tile.md (for general info on Tiles)
- Obj.md (for general info on Objs)
- Color.md (for general info on Colors)
- Windows.md (for details on windows, especially the color window)
- Color Math.md (for details on how color math works)

## 1. Main and sub buffer
The composition pipeline provides two frame buffers: main and sub. The layer data may be sent to both, neither or one of them for further processing.

**Relevant registers:**
- `to_main, to_sub`: Should this layer be sent to the main/sub buffer?

## 2. Window application
The BG and Obj layers are masked using the window data for the respective layer and main/sub buffer as detailed in the window docs.

## 3. Priority resolver
If many layers overlap, the following logic is applied to determine the final color. This logic takes the BGs and the priority flag of the Tiles, as well as the Objs priority setting into account. Additionally, a register may be used to increase the priority of some tiles; this is useful for e.g. GUI elements.

The layer's priorities are as such (top is highest):
- BG 3 prio tiles if remap register flag is set
- BG 2 prio tiles if remap register flag is set
- BG 1 prio tiles if remap register flag is set
- BG 0 prio tiles if remap register flag is set
- Objs with prio = 3
- BG 3 prio tiles
- BG 2 prio tiles
- Objs with prio = 2
- BG 3 normal tiles
- BG 2 normal tiles
- Objs with prio = 1
- BG 1 prio tiles
- BG 0 prio tiles
- Objs with prio = 0
- BG 1 normal tiles
- BG 0 normal tiles
- Main/Sub buffer fixcol

**Relevant registers:**
- `prio_remap`: Should this BG's prio tiles have higher prio?

## 4. Fixcol application
After all layers in the main/sub are merged together, there might be transparent pixels. These are replaced with a fixed color for the respective buffer. This color is referred to as "Fixcol".
The sub buffer may also be replaced by the Fixcol entirely by enabling a the Fix/Sub flag.

**Relevant registers:**
`fixcol_main`/`fixcol_sub`: Fixcol for the main/sub buffer. DMA-able.
`fixcol_main_do_dma`/`fixcol_sub_do_dma`: Should the Fixcol for the main/sub buffer use DMA?
`dma_dir_fixcol`: Change the DMA direction for the fixcols.
`fix_sub`: Should the subscreen be filled with the sub fixcol?

## 5. Color window application
Here, the color window is applied. Refer to Window.md for further details.

This step may re-introduce transparent pixels. They are treated as opaque black from here on.

## 6. Color math
Finally, the two buffers are merged using color math to get the final image. See Color Math.md for further details.