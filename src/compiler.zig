const std = @import("std");
const my = @import("./my.zig");

pub const Precision = enum {
    None,
    Term,
    Factor,
};

pub const Parser = struct { };

pub const ParseRule = struct {
    token_type: my.TokenType,
    prefix: ?fn(parser: *Parser) void = null,
    infix: ?fn(parser: *Parser) void = null,
    precision : Precision,
};

pub const global_parsing_rules = []ParseRule {
    .{ .token_type = my.TokenType.TokenLeftParen, .prefix = null, .infix = null, .precision = .None }
};


pub fn compile(allocator: *std.mem.Allocator, source: []u8) !std.ArrayList(Token) {
    var scanner = my.Scanner.init(source);
    var tokens = std.ArrayList(my.Token).init(allocator);

    std.debug.print("--------- Compiler initialized:\n", .{});
    std.debug.print("===[\x1b[93m {s} \x1b[0m\n", .{source});
    var line : i32 = -1;
    for ( scanner.nextToken() ) | token | {
        tokens.append(token) catch unreachable;
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

    return tokens;
}

pub fn interpret(allocator: *std.mem.Allocator, vm: *my.VirtualMachine, source: []u8) my.InterpreterError!my.InterpreterResult {
    var chunk = my.Chunk.init(allocator);
    defer chunk.deinit();
    
    var tokens = compile(allocator, source) catch | err | {
        chunk.deinit();
        return my.InterpreterError.CompileError;
    };
    
    vm.chunk = &chunk;
    vm.ip = 0;
    return try vm.run();
} 