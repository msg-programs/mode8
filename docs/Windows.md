# Windows
Windows are masks that are applied to layers at various points.
All pixels inside a window are treated as transparent.

## Using windows
Windows are defined by a start value and an end value. If a pixel's coordinate is between the start and the end (both inclusive), it's inside the window, else it's not.

When the `dma_dir_win` register is set to `.top_to_bottom`, the start and end values refer to columns and the pixel's X coord is used; if it's set to `.left_to_right`, the values refer to rows and the Y coord is used.

## Relevant Registers
`win_start`: Window 0/1 start value(s). DMA-able
`win_end`: Window 0/1 end value(s). DMA-able
`win_start_do_dma`: Should window 0/1's start value use DMA?.
`win_end_do_dma`: Should window 0/1's end value use DMA?.
`dma_dir_win`: Change the DMA direction for the windows.