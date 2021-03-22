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
    chunk.write(@enumToInt(Opcode.Constant));
    var index = @intCast(u8, constant);
    chunk.write(index);
    chunk.write(@enumToInt(Opcode.Return));

    disasm.disassembleChunk(&chunk, "RET");

    std.debug.print("-------------------------------------\n", .{});
    std.debug.print("\n\n", .{});
    std.debug.print("Size of usize: {d}", .{@sizeOf(usize)});
}
