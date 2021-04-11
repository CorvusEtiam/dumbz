const std = @import("std");

pub const TokenType = enum(u8) {
// Single-char
LeftParen, RightParen, LeftBrace, RightBrace, Comma, Dot, Minus, Plus, Semicolon, Slash, Star, Bang,
// One or two
BangEqual, Equal, EqualEqual, Greater, GreaterEqual, Less, LessEqual,
// Literals
Identifier, String, Number,
// Keywords
And, Class, Else, False, For, Fun, If, Nil, Or, Print, Return, Super, This, True, Var, While,
// Tokenization errors
Error, Eof
};


/// Check if char is part of number
fn is_digit(char: u8) bool {
    return char >= '0' and char <= '9'; 
}

fn is_alpha(char: u8) bool {
    return (char >= 'a' and char <= 'z') or (char >= 'A' and char <= 'Z') or char == '_';
}

pub const Token = struct {
    token_type: TokenType,
    data: [] const u8,
    line: usize,

    pub fn create(scanner: *Scanner, token_type: TokenType) Token {
        return Token {
            .token_type = token_type,
            .data = scanner.code[scanner.start..scanner.current],
            .line = scanner.line,
        };
    }

    pub fn err(scanner: *Scanner, message: [] const u8) Token {
        return Token {
            .token_type = TokenType.Error,
            .data = message,
            .line = scanner.line,
        };
    }
};

