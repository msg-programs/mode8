// apparently, WGSL doesn't have include functionality...
// WGSL also lacks some kind of typedef. terrific, can't wait to rewrite in zig.

///////////////////////////////////////////////////////////////////////////////////////////////////
/// CONSTANTS
///////////////////////////////////////////////////////////////////////////////////////////////////

const SCREEN_DIM_PIX: u32 = 256;
const OBJ_POS_DIM_PIX: u32 = 360;
const MAX_OBJS_NUM: u32 = 256;
const OBJ_ATT_SZE_BIT: u32 = 36;
const OAM_SZE_BIT: u32 = (OBJ_ATT_SZE_BIT * MAX_OBJS_NUM);
const OAM_SZE_BYT: u32 = OAM_SZE_BIT / 8;
const OAM_SZE_U32: u32 = OAM_SZE_BYT / 4;
const OBJ_ATL_DIM_TIL: u32 = 16;
const OBJ_GFX_SZE_BIT: u32 = 8 * 8 * 8;
const OBJ_ATL_NUM: u32 = 4;
const OBJ_GFX_UNIT_DIM_PIX: u32 = 8;
const OBJ_GFX_UNIT_PIX_NUM: u32 = OBJ_GFX_UNIT_DIM_PIX * OBJ_GFX_UNIT_DIM_PIX;
const OGM_SZE_BIT: u32 = OBJ_ATL_NUM * OBJ_ATL_DIM_TIL * OBJ_ATL_DIM_TIL * OBJ_GFX_SZE_BIT;
const OGM_SZE_BYT: u32 = OGM_SZE_BIT / 8;
const OGM_SZE_U32: u32 = OGM_SZE_BYT / 4;
const COLOR_SZE_BIT: u32 = 16;
const MAX_COLORS_NUM: u32 = 256;
const GCM_SZE_BIT: u32 = (COLOR_SZE_BIT * MAX_COLORS_NUM);
const GCM_SZE_BYT: u32 = GCM_SZE_BIT / 8;
const GCM_SZE_U32: u32 = GCM_SZE_BYT / 4;
const TILE_ATT_SZE_BIT: u32 = 16;
const BG_DIM_TIL: u32 = 512;
const BG_NUM: u32 = 4;
const TAM_SZE_BIT: u32 = TILE_ATT_SZE_BIT * BG_DIM_TIL * BG_DIM_TIL * BG_NUM;
const TAM_SZE_BYT: u32 = TAM_SZE_BIT / 8;
const TAM_SZE_U32: u32 = TAM_SZE_BYT / 4;
const TILE_ATL_DIM_TIL: u32 = 32;
const TILE_ATL_NUM: u32 = 4;
const TILE_GFX_DIM_PIX: u32 = 8;
const TILE_GFX_PIX_NUM: u32 = TILE_GFX_DIM_PIX * TILE_GFX_DIM_PIX;
const TILE_GFX_SZE_BIT: u32 = TILE_GFX_PIX_NUM * 8;
const TGM_SZE_BIT: u32 = TILE_ATL_DIM_TIL * TILE_ATL_DIM_TIL * TILE_ATL_NUM * TILE_GFX_SZE_BIT;
const TGM_SZE_BYT: u32 = TGM_SZE_BIT / 8;
const TGM_SZE_U32: u32 = TGM_SZE_BYT / 4;
const DMA_NUM: u32 = SCREEN_DIM_PIX;
const WINDOW_NUM: u32 = 2;

// const OOB_SETTING_WRAP  = 0; --> default case
const OOB_SETTING_TILE  = 1;
const OOB_SETTING_COLOR = 2;
const OOB_SETTING_CLAMP = 3;

const DEBUG_MODE_NONE                = 0;
const DEBUG_MODE_LAYER               = 1;
const DEBUG_MODE_WINDOWS_SETUP       = 2;
const DEBUG_MODE_WINDOWS_MAIN        = 3;
const DEBUG_MODE_WINDOWS_SUB         = 4;
const DEBUG_MODE_COL_WINDOW          = 5;
const DEBUG_MODE_WINDOW_COMP         = 7;
const DEBUG_MODE_FIXCOL_SETUP        = 8;
const DEBUG_MODE_BUF_PRE_WIN         = 9;
const DEBUG_MODE_BUF_POST_WIN        = 11;
const DEBUG_MODE_BUF_COLMATH_IN      = 13;

const DEBUG_ARG_SHOW_BG_0 = 0;
const DEBUG_ARG_SHOW_BG_1 = 1;
const DEBUG_ARG_SHOW_BG_2 = 2;
const DEBUG_ARG_SHOW_BG_3 = 3;
const DEBUG_ARG_SHOW_OBJS = 4;
const DEBUG_ARG_SHOW_COL = 5;
const DEBUG_ARG_SHOW_MAIN = 6;
const DEBUG_ARG_SHOW_SUB = 7;
const DEBUG_ARG_NONE = 15;

// temp fix for sysgpu bug
const OxFFFF: u32 = 65535;
const OxFF: u32 = 255;
const OxF: u32 = 15;
const Ox0FFF: u32 = 4095;
const OxFF0000: u32 = 16711680;
const Ox0000000F: u32 = 15;
const Ox000000F0: u32 = 240;
const Ox00000F00: u32 = 3840;
const Ox0000F000: u32 = 61440;
const Ox000F0000: u32 = 938040;
const Ox00F00000: u32 = 15728640;
const Ox0F000000: u32 = 251658240;
const OxF0000000: u32 = 4026531840;
const Ox01FFFF: u32 = 131071;
const Ox0FFE0000: u32 = 268304384;
const Ox001F: u32 = 31;
const Ox000000FF: u32 = 255;
const Ox0000FF00: u32 = 65280;
const Ox00FF0000: u32 = 16711680;
const OxFF000000: u32 = 4278190080;

const OBJ_DIMS_PIX: array<vec2<u32>, 8> = array(
        vec2(8, 8),
        vec2(16, 16),
        vec2(32, 32),
        vec2(64, 64),
        vec2(8, 16),
        vec2(16, 8),
        vec2(16, 32),
        vec2(32, 16),
);

///////////////////////////////////////////////////////////////////////////////////////////////////
/// STRUCT TYPES
///////////////////////////////////////////////////////////////////////////////////////////////////

struct Tile {
    gfxid: u32,
    prio: bool,
    vflip: bool,
    hflip: bool,
    rot: bool,
};

struct Obj {
    pos: vec2u,
    gfxid: u32,
    vflip: bool,
    hflip: bool,
    prio: u32,
    size: u32,
    rot: bool,
};

struct BGPixel {
    p_col: u32,
    isprio: bool,
};

// struct ObjPixel {
//     p_col: u32, --> x
//     prio: u32, --> y
// };

// struct vec2u {
//     p_col: u32, --> x
//     origin: u32, --> y
// };

struct BGTransform {
    xscroll: array<array<i32, DMA_NUM>, BG_NUM>,
    yscroll: array<array<i32, DMA_NUM>, BG_NUM>,
    affine_x0: array<array<i32, DMA_NUM>, BG_NUM>,
    affine_y0: array<array<i32, DMA_NUM>, BG_NUM>,
    affine_a: array<array<f32, DMA_NUM>, BG_NUM>,
    affine_b: array<array<f32, DMA_NUM>, BG_NUM>,
    affine_c: array<array<f32, DMA_NUM>, BG_NUM>,
    affine_d: array<array<f32, DMA_NUM>, BG_NUM>,
    cmsr: ColorMathSettingsRaw
};


