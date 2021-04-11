const std = @import("std");
const my = @import("./my.zig");


pub fn collect_tokens(allocator: *std.mem.Allocator, source: []u8) !std.ArrayList(Token) {
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
        if ( token.token_type == my.TokenType.Eof ) {
            break;
        }
    }

    return tokens;
}

pub fn compile(allocator: *std.mem.Allocator, source: []u8) my.InterpreterError!my.InterpreterResult {
    var scanner = my.Scanner.init(source);
    var parser  = my.Parser.init(allocator, &scanner);
    parser.advance();
    my.parser.expression(&parser);
    parser.consume(my.TokenType.Eof, "Expected end of expression");
    if ( parser.hadError ) {
        return my.InterpreterError.CompileError;
    } else {
        return my.InterpreterResult.Ok;
    }
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