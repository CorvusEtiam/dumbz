const std = @import("std");
const print = std.debug.print;
const Opcode = @import("./opcodes.zig").Opcode;

const Allocator = @import("std").mem.Allocator;
const ArrayList = std.ArrayList;


/// Chunk data structure
/// ----------------------------
/// First main part of intepreter
///
/// FIXME: Add run-length encoded lines info 
/// FIXME: Provide Accessor for given line data. 
/// > 1 1 1 2 2 4 4 4 4 5 5 5
/// > 1 3  2 2  4 4  5 3
/// > 6th => 3 2 4

const LineSpan = packed struct {
    line: u32,
    length: u32,
};

pub const Chunk = struct {
    const Self = @This();
    code: ArrayList(u8),
    constants: ArrayList(f32),
    lines: ArrayList(LineSpan), 

    pub fn opCount(self: *Self) usize {
        return self.code.items.len;
    }
    
    pub fn constantCount(self: *Self) usize {
        return self.constants.items.len;
    }

    pub fn init(allocator: *Allocator) Chunk {
        return .{
            .code = ArrayList(u8).init(allocator),
            .constants = ArrayList(f32).init(allocator),
            .lines = ArrayList(LineSpan).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.code.deinit();
        self.constants.deinit();
        self.lines.deinit();
    }

    pub fn write(self: *Self, byte: u8, line_number: usize) void {
        self.code.append(byte) catch |err| { std.debug.panic("ERROR while allocating space for: {d}", .{byte}); };
        if ( self.lines.items.len > 0 and self.lines.items[self.lines.items.len - 1].line == line_number ) {
            self.lines.items[self.lines.items.len - 1].length += 1;
        } else {
            self.lines.append(LineSpan { .length = 1, .line = @intCast(u32, line_number) }) catch unreachable;
        }
    }


    pub fn getLine(self: *Self, offset: usize) usize {
        const index = @intCast(u32, offset); 
        var i: usize = 0;
        var acc: usize = 0;
        while ( i < self.lines.items.len ) {
            var curr = self.lines.items[i];
            if ( offset >= acc and offset < acc + curr.length) {
                return @as(usize, curr.line);
            } else { // offset > acc + curr.len
                acc += curr.length;
            }

            i += 1;
        }

        return 0;
    }

    pub fn writeOpcode(self: *Self, opcode: Opcode, line_number: usize) void {
        self.write(@enumToInt(opcode), line_number);
    }

    pub fn read(self: *Self, index: usize) u8 {
        return self.code.items[index];
    }

    pub fn writeConstant(self: *Self, value: f32) usize {
        const tmp = self.constantCount();
        self.constants.append(value) catch |err| { std.debug.panic("ERROR while allocating space for: {d}", .{value}); };
        return tmp;
    }

    pub fn readConstant(self: *Self, index: usize) f32 {
        return self.constants.items[index];
    }
};