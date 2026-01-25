//! Token definitions and utilities.

/// Defines the different types of tokens.
pub const TokenName = enum {
    None,
    Number,
    Label,
    Register,
    Instruction,
    Jump,
    JumpConditional,
};

/// Represents a token with its type and value.
pub const Token = struct {
    name: TokenName,
    value: [32]u8,
    length: usize,

    line: usize,
    column: usize,

    /// Initializes a new token with the given name and value.
    pub fn init(name: TokenName) Token {
        return Token{
            .name = name,
            .value = [_]u8{0} ** 32,
            .length = 0,

            .line = 0,
            .column = 0,
        };
    }

    /// Appends a character to the token value.
    pub fn appendCharacter(self: *Token, character: u8) bool {
        if (self.length < self.value.len) {
            self.value[self.length] = character;
            self.length += 1;

            return true;
        }

        return false;
    }

    /// Sets the line and column of the token.
    pub fn setPosition(self: *Token, line: usize, column: usize) void {
        self.line = line;
        self.column = column;
    }

    /// Returns the value slice of the token.
    pub fn getValueSlice(self: *const Token) []const u8 {
        return self.value[0..self.length];
    }
};