pub const Scanner = struct {
    start: usize,
    current: usize,
    line: usize,
    code: []u8,
    eof: bool =  false,

    pub fn init(code: []u8) Scanner {
        return Scanner {
            .start = 0,
            .current = 0,
            .line = 1,
            .code = code,
        };
    } 

    fn isEof(self: *Scanner) bool {
        return self.current == self.code.len;
    }

    fn match(self: *Scanner, expected: u8) bool {
        if ( self.isEof() ) return false;
        if ( self.code[self.current] != expected ) return false;

        self.current += 1;
        return true;
    }

    fn peek(self: *Scanner) u8 {
        if ( self.code.len == self.current ) return 0;
        return self.code[self.current];
    }
    
    fn peekNext(self: *Scanner) u8 {
        return if ( self.code.len == self.current + 1 ) 0 else self.code[self.current + 1];
    }


    fn skipWhitespace(self: *Scanner) void {
        while ( true ) {
            var c: u8 = self.peek();
            switch ( c ) {
                ' ', '\r', '\t', '\n' => {
                    _ = self.advance();
                    break;
                },
                '/' => {
                    if ( self.peekNext() == '/' ) {
                        while ( self.peek() != '\n' and !self.isEof()) { _ = self.advance(); }
                    } else {
                        return;
                    }
                },
                else => return,
            }
        }
    }

    pub fn nextToken(self: *Scanner) Token {
        self.skipWhitespace();
        self.start = self.current;
        if ( self.isEof() ) {
            if (self.eof) { 
                return Token.err(self, "You keep on polling bruh!!!"); 
            } else {
                self.eof = true;
                return Token.create(self, TokenType.Eof);
            }
        }
        
        var byte : u8 = self.advance();
        if ( is_alpha(byte) ) {
            return self.lexIdentifier();
        }

        if ( is_digit(byte) ) {
            return self.lexNumber();
        }

        switch ( byte ) {
            '(' => return Token.create(self, TokenType.LeftParen),
            ')' => return Token.create(self, TokenType.RightParen),
            '{' => return Token.create(self, TokenType.LeftBrace),
            '}' => return Token.create(self, TokenType.RightBrace),
            '.' => return Token.create(self, TokenType.Dot),
            ',' => return Token.create(self, TokenType.Comma),
            ';' => return Token.create(self, TokenType.Semicolon),
            '+' => return Token.create(self, TokenType.Plus),
            '-' => return Token.create(self, TokenType.Minus),
            '*' => return Token.create(self, TokenType.Star),
            '/' => return Token.create(self, TokenType.Slash),
            '!' => {
                return Token.create(self, if (self.match('=')) TokenType.BangEqual else TokenType.Bang);
            },
            '=' => {
                return Token.create(self, if (self.match('=')) TokenType.EqualEqual else TokenType.Equal);
            },
            '>' => {
                return Token.create(self, if (self.match('=')) TokenType.GreaterEqual else TokenType.Greater);    
            },
            '<' => {
                return Token.create(self, if (self.match('=')) TokenType.LessEqual else TokenType.Less);
            },
            '\n' => {
                self.line += 1;
                return self.nextToken();
            },
            '"' => {
                return self.lexString();
            },
            else => return Token.create(self, TokenType.Number),
        }

        return Token.err(self, "Unexpected character");
    }

    fn lexString(self: *Scanner) Token {
        while ( self.peek() != '"' and !self.isEof() ) {
            if ( self.peek() == '\n' ) { 
                self.line += 1;
            }
            _ = self.advance();
        }

        if ( self.isEof() ) return Token.err(self, "Unterminated string");
        _ = self.advance();
        return Token.create(self, TokenType.String);
    }

    fn lexNumber(self: *Scanner) Token {
        while ( is_digit(self.peek()) ) { _ = self.advance(); }
        
        if ( self.isEof() ) {
            return Token.create(self, TokenType.Number); 
        }
        
        if ( self.peek() == '.' and is_digit(self.peekNext()) ) {
            _ = self.advance(); // skip '.'
            
            while ( is_digit(self.peek()) ) { _ = self.advance(); }
        }
        
        return Token.create(self, TokenType.Number);
    }

    fn lexIdentifier(self: *Scanner) Token {
        while ( is_alpha(self.peek()) or is_digit(self.peek()) ) _ = self.advance();

        return Token.create(self, self.lexIdentifierType());
    }
    
    fn checkKeyword(self: *Scanner, rest: []const u8, token_type: TokenType) TokenType {
        var result : TokenType = undefined;

        if ( std.mem.startsWith(u8, self.code[self.current..], rest) ) {
            self.current += rest.len;
            result = token_type;
        } else {
            result = TokenType.Identifier;
        }
        // advance current index to the end of keyword
        return result;
    }

    fn lexIdentifierType(self: *Scanner) TokenType {
        switch ( self.peek() ) {
            'a' => return self.checkKeyword("and", TokenType.And),
            'c' => return self.checkKeyword("class", TokenType.Class),
            'e' => return self.checkKeyword("else", TokenType.Else),
            'i' => return self.checkKeyword("if", TokenType.If),
            'n' => return self.checkKeyword("nil", TokenType.Nil),
            'o' => return self.checkKeyword("or", TokenType.Or),
            'p' => return self.checkKeyword("print", TokenType.Print),
            'r' => return self.checkKeyword("return", TokenType.Return),
            's' => return self.checkKeyword("super", TokenType.Super),
            'v' => return self.checkKeyword("var", TokenType.Var),
            'w' => return self.checkKeyword("while", TokenType.While),
            'f' => {
                if ( self.code.len - self.current > 1 ) {
                    switch ( self.peekNext() ) {
                        'a' => return self.checkKeyword("false", TokenType.False),
                        'o' => return self.checkKeyword("for", TokenType.False),
                        'u' => return self.checkKeyword("fun", TokenType.Fun),
                        else => return TokenType.Identifier,
                    }
                } else {
                    return TokenType.Identifier;
                }
            },
            't' => {
                if ( self.code.len - self.current > 1 ) {
                    switch ( self.peekNext() ) {
                        'h' => return self.checkKeyword("this", TokenType.This),
                        'r' => return self.checkKeyword("true", TokenType.True),
                        else => return TokenType.Identifier,
                    }
                }
            },
            else => { return TokenType.Identifier; }
        }

        unreachable;
    }

    fn advance(self: *Scanner) u8 {
        if ( self.isEof() ) return 0;
        self.current += 1;
        return self.code[self.current - 1];
    }
};