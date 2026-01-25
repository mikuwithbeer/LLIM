//! Lexer module for tokenizing source code files.

const std = @import("std");

const Token = @import("token.zig").Token;

/// Represents errors that can occur during lexing operations.
pub const LexerError = error{
    FailedToReadFile,
    FailedToGetSize,
    OutOfMemory,
    EndOfFile,
    NumberError,
    LabelError,
    RegisterError,
    InstructionError,
    UnknownCharacter,
};

/// Lexer struct for tokenizing source code.
pub const Lexer = struct {
    allocator: std.mem.Allocator,

    source: []u8,
    token: Token,
    tokens: *std.ArrayList(Token),

    cursor: usize,
    line: usize,
    column: usize,

    /// Initializes a new `Lexer` instance by reading the source code from the specified file path.
    /// Must be deinitialized with `deinit` when no longer needed.
    pub fn init(allocator: std.mem.Allocator, path: []const u8, tokens: *std.ArrayList(Token)) LexerError!Lexer {
        const file = std.fs.cwd().openFile(path, .{ .mode = .read_only }) catch {
            return LexerError.FailedToReadFile;
        };
        defer file.close();

        const file_size = file.getEndPos() catch {
            return LexerError.FailedToGetSize;
        };

        const source = file.readToEndAlloc(allocator, file_size) catch {
            return LexerError.FailedToReadFile;
        };

        return Lexer{
            .allocator = allocator,

            .source = source,
            .token = Token.init(.None),
            .tokens = tokens,

            .cursor = 0,
            .line = 1,
            .column = 1,
        };
    }

    /// Returs the current character without advancing the cursor.
    pub fn currentCharacter(self: *const Lexer) LexerError!u8 {
        if (self.cursor == self.source.len) {
            return '\n'; // small hack to fix EOF handling
        } else if (self.cursor > self.source.len) {
            return LexerError.EndOfFile;
        }

        return self.source[self.cursor];
    }

    /// Collects the current character and advances the cursor.
    pub fn collectCharacter(self: *Lexer) LexerError!u8 {
        const current_char = try self.currentCharacter();
        self.cursor += 1;

        if (current_char == '\n') {
            self.line += 1;
            self.column = 1;
        } else {
            self.column += 1;
        }

        return current_char;
    }

    /// Main loop that processes the source code and generates tokens.
    pub fn loop(self: *Lexer) LexerError!void {
        while (true) {
            const character = self.collectCharacter() catch |err| {
                if (err == LexerError.EndOfFile) {
                    break;
                } else {
                    return err;
                }
            };

            try switch (self.token.name) {
                .None => self.determineToken(character),
                .Number => self.collectNumber(character),
                .Register => self.collectRegister(character),
                .Instruction => self.collectInstruction(character),
                .Label, .Jump, .JumpConditional => self.collectLabel(character),
            };
        }
    }

    /// Deinitializes the `Lexer`, freeing its resources.
    pub fn deinit(self: *Lexer) void {
        self.allocator.free(self.source);
    }

    /// Appends the current token to the token list and resets it.
    fn appendToken(self: *Lexer) LexerError!void {
        self.token.setPosition(self.line, self.column);
        self.tokens.append(self.allocator, self.token) catch {
            return LexerError.OutOfMemory;
        };

        self.token = Token.init(.None);
    }

    /// Determines the type of token based on the current character.
    fn determineToken(self: *Lexer, character: u8) LexerError!void {
        switch (character) {
            '0'...'9' => {
                self.token.name = .Number;
                try self.collectNumber(character);
            },
            ':' => self.token.name = .Label,
            '@' => self.token.name = .Register,
            '.' => self.token.name = .Instruction,
            '^' => self.token.name = .Jump,
            '?' => self.token.name = .JumpConditional,
            '#' => try self.collectComment(),
            ' ', '\t', '\n', '\r' => {
                // ignore whitespace
            },
            else => return LexerError.UnknownCharacter,
        }
    }

    /// Collects characters for a number token.
    fn collectNumber(self: *Lexer, character: u8) LexerError!void {
        switch (character) {
            '0'...'9' => {
                if (!self.token.appendCharacter(character)) {
                    return LexerError.OutOfMemory;
                }
            },
            '\'' => {
                // ignore inside numbers
            },
            ' ', '\t', '\n', '\r' => try self.appendToken(),
            else => return LexerError.NumberError,
        }
    }

    /// Collects characters for a label token.
    fn collectLabel(self: *Lexer, character: u8) LexerError!void {
        switch (character) {
            'A'...'Z', '_' => {
                if (!self.token.appendCharacter(character)) {
                    return LexerError.OutOfMemory;
                }
            },
            ' ', '\t', '\n', '\r' => try self.appendToken(),
            else => return LexerError.LabelError,
        }
    }

    /// Collects characters for a register token.
    fn collectRegister(self: *Lexer, character: u8) LexerError!void {
        switch (character) {
            'A'...'F', 'I' => {
                if (!self.token.appendCharacter(character)) {
                    return LexerError.OutOfMemory;
                }

                try self.appendToken();
            },
            else => return LexerError.RegisterError,
        }
    }

    /// Collects characters for an instruction token.
    fn collectInstruction(self: *Lexer, character: u8) LexerError!void {
        switch (character) {
            'a'...'z', '_' => {
                if (!self.token.appendCharacter(character)) {
                    return LexerError.OutOfMemory;
                }
            },
            ' ', '\t', '\n', '\r' => try self.appendToken(),
            else => return LexerError.InstructionError,
        }
    }

    /// Ignores a comment until the end of the line.
    fn collectComment(self: *Lexer) LexerError!void {
        while (true) {
            const character = try self.collectCharacter();

            if (character == '\n') {
                break;
            }
        }
    }
};
