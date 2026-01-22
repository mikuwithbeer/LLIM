//! Assembler module for assembling instructions into machine code.

pub const std = @import("std");

pub const Bytecode = @import("bytecode.zig").Bytecode;
pub const Token = @import("token.zig").Token;

/// Errors that can occur during assembly.
pub const AssemblerError = error{
    OutOfMemory,
    FailedToWriteFile,
    WaitingForInstruction,
    WaitingForNumberOrRegister,
    WaitingForLabel,
    LabelAlreadyDefined,
    LabelNotFound,
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
    bytes: usize,

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
            .bytes = 0,

            .labels = .init(allocator),
            .tokens = tokens,

            .argc = 0,
            .state = .Idle,
        };
    }

    /// Prepares the assembler.
    pub fn prepare(self: *Assembler) AssemblerError!void {
        for (self.tokens.*.items) |token| {
            switch (token.name) {
                .Instruction => self.bytes += 1,
                .Label => {
                    if (self.labels.contains(token.value)) {
                        return AssemblerError.LabelAlreadyDefined;
                    }

                    self.labels.put(token.value, self.bytes) catch {
                        return AssemblerError.OutOfMemory;
                    };
                },
                .Number => self.bytes += 2,
                .Register => self.bytes += 1,
                .Jump => self.bytes += 5,
                .None => {
                    // ignore
                },
            }
        }
    }

    /// Assembles the tokens into bytecode.
    pub fn loop(self: *Assembler) AssemblerError!void {
        for (self.tokens.*.items) |token| {
            switch (self.state) {
                .Idle => {
                    switch (token.name) {
                        .Instruction => {
                            self.state = .Instruction;
                            try self.handleInstruction(token);
                        },
                        .Label => {
                            // ignore labels in this pass
                        },
                        .Jump => {
                            try self.handleJump(token);
                        },
                        else => return AssemblerError.WaitingForInstruction,
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

    /// Writes the assembled bytecode to a file.
    pub fn writeFile(self: *Assembler, path: []const u8) AssemblerError!void {
        const file = std.fs.cwd().createFile(path, .{}) catch {
            return AssemblerError.FailedToWriteFile;
        };

        defer file.close();

        file.writeAll(self.bytecode.values.items) catch {
            return AssemblerError.FailedToWriteFile;
        };
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

    /// Handles a jump token by calculating and appending its bytecode.
    fn handleJump(self: *Assembler, token: Token) AssemblerError!void {
        if (self.labels.get(token.value)) |position| {
            const high = @as(u8, @intCast((position >> 24) & 0xFF));
            const mid_high = @as(u8, @intCast((position >> 16) & 0xFF));
            const mid_low = @as(u8, @intCast((position >> 8) & 0xFF));
            const low = @as(u8, @intCast(position & 0xFF));

            try self.appendByte(0x30);
            try self.appendByte(high);
            try self.appendByte(mid_high);
            try self.appendByte(mid_low);
            try self.appendByte(low);
        } else {
            return AssemblerError.LabelNotFound;
        }

        self.state = .Idle;
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
        } else if (std.mem.eql(u8, value, "add_register")) {
            try self.appendByte(0x05);
            self.argc = 3;
        } else if (std.mem.eql(u8, value, "sub_register")) {
            try self.appendByte(0x06);
            self.argc = 3;
        } else if (std.mem.eql(u8, value, "mul_register")) {
            try self.appendByte(0x07);
            self.argc = 3;
        } else if (std.mem.eql(u8, value, "div_register")) {
            try self.appendByte(0x08);
            self.argc = 3;
        } else if (std.mem.eql(u8, value, "mod_register")) {
            try self.appendByte(0x09);
            self.argc = 3;
        } else if (std.mem.eql(u8, value, "push_register")) {
            try self.appendByte(0x0A);
            self.argc = 1;
        } else if (std.mem.eql(u8, value, "sleep_seconds")) {
            try self.appendByte(0x60);
            self.state = .Idle;
        } else if (std.mem.eql(u8, value, "sleep_milliseconds")) {
            try self.appendByte(0x61);
            self.state = .Idle;
        } else if (std.mem.eql(u8, value, "exit")) {
            try self.appendByte(0x62);
            self.state = .Idle;
        } else if (std.mem.eql(u8, value, "get_mouse_position")) {
            try self.appendByte(0x90);
            self.state = .Idle;
        } else if (std.mem.eql(u8, value, "set_mouse_position")) {
            try self.appendByte(0x91);
            self.state = .Idle;
        } else if (std.mem.eql(u8, value, "mouse_event")) {
            try self.appendByte(0x92);
            self.argc = 1;
        } else if (std.mem.eql(u8, value, "keyboard_event")) {
            try self.appendByte(0x93);
            self.argc = 1;
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
