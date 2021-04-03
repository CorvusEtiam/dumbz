const std = @import("std");
const my = @import("./my.zig");

const chunks = @import("./chunk.zig");
const debug = @import("./debug.zig");
const opcodes = @import("./opcodes.zig");

const Chunk = chunks.Chunk;
const Opcode = opcodes.Opcode;


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
    stack: std.ArrayList(my.Value),

    pub fn init(allocator: *std.mem.Allocator) Self {
        return VirtualMachine{
            .ip = 0,
            .stack = std.ArrayList(my.Value).init(allocator),
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

    pub fn resetStack(self: *Self) void {
        std.mem.set(my.Value, self.stack.items, 0.0);
        const allocator = self.stack.allocator;
        self.stack.deinit();
        self.stack = std.ArrayList(my.Value).init(self.allocator);
    }

    pub fn popStack(self: *Self) my.Value {
        return self.stack.pop();
    }
    
    pub fn pushStack(self: *Self, v: my.Value) void {
        self.stack.append(v) catch unreachable;
    }

    pub fn run(self: *Self) InterpreterError!InterpreterResult {
        while (true) {
            if (debug.has_tracing_enabled) {
                debug.printStack(self.stack.items);
                _ = debug.disassembleInstruction(self.chunk, self.ip);

            }
            var opcode: opcodes.Opcode = self.nextInstruction();
            switch (opcode) {
                Opcode.Return => { 
                    std.debug.print("   ", .{});
                    my.printValue(self.popStack());
                    std.debug.print("\n", .{});
                    return InterpreterResult.Ok;
                },
                Opcode.Constant => {
                    var code = self.codeSlice();
                    var idx : usize = @intCast(usize, code[self.ip]);
                    self.stack.append(self.chunk.constants.items[idx]) catch unreachable;
                    self.ip += 1;
                },
                Opcode.ConstantLong => {
                    var code = self.codeSlice();
                    var idx = @intCast(usize, std.mem.readIntLittle(u24, code[self.ip..][0..3]));
                    self.stack.append(self.chunk.constants.items[idx]) catch unreachable;
                    self.ip += 3;
                },
                Opcode.Negate => {
                    self.stack.items[self.stack.items.len - 1] = -self.stack.items[self.stack.items.len - 1]; 
                },
                Opcode.Add => {
                    var b : my.Value = self.popStack();
                    var a : my.Value = self.popStack();
                    self.pushStack(a + b);
                },
                Opcode.Substract => {
                    var b : my.Value = self.popStack();
                    var a : my.Value = self.popStack();
                    self.pushStack(a - b);
                },
                Opcode.Multiply => {
                    var b : my.Value = self.popStack();
                    var a : my.Value = self.popStack();
                    self.pushStack(a * b);
                },
                Opcode.Divide => {
                    var b : my.Value = self.popStack();
                    var a : my.Value = self.popStack();
                    self.pushStack(a / b);
                },
                
//                else => InterpreterError.CompileError,
            }
        }
        return InterpreterResult.Ok;
    }
};

