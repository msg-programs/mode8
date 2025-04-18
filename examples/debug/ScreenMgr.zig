const WST = @import("./screens/WinSetupTest.zig");
const FCT = @import("./screens/FixcolTest.zig");
// const BGT = @import("./screens/BgTest.zig");
// const OBT = @import("./screens/ObjTest.zig");
// const COM = @import("./screens/ComposeTest.zig");

pub const ManagedScreen = union(enum) {
    test_win_nodma: *WST.TestWinNoDMA,
    test_win_dma: *WST.TestWinDMA,
    win_tests_data_setup: *WST.WinTestsDataSetup,
    test_win_compose: *WST.TestWinCompose,
    test_win_send: *WST.TestWinSend,
    test_win_col: *WST.TestColWin,
    test_fixcol: *FCT.TestFixcol,
    test_fixcol_dma: *FCT.TestFixcolDMA,
    // bg_tests_data_setup: *BGT.BgTestsDataSetup,
    // test_bg_size: *BGT.TestBgSize,
    // test_bg_oob: *BGT.TestBgOOB,
    // test_bg_scroll_dma: *BGT.TestBgScrollDMA,
    // bg_pos_fixup: *BGT.BgPosFixup,
    // test_bg_mosiac: *BGT.TestBgMosiac,
    // test_bg_affine: *BGT.TestBgAffine,
    // test_bg_affine_dma: *BGT.TestBgAffineDMA,
    // test_bg_prio_feat: *BGT.TestBgPrioFeat,
    // test_obj_attrs: *OBT.TestObjAttrs,
    // test_obj_wrap: *OBT.TestObjWrap,
    // compose_tests_data_setup: *COM.ComposeTestsDataSetup,
    // test_buffer: *COM.TestBuffer,
    // test_colwin: *COM.TestColwin,
    // test_cmath_enable: *COM.TestColorMathEnable,
    // test_cmath_sett: *COM.TestColorMathSettings,

    pub fn init(self: ManagedScreen) void {
        switch (self) {
            inline else => |s| s.init(),
        }
    }

    pub fn tick(self: ManagedScreen) bool {
        switch (self) {
            inline else => |s| {
                const res = s.tick();
                s.frame +%= 1;
                return res;
            },
        }
    }
};
