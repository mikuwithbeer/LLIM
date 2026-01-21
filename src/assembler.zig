//! Assembler module for assembling instructions into machine code.

pub const std = @import("std");

pub const Bytecode = @import("bytecode.zig").Bytecode;
pub const Token = @import("token.zig").Token;

/// Errors that can occur during assembly.
pub const AssemblerError = error{
    OutOfMemory,
    FailedToReadFile,
    WaitingForInstructionOrLabel,
    WaitingForNumberOrRegister,
    LabelAlreadyDefined,
    UnknownInstruction,
    InvalidNumber,
    InvalidRegister,
};

/// Represents the state of the assembler.
pub const AssemblerState = enum {
    Idle,
    Instruction,
};

pub const Assembler = struct {
    allocator: std.mem.Allocator,

    bytecode: Bytecode,
    labels: std.AutoHashMap([32]u8, usize),
    tokens: *std.ArrayList(Token),

    argc: usize,
    state: AssemblerState,

    /// Initializes a new `Assembler` instance.
    pub fn init(allocator: std.mem.Allocator, tokens: *std.ArrayList(Token)) AssemblerError!Assembler {
        const bytecode = Bytecode.init(allocator) catch {
            return AssemblerError.OutOfMemory;
        };

        return Assembler{
            .allocator = allocator,

            .bytecode = bytecode,
            .labels = .init(allocator),
            .tokens = tokens,

            .argc = 0,
            .state = .Idle,
        };
    }

    /// Assembles the tokens into bytecode.
    pub fn loop(self: *Assembler) AssemblerError!void {
        for (self.tokens.*.items) |token| {
            switch (self.state) {
                .Idle => {
                    switch (token.name) {
                        .Label => try self.handleLabel(token),
                        .Instruction => {
                            self.state = .Instruction;
                            try self.handleInstruction(token);
                        },
                        else => return AssemblerError.WaitingForInstructionOrLabel,
                    }
                },
                .Instruction => {
                    switch (token.name) {
                        .Number => try self.handleNumber(token),
                        .Register => try self.handleRegister(token),
                        else => return AssemblerError.WaitingForNumberOrRegister,
                    }

                    self.argc -= 1;
                    if (self.argc == 0) {
                        self.state = .Idle;
                    }
                },
            }
        }
    }

    /// Deinitializes the assembler, freeing its resources.
    pub fn deinit(self: *Assembler) void {
        self.labels.deinit();
        self.bytecode.deinit();
    }

    /// Appends a byte to the bytecode.
    fn appendByte(self: *Assembler, byte: u8) AssemblerError!void {
        self.bytecode.append(byte) catch {
            return AssemblerError.OutOfMemory;
        };
    }

    /// Handles a label token by adding it to the label map.
    fn handleLabel(self: *Assembler, token: Token) AssemblerError!void {
        if (self.labels.contains(token.value)) {
            return AssemblerError.LabelAlreadyDefined;
        }

        self.labels.put(token.value, self.bytecode.cursor) catch {
            return AssemblerError.OutOfMemory;
        };
    }

    /// Handles an instruction token by appending its bytecode.
    fn handleInstruction(self: *Assembler, token: Token) AssemblerError!void {
        const value = token.value[0..token.index];
        if (std.mem.eql(u8, value, "noop")) {
            try self.appendByte(0x00);
            self.state = .Idle;
        } else if (std.mem.eql(u8, value, "push_const")) {
            try self.appendByte(0x01);
            self.argc = 1;
        } else if (std.mem.eql(u8, value, "pop_const")) {
            try self.appendByte(0x02);
            self.argc = 1;
        } else if (std.mem.eql(u8, value, "set_register")) {
            try self.appendByte(0x03);
            self.argc = 2;
        } else if (std.mem.eql(u8, value, "copy_register")) {
            try self.appendByte(0x04);
            self.argc = 2;
        } else if (std.mem.eql(u8, value, "debug")) {
            try self.appendByte(0xFF);
            self.state = .Idle;
        } else {
            return AssemblerError.UnknownInstruction;
        }
    }

    /// Handles a number token by parsing and appending its bytecode.
    fn handleNumber(self: *Assembler, token: Token) AssemblerError!void {
        const value = token.value[0..token.index];
        const number = std.fmt.parseInt(u16, value, 10) catch {
            return AssemblerError.InvalidNumber;
        };

        const high = @as(u8, @intCast((number >> 8) & 0xFF));
        const low = @as(u8, @intCast(number & 0xFF));

        try self.appendByte(high);
        try self.appendByte(low);
    }

    /// Handles a register token by appending its bytecode.
    fn handleRegister(self: *Assembler, token: Token) AssemblerError!void {
        switch (token.value[0]) {
            'A' => try self.appendByte(0x00),
            'B' => try self.appendByte(0x01),
            'C' => try self.appendByte(0x02),
            'D' => try self.appendByte(0x03),
            'E' => try self.appendByte(0x04),
            'F' => try self.appendByte(0x05),
            'I' => try self.appendByte(0x06),
            else => return AssemblerError.InvalidRegister,
        }
    }
};
