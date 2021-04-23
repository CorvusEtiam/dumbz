const std = @import("std");

// pub const Value = f32;


pub fn printValue(value: Value) void {
    switch ( value ) {
        .vt_nil => std.debug.print("nil", .{}),
        .vt_boolean => std.debug.print("BOOL: {}", .{ value.vt_boolean }),
        .vt_number => std.debug.print("NUMBER: {d:.2}", .{value.vt_number}),
    }
}

// Using ValueType with vt prefix
pub const ValueType = enum {
    vt_boolean,
    vt_nil,
    vt_number,
};

pub const Value = union(enum) {
    vt_boolean : bool,
    vt_number: f32,
    vt_nil: void,

    pub fn asNumber(value: f32) Value {
        return .{
            .vt_number = value,
        };
    }

    pub fn asNil() Value {
        return .{
            .vt_nil = void 
        };
    }
    
    pub fn asBool(value: bool) Value {
        return .{
            .vt_boolean = value
        };
    }

    pub fn boolean(v: *Value) bool {
        return v.vt_boolean;
    }
    pub fn number(v: *Value) f32 {
        return v.vt_number;
    }
    pub fn isNil(self: Value) bool {
        switch ( self ) {
            Value.vt_nil => return true,
            else => return false,
        }
    }
    pub fn isNumber(self: Value) bool {
        switch ( self ) {
            Value.vt_number => return true,
            else => return false,
        }
    }
    pub fn isBoolean(self: Value) bool {
        switch ( self ) {
            Value.vt_boolean => return true,
            else => return false,
        }
    }
};

