const std = @import("std");
const print = std.debug.print;
const opcodes = @import("./opcodes.zig");
const Opcode = opcodes.Opcode;
const Chunk = @import("./chunk.zig").Chunk;

pub fn disassembleChunk(chunk: *Chunk, name: []const u8) void {
    print("=== {s} ===\n", .{name});
    var offset: usize = 0;
    while (offset < chunk.opCount()) {
        offset = disassembleInstruction(chunk, offset);
    }
}

fn simpleInstruction(name: []const u8, offset: usize) usize {
    print("{s}\n", .{name});
    return offset + 1;
}

const U3Slice = packed struct {
    a: u8,
    b: u8,
    c: u8,
    ___filler__: u8 = 0,
};

fn disassembleInstruction(chunk: *Chunk, offset: usize) usize {
    print("{d:0>4}    ", .{offset});
    if (offset > 0 and chunk.getLine(offset) == chunk.getLine(offset - 1)) {
        print("    | ", .{});
    } else {
        print(" {d:0>3}  ", .{chunk.getLine(offset)});
    }
    const opcode = @intToEnum(Opcode, chunk.read(offset));
    switch (opcode) {
        Opcode.Return => return simpleInstruction("OP_RETURN", offset),
        Opcode.Constant => {
            var index = chunk.read(offset + 1);
            print("OP_CONSTANT        <{d}>\n", .{chunk.readConstant(index)});
            return offset + 2;
        },
        Opcode.ConstantLong => {
            var long_index = opcodes.slice_to_long_index(chunk.code.items[offset + 1 .. offset + 4]);
            print("OP_CONSTANT .L     <{d}>\n", .{chunk.readConstant(long_index)});
        },
    }
    return offset + 1;
}
