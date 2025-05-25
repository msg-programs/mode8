const mode8 = @import("../root.zig");
const std = @import("std");
const con = mode8.hardware.constants;
const reg = mode8.hardware.registers;
const bsp = mode8.bsp;
const bits = mode8.bsp.bits;
const Color = mode8.bsp.Color;

pub const RenderParams = struct {
    pub const Layer = enum(u3) {
        bg_0,
        bg_1,
        bg_2,
        bg_3,
        obj,
        color,
    };

    pub const DmaDir = enum(u1) {
        top_to_bottom,
        left_to_right,
    };

    pub const WinComposition = packed struct {
        neither: bool,
        win0: bool,
        win1: bool,
        both: bool,
    };

    pub const ColWinApplyAlgo = enum(u2) {
        always_on,
        direct,
        inverted,
        always_off,
    };

    pub const MathComposeAlgo = enum(u4) {
        /// highest priority color is used directly
        normal,

        /// add colors together component-wise
        add,

        /// subtract sub buffer color from main buffer color component-wise
        subtract,

        /// multiply colors together and then divides by maximum value component-wise
        multiply,

        /// divice main buffer color by sub-buffer color component-wise
        divide,

        /// subtract larger value from smaller value component-wise
        difference,

        /// if sub buffer is light/dark, replace darker/lighter colors in the main buffer with sub buffer color
        pinlight,

        /// multiply compliments and take compliment of result component-wise
        screen,

        /// use darker color component-wise
        darken,

        /// use lighter color component-wise
        lighten,

        /// MULTIPLY if sub buffer is light, else SCREEN
        overlay,

        /// LIGHTEN if sub buffer is light, else DARKEN
        softlight,

        /// reserved
        _,
    };

    pub const MathNormalizeFunc = enum(u2) {
        /// clamp result to 0..31 component-wise
        clamp,

        /// half result and clamp to 0..31 component-wise
        half,

        /// double result and clamp to 0..31 component-wise
        double,

        /// bleed excess to other color channels
        bleed,
    };

    pub const OobSetting = enum(u2) {
        wrap,
        tile,
        color,
        mirror,
    };

    pub const DebugMode = enum(u4) {
        off,
        layer,
        windows_setup,
        windows_main,
        windows_sub,
        col_window,
        window_comp,
        fixcol_setup,
        buf_pre_win,
        buf_post_win,
        buf_colmath_in,
        _,
    };

    pub const DebugArg = enum(u4) {
        none,
        show_bg_0,
        show_bg_1,
        show_bg_2,
        show_bg_3,
        show_objs,
        show_col,
        show_main,
        show_sub,
    };

    pub fn setBgSize(bg: u2, size: u10) void {
        const sz: u10 = std.math.clamp(size, 2, 512);
        // note: int cast is safe, as 512/2 = 256 -> 256-1 = 255 = 0xFF
        // design decision: panic if the BG is set to a size that can't be divided by 2, as this isn't supported.
        std.debug.assert(sz % 2 == 0);
        reg.bgsz[bg] = @intCast(sz / 2 - 1);
    }
};