struct WinSettingsRaw {
    win_start: array<array<u32, DMA_NUM / 4>, WINDOW_NUM>,
    win_end: array<array<u32, DMA_NUM / 4>, WINDOW_NUM>,
    win_compose: u32,
    win_to_scrns: u32
};

struct ColorMathSettingsRaw {
    fixcol_main: array<u32, DMA_NUM/2>,
    fixcol_sub: array<u32, DMA_NUM/2>,
    math_debug_settings: u32
};

///////////////////////////////////////////////////////////////////////////////////////////////////
/// BINDINGS
///////////////////////////////////////////////////////////////////////////////////////////////////

// output
@group(0) @binding(0) var SCREEN_BUFFER: texture_storage_2d<rgba8unorm, write>;

// memory buffers.
@group(1) @binding(0) var<storage, read> GCM: array<u32, GCM_SZE_U32>;
@group(1) @binding(1) var<storage, read> TGM: array<u32, TGM_SZE_U32>;
@group(1) @binding(2) var<storage, read> TAM: array<u32, TAM_SZE_U32>;
@group(1) @binding(3) var<storage, read> OGM: array<u32, OGM_SZE_U32>;
@group(1) @binding(4) var<storage, read> OAM: array<u32, OAM_SZE_U32>;

// composition settings
// other bg settings
// DMA switches
@group(2) @binding(0) var<storage, read> settings_raw: array<u32, 8>;

// affine transform and scrolling settings + color math and fixcol settings (not enough bindings...)
@group(2) @binding(1) var<storage, read> bg_transform: BGTransform;

// window settings
@group(2) @binding(2) var<storage, read> win_settings_raw: WinSettingsRaw;

///////////////////////////////////////////////////////////////////////////////////////////////////
/// VARIABLES
///////////////////////////////////////////////////////////////////////////////////////////////////

var<private> g_bg_mosiac: array<u32, BG_NUM>;
var<private> g_bg_sz: array<u32, BG_NUM>;
var<private> g_bg_offs: array<vec2u, BG_NUM>;
var<private> g_bg_oob_setting: array<u32, BG_NUM>;
var<private> g_bg_oob_data: array<u32, BG_NUM>;

var<private> g_comp_prio_remap_bg0: bool;
var<private> g_comp_prio_remap_bg1: bool;
var<private> g_comp_prio_remap_bg2: bool;
var<private> g_comp_prio_remap_bg3: bool;
var<private> g_comp_fix_sub: bool;
var<private> g_comp_to_main: array<bool, 5>;
var<private> g_comp_to_sub: array<bool, 5>;

var<private> g_dma_xscroll_do_dma: array<bool, 4>;
var<private> g_dma_yscroll_do_dma: array<bool, 4>;
var<private> g_dma_affine_x0_do_dma: array<bool, 4>;
var<private> g_dma_affine_y0_do_dma: array<bool, 4>;
var<private> g_dma_affine_a_do_dma: array<bool, 4>;
var<private> g_dma_affine_b_do_dma: array<bool, 4>;
var<private> g_dma_affine_c_do_dma: array<bool, 4>;
var<private> g_dma_affine_d_do_dma: array<bool, 4>;
var<private> g_dma_dir: array<bool, 4>;
var<private> g_dma_dir_ex: array<bool, 4>;
var<private> g_dma_win_start_do_dma: array<bool, 2>;
var<private> g_dma_win_end_do_dma: array<bool, 2>;
var<private> g_dma_fixcol_main_do_dma: bool;
var<private> g_dma_fixcol_sub_do_dma: bool;

var<private> g_win_start: array<array<u32, DMA_NUM / 4>, WINDOW_NUM>;
var<private> g_win_end: array<array<u32, DMA_NUM / 4>, WINDOW_NUM>;
var<private> g_win_compose: array<u32, 6>;
var<private> g_win_to_main: array<bool, 5>;
var<private> g_win_to_sub: array<bool, 5>;
var<private> g_win_apply_main: u32;
var<private> g_win_apply_sub: u32;

var<private> g_fixcol_main: array<u32, DMA_NUM/2>;
var<private> g_fixcol_sub: array<u32, DMA_NUM/2>;
var<private> g_math_enable: array<bool, 6>;
var<private> g_math_algo: u32;
var<private> g_math_normalize: u3;

var<private> g_debug_mode: u32;
var<private> g_debug_arg: u32;

///////////////////////////////////////////////////////////////////////////////////////////////////
/// SETTINGS UNPACKING FUNCTIONS
///////////////////////////////////////////////////////////////////////////////////////////////////

// apparently not a builtin...
fn unpack4xU8(in: u32) -> vec4<u32> {
    return vec4(
        (in & Ox000000FF) >> 0,
        (in & Ox0000FF00) >> 8,
        (in & Ox00FF0000) >> 16,
        (in & OxFF000000) >> 24,
    );
}

fn readCompSettings() {

    let comp_settings_raw: vec4<u32> = unpack4xU8(settings_raw[0]);

    let prio_remap: u32 = comp_settings_raw.x;
    let fix_sub: u32 =    comp_settings_raw.y;
    let to_main: u32 =    comp_settings_raw.z;
    let to_sub: u32 =     comp_settings_raw.w;

    g_comp_prio_remap_bg0 = (prio_remap & (1 << 0)) != 0;
    g_comp_prio_remap_bg1 = (prio_remap & (1 << 1)) != 0;
    g_comp_prio_remap_bg2 = (prio_remap & (1 << 2)) != 0;
    g_comp_prio_remap_bg3 = (prio_remap & (1 << 3)) != 0;
    g_comp_fix_sub = fix_sub != 0;
    g_comp_to_main = array(
        (to_main & (1 << 0)) != 0,
        (to_main & (1 << 1)) != 0,
        (to_main & (1 << 2)) != 0,
        (to_main & (1 << 3)) != 0,
        (to_main & (1 << 4)) != 0,
    );
    g_comp_to_sub = array(
        (to_sub & (1 << 0)) != 0,
        (to_sub & (1 << 1)) != 0,
        (to_sub & (1 << 2)) != 0,
        (to_sub & (1 << 3)) != 0,
        (to_sub & (1 << 4)) != 0,
    );
}

