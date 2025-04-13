# Debug
mode8's builtin debug modes are used to display various intermediate stages of the render pipeline.

## Relevant registers
`debug_mode`: Selects what stage of the render pipeline should be displayed.
`debug_arg`: Fine selection for stages that produce multiple outputs.

## Relevant BSP definitions
* Enums:
    * `bsp.RenderParams.DebugMode`
    * `bsp.RenderParams.DebugArg`

## All Debug Modes
* `.windows_setup`
    * Requires args: None
    * Shows the configuration of the windows before any merging or manipulation.
    * Displays window 0 in red, window 1 in green, an overlap in yellow and everything else in dark blue.
