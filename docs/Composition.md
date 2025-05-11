# Composition
BGs and Objs aren't rendered to the screen directly. Instead, the layers' color (and priority) data is sent through the composition pipeline first.

**Further reading:**
- Tile.md (for general info on Tiles)
- Obj.md (for general info on Objs)
- Fixcol.md (for general info on the Fixcols)
- Windows.md (for details on how the window data is constructed and applied)
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

## 4. TODO

## 5. TODO

## 6. Color math
Finally, the two buffers are merged using color math. See the 