fn readBGSettings() {

    let bg_settings_raw = array(settings_raw[3], settings_raw[4], settings_raw[5], settings_raw[6], settings_raw[7]);

    let mosiac = (bg_settings_raw[0]) & OxFFFF;
    let oob_setting = (bg_settings_raw[0] & OxFF0000) >> 16;
    let bgsize = unpack4xU8(bg_settings_raw[1]);
    let bgoffs = bg_settings_raw[2];
    let oobdat_lo = unpack4xU8(bg_settings_raw[3]);
    let oobdat_hi = unpack4xU8(bg_settings_raw[4]);

    g_bg_mosiac = array(
        ((mosiac & Ox0000000F) >> 0) + 1,
        ((mosiac & Ox000000F0) >> 4) + 1,
        ((mosiac & Ox00000F00) >> 8) + 1,
        ((mosiac & Ox0000F000) >> 12) + 1,
    );
    g_bg_sz = array(
        (bgsize.x + 1) * 2,
        (bgsize.y + 1) * 2,
        (bgsize.z + 1) * 2,
        (bgsize.w + 1) * 2,
    );
    g_bg_offs = array(
        vec2u(((bgoffs & Ox0000000F) >> 0) * 32, ((bgoffs & Ox000000F0) >> 4) * 32),
        vec2u(((bgoffs & Ox00000F00) >> 8) * 32, ((bgoffs & Ox0000F000) >> 12) * 32),
        vec2u(((bgoffs & Ox000F0000) >> 16) * 32, ((bgoffs & Ox00F00000) >> 20) * 32),
        vec2u(((bgoffs & Ox0F000000) >> 24) * 32, ((bgoffs & OxF0000000) >> 28) * 32),
    );
    g_bg_oob_setting = array(
        ((oob_setting & 0x03) >> 0),
        ((oob_setting & 0x0C) >> 2),
        ((oob_setting & 0x30) >> 4),
        ((oob_setting & 0xC0) >> 6),
    );
    g_bg_oob_data = array(
        oobdat_lo.x | (oobdat_hi.x << 8),
        oobdat_lo.y | (oobdat_hi.y << 8),
        oobdat_lo.z | (oobdat_hi.z << 8),
        oobdat_lo.w | (oobdat_hi.w << 8),
    );
}

fn readDMASwitches() {
    let dma_switches_raw = array(settings_raw[1], settings_raw[2]);
    g_dma_xscroll_do_dma = array( // xscroll
        (dma_switches_raw[0] & 0x00000001) != 0,
        (dma_switches_raw[0] & 0x00000002) != 0,
        (dma_switches_raw[0] & 0x00000004) != 0,
        (dma_switches_raw[0] & 0x00000008) != 0
    );
    g_dma_yscroll_do_dma = array( // yscroll
        (dma_switches_raw[0] & 0x00000010) != 0,
        (dma_switches_raw[0] & 0x00000020) != 0,
        (dma_switches_raw[0] & 0x00000040) != 0,
        (dma_switches_raw[0] & 0x00000080) != 0
    );
    g_dma_affine_x0_do_dma = array( // x0
        (dma_switches_raw[0] & 0x00000100) != 0,
        (dma_switches_raw[0] & 0x00000200) != 0,
        (dma_switches_raw[0] & 0x00000400) != 0,
        (dma_switches_raw[0] & 0x00000800) != 0
    );
    g_dma_affine_y0_do_dma = array( // y0
        (dma_switches_raw[0] & 0x00001000) != 0,
        (dma_switches_raw[0] & 0x00002000) != 0,
        (dma_switches_raw[0] & 0x00004000) != 0,
        (dma_switches_raw[0] & 0x00008000) != 0
    );
    g_dma_affine_a_do_dma = array( // d
        (dma_switches_raw[0] & 0x00010000) != 0,
        (dma_switches_raw[0] & 0x00020000) != 0,
        (dma_switches_raw[0] & 0x00040000) != 0,
        (dma_switches_raw[0] & 0x00080000) != 0
    );
    g_dma_affine_b_do_dma = array( // c
        (dma_switches_raw[0] & 0x000100000) != 0,
        (dma_switches_raw[0] & 0x000200000) != 0,
        (dma_switches_raw[0] & 0x000400000) != 0,
        (dma_switches_raw[0] & 0x000800000) != 0
    );
    g_dma_affine_c_do_dma = array( // b
        (dma_switches_raw[0] & 0x001000000) != 0,
        (dma_switches_raw[0] & 0x002000000) != 0,
        (dma_switches_raw[0] & 0x004000000) != 0,
        (dma_switches_raw[0] & 0x008000000) != 0
    );
    g_dma_affine_d_do_dma = array( // a
        (dma_switches_raw[0] & 0x010000000) != 0,
        (dma_switches_raw[0] & 0x020000000) != 0,
        (dma_switches_raw[0] & 0x040000000) != 0,
        (dma_switches_raw[0] & 0x080000000) != 0
    );
    g_dma_dir = array( // dir
        (dma_switches_raw[1] & 0x000000001) != 0,
        (dma_switches_raw[1] & 0x000000002) != 0,
        (dma_switches_raw[1] & 0x000000004) != 0,
        (dma_switches_raw[1] & 0x000000008) != 0
    );
    g_dma_dir_ex = array( // dir
        (dma_switches_raw[1] & 0x000000010) != 0,
        (dma_switches_raw[1] & 0x000000020) != 0,
        (dma_switches_raw[1] & 0x000000040) != 0,
        (dma_switches_raw[1] & 0x000000080) != 0
    );
    g_dma_win_start_do_dma = array( // win start
        (dma_switches_raw[1] & 0x000000100) != 0,
        (dma_switches_raw[1] & 0x000000200) != 0
    );
    g_dma_win_end_do_dma = array( // win end
        (dma_switches_raw[1] & 0x000000400) != 0,
        (dma_switches_raw[1] & 0x000000800) != 0
    );
    g_dma_fixcol_main_do_dma = (dma_switches_raw[1] & OxFF0000) != 0; // fixcol main
    g_dma_fixcol_sub_do_dma = (dma_switches_raw[1] & OxFF000000) != 0; // fixcol sub
}

fn readWinSettings() {

    g_win_start = win_settings_raw.win_start;
    g_win_end = win_settings_raw.win_end;
    g_win_compose = array(
        (win_settings_raw.win_compose & Ox0000000F) >> 0,
        (win_settings_raw.win_compose & Ox000000F0) >> 4,
        (win_settings_raw.win_compose & Ox00000F00) >> 8,
        (win_settings_raw.win_compose & Ox0000F000) >> 12,
        (win_settings_raw.win_compose & Ox000F0000) >> 16,
        (win_settings_raw.win_compose & Ox00F00000) >> 20
    );
    g_win_to_main = array(
        (win_settings_raw.win_to_scrns & 0x00000001) != 0,
        (win_settings_raw.win_to_scrns & 0x00000002) != 0,
        (win_settings_raw.win_to_scrns & 0x00000004) != 0,
        (win_settings_raw.win_to_scrns & 0x00000008) != 0,
        (win_settings_raw.win_to_scrns & 0x00000010) != 0,
    );
    g_win_to_sub = array(
        (win_settings_raw.win_to_scrns & 0x00000100) != 0,
        (win_settings_raw.win_to_scrns & 0x00000200) != 0,
        (win_settings_raw.win_to_scrns & 0x00000400) != 0,
        (win_settings_raw.win_to_scrns & 0x00000800) != 0,
        (win_settings_raw.win_to_scrns & 0x00001000) != 0,
    );
    g_win_apply_main = (win_settings_raw.win_to_scrns & Ox000F0000) >> 16;
    g_win_apply_sub = (win_settings_raw.win_to_scrns & Ox00F00000) >> 20;
}

