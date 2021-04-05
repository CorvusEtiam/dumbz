const std = @import("std");

pub const TokenType = enum {
// Single-char
TokenLeftParen, TokenRightParen, TokenLeftBrace, TokenRightBrace, TokenComma, TokenDot, TokenMinus, TokenPlus, TokenSemicolon, TokenSlash, TokenStar, TokenBang,
// One or two
TokenBangEqual, TokenEqual, TokenEqualEqual, TokenGreater, TokenGreaterEqual, TokenLess, TokenLessEqual,
// Literals
TokenIdentifier, TokenString, TokenNumber,
// Keywords
TokenAnd, TokenClass, TokenElse, TokenFalse, TokenFor, TokenFun, TokenIf, TokenNil, TokenOr, TokenPrint, TokenReturn, TokenSuper, TokenThis, TokenTrue, TokenVar, TokenWhile,
// Tokenization errors
TokenError, TokenEof
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
    data: []u8,
    line: usize,

    pub fn create(scanner: Scanner, token_type: TokenType) Token {
        return Token {
            .token_type = token,
            .data = scanner.code[scanner.start..scanner.current],
            .line = scanner.line,
        };
    }

    pub fn err(scanner: Scanner, message: []const u8) Token {
        return Token {
            .token_type = TokenType.TokenError,
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
        return self.code[self.current];
    }
    
    fn peekNext(self: *Scanner) u8 {
        return if ( self.isEof() ) '\0' else self.code[self.current + 1];
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
                _ => return,
            }
        }
    }

    pub fn nextToken(self: *Scanner) ?Token {
        self.skipWhitespace();
        self.start = self.current;
        if ( self.isEof() ) {
            if (self.eof) { 
                return null; 
            } else {
                self.eof = true;
                return Token.create(self, TokenType.TokenEof);
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
            '(' => return Token.create(self, TokenType.TokenLeftParen),
            ')' => return Token.create(self, TokenType.TokenRightParen),
            '{' => return Token.create(self, TokenType.TokenLeftBrace),
            '}' => return Token.create(self, TokenType.TokenRightBrace),
            '.' => return Token.create(self, TokenType.TokenDot),
            ',' => return Token.create(self, TokenType.TokenComma),
            ';' => return Token.create(self, TokenType.TokenSemicolon),
            '+' => return Token.create(self, TokenType.TokenPlus),
            '-' => return Token.create(self, TokenType.TokenMinus),
            '*' => return Token.create(self, TokenType.TokenStar),
            '/' => return Token.create(self, TokenType.TokenSlash),
            '!' => {
                return Token.create(self, if (self.match('=')) TokenType.TokenBangEqual else TokenType.TokenBang);
            },
            '=' => {
                return Token.create(self, if (self.match('=')) TokenType.TokenEqualEqual else TokenType.TokenEqual);
            },
            '>' => {
                return Token.create(self, if (self.match('=')) TokenType.TokenGreaterEqual else TokenType.TokenGreater);    
            },
            '<' => {
                return Token.create(self, if (self.match('=')) TokenType.TokenLessEqual else TokenType.TokenLess);
            },
            '\n' => {
                self.line += 1;
                return self.nextToken();
            },
            '"' => {
                return self.lexString();
            },
            _   => return Token.create(self, TokenType.TokenNumber),
        }

        return Token.err(self, "Unexpected character");
    }

    fn lexString(self: *Scanner) ?Token {
        while ( self.peek() != '"' and !self.isEof() ) {
            if ( self.peek() == '\n' ) { 
                self.line += 1;
            }
            self.advance();
        }

        if ( self.isEof() ) return Token.err(self, "Unterminated string");
        self.advance();
        return Token.create(self, TokenType.TokenString);
    }

    fn lexNumber(self: *Scanner) ?Token {
        while ( is_digit(self.peek()) ) self.advance();
        
        if ( self.peek() == '.' and is_digit(self.peekNext()) ) {
            self.advance(); // skip '.'
            
            while ( is_digit(self.peek()) ) self.advance();
        }
        
        return Token.create(self, TokenType.TokenNumber);
    }

    fn lexIdentifier(self: *Scanner) ?Token {
        while ( is_alpha(self.peek()) || is_digit(self.peek()) ) self.advance();

        return Token.create(self.lexIdentifierType());
    }
    
    fn checkKeyword(self: *Scanner, rest: []u8, token_type: TokenType) TokenType {
        var result : TokenType = undefined;

        if ( std.mem.startsWith(u8, self.code[self.current..], rest) ) {
            self.current += rest.len;
            result = token_type;
        } else {
            result = TokenType.TokenIdentifier;
        }
        // advance current index to the end of keyword
        return result;
    }

    fn lexIdentifierType(self: *Scanner) TokenType {
        switch ( self.peek() ) {
            'a' => return self.checkKeyword("and", TokenType.TokenAnd),
            'c' => return self.checkKeyword("class", TokenType.TokenClass),
            'e' => return self.checkKeyword("else", TokenType.TokenElse),
            'i' => return self.checkKeyword("if", TokenType.TokenIf),
            'n' => return self.checkKeyword("nil", TokenType.TokenNil),
            'o' => return self.checkKeyword("or", TokenType.TokenOr),
            'p' => return self.checkKeyword("print", TokenType.TokenPrint),
            'r' => return self.checkKeyword("return", TokenType.TokenReturn),
            's' => return self.checkKeyword("super", TokenType.TokenSuper),
            'v' => return self.checkKeyword("var", TokenType.TokenVar),
            'w' => return self.checkKeyword("while", TokenType.TokenWhile),
            'f' => {
                if ( self.code.len - self.current > 1 ) {
                    switch ( self.peekNext() ) {
                        'a' => return self.checkKeyword("false", TokenType.TokenFalse),
                        'o' => return self.checkKeyword("for", TokenType.TokenFalse),
                        'u' => return self.checkKeyword("fun", TokenType.TokenFun),
                        _ => return TokenType.TokenIdentifier,
                    }
                }
            },
            't' => {
                if ( self.code.len - self.current > 1 ) {
                    switch ( self.peekNext() ) {
                        'h' => return self.checkKeyword("this", TokenType.TokenThis),
                        'r' => return self.checkKeyword("true", TokenType.TokenTrue),
                        _ => return TokenType.TokenIdentifier,
                    }
                }
            }
        }

        return TokenType.TokenIdentifier;
    }

    fn advance(self: *Scanner) void {
        if ( !self.isEof() ) self.current += 1;
        return self.code[self.current - 1];
    }
};