const std = @import("std");
const my = @import("./my.zig");

const opcodes = @import("./opcodes.zig");
const Opcode = opcodes.Opcode;
const Chunk = @import("./chunk.zig").Chunk;

const print = std.debug.print;

pub const has_tracing_enabled : bool = false;
pub const has_code_printing_enabled: bool = true;
pub const has_parser_state_dumping: bool = false;
pub const has_block_printing : bool = false;

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


pub fn disassembleInstruction(chunk: *Chunk, offset: usize) usize {
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
            var value = chunk.readConstant(index);
            print("OP_CONSTANT .S     ", .{});
            switch ( value ) {
                my.Value.vt_number => print("<{d:.2}>\n", .{ value.vt_number }),
                my.Value.vt_boolean => print("<{}>\n", .{ value.vt_boolean }),
                my.Value.vt_nil => print("<nil>\n", .{ }),
            }
            return offset + 2;
        },
        Opcode.ConstantLong => {
            var long_index = @intCast(usize, std.mem.readIntLittle(u24, chunk.code.items[offset..][0..3]));
            var value = chunk.readConstant(long_index);
            print("OP_CONSTANT .L     ", .{});
            switch ( value ) {
                my.Value.vt_number => print("<{d:.2}>\n", .{ value.vt_number }),
                my.Value.vt_boolean => print("<{}>\n", .{ value.vt_boolean }),
                my.Value.vt_nil => print("<nil>\n", .{ }),
            }
            return offset + 3;
        },
        Opcode.Add => {
            print("OP_ADD\n", .{});
        },
        Opcode.Substract => {
            print("OP_SUB\n", .{});
        },
        Opcode.Divide => { 
            print("OP_DIV\n", .{});
        },
        Opcode.Multiply => { 
            print("OP_MUL\n", .{});
        },
        Opcode.Negate => { 
            print("OP_NEG\n", .{});
        }
    }
    return offset + 1;
}

pub fn printStack(stack: []my.Value) void {
    print("          ", .{});
    for ( stack ) | value | {
        print("[ ", .{});
        my.printValue(value);
        print(" ]", .{});
    } 
    print("\n", .{});
}

fn dumpToken(token: *my.Token) void {
    std.debug.print("Token<{d}>  {s} at line: {d}\n", .{@enumToInt(token.token_type), token.data, token.line});
}

pub fn dumpParserState(parser: *my.Parser) void {
    std.debug.print("=== Parser >> {{ \n", .{});
    std.debug.print("\tprev: ", .{});
    dumpToken(&parser.previous);
    std.debug.print("\tcurrent:", .{});
    dumpToken(&parser.current);
    std.debug.print("\tflags:\t panic={s}, error={s}\n", .{ parser.panicMode, parser.hadError });
    std.debug.print("}} \n", .{});
}

pub fn dumpLines(lines: []my.LineSpan) void {
    std.debug.print("=== Line Spans dump: \n", .{});
    for ( lines ) | line | {
        std.debug.print("\tline={d}  span={d}\n", .{line.line, line.length});
    }
}

pub fn blockStart(tag: []const u8) void  {
    if ( has_block_printing )
        std.debug.print(">>> Entering function: {s}\n", .{tag});
}

pub fn blockEnd(tag: []const u8) void {
    if ( has_block_printing )
        std.debug.print("<<< Exiting function: {s}\n", .{tag});
}