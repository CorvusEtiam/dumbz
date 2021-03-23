pub const Opcode = enum(u8) {
    Return,
    Constant,
    ConstantLong,
};


/// FIXME: Dirty Hack; rewrite using memcopy and tip from WIKI
pub const LongIndex = packed struct {
    const U3Unpacked = struct {
        a: u8 = 0,
        b: u8 = 0,
        c: u8 = 0,
        d: u8 = 0
    };

    value: u32,
};

pub fn unpack_long_index(index: usize) LongIndex.U3Unpacked {
    var pack = LongIndex { .value = @intCast(u32, index) };
    
    return @bitCast(LongIndex.U3Unpacked, pack);
}

pub fn slice_to_long_index(slice: []u8) usize {
    var u3p = LongIndex.U3Unpacked {
        .a = slice[0],
        .b = slice[1],
        .c = slice[2],
    };

    return @as(usize, @bitCast(LongIndex, u3p).value);
}