fn readCMathSettings() {
    g_fixcol_main = bg_transform.cmsr.fixcol_main;
    g_fixcol_sub = bg_transform.cmsr.fixcol_sub;
    g_math_enable = array(
        (bg_transform.cmsr.math_debug_settings & 0x00000001) != 0,
        (bg_transform.cmsr.math_debug_settings & 0x00000002) != 0,
        (bg_transform.cmsr.math_debug_settings & 0x00000004) != 0,
        (bg_transform.cmsr.math_debug_settings & 0x00000008) != 0,
        (bg_transform.cmsr.math_debug_settings & 0x00000010) != 0,
        (bg_transform.cmsr.math_debug_settings & 0x00000020) != 0,
    );
    g_math_algo = (bg_transform.cmsr.math_debug_settings & Ox0000FF00) >> 8;
    g_math_normalize = (bg_transform.cmsr.math_debug_settings & Ox00FF0000) >> 16;
    g_debug_mode = (bg_transform.cmsr.math_debug_settings & Ox0F000000) >> 24;
    g_debug_arg = (bg_transform.cmsr.math_debug_settings & OxF0000000) >> 28;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
/// COLOR FUNCTIONS
///////////////////////////////////////////////////////////////////////////////////////////////////

// given a packed color, unpack it into a vec4f
fn unpackColor(p_col: u32) -> vec4f {
    var res: vec4<f32>;
    res.r = f32((p_col & Ox001F) >> 0) / 31.0;
    res.g = f32((p_col & 0x03E0) >> 5) / 31.0;
    res.b = f32((p_col & 0x7C00) >> 10) / 31.0;
    res.a = f32((p_col & 0x8000) >> 15);
    return res;
}

// given a packed color, check if it's opaque
fn isPackedColorOpaque(p_col: u32) -> bool {
    return (p_col & 0x8000) != 0;
}

// given a palette index, return the packed color stored there
fn lookupPaletteColor(idx: u32) -> u32 {
    let idx_u32 = idx / 2;
    let shift = 16 * (idx % 2);
    let p_col = (GCM[idx_u32] >> shift) & OxFFFF;
    return p_col;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
/// BG TILE FUNCTIONS
///////////////////////////////////////////////////////////////////////////////////////////////////

// given a viewpos and a Tile struct, find the palette index of the pixel that is at that position.
// this implements flipping and rotation.
fn fetchTilePixel(viewpos: vec2<u32>, tile_attrs: Tile) -> u32 {
    // viewpos to pos inside tile
    var pixpos: vec2<u32> = viewpos % TILE_GFX_DIM_PIX;

    // do mirroring of tile
    if (tile_attrs.vflip) {
        pixpos.x = 7 - pixpos.x;
    }
    if (tile_attrs.hflip) {
        pixpos.y = 7 - pixpos.y;
    }
    if (tile_attrs.rot) {
        let tmp = pixpos.x;
        pixpos.x = pixpos.y;
        pixpos.y = tmp;
    }

    // 2D pixpos to 1D pix array index
    let pixidx = pixpos.y * TILE_GFX_DIM_PIX + pixpos.x + tile_attrs.gfxid * TILE_GFX_PIX_NUM;
    // 4 gfx data entries per u32 pix array entry
    let tgmoffs_u32 = pixidx / 4;
    // shift by 0, 8, 16 or 24 bits, same as above
    // pixidx % data entries per u32 array entry = index of entry in this u32
    // mult by "stride" = bit length of data entry
    let tgmshift = 8 * (pixidx % 4);
    // shift and mask for data
    return (TGM[tgmoffs_u32] >> tgmshift) & OxFF;
}

// given a viewpos and a BG, get the tile that is being viewed from the TAM
fn fetchTileAttrs(bg: u32, bgsz: u32, bgoffs: vec2<u32>, viewpos: vec2<u32>) -> Tile {
    // viewpos to tilepos
    let tilepos: vec2<u32> = (viewpos / TILE_GFX_DIM_PIX) + bgoffs;
    // 2D tilepos to 1D tile array index
    let tileidx = (tilepos.y * BG_DIM_TIL) + tilepos.x + (bg * BG_DIM_TIL * BG_DIM_TIL);
    // 2 tile data entries per u32 tile array entry
    let tamoffs_u32 = tileidx / 2;
    // on even index, data is in high 2 bytes of u32.
    // shift by either 0 or 16 bits
    let tamshift = 16 * (tileidx % 2);
    // shift and mask for data
    let tam_data = (TAM[tamoffs_u32] >> tamshift) & OxFFFF;
    return Tile(
        (tam_data & Ox0FFF) >> 0,
        (tam_data & 0x1000) != 0,
        (tam_data & 0x2000) != 0,
        (tam_data & 0x4000) != 0,
        (tam_data & 0x8000) != 0,
    );
}

// normally, the pos of a pixel on the screen is == the position to look up in the TAM.
// mosiac, affine xform and scrolling are implemented by remapping the screenpos into a viewpos
fn toTileAttrViewPos(bg: u32, screenpos: vec2u) -> vec2i {
    var viewpos = vec2i(screenpos);
    viewpos = (viewpos / i32(bg_settings.mosiac[bg])) * i32(bg_settings.mosiac[bg]);

    let index: u32 = select(screenpos.y, screenpos.x, dma_switches.dma_dir[bg]);

    let xscroll: i32 = select(bg_transform.xscroll[bg][0], bg_transform.xscroll[bg][index], dma_switches.xscroll_do_dma[bg]);
    let yscroll: i32 = select(bg_transform.yscroll[bg][0], bg_transform.yscroll[bg][index], dma_switches.yscroll_do_dma[bg]);

    let x0: i32 = select(bg_transform.affine_x0[bg][0], bg_transform.affine_x0[bg][index], dma_switches.affine_x0_do_dma[bg]);
    let y0: i32 = select(bg_transform.affine_y0[bg][0], bg_transform.affine_y0[bg][index], dma_switches.affine_y0_do_dma[bg]);
    let a: f32 = select(bg_transform.affine_a[bg][0], bg_transform.affine_a[bg][index], dma_switches.affine_a_do_dma[bg]);
    let b: f32 = select(bg_transform.affine_b[bg][0], bg_transform.affine_b[bg][index], dma_switches.affine_b_do_dma[bg]);
    let c: f32 = select(bg_transform.affine_c[bg][0], bg_transform.affine_c[bg][index], dma_switches.affine_c_do_dma[bg]);
    let d: f32 = select(bg_transform.affine_d[bg][0], bg_transform.affine_d[bg][index], dma_switches.affine_d_do_dma[bg]);

    let affine_mat: mat2x2<f32> = mat2x2<f32>(a,c,b,d);
    let affine_vec1: vec2<f32> = vec2f(viewpos) + vec2f(f32(xscroll), f32(yscroll)) - vec2f(f32(x0), f32(y0));
    let affine_vec2: vec2<f32> = vec2f(f32(x0), f32(y0));

    let viewpos_pre: vec2<f32> = affine_mat * affine_vec1 + affine_vec2;
    viewpos = vec2i(viewpos_pre);

    return viewpos;
}

// given the screenpos, calculate the packed color for that pixel based on the specified BG.
fn calcBGPixel(screenpos: vec2<u32>, bg: u32) -> BGPixel {
    var viewpos_pre = toTileAttrViewPos(bg, screenpos);
    let bgsz = bg_settings.bg_sz[bg] * 8;

    let viewpos_pre_in_bounds: bool = (viewpos_pre.x < 0 || viewpos_pre.y < 0 || viewpos_pre.x >= i32(bgsz) || viewpos_pre.y >= i32(bgsz));

    if (!viewpos_pre_in_bounds) {
        let viewpos = vec2u(viewpos_pre);
        let tile_attrs = fetchTileAttrs(bg, bg_settings.bg_sz[bg], bg_settings.bg_offs[bg], viewpos);
        let tilecol_idx = fetchTilePixel(viewpos, tile_attrs);
        return BGPixel(
            lookupPaletteColor(tilecol_idx),
            tile_attrs.prio
        );
    }
    switch (bg_settings.oob_setting[bg]) {
        case OOB_SETTING_CLAMP: {
            viewpos_pre = clamp(vec2(0,0), viewpos_pre, vec2(i32(bgsz), i32(bgsz)));
            var viewpos = vec2u(viewpos_pre);
            // else color is taken from "next" tile instead of the one on the border
            if (viewpos.x >= bgsz) {
                viewpos.x -= 1;
            }
            if (viewpos.y >= bgsz) {
                viewpos.y -= 1;
            }
            let tile_attrs = fetchTileAttrs(bg,bg_settings.bg_sz[bg], bg_settings.bg_offs[bg], viewpos);
            let tilecol_idx = fetchTilePixel(viewpos, tile_attrs);
            return BGPixel(
                lookupPaletteColor(tilecol_idx),
                tile_attrs.prio
            );
        }
        case OOB_SETTING_COLOR: {
            return BGPixel(
                bg_settings.oob_data[bg] & OxFFFF,
                false
            );
        }
        case OOB_SETTING_TILE: {
            let dummy = Tile(
                (bg_settings.oob_data[bg] & Ox0FFF) >> 0,
                (bg_settings.oob_data[bg] & 0x1000) != 0,
                (bg_settings.oob_data[bg] & 0x2000) != 0,
                (bg_settings.oob_data[bg] & 0x4000) != 0,
                (bg_settings.oob_data[bg] & 0x8000) != 0,
            );
            let viewpos = vec2u(viewpos_pre);
            let tilecol_idx = fetchTilePixel(vec2u(viewpos_pre), dummy);

            return BGPixel(
                lookupPaletteColor(tilecol_idx),
                dummy.prio
            );
        }
        default: { // OOB_SETTING_WRAP
            // manual modulo for negative values
            if (viewpos_pre.x < 0 || viewpos_pre.y < 0) {
                let diff = -viewpos_pre;
                let mult = (diff / i32(bgsz)) + 1;
                viewpos_pre += i32(bgsz) * mult;
            }
            let viewpos = vec2u(viewpos_pre % vec2(i32(bgsz)));
            let tile_attrs = fetchTileAttrs(bg, bg_settings.bg_sz[bg], bg_settings.bg_offs[bg], viewpos);
            let tilecol_idx = fetchTilePixel(viewpos, tile_attrs);
            return BGPixel(
                lookupPaletteColor(tilecol_idx),
                tile_attrs.prio
            );
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
/// OBJ FUNCTIONS
///////////////////////////////////////////////////////////////////////////////////////////////////

// given an object's index, get its attributes from the OAM
fn fetchObjAttrs(obj_idx: u32) -> Obj {
    let packed_1 = OAM[obj_idx]; // rejoice! no unpacking needed
    let oamoffs2_u32 = obj_idx / 8;
    let oam2shift = 4 * (obj_idx % 8);
    let packed_2 = (OAM[256 + oamoffs2_u32] >> oam2shift) & OxF; // argh

    let pos_raw: u32 = (packed_1 & Ox01FFFF);
    return Obj(
        // correct for obj playfield (360^2) vs screen dim (256^2)
        vec2((pos_raw % OBJ_POS_DIM_PIX), (pos_raw / OBJ_POS_DIM_PIX)),
        (packed_1 & Ox0FFE0000) >> 17,
        (packed_1 & 0x10000000) != 0,
        (packed_1 & 0x20000000) != 0,
        (packed_1 & 0xC0000000) >> 30,
        (packed_2 & 0x7),
        (packed_2 & 0x8) != 0
    );
}

// given the screenpos and an Obj struct, find the packed color of the pixel at that position.
// this implements flipping and rotation.
// note that this uses the screenpos as the obj playfield is independent of the BGs.
fn fetchObjPixel(screenpos: vec2<u32>, obj_attrs: Obj) -> u32 {
    // what a horrible day to be a GPU 2: electric boogaloo

    // shift obj to top right corner, move screenpos accordingly
    var relpos = screenpos - obj_attrs.pos;
    if (screenpos.x < obj_attrs.pos.x) {
        relpos.x = screenpos.x + OBJ_POS_DIM_PIX - obj_attrs.pos.x;
    }
    if (screenpos.y < obj_attrs.pos.y) {
        relpos.y = screenpos.y + OBJ_POS_DIM_PIX - obj_attrs.pos.y;
    }

    var objsize = OBJ_DIMS_PIX[obj_attrs.size];

    if (obj_attrs.rot) {
        var tmp = relpos.x;
        relpos.x = relpos.y;
        relpos.y = tmp;
    }
    if (obj_attrs.vflip) {
        relpos.x = objsize.x - 1 - relpos.x;
    }
    if (obj_attrs.hflip) {
        relpos.y = objsize.y - 1 - relpos.y;
    }

    if (relpos.x < 0 || relpos.y < 0) {
        return OxFFFFFFFF;
    }
    if (relpos.x >= objsize.x || relpos.y >= objsize.y) {
        return OxFFFFFFFF;
    }

    let tilepos: vec2<u32> = relpos / 8;
    let gfxid_offset = tilepos.x + tilepos.y * 16;

    var pixpos: vec2<u32> = relpos % 8;
    let pixidx = pixpos.y * OBJ_GFX_UNIT_DIM_PIX + pixpos.x + (obj_attrs.gfxid + gfxid_offset) * OBJ_GFX_UNIT_PIX_NUM;
    let ogmoffs_u32 = pixidx / 4;
    let ogmshift = 8 * (pixidx % 4);
    return (OGM[ogmoffs_u32] >> ogmshift) & OxFF;
}

// given the screenpos, search for the obj with the highest prio (highest OAM index == tiebreaker).
// get the obj's prio and the packed color at that screenpos.
fn calcObjsPixel(screenpos: vec2<u32>) -> vec2<u32> {

    var candidate = vec2u(
        0x0000,
        0,
    );

    // what a horrible day to be a GPU
    for (var i: u32 = 0; i < MAX_OBJS_NUM; i++) {

        let oam_data = fetchObjAttrs(i);

        let objcol_index = fetchObjPixel(screenpos, oam_data);
        if (objcol_index == OxFFFFFFFF) {
            continue;
        }
        let col = lookupPaletteColor(objcol_index);

        if (!isPackedColorOpaque(col)) {
            continue;
        }
        if (oam_data.prio < candidate.y) {
            continue;
        }
        candidate.x = col;
        candidate.y = oam_data.prio;
    }
    return candidate;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
/// WINDOW FUNCTIONS
///////////////////////////////////////////////////////////////////////////////////////////////////

// given the screenpos, check if it's inside the specified window
fn isPixelInWin(screenpos: vec2<u32>, win: u32) -> bool {

    let index: u32 = select(screenpos.y, screenpos.x, dma_switches.dma_dir_ex[win]);

    // 4 values per u32
    // shift by 0, 8, 16 or 24 bits to get correct val to the least sig byte
    let shift = 8 * (index % 4);

    var start: u32;
    if (dma_switches.win_start_do_dma[win]) {
        start = (win_settings.win_start[win][index / 4] >> shift) & OxFF;
    } else {
        start = (win_settings.win_start[win][0]) & OxFF;
    }

    var end: u32;
    if (dma_switches.win_end_do_dma[win]) {
        end = (win_settings.win_end[win][index / 4] >> shift) & OxFF;
    } else {
        end = (win_settings.win_end[win][0]) & OxFF;
    }

    if (dma_switches.dma_dir_ex[win]) {
        return (start <= screenpos.y && screenpos.y <= end);
    } else {
        return (start <= screenpos.x && screenpos.x <= end);
    }
}

// combine the window data obtained above (valid for all layers) according to a layer's setting.
fn combineWinsForLayer(layer: u32, w0: bool, w1: bool) -> bool {

    switch win_settings.win_compose[layer] {
                                                        // over   1   0 out
        case 0: {return false;}                         //    0   0   0   0
        case 1: {return (!w0) && (!w1);}                //    0   0   0   1
        case 2: {return w0 && !(w1);}                   //    0   0   1   0
        case 3: {return !w1;}                           //    0   0   1   1
        case 4: {return (!w0) && w1;}                   //    0   1   0   0
        case 5: {return !w0;}                           //    0   1   0   1
        case 6: {return (w0 || w1) && (!(w0 && w1));}   //    0   1   1   0
        case 7: {return (!w0) || (!w1);}                //    0   1   1   1
        case 8: {return w0 && w1;}                      //    1   0   0   0
        case 9: {return !((w0 || w1) && (!(w0 && w1)));}//    1   0   0   1
        case 10: {return w0;}                           //    1   0   1   0
        case 11: {return w0 || (!w1);}                  //    1   0   1   1
        case 12: {return w1;}                           //    1   1   0   0
        case 13: {return (!w0) || w1;}                  //    1   1   0   1
        case 14: {return w0 || w1;}                     //    1   1   1   0
        case 15: {return true;}                         //    1   1   1   1
        default: {return w0 && w1;}                     //    1   1   1   1
    }
}

fn isPixelInColWin(is_main: bool, data_in: bool) -> bool {
    let setting: u32 = select(win_settings.win_apply_sub, win_settings.win_apply_main, is_main);

    switch (setting) {
        case 0: {return true;}      // ALWAYS ON
        case 2: {return !data_in;}  // INVERTED
        case 3: {return false;}     // ALWAYS OFF
        default: {return data_in;}   // DIRECT
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
/// THE LONG ONE
///////////////////////////////////////////////////////////////////////////////////////////////////

// resolve BG and obj prios to produce the final color for a pixel
fn resolvePrios(cols: array<u32, 5>, bg_is_prio: array<bool, 4>, obj_prio: u32, fixcol: u32) -> vec2<u32> {

    // what a horrible day to be a GPU 3: revenge of the if chain (something something yandere simulator. ha ha.)

    // precalc this. the compiler will probably figure this out itself but it feels right.
    let is_opaque: array<bool, 5> = array(
        isPackedColorOpaque(cols[0]),
        isPackedColorOpaque(cols[1]),
        isPackedColorOpaque(cols[2]),
        isPackedColorOpaque(cols[3]),
        isPackedColorOpaque(cols[4]),
    );

    // this could probably be reduced using some analysis.
    // if you want do that for some reason, open a PR :)

    if (comp_settings.prio_remap_bg3 && bg_is_prio[3] && is_opaque[3]) {
        return vec2u(cols[3], 3);
    }

    if (comp_settings.prio_remap_bg2 && bg_is_prio[2] && is_opaque[2]) {
        return vec2u(cols[2], 2);
    }

    if (comp_settings.prio_remap_bg1 && bg_is_prio[1] && is_opaque[1]) {
        return vec2u(cols[1], 1);
    }

    if (comp_settings.prio_remap_bg0 && bg_is_prio[0] && is_opaque[0]) {
        return vec2u(cols[0], 0);
    }

    if (obj_prio == 3 && is_opaque[4]) {
        return vec2u(cols[4], 4);
    }

    if (bg_is_prio[3] && is_opaque[3]) {
        return vec2u(cols[3], 3);
    }

    if (bg_is_prio[2] && is_opaque[2]) {
        return vec2u(cols[2], 2);
    }

    if (obj_prio == 2 && is_opaque[4]) {
        return vec2u(cols[4], 4);
    }

    if (!bg_is_prio[3] && is_opaque[3]) {
        return vec2u(cols[3], 3);
    }

    if (!bg_is_prio[2] && is_opaque[2]) {
        return vec2u(cols[2], 2);
    }

    if (obj_prio == 1 && is_opaque[4]) {
        return vec2u(cols[4], 4);
    }

    if (bg_is_prio[1] && is_opaque[1]) {
        return vec2u(cols[1], 1);
    }

    if (bg_is_prio[0] && is_opaque[0]) {
        return vec2u(cols[0], 0);
    }

    if (obj_prio == 0 && is_opaque[4]) {
        return vec2u(cols[4], 4);
    }

    if (!bg_is_prio[1] && is_opaque[1]) {
        return vec2u(cols[1], 1);
    }

    if (!bg_is_prio[0] && is_opaque[0]) {
        return vec2u(cols[0], 0);
    }

    // fallthrough: set to fixcol
    return vec2u(fixcol, 5);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
/// FIXCOL FUNCTION
///////////////////////////////////////////////////////////////////////////////////////////////////

fn getFixcol(screenpos: vec2u, for_main: bool) -> u32 {

    let magic_num: u32 = select(u32(3), u32(2), for_main);
    let do_dma_switch: bool = select(dma_switches.fixcol_sub_do_dma, dma_switches.fixcol_main_do_dma, for_main);

    let index_raw: u32 = select(screenpos.y, screenpos.x, dma_switches.dma_dir_ex[magic_num]);
    let index: u32 = select(0, index_raw, do_dma_switch);

    let offs: u32 = index / 2;
    let shift: u32 = (index % 2) * 16;

    return select(
        (cmath_settings.fixcol_sub[offs] >> shift) & OxFFFF,
        (cmath_settings.fixcol_main[offs] >> shift) & OxFFFF,
        for_main
    );
}

///////////////////////////////////////////////////////////////////////////////////////////////////
/// COLOR MATH
///////////////////////////////////////////////////////////////////////////////////////////////////


fn brightness(col: vec4<f32>) -> f32 {
    // SO says that this is incorrect, but it should be good enough tbh.
    return col.r * 0.2126 + col.g * 0.7152 + col.b * 0.0722;
}

fn luma(col: vec4<f32>) -> f32 {
    // SO says that this is incorrect, but it should be good enough tbh.
    return col.r * 0.299 + col.g * 0.298 + col.b * 0.114;
}

fn mixPinlight(main: vec4<f32>, sub: vec4<f32>) -> vec4<f32> {
    let lm = brightness(main);
    let ls = brightness(sub);
    if (ls > 0.5) {
        if (lm < ls) {
            return sub;
        } else {
            return main;
        }
    } else {
        if (lm > ls) {
            return sub;
        } else {
            return main;
        }
    }
}

fn mixOverlay(main: vec4<f32>, sub: vec4<f32>) -> vec4<f32> {
    if (brightness(sub) > 0.5) {
        return main * sub;
    } else {
        return 1.0 - (( 1.0 - main) * (1.0 - sub));
    }
}

fn mixSoftlight(main: vec4<f32>, sub: vec4<f32>) -> vec4<f32> {
    if (brightness(sub) > 0.5) {
        return max(main, sub);
    } else {
        return min(main, sub);
    }
}

fn doColorMath(main: vec2<u32>, sub: u32) -> vec4<f32> {

    let is_main_opaque: bool = isPackedColorOpaque(main.x);
    let is_sub_opaque: bool = isPackedColorOpaque(sub);

    if (!is_main_opaque && !is_sub_opaque) {
        return vec4(0,0,0,1);
    }
    if (!is_main_opaque) {
        return unpackColor(sub);
    }
    if (!is_sub_opaque) {
        return unpackColor(main.x);
    }

    if (!cmath_settings.math_enable[main.y]) {
        return unpackColor(main.x);
    }

    let a: vec4f = unpackColor(main.x);
    let b: vec4f = unpackColor(sub);

    var rescol: vec4<f32>;

    switch (cmath_settings.math_algo) {
        case 1:  {rescol = b + a;}
        case 2:  {rescol = b - a;}
        case 3:  {rescol = (b * a);}
        case 4:  {rescol = b / a;}
        case 5:  {rescol = max(b, a) - min(b, a);}
        case 6:  {rescol = mixPinlight(b, a);}
        case 7:  {rescol = 1.0 - (( 1.0 - b) * (1.0 - a));}
        case 8:  {rescol = min(b, a);}
        case 9:  {rescol = max(b, a);}
        case 10: {rescol = mixOverlay(b, a);}
        case 11: {rescol = mixSoftlight(b, a);}
        default: {rescol = a;}
    }

    switch (cmath_settings.math_normalize) {
        default: {rescol = saturate(rescol);}
        case 1:  {rescol = saturate(rescol / 2);}
        case 2:  {rescol = saturate(rescol * 2);}
        case 3:  {
            // https://www.quizcanners.com/single-post/2018/04/02/Color-Bleeding-in-Shader
            // value 0f 0.01 determined by testing with the debug example
            let mix = rescol.gbra + rescol.brga;
            rescol = rescol + (mix * mix * 0.01);
        }
    }

    return rescol;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
/// UTIL
///////////////////////////////////////////////////////////////////////////////////////////////////

// array select x5 for bools
// because WGSL only supports select() for vectors, which stop at 4 elements
fn arrselx5b(no: array<bool, 5>, yes: array<bool, 5>, decide: array<bool, 5>) -> array<bool, 5> {
    return array(
        select(no[0], yes[0], decide[0]),
        select(no[1], yes[1], decide[1]),
        select(no[2], yes[2], decide[2]),
        select(no[3], yes[3], decide[3]),
        select(no[4], yes[4], decide[4])
    );
}

// array select x5 for u32
// same as above
fn arrselx5u(no: array<u32, 5>, yes: array<u32, 5>, decide: array<bool, 5>) -> array<u32, 5> {
    return array(
        select(no[0], yes[0], decide[0]),
        select(no[1], yes[1], decide[1]),
        select(no[2], yes[2], decide[2]),
        select(no[3], yes[3], decide[3]),
        select(no[4], yes[4], decide[4])
    );
}

///////////////////////////////////////////////////////////////////////////////////////////////////
/// MAIN
///////////////////////////////////////////////////////////////////////////////////////////////////

fn setPx(screenpos: vec2u, color: vec4f) {
    // need to flip x axis for some reason
    textureStore(SCREEN_BUFFER, vec2((SCREEN_DIM_PIX - 1) - screenpos.x, screenpos.y), color);
}

@compute @workgroup_size(16, 16, 1)
fn main(@builtin(global_invocation_id) GlobalInvocationID : vec3<u32>) {

    /// SETUP
    /////////////////////////////////////////////

    readCompSettings();
    readBGSettings();
    readDMASwitches();
    readWinSettings();
    readCMathSettings();

    // screenpos = location on the logical 256x256 px output
    let screenpos: vec2<u32> = GlobalInvocationID.xy;

    // used for vector select() calls
    let no_p_cols: array<u32, 5> = array(0x0000, 0x0000, 0x0000, 0x0000, 0x0000);
    let no_wins: array<bool, 5> = array(false, false, false, false, false);

    // used for bad debug config
    let errcol = vec4(1.0,0.0,1.0,1.0);

    /// WINDOW PREPARATION
    /////////////////////////////////////////////

    // is the pixel in window 0/1?
    let px_in_win0: bool = isPixelInWin(screenpos, 0);
    let px_in_win1: bool = isPixelInWin(screenpos, 1);

    // combine win 0/1 according to the layer's merging rules:
    // is a layer's pixel inside the layer windows?
    let layer_wins: array<bool, 5> = array(
        combineWinsForLayer(0, px_in_win0, px_in_win1),
        combineWinsForLayer(1, px_in_win0, px_in_win1),
        combineWinsForLayer(2, px_in_win0, px_in_win1),
        combineWinsForLayer(3, px_in_win0, px_in_win1),
        combineWinsForLayer(4, px_in_win0, px_in_win1),
    );

    // does a window apply to a layer sent to the main/sub buffer?
    let main_wins: array<bool, 5> = arrselx5b(no_wins, layer_wins, win_settings.win_to_main);
    let sub_wins: array<bool, 5> = arrselx5b(no_wins, layer_wins, win_settings.win_to_sub);

    // color window is used in a different way than the others, combine seperately
    let col_win: bool = combineWinsForLayer(5, px_in_win0, px_in_win1);

    // is a buffer's pixel inside the color window?
    let col_win_main: bool = isPixelInColWin(true, col_win);
    let col_win_sub: bool = isPixelInColWin(false, col_win);

    /// COLOR MAIN/SUB BUFFER
    /////////////////////////////////////////////

    // BG and obj data: color and prio of the color's source
    let bg0_data: BGPixel = calcBGPixel(screenpos, 0);
    let bg1_data: BGPixel = calcBGPixel(screenpos, 1);
    let bg2_data: BGPixel = calcBGPixel(screenpos, 2);
    let bg3_data: BGPixel = calcBGPixel(screenpos, 3);
    let obj_data: vec2<u32> = calcObjsPixel(screenpos);

    // colors array for efficient processing later
    let p_cols: array<u32, 5> = array(bg0_data.p_col, bg1_data.p_col, bg2_data.p_col, bg3_data.p_col, obj_data.x);

    // prio array for use in priority calculation later
    // objs have 4 prio settings, so handle them differently.
    let bg_prios: array<bool, 4> = array(bg0_data.isprio, bg1_data.isprio, bg2_data.isprio, bg3_data.isprio);
    let obj_prio: u32 = obj_data.y;

    // should the color be sent to the main/sub buffer?
    let p_cols_main: array<u32, 5> = arrselx5u(no_p_cols, p_cols, comp_settings.to_main);
    let p_cols_sub: array<u32, 5> = arrselx5u(no_p_cols, p_cols, comp_settings.to_sub);

    // apply windows to buffers layer-wise
    let wind_p_cols_main: array<u32, 5> = arrselx5u(p_cols_main, no_p_cols, main_wins);
    let wind_p_cols_sub: array<u32, 5> = arrselx5u(p_cols_sub, no_p_cols, sub_wins);

    // get fallback color ("fixcol") for buffers
    // fixcol is always a packed color, but the consistent naming feels wrong...
    // TODO: ignore feelings, make consistent
    let fixcol_main: u32 = getFixcol(screenpos, true);
    let fixcol_sub: u32 = getFixcol(screenpos, false);

    // apply priority logic.
    // result: the final color for this buffer + its source layer
    let main_result: vec2<u32> = resolvePrios(wind_p_cols_main, bg_prios, obj_prio, fixcol_main);
    let sub_result_pre: vec2<u32> = resolvePrios(wind_p_cols_sub, bg_prios, obj_prio, fixcol_sub);

    /// MAIN/SUB BUFFER AFTER PRIO RESOLVE
    /////////////////////////////////////////////

    // replace transparent pixels with fixcol. unsure if actually needed as resolvePrios does this,
    // but better safe than sorry...
    // also discard unneeded origin value for sub buffer
    let main_result_fixed: vec2<u32> = vec2u(
        select(fixcol_main, main_result.x, isPackedColorOpaque(main_result.x)),
        main_result.y
    );
    let sub_result_pre_fixed: u32 = select(fixcol_sub, sub_result_pre.x, isPackedColorOpaque(sub_result_pre.x));

    // apply fixcol override
    let sub_result: u32 = select(sub_result_pre_fixed, fixcol_sub, comp_settings.fix_sub);

    // apply color window
    let wind_main_result: vec2<u32> = vec2u(
        select(main_result_fixed.x, 0x0000, col_win_main),
        main_result_fixed.y
    );
    let wind_sub_result: u32 = select(sub_result, 0x0000, col_win_sub);

    /// COLOR MATH AND OUTPUT
    /////////////////////////////////////////////

    // do color math
    let fincol: vec4<f32> = doColorMath(wind_main_result, wind_sub_result);

    /// DEBUG AND OUTPUT
    /////////////////////////////////////////////


    switch (debug_mode) {
        default: {
            // default: catch bad debug args
            setPx(screenpos, errcol);
            return;
        }
        case DEBUG_MODE_NONE: {
            // normal case: no debug, just output
            setPx(screenpos, fincol);
            return;
        }
        case DEBUG_MODE_LAYER: {
            // show just a single layer before entering the composition pipeline,
            // i.e. transformation, size, affine, mosaic
            if (debug_arg > DEBUG_ARG_SHOW_OBJS) {
                setPx(screenpos, errcol);
                return;
            }
            setPx(screenpos, unpackColor(p_cols[debug_arg]));
            return;
        }
        case DEBUG_MODE_WINDOWS_SETUP: {
            // show how the windows are set up based on the start/end data
            let r: f32 = select(0.0, 1.0, px_in_win0);
            let g: f32 = select(0.0, 1.0, px_in_win1);
            let b: f32 = select(0.0, 0.2, !px_in_win0 && !px_in_win1);
            setPx(screenpos, vec4(r, g, b, 1.0));
            return;
        }
        case DEBUG_MODE_WINDOW_COMP: {
            if (debug_arg > DEBUG_ARG_SHOW_COL) {
                setPx(screenpos, errcol);
                return;
            }

            if (debug_arg == DEBUG_ARG_SHOW_COL) {
                let v: f32 = select(0.0, 1.0, col_win);
                setPx(screenpos, vec4(v, v, v, 1.0));
                return;
            }

            let v: f32 = select(0.0, 1.0, layer_wins[debug_arg]);
            setPx(screenpos, vec4(v, v, v, 1.0));
            return;
        }
        case DEBUG_MODE_WINDOWS_MAIN: {
            // show how the windows apply to a certain layer in the main buffer.
            // useful for checking if the win is applied to the layer.
            if (debug_arg > DEBUG_ARG_SHOW_OBJS) {
                setPx(screenpos, errcol);
                return;
            }

            if (win_settings.win_to_main[debug_arg]) {
                if (main_wins[debug_arg]) {
                    setPx(screenpos, vec4(0,1,0,1));
                } else {
                    setPx(screenpos, vec4(0,0,0,1));
                }
                return;
            } else {
                setPx(screenpos, vec4(0.5,0,0,1));
                return;
            }
        }
        case DEBUG_MODE_WINDOWS_SUB: {
            // same as above, but for the sub buffers
            if (debug_arg > DEBUG_ARG_SHOW_OBJS) {
                setPx(screenpos, errcol);
                return;
            }

            if (win_settings.win_to_sub[debug_arg]) {
                if (sub_wins[debug_arg]) {
                    setPx(screenpos, vec4(0,1,0,1));
                } else {
                    setPx(screenpos, vec4(0,0,0,1));
                }
                return;
            } else {
                setPx(screenpos, vec4(0.5,0,0,1));
                return;
            }
        }
        case DEBUG_MODE_COL_WINDOW: {
            // same as above, but for the color window
            // useful, as the col window has an additional setting

            var trig: bool;
            if (debug_arg == DEBUG_ARG_SHOW_MAIN) {
                trig = col_win_main;
            } else if (debug_arg == DEBUG_ARG_SHOW_SUB) {
                trig = col_win_sub;
            } else {
                setPx(screenpos, errcol);
                return;
            }

            if (trig) {
                setPx(screenpos, vec4(1,1,1,1));
            } else {
                setPx(screenpos, vec4(0,0,0,1));
            }
            return;
        }
        case DEBUG_MODE_BUF_PRE_WIN: {
            // main/sub buffer layers combined by priority, without the windows applied
            if (debug_arg == DEBUG_ARG_SHOW_MAIN) {
                let pcol: u32 = resolvePrios(p_cols_main, bg_prios, obj_prio, fixcol_main).p_col;
                setPx(screenpos, unpackColor(pcol));
            } else if (debug_arg == DEBUG_ARG_SHOW_SUB) {
                let pcol: u32 = resolvePrios(p_cols_sub, bg_prios, obj_prio, fixcol_sub).p_col;
                setPx(screenpos, unpackColor(pcol));
            } else {
                setPx(screenpos, errcol);
            }
            return;
        }
        case DEBUG_MODE_BUF_POST_WIN: {
            // main/sub buffer layers combined by priority, with the windows applied
            if (debug_arg == DEBUG_ARG_SHOW_MAIN) {
                setPx(screenpos, unpackColor(main_result_fixed.p_col));
            } else if (debug_arg == DEBUG_ARG_SHOW_SUB) {
                setPx(screenpos, unpackColor(sub_result_pre_fixed));
            } else {
                setPx(screenpos, errcol);
            }
            return;
        }
        case DEBUG_MODE_BUF_COLMATH_IN: {
            // main/sub buffer data to be fed into color math
            // post-win step + transparency fixed + color window applied
            if (debug_arg == DEBUG_ARG_SHOW_MAIN) {
                setPx(screenpos, unpackColor(wind_main_result.p_col));
            } else if (debug_arg == DEBUG_ARG_SHOW_SUB) {
                setPx(screenpos, unpackColor(wind_sub_result));
            } else {
                setPx(screenpos, errcol);
            }
            return;
        }
        case DEBUG_MODE_FIXCOL_SETUP: {
            // show fixcols for main and sub buffer
            if (debug_arg == DEBUG_ARG_SHOW_MAIN) {
                setPx(screenpos, unpackColor(fixcol_main));
            } else if (debug_arg == DEBUG_ARG_SHOW_SUB) {
                setPx(screenpos, unpackColor(fixcol_sub));
            } else {
                setPx(screenpos, errcol);
            }
            return;
        }
    }
}