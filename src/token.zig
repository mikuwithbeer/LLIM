//! Token definitions and utilities.

/// Defines the different types of tokens.
pub const TokenName = enum {
    None,
    Number,
    Label,
    Register,
    Instruction,
    Jump,
};

/// Represents a token with its type and value.
pub const Token = struct {
    name: TokenName,
    value: [32]u8,
    index: usize,

    /// Initializes a new token with the given name and value.
    pub fn init(name: TokenName) Token {
        return Token{
            .name = name,
            .value = [_]u8{0} ** 32,
            .index = 0,
        };
    }

    /// Appends a character to the token value.
    pub fn appendCharacter(self: *Token, character: u8) bool {
        if (self.index < self.value.len) {
            self.value[self.index] = character;
            self.index += 1;

            return true;
        }

        return false;
    }
};
