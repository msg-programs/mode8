/// note on format
/// {NAME}_{TYPE}_[UNIT]
/// DIM = geometric dimension
///     -> _PIX in pixel
///     -> _TIL in tiles
/// SZE = memory size
///     -> _BIT in bits
///     -> _BYT in bytes
///     -> _U32 in multiples of u32
/// NUM = unitless amount

// ==== VIDEO CONSTANTS =======================================================

/// size of the (square) output screen
pub const SCREEN_DIM_PIX = 256;

// ==== OBJ CONSTANTS =========================================================

/// size of the (square) area where objs can be positioned
pub const OBJ_POS_DIM_PIX = 360;

/// how many objs can at most be rendered at once
pub const MAX_OBJS_NUM = 256;

/// size of a singular object
pub const OBJ_ATT_SZE_BIT = 36;

/// size of the obj attribute memory (OAM)
pub const OAM_SZE_BIT = (OBJ_ATT_SZE_BIT * MAX_OBJS_NUM);
/// size of the obj attribute memory (OAM)
pub const OAM_SZE_BYT = OAM_SZE_BIT / 8;
/// size of the obj attribute memory (OAM)
pub const OAM_SZE_U32 = OAM_SZE_BYT / 4;

/// width of a atlas used for objects
pub const OBJ_ATL_DIM_W_TIL = 16;
/// height of a atlas used for objects
pub const OBJ_ATL_DIM_H_TIL = 32;

/// size of a tile (8x8 px, 8 bits/px)
pub const OBJ_GFX_SZE_BIT = 8 * 8 * 8;

// size of a (square) object sprite unit
pub const OBJ_GFX_UNIT_DIM_PIX = 8;

// number of pixels per sprite unit
pub const OBJ_GFX_UNIT_PIX_NUM = OBJ_GFX_UNIT_DIM_PIX * OBJ_GFX_UNIT_DIM_PIX;

/// how many obj atlasses can be loaded at once
pub const OBJ_ATL_NUM = 4;
/// size of the OGM
pub const OGM_SZE_BIT = OBJ_ATL_NUM * OBJ_ATL_DIM_W_TIL * OBJ_ATL_DIM_H_TIL * OBJ_GFX_SZE_BIT;
/// size of the OGM
pub const OGM_SZE_BYT = OGM_SZE_BIT / 8;
/// size of the OGM
pub const OGM_SZE_U32 = OGM_SZE_BYT / 4;

// ==== COLOR CONSTANTS =======================================================

/// size of a color in bits
pub const COLOR_SZE_BIT = 16;

/// number of colors in a palette
pub const MAX_COLORS_NUM = 256;

/// size of the GCM
pub const GCM_SZE_BIT = (COLOR_SZE_BIT * MAX_COLORS_NUM);
/// size of the GCM
pub const GCM_SZE_BYT = GCM_SZE_BIT / 8;
/// size of the GCM
pub const GCM_SZE_U32 = GCM_SZE_BYT / 4;

// ==== TILE CONSTANTS =======================================================

/// size of a tile
pub const TILE_ATT_SZE_BIT = 16;

/// size of a (square) background
pub const BG_DIM_TIL = 512;

/// how many backgrounds there are
pub const BG_NUM = 4;

/// size of the TAM
pub const TAM_SZE_BIT = TILE_ATT_SZE_BIT * BG_DIM_TIL * BG_DIM_TIL * BG_NUM;
pub const TAM_SZE_BYT = TAM_SZE_BIT / 8;
pub const TAM_SZE_U32 = TAM_SZE_BIT / 4;

// size of a (square) tile atlas
pub const TILE_ATL_DIM_TIL = 32;

/// how many tile atlasses can be loaded at once
pub const TILE_ATL_NUM = 4;

// size of a (square) tile
pub const TILE_GFX_DIM_PIX = 8;

// number of pixels in a tile graphic
pub const TILE_GFX_PIX_NUM = TILE_GFX_DIM_PIX * TILE_GFX_DIM_PIX;

/// size of a bg tile at 8 bits/px
pub const TILE_GFX_SZE_BIT = TILE_GFX_PIX_NUM * 8;

/// size of the TGM
pub const TGM_SZE_BIT = TILE_ATL_DIM_TIL * TILE_ATL_DIM_TIL * TILE_ATL_NUM * TILE_GFX_SZE_BIT;
/// size of the TGM
pub const TGM_SZE_BYT = TGM_SZE_BIT / 8;
/// size of the TGM
pub const TGM_SZE_U32 = TGM_SZE_BYT / 4;

// ==== RENDERING CONSTANTS ===================================================

pub const DMA_NUM = SCREEN_DIM_PIX;

pub const WINDOW_NUM = 2;
