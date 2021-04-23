const std = @import("std");
const my = @import("./my.zig");

pub const Precedence = enum {
    None,
    Assignment,
    Or,
    And,
    Equality,
    Comparison,
    Term,
    Factor,
    Unary,
    Call,
    Primary,
};

pub const Parser = struct {
    const Self = @This();
    scanner: *my.Scanner = undefined,
    previous: my.Token = .{ .token_type = my.TokenType.Error, .data = "Uninit state", .line = 9999 },
    current: my.Token = .{ .token_type = my.TokenType.Error, .data = "Uninit state", .line = 9999 },
    hadError: bool = false,
    panicMode: bool = false,
    builder: my.ChunkBuilder = undefined,

    pub fn init(allocator: *std.mem.Allocator, scanner: *my.Scanner) Self {
        var parser: Parser = Parser {
            .scanner = scanner,
            .builder = my.ChunkBuilder.init(allocator),
        };
        return parser;
    }

    pub fn advance(self: *Self) void {
        self.previous = self.current;
        
        while (true) {
            if ( self.scanner.nextToken() ) | token | {
                self.current = token;
                if (token.token_type != my.TokenType.Error) break;
            }
            self.errorAtCurrent(self.current.data);
        }
    }

    pub fn consume(self: *Self, token_type: my.TokenType, error_message: []const u8) void {
        if (self.current.token_type == token_type) {
            if ( token_type == my.TokenType.Eof ) return;
            self.advance();
            return;
        }
        self.errorAtCurrent(error_message);
    }

    fn errorAt(self: *Self, token: my.Token, error_message: []const u8) void {
        if (self.panicMode) return;

        self.panicMode = true;
        std.debug.print("[line {d}] Error", .{token.line});
        if (token.token_type == my.TokenType.Eof) {
            std.debug.print(" at the end", .{});
        } else if (token.token_type == my.TokenType.Error) {
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
    prefix: ?fn (parser: *Parser) void = null,
    infix: ?fn (parser: *Parser) void = null,
    precedence: Precedence,
};

fn number(parser: *Parser) void {
    my.debug.blockStart("number");
    var val: f32 = std.fmt.parseFloat(f32, parser.previous.data) catch unreachable;
    parser.builder.emitConstant(my.Value.asNumber(val));
    my.debug.blockEnd("number");
}

fn grouping(parser: *Parser) void {
    my.debug.blockStart("grouping");
    expression(parser);
    parser.consume(my.TokenType.RightParen, "Expect ')' after expression");
    my.debug.blockEnd("grouping");
}


pub fn expression(parser: *Parser) void {
    my.debug.blockStart("expression");
    parsePrecedence(parser, Precedence.Assignment);
    my.debug.blockEnd("expression");
}

fn getRule(token_type: my.TokenType) *ParseRule {
    return &global_parsing_rules[@enumToInt(token_type)];
}

fn parsePrecedence(parser: *Parser, prec: Precedence) void {
    parser.advance();
    if ( getRule(parser.previous.token_type).prefix) |prefix_rule| {
        prefix_rule(parser);
    } else {
        parser.errorAtConsumed("Expected expression");
        return;
    }

    while (@enumToInt(prec) <= @enumToInt(getRule(parser.current.token_type).precedence)) {
        parser.advance();
        if (getRule(parser.previous.token_type).infix) |infix_rule| {
            infix_rule(parser);
        }
    }
}

fn binary(parser: *Parser) void {
    my.debug.blockStart("binary");
    var operator_type: my.TokenType = parser.previous.token_type;
    var rule = getRule(operator_type);
    parsePrecedence(parser, @intToEnum(Precedence, @enumToInt(rule.precedence) + 1));

    my.debug.blockEnd("binary");
    switch ( operator_type ) {
        my.TokenType.Plus => { 
            parser.builder.emitOpcode(my.Opcode.Add);
        },
        my.TokenType.Minus => { 
            parser.builder.emitOpcode(my.Opcode.Substract);
        },
        my.TokenType.Star => { 
            parser.builder.emitOpcode(my.Opcode.Multiply);
        },
        my.TokenType.Slash => { 
            parser.builder.emitOpcode(my.Opcode.Divide);
        },
        else => unreachable,
    }
}

fn unary(parser: *Parser) void {
    my.debug.blockStart("unary");
    var operator_type: my.TokenType = parser.previous.token_type;
    expression(parser);

    parsePrecedence(parser, Precedence.Unary);
    my.debug.blockEnd("unary");

    switch (operator_type) {
        my.TokenType.Minus => {
            parser.builder.emitOpcode(my.Opcode.Negate);
        },
        else => {
            return;
        },
    }
}

fn conditional_expression(parser: *Parser) void {

}

var global_parsing_rules = [_]ParseRule{
    .{ .token_type = my.TokenType.LeftParen, .prefix = grouping, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.RightParen, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.LeftBrace, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.RightBrace, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Comma, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Dot, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Minus, .prefix = unary, .infix = binary, .precedence = .Term },
    .{ .token_type = my.TokenType.Plus, .prefix = null, .infix = binary, .precedence = .Term },
    .{ .token_type = my.TokenType.Semicolon, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Slash, .prefix = null, .infix = binary, .precedence = .Factor },
    .{ .token_type = my.TokenType.Star, .prefix = null, .infix = binary, .precedence = .Factor },
    .{ .token_type = my.TokenType.Bang, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.QuestionMark, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Colon, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.BangEqual, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Equal, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.EqualEqual, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Greater, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.GreaterEqual, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Less, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.LessEqual, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Identifier, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.String, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Number, .prefix = number, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.And, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Class, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Else, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.False, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.For, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Fun, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.If, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Nil, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Or, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Print, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Return, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Super, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.This, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.True, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Var, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.While, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Error, .prefix = null, .infix = null, .precedence = .None },
    .{ .token_type = my.TokenType.Eof, .prefix = null, .infix = null, .precedence = .None },
};
