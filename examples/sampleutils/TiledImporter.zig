const std = @import("std");
const json = std.json;
const mode8 = @import("mode8");
const bsp = mode8.bsp;
const mem = mode8.hardware.memory;
const con = mode8.hardware.constants;

pub const TiledMap = struct {
    pub const Layer = struct {
        data: []u64,
        height: u32, // assert even and <= 512
        width: u32, // assert even and <= 512
        type: []u8, // assert "tilelayer"
        name: []u8,
    };

    pub const Group = struct {
        layers: []Layer,
        name: []u8,
        type: []u8, // assert "group"
    };

    pub const File = struct {
        compressionlevel: i32, // assert -1
        height: u32, // assert even and <= 512
        width: u32, // assert even and <= 512
        infinite: bool, // assert false
        layers: []Group,
        orientation: []u8, // assert "orthogonal"
        renderorder: []u8, // assert "right-down"
        tileheight: u32, // assert 8,
        tilewidth: u32, // assert 8
    };

    parsed: json.Parsed(File),
    content: File,

    pub fn init(alloc: std.mem.Allocator, srcfile: []const u8) !TiledMap {
        const res = try json.parseFromSlice(File, alloc, srcfile, .{ .ignore_unknown_fields = true });
        return .{
            .parsed = res,
            .content = res.value,
        };
    }

    pub fn deinit(self: TiledMap) void {
        self.parsed.deinit();
    }

    pub fn loadLayer(self: TiledMap, dirname: []const u8, layername: []const u8, dstbg: u2, as_prio: bool, atlid: u2) !void {
        const grp = found: {
            for (self.content.layers) |g| {
                if (std.mem.eql(u8, g.name, dirname)) {
                    break :found g;
                }
            } else {
                @panic("no such group");
            }
        };
        const layer = found: {
            for (grp.layers) |l| {
                if (std.mem.eql(u8, l.name, layername)) {
                    break :found l;
                }
            } else {
                @panic("no such layer");
            }
        };
        for (layer.data, 0..) |id, idx| {
            if (id == 0) {
                if (!as_prio) {
                    @panic("Tile 0 only allowed on prio layers!");
                }
                continue;
            }
            const gid: u10 = @truncate((id - 1) & 0x3FF);
            const rot: u1 = @truncate((id >> 29) & 0x01);
            const hflip: u1 = @truncate((id >> 30) & 0x01);
            const vflip: u1 = @truncate((id >> 31) & 0x01);
            const tile = bsp.Tile{
                .atlid = atlid,
                .gfxid = gid,
                .hflip = hflip,
                .vflip = vflip,
                .prio = if (as_prio) 1 else 0,
                .rot = rot,
            };
            const xpos: u9 = @truncate(idx % self.content.width);
            const ypos: u9 = @truncate(idx / self.content.height);
            tile.writeToTAM(dstbg, xpos, ypos);
        }
    }

    pub fn makeEmpty(dstbgs: []const u2, emptytile: bsp.Tile) void {
        for (dstbgs) |bg| {
            for (0..con.BG_DIM_TIL) |y| {
                for (0..con.BG_DIM_TIL) |x| {
                    emptytile.writeToTAM(@truncate(bg), @truncate(x), @truncate(y));
                }
            }
        }
    }
};
