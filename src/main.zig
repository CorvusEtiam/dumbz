const std = @import("std");
const Chunk = @import("./chunk.zig").Chunk;
const Opcode = @import("./opcodes.zig").Opcode;
const disasm = @import("./debug.zig");
const VM = @import("./vm.zig");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;

    var chunk: Chunk = Chunk.init(allocator);
    defer chunk.deinit();

    std.debug.print("-------------------------------------\n", .{});

    chunk.writeConstant(125.00, 123);
    chunk.writeConstant(160.20, 123);
    chunk.writeConstant(195.30, 124);
    chunk.writeConstant(240.50, 124);
    chunk.writeOpcode(Opcode.Return, 125);

    var vm = VM.VirtualMachine { .ip = 0 };
    var ok = vm.interpret(&chunk) catch |err| {
        switch (err) {
            VM.InterpreterError.CompileError => {
                std.debug.warn("Compilation Error ip:{d} !\n", .{vm.ip});
                return;
            },
            VM.InterpreterError.RuntimeError => {
                std.debug.warn("Runtime Error ip:{d} !\n", .{vm.ip});
                return;
            },
        }
    };
    std.debug.print("Intepreter run was successful \n", .{});
    disasm.disassembleChunk(&chunk, "RET");
}
