const std = @import("std");
const my = @import("./my.zig");

pub fn compile(source: []u8) void {
    var scanner = my.Scanner.init(source);
    std.debug.print("--------- Compiler initialized:\n", .{});
    std.debug.print("===[\x1b[93m {s} \x1b[0m\n", .{source});
    var line : i32 = -1;
    for ( scanner.nextToken() ) | token | {
        if ( token.line != line ) {
            std.debug.print("{d:.4} ", .{token.line});
            line = token.line;
        } else {
            std.debug.print("    | ", .{});
        }
        std.debug.print("Token<{s}>  {s}\n", .{@tagName(token.token_type), @enumToInt(token.data)});
        if ( token.token_type == my.TokenType.TokenEof ) {
            break;
        }
    }
}

