
/// FIXME: Dirty Hack; rewrite using memcopy and tip from WIKI
pub const LongIndex = packed struct {
    const U3Unpacked = struct { a: u8 = 0, b: u8 = 0, c: u8 = 0, d: u8 = 0 };

    value: u32,
};

pub const IndexMode = enum {
    ShortMode,
    LongMode,
};

pub fn readIndex(memory: []u8, mode: IndexMode) usize {
    
}

pub fn readUint24(memory: []u8, offset: usize) u24 {
    var u3p = LongIndex.U3Unpacked{
        .a = memory[offset+0],
        .b = memory[offset+1],
        .c = memory[offset+2],
    };

    return @bitCast(LongIndex, u3p).value;
}


pub fn writeUint24AtOffset(memory: []u8, offset: usize, value: u24) void {
    const idx = @bitCast(LongIndex.U3Unpacked, .{ .value = value }); 
    memory[offset + 0] = idx.a;
    memory[offset + 1] = idx.b;
    memory[offset + 2] = idx.c;
}