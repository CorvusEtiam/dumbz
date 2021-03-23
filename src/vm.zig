const std = @import("std");
const chunks = @import("./chunk.zig");
const Chunk = chunks.Chunk;
const Opcode = @import("./opcodes.zig").Opcode;

pub const InterpreterResult = enum {
    Ok,
};
pub const InterpreterError = error{
    CompileError,
    RuntimeError,
};

pub const VirtualMachine = struct {
    const Self = @This();
    chunk: *chunks.Chunk,
    // I change it a bit from original, because any instruction change will invalidate IP pointers.
    ip: usize,

    pub fn init(allocator: *std.mem.Allocator) Self {
        return VirtualMachine{};
    }

    pub fn deinit() void {}

    pub fn interpret(self: *Self, chunk: *chunks.Chunk) IntepreterError!InterpreterResult {
        self.chunk = chunk;
        self.ip = 0;
        return self.run();
    }

    fn nextInstruction(self: *Self) opcodes.Opcode {
        return @intToEnum(Opcode, self.chunk.read(self.ip));
    }

    pub fn run() IntepreterError!InterpreterResult {
        while (1) {
            var opcode: opcodes.Opcode = self.nextInstruction();
            switch (opcode) {
                Opcode.Return => .Ok,
                else => InterpreterError.CompileError,
            }
        }
        return .Ok;
    }
};
