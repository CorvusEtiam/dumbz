const std = @import("std");
const print = std.debug.print;

const Allocator = @import("std").mem.Allocator;
const ArrayList = std.ArrayList;

pub const Chunk = struct {
    const Self = @This();
    code: ArrayList(u8),
    count: usize,
    constants: ArrayList(f32),
    constants_count: usize,

    pub fn init(allocator: *Allocator) Chunk {
        return .{
            .code = ArrayList(u8).init(allocator),
            .count = 0,
            .constants = ArrayList(f32).init(allocator),
            .constants_count = 0,
        };
    }

    pub fn deinit(self: *Self) void {
        self.code.deinit();
        self.constants.deinit();
    }

    pub fn write(self: *Self, byte: u8) void {
        self.code.append(byte) catch |err| { std.debug.panic("ERROR while allocating space for: {d}", .{byte}); };
        self.count += 1;
    }

    pub fn read(self: *Self, index: usize) u8 {
        std.debug.assert(index < self.count);
        return self.code.items[index];
    }

    pub fn writeConstant(self: *Self, value: f32) usize {
        self.constants.append(value) catch |err| { std.debug.panic("ERROR while allocating space for: {d}", .{value}); };
        const tmp = self.constants_count;
        self.constants_count += 1;
        return tmp;
    }

    pub fn readConstant(self: *Self, index: usize) f32 {
        return self.constants.items[index];
    }
};