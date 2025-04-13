# Debug
mode8's builtin debug modes are used to display various intermediate stages of the render pipeline.

**Relevant registers**:
`debug_mode`: Selects what stage of the render pipeline should be displayed.
`debug_arg`: Fine selection for stages that produce multiple outputs.

**Relevant BSP definitions**:
- Enums:
    - `bsp.RenderParams.DebugMode`
    - `bsp.RenderParams.DebugArg`

## All Debug Modes
- `.windows_setup`
    - Requires args: None
    - Shows the configuration of the windows before any merging or manipulation.
    - Displays the inside of window 0 in red, the inside of window 1 in green, overlapping areas in yellow and everything else in dark blue.
- `.window_comp`
    - Requires args: One of `.show_bg_0, .show_bg_1, .show_bg_2, .show_bg_3, .show_objs, .show_col`
    - Shows how windows are merged for the specified layer
    - Displays the result's inside in white and the outside in black.