const std = @import("std");
const mode8 = @import("mode8");
const bsp = mode8.bsp;
const con = mode8.hardware.constants;
const zigimg = @import("zigimg");

/// imports color 0 as transparent
pub fn importPal(palfile: []const u8, offset: u8) !void {
    var toks = std.mem.tokenizeAny(u8, palfile, "\r\n");
    var gcm_idx: u8 = offset;
    while (toks.next()) |tok| {
        const intcol: u24 = try std.fmt.parseInt(u24, tok, 16);
        const col = bsp.Color.of(intcol, if (gcm_idx == 0) true else false);
        col.writeToGCM(gcm_idx);
        gcm_idx = gcm_idx +% 1;
    }
}

/// imports color 0 as transparent
pub fn importPalAndAtlas(alloc: std.mem.Allocator, palfile: []const u8, offset: u8, atlfile: []const u8, atlid: u2) !void {
    var toks = std.mem.tokenizeAny(u8, palfile, "\r\n");
    var gcm_idx: u8 = offset;
    var col_no: u8 = 0;
    var cols: [con.MAX_COLORS_NUM]u24 = .{0} ** con.MAX_COLORS_NUM;
    while (toks.next()) |tok| {
        const intcol: u24 = try std.fmt.parseInt(u24, tok, 16);
        const col = bsp.Color.of(intcol, if (gcm_idx == 0) true else false);
        cols[col_no] = intcol;
        col.writeToGCM(gcm_idx);
        gcm_idx = gcm_idx +% 1;
        col_no += 1;
    }

    var img = try zigimg.Image.fromMemory(alloc, atlfile);
    var buf: [con.TILE_GFX_PIX_NUM]u8 = undefined;
    for (0..con.TILE_ATL_DIM_TIL) |y| {
        for (0..con.TILE_ATL_DIM_TIL) |x| {
            for (0..con.TILE_GFX_PIX_NUM) |p| {
                const offs_from_top = con.TILE_ATL_DIM_TIL * con.TILE_GFX_PIX_NUM * y;
                const offs_from_left = x * con.TILE_GFX_DIM_PIX;
                const tile_row = p / con.TILE_GFX_DIM_PIX;
                const tile_col = p % con.TILE_GFX_DIM_PIX;
                const offs = offs_from_top + tile_row * con.TILE_ATL_DIM_TIL * con.TILE_GFX_DIM_PIX + offs_from_left + tile_col;
                const px: u24 = @truncate(img.pixels.rgba32[offs].toU32Rgb() & 0xFFFFFF);
                buf[p] = @as(u8, @truncate(std.mem.indexOf(u24, &cols, &.{px}) orelse @as(u8, 0)));
            }
            bsp.Tile.writeToTGM(atlid, @truncate(y * con.TILE_ATL_DIM_TIL + x), buf);
        }
    }
    defer img.deinit();
}
/// imports color 0 as transparent
pub fn importPalAndObjects(alloc: std.mem.Allocator, palfile: []const u8, offset: u8, atlfile: []const u8, atlid: u2) !void {
    var toks = std.mem.tokenizeAny(u8, palfile, "\r\n");
    var gcm_idx: u8 = offset;
    var col_no: u8 = 0;
    var cols: [con.MAX_COLORS_NUM]u24 = .{0} ** con.MAX_COLORS_NUM;
    while (toks.next()) |tok| {
        const intcol: u24 = try std.fmt.parseInt(u24, tok, 16);
        const col = bsp.Color.of(intcol, if (gcm_idx == 0) true else false);
        cols[col_no] = intcol;
        col.writeToGCM(gcm_idx);
        gcm_idx = gcm_idx +% 1;
        col_no += 1;
    }

    var img = try zigimg.Image.fromMemory(alloc, atlfile);
    var buf: [con.OBJ_GFX_UNIT_PIX_NUM]u8 = undefined;
    for (0..con.OBJ_ATL_DIM_H_TIL) |y| {
        for (0..con.OBJ_ATL_DIM_W_TIL) |x| {
            for (0..con.OBJ_GFX_UNIT_PIX_NUM) |p| {
                const offs_from_top = con.OBJ_ATL_DIM_W_TIL * con.OBJ_GFX_UNIT_PIX_NUM * y;
                const offs_from_left = x * con.OBJ_GFX_UNIT_DIM_PIX;
                const tile_row = p / con.OBJ_GFX_UNIT_DIM_PIX;
                const tile_col = p % con.OBJ_GFX_UNIT_DIM_PIX;
                const offs = offs_from_top + tile_row * con.OBJ_ATL_DIM_W_TIL * con.OBJ_GFX_UNIT_DIM_PIX + offs_from_left + tile_col;
                const px: u24 = @truncate(img.pixels.rgba32[offs].toU32Rgb() & 0xFFFFFF);
                buf[p] = @as(u8, @truncate(std.mem.indexOf(u24, &cols, &.{px}) orelse @as(u8, 0)));
            }
            bsp.Obj.writeToOGM(atlid, @truncate(y * con.OBJ_ATL_DIM_W_TIL + x), buf);
        }
    }
    defer img.deinit();
}
