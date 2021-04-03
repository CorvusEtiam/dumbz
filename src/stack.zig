const std = @import("std");

const ArrayList = std.ArrayList;

pub fn Stack(comptime T: type) type {
    return struct {
        stack: ArrayList(T),

        const Self = @This();

        pub fn init(allocator: *std.mem.Allocator) Self {
            return .{
                .stack = ArrayList(T).init(allocator)
            };
        }

        pub fn push(self: *Self, val: T) void {
            try self.stack.append(val);
        }

        pub fn pop(self: *Self) !T {
            return self.stack.pop();
        } 

        pub fn top() ?T {
            if ( self.stack.items.len == 0 ) {
                return null;
            } else {
                return self.stack.items[self.stack.items.len - 1];
            }
        }

        pub fn count(self: *Self) usize {
            return self.stack.items.len;
        }

        pub fn isEmpty(self: *Self) bool {
            return self.size() == 0;
        }
    };
}