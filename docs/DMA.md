# DMA
mode8 is heavily inspired by the SNES console, which had a feature called "H-Blank/Horizontal Direct Memory Access". Effectively, it allowed programmers to change some memory (usually graphics registers) while the CRT screen prepared to draw the next row of the screen.

## DMA-able Registers
In order to simulate this feature, some registers are defined like this:
`foo_register: [con.DMA_NUM]u8`
`bar_register: [con.NUM_BAR][con.DMA_NUM]u8`

Instead of a constant value for the entire image, there is an array of size `con.DMA_NUM` that holds the values for each row. Row 0 is at the top of the screen.
Such registers are referred to as "DMA-able".

## DMA Flags
DMA needs to be turned on using a seperate flag that looks like this:
`foo_register_do_dma: bool`
`bar_register_do_dma: [con.NUM_BAR]bool`

If DMA is turned off, the first value in the DMA array is used for the entire screen (`foo_register[0]`, `bar_register[...][0]`);

## DMA Direction
mode8 allows for both horizontal DMA like the SNES and vertical DMA.
To switch between the two settings, a seperate flag needs to be set:
`dma_dir_foo: u1`
`dma_dir_bar: [con.NUM_BAR]u1`

The BSP defines an enum that can be used to set such variables:
`bsp.RenderParams.DMADir`

The document assumed the flag to be set to `.top_to_bottom` up to this point.
When the flag is set to `.left_to_right`, the following changes:
* The values in the DMA array are applied per-column instead of per-row
* Column 0 is the leftmost column

