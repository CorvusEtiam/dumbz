const std = @import("std");

const chunks = @import("./chunk.zig");
const debug = @import("./debug.zig");
const opcodes = @import("./opcodes.zig");

const Chunk = chunks.Chunk;
const Opcode = opcodes.Opcode;

const Value = f32;
pub fn printValue(v: Value) void {
    std.debug.print("CONST: {d:.2}\n", .{v});
}

pub const InterpreterResult = enum {
    Ok,
};

pub const InterpreterError = error {
    CompileError,
    RuntimeError,
};

pub const VirtualMachine = struct {
    const Self = @This();
    chunk: *chunks.Chunk = undefined,
    // I change it a bit from original, because any instruction change will invalidate IP pointers.
    ip: usize,

    pub fn init(allocator: *std.mem.Allocator) Self {
        return VirtualMachine{
            .ip = 0,
        };
    }

    pub fn interpret(self: *Self, chunk: *chunks.Chunk) InterpreterError!InterpreterResult {
        self.chunk = chunk;
        self.ip = 0;
        return self.run();
    }

    fn nextInstruction(self: *Self) opcodes.Opcode {
        const tmp = self.ip;
        self.ip += 1;
        return @intToEnum(Opcode, self.chunk.read(tmp));
    }

    fn nextByte(self: *Self) u8 {
        const tmp = self.ip;
        self.ip += 1;
        return self.chunk.read(tmp);
    }

    fn codeSlice(self: *Self) []u8 {
        return self.chunk.code.items;
    }

    fn constantsSlice(self: *Self) []u8 {
        return self.chunk.constants.items;
    }

    pub fn run(self: *Self) InterpreterError!InterpreterResult {
        while (true) {
            if (debug.has_tracing_enabled) {
                _ = debug.disassembleInstruction(self.chunk, self.ip);
            }
            var opcode: opcodes.Opcode = self.nextInstruction();
            switch (opcode) {
                Opcode.Return => return InterpreterResult.Ok,
                Opcode.Constant => {
                    var code = self.codeSlice();
                    var idx : usize = @intCast(usize, code[self.ip]);
                    printValue(self.chunk.constants.items[idx]);
                    self.ip += 1;
                },
                Opcode.ConstantLong => {
                    var code = self.codeSlice();
                    var idx = @intCast(usize, std.mem.readIntLittle(u24, code[self.ip..][0..3]));
                    printValue(self.chunk.constants.items[idx]);
                    self.ip += 3;
                },
//                else => InterpreterError.CompileError,
            }
        }
        return InterpreterResult.Ok;
    }
};
