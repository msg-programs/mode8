# Fixcol
After all layers in the main/sub are merged together, there might be transparent pixels. These are replaced with a fixed color for the respective buffer. This color is referred to as "Fixcol".
The sub buffer may also be replaced by the Fixcol entirely by enabling a switch.

**Relevant Registers:**
`fixcol_main`/`fixcol_sub`: Fixcol for the main/sub buffer. DMA-able.
`fixcol_main_do_dma`/`fixcol_sub_do_dma`: Should the Fixcol for the main/sub buffer use DMA?
`dma_dir_fixcol`: Change the DMA direction for the fixcols.