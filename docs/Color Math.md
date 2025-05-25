# Color Math
If color math is enabled for a certain layer, the sub buffer will not be overridden by the main buffer but is instead composited into it. This is done by first combining the colors using a formula (referred to as "algorithm"). As this may cause values that can't be shown by the screen, a normalization function is then applied.

Please refer to the BSP defines below for details on the algorithms and normalization funcs.

**Relevant registers:**
`math_enable`: Should color math be enabled for this layer?
`math_algo`: The compositing algorithm to use
`math_normalize`: The normalization to use

**Relevant BSP definitions**:
- Enums:
    - `bsp.RenderParams.MathNormalizeFunc`
    - `bsp.RenderParams.MathComposeAlgo`