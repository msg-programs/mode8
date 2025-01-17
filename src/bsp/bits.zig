pub inline fn sto4x2in8(ll: u2, lh: u2, hl: u2, hh: u2) u8 {
    return @as(u8, 0) |
        (@as(u8, ll) << 0) |
        (@as(u8, lh) << 2) |
        (@as(u8, hl) << 4) |
        (@as(u8, hh) << 6);
}

pub inline fn sto2x4in8(l: u4, h: u4) u8 {
    return @as(u8, 0) |
        (@as(u8, l) << 0) |
        (@as(u8, h) << 4);
}

pub inline fn sto1x8in8(h: u1, g: u1, f: u1, e: u1, d: u1, c: u1, b: u1, a: u1) u8 {
    return @as(u8, 0) |
        (@as(u8, a) << 0) |
        (@as(u8, b) << 1) |
        (@as(u8, c) << 2) |
        (@as(u8, d) << 3) |
        (@as(u8, e) << 4) |
        (@as(u8, f) << 5) |
        (@as(u8, g) << 6) |
        (@as(u8, h) << 7);
}

pub inline fn stoBoolx8in8(h: bool, g: bool, f: bool, e: bool, d: bool, c: bool, b: bool, a: bool) u8 {
    return sto1x8in8(
        @intFromBool(h),
        @intFromBool(g),
        @intFromBool(f),
        @intFromBool(e),
        @intFromBool(d),
        @intFromBool(c),
        @intFromBool(b),
        @intFromBool(a),
    );
}

pub inline fn sto4x8in32(ll: u8, lh: u8, hl: u8, hh: u8) u32 {
    return @as(u32, 0) |
        (@as(u32, ll) << 0) |
        (@as(u32, lh) << 8) |
        (@as(u32, hl) << 16) |
        (@as(u32, hh) << 24);
}
