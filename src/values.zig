const std = @import("std");

pub const Value = f32;

pub fn printValue(v: Value) void {
    std.debug.print("CONST: {d:.2}", .{v});
}
