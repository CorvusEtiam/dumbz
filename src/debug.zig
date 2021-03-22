const std = @import("std");
const print = std.debug.print;
const Opcode = @import("./opcodes.zig").Opcode;
const Chunk  = @import("./chunk.zig").Chunk;

pub fn disassembleChunk(chunk: *Chunk, name: []const u8) void {
    print("=== {s} ===\n", .{name});
    var offset: usize = 0;
    while ( offset < chunk.count ) {
        offset = disassembleInstruction(chunk, offset);
    }
}

fn simpleInstruction(name: []const u8, offset: usize) usize {
    print("{d:0>4} {s}\n", .{offset, name});
    return offset + 1;
}

fn disassembleInstruction(chunk: *Chunk, offset: usize) usize {
    const opcode : u8 = chunk.read(offset);
    switch ( @intToEnum(Opcode, opcode) ) {
        Opcode.Return => return simpleInstruction("OP_RETURN", offset),
        Opcode.Constant => {
            var off = simpleInstruction("OP_CONSTANT", offset);
            var index = chunk.read(off);
            print("   | {d}\n", .{chunk.readConstant(index)});
            return off + 1;
        },
    }
    return offset + 1;
}