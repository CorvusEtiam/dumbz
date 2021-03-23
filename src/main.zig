const std = @import("std");
const Chunk = @import("./chunk.zig").Chunk;
const Opcode = @import("./opcodes.zig").Opcode;
const disasm = @import("./debug.zig");



pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;

    var chunk: Chunk = Chunk.init(allocator);
    defer chunk.deinit();
    
    std.debug.print("-------------------------------------\n", .{});
    
    var constant = chunk.writeConstant(@as(f32, 120.0));
    chunk.writeOpcode(Opcode.Constant, 123);
    chunk.write(@intCast(u8, constant), 123);
    chunk.writeOpcode(Opcode.Return, 123);

    disasm.disassembleChunk(&chunk, "RET");
}
