# BG
mode8 renders four independent tilemap layers, referred to as BGs 0-3 (BackGround). Each BG consists of up to 512 by 512 Tiles. BGs may be transformed, ...

**Further Reading:**
- Tile.md (for general info on tiles)

**Relevant Registers:**
Note that all register values are per-BG.
- `xscroll, yscroll`: Move the BG in the x/y direction
- `xscroll_do_dma, yscroll_do_dma`: Should the `xscroll/yscroll` registers use DMA?
- `dma_dir_bg`: DMA direction for all DMA-able BG registers

