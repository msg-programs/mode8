const std = @import("std");
const mode8 = @import("mode8");
const bsp = mode8.bsp;
const mem = mode8.hardware.memory;

pub const TileWriter = struct {
    pub const Keys = struct {
        loc_alpha: u8,
        loc_num: u8,
        loc_space: u8,
        loc_colon: u8,
        loc_dot: u8,
        loc_exmark: u8,
        loc_qumark: u8,
        loc_comma: u8,
        loc_quotmark: u8,
        loc_dash: u8,
        loc_unknown: u8,
        loc_underscore: u8 = 0,
        loc_plus: u8 = 0,
    };

    keys: Keys,
    template: bsp.Tile,

    pub fn write(self: TileWriter, txt: []const []const u8, bg: u2, xstart: u9, ystart: u9, linestart: u9, linestop: u9) void {
        var x: u9 = xstart;
        var y: u9 = ystart;
        for (txt) |line| {
            var toks = std.mem.tokenize(u8, line, " ");
            while (toks.next()) |tok| {
                if (x + 1 + tok.len > linestop) {
                    y += 1;
                    x = linestart;
                }
                for (tok) |char| {
                    const gfxid: u8 = switch (char) {
                        'a'...'z' => |c| @as(u8, @truncate(c - 'a' + self.keys.loc_alpha)),
                        '0'...'9' => |c| @as(u8, @truncate(c - '0' + self.keys.loc_num)),
                        ':' => self.keys.loc_colon,
                        '.' => self.keys.loc_dot,
                        '!' => self.keys.loc_exmark,
                        '?' => self.keys.loc_qumark,
                        ',' => self.keys.loc_comma,
                        '"' => self.keys.loc_quotmark,
                        '-' => self.keys.loc_dash,
                        '_' => self.keys.loc_underscore,
                        '+' => self.keys.loc_plus,
                        else => self.keys.loc_unknown,
                    };
                    const tile = bsp.Tile{
                        .atlid = self.template.atlid,
                        .gfxid = gfxid,
                        .hflip = self.template.hflip,
                        .vflip = self.template.vflip,
                        .prio = self.template.prio,
                        .rot = self.template.rot,
                    };
                    tile.writeToTAM(bg, x, y);
                    x += 1;
                }
                const tile = bsp.Tile{
                    .atlid = self.template.atlid,
                    .gfxid = self.keys.loc_space,
                    .hflip = self.template.hflip,
                    .vflip = self.template.vflip,
                    .prio = self.template.prio,
                    .rot = self.template.rot,
                };
                tile.writeToTAM(bg, x, y);
                x += 1;
            }
            y += 2;
            x = linestart;
        }
    }
};
