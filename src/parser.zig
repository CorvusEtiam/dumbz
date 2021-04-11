const std = @import("std");
const my = @import("./my.zig");

pub const Precision = enum {
    None,
    Term,
    Factor,
};

// Scanner > Parser > Emitter


pub const Parser = struct {
    const Self = @This();
    scanner: *my.Scanner = null,
    previous: my.Token = undefined,
    current: my.Token = undefined,
    hadError: bool = false,
    panicMode: bool = false,
    builder: my.ChunkBuilder = null,

    pub fn init(allocator: *std.mem.Allocator, scanner: *my.Scanner) Self {
        var parser: Parser = Parser {
            .scanner = scanner,
            .builder   = null,
        };
        parser.builder = my.ChunkBuilder.init(allocator, &parser);
        return parser;
    }

    pub fn advance(self: *Self) void {
        self.previous = self.current;
        while (true) {
            self.current = self.scanner.nextToken() orelse unreachable;
            if ( self.current.token_type != my.TokenType.TokenError ) break;

            self.errorAtCurrent(self.current.data);
        }
    }

    pub fn expression(self: *Self) void { 

    }

    pub fn consume(self: *Self, token_type: my.TokenType, error_message: []const u8) void { 
        if ( self.current.token_type == token_type ) {
            self.advance();
            return; 
        } 
        self.errorAtCurrent(error_message);
    }

    fn errorAt(self: *Self, token: my.Token, error_message: []const u8) void { 
        if ( self.panicMode ) return;

        self.panicMode = true;
        std.debug.print("[line {d}] Error", .{token.line});
        if ( token.token_type == my.TokenType.TokenEof ) {
            std.debug.print(" at the end", .{});
        } else if ( token.token_type == my.TokenType.TokenError ) {
            // nop
        } else {
            std.debug.print("at {s}", .{token.data});
        }
        std.debug.print(" : {s}\n", .{error_message});
        self.hadError = true;
    }

    fn errorAtCurrent(self: *Self, error_message: []const u8) void { 
        self.errorAt(self.current, error_message);
    }

    fn errorAtConsumed(self: *Self, error_message: []const u8) void { 
        self.errorAt(self.previous, error_message);
    }

};

pub const ParseRule = struct {
    token_type: my.TokenType,
    prefix: ?fn(parser: *Parser) void = null,
    infix: ?fn(parser: *Parser) void = null,
    precision : Precision,
};

const global_parsing_rules = []ParseRule {
    .{ .token_type = my.TokenType.TokenLeftParen, .prefix = null, .infix = null, .precision = .None }
};
