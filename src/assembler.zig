//! Assembler module for turning instructions into bytecode.

const std = @import("std");

const Bytecode = @import("bytecode.zig").Bytecode;
const CommandID = @import("command.zig").CommandID;
const RegisterName = @import("register.zig").RegisterName;
const Token = @import("token.zig").Token;

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

/// Assembler struct for converting tokens into bytecode.
pub const Assembler = struct {
    allocator: std.mem.Allocator,

    bytecode: Bytecode,
    bytes: usize,
    line: usize,
    column: usize,

    labels: std.AutoHashMap([32]u8, usize),
    tokens: *const std.ArrayList(Token),

    argc: usize,
    state: AssemblerState,

    /// Initializes a new `Assembler` instance.
    /// Must be deinitialized with `deinit` when no longer needed.
    pub fn init(allocator: std.mem.Allocator, tokens: *const std.ArrayList(Token)) AssemblerError!Assembler {
        const bytecode = Bytecode.init(allocator) catch {
            return AssemblerError.OutOfMemory;
        };

        return Assembler{
            .allocator = allocator,

            .bytecode = bytecode,
            .bytes = 0,
            .line = 1,
            .column = 1,

            .labels = .init(allocator),
            .tokens = tokens,

            .argc = 0,
            .state = .Idle,
        };
    }

    /// Prepares the assembler.
    pub fn prepare(self: *Assembler) AssemblerError!void {
        for (self.tokens.items) |token| {
            self.syncPosition(&token);
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
        for (self.tokens.items) |token| {
            self.syncPosition(&token);
            switch (self.state) {
                .Idle => {
                    switch (token.name) {
                        .Instruction => {
                            self.state = .Instruction;
                            try self.handleInstruction(&token);
                        },
                        .Label => {
                            // ignore labels in this state
                            // since they were handled in prepare phase
                        },
                        .Jump => try self.handleJump(&token),
                        else => return AssemblerError.WaitingForInstruction,
                    }
                },
                .Instruction => {
                    switch (token.name) {
                        .Number => try self.handleNumber(&token),
                        .Register => try self.handleRegister(&token),
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

    /// Writes the resulting bytecode into a file.
    pub fn writeFile(self: *const Assembler, path: []const u8) AssemblerError!void {
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

    /// Synchronizes the current line and column with the given token.
    fn syncPosition(self: *Assembler, token: *const Token) void {
        self.line = token.line;
        self.column = token.column;
    }

    /// Appends single `u8` to the bytecode.
    fn appendByte(self: *Assembler, byte: u8) AssemblerError!void {
        self.bytecode.append(byte) catch {
            return AssemblerError.OutOfMemory;
        };
    }

    /// Handles a jump token by calculating and appending its bytecode.
    fn handleJump(self: *Assembler, token: *const Token) AssemblerError!void {
        if (self.labels.get(token.value)) |position| {
            const high = @as(u8, @intCast((position >> 24) & 0xFF));
            const mid_high = @as(u8, @intCast((position >> 16) & 0xFF));
            const mid_low = @as(u8, @intCast((position >> 8) & 0xFF));
            const low = @as(u8, @intCast(position & 0xFF));

            try self.appendByte(@intFromEnum(CommandID.JumpConst));
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
    fn handleInstruction(self: *Assembler, token: *const Token) AssemblerError!void {
        const value = token.getValueSlice();
        if (std.mem.eql(u8, value, "noop")) {
            try self.appendByte(@intFromEnum(CommandID.None));
            self.state = .Idle;
        } else if (std.mem.eql(u8, value, "push_const")) {
            try self.appendByte(@intFromEnum(CommandID.PushConst));
            self.argc = 1;
        } else if (std.mem.eql(u8, value, "pop_const")) {
            try self.appendByte(@intFromEnum(CommandID.PopConst));
            self.argc = 1;
        } else if (std.mem.eql(u8, value, "set_register")) {
            try self.appendByte(@intFromEnum(CommandID.MoveConstToRegister));
            self.argc = 2;
        } else if (std.mem.eql(u8, value, "copy_register")) {
            try self.appendByte(@intFromEnum(CommandID.CopyRegister));
            self.argc = 2;
        } else if (std.mem.eql(u8, value, "add_register")) {
            try self.appendByte(@intFromEnum(CommandID.AddRegister));
            self.argc = 3;
        } else if (std.mem.eql(u8, value, "sub_register")) {
            try self.appendByte(@intFromEnum(CommandID.SubtractRegister));
            self.argc = 3;
        } else if (std.mem.eql(u8, value, "mul_register")) {
            try self.appendByte(@intFromEnum(CommandID.MultiplyRegister));
            self.argc = 3;
        } else if (std.mem.eql(u8, value, "div_register")) {
            try self.appendByte(@intFromEnum(CommandID.DivideRegister));
            self.argc = 3;
        } else if (std.mem.eql(u8, value, "mod_register")) {
            try self.appendByte(@intFromEnum(CommandID.ModuloRegister));
            self.argc = 3;
        } else if (std.mem.eql(u8, value, "push_register")) {
            try self.appendByte(@intFromEnum(CommandID.PushRegister));
            self.argc = 1;
        } else if (std.mem.eql(u8, value, "compare_bigger_register")) {
            try self.appendByte(@intFromEnum(CommandID.CompareBiggerRegister));
            self.argc = 2;
        } else if (std.mem.eql(u8, value, "compare_smaller_register")) {
            try self.appendByte(@intFromEnum(CommandID.CompareSmallerRegister));
            self.argc = 2;
        } else if (std.mem.eql(u8, value, "compare_equal_register")) {
            try self.appendByte(@intFromEnum(CommandID.CompareEqualRegister));
            self.argc = 2;
        } else if (std.mem.eql(u8, value, "sleep_seconds")) {
            try self.appendByte(@intFromEnum(CommandID.SleepSeconds));
            self.state = .Idle;
        } else if (std.mem.eql(u8, value, "sleep_milliseconds")) {
            try self.appendByte(@intFromEnum(CommandID.SleepMilliseconds));
            self.state = .Idle;
        } else if (std.mem.eql(u8, value, "exit")) {
            try self.appendByte(@intFromEnum(CommandID.ExitMachine));
            self.state = .Idle;
        } else if (std.mem.eql(u8, value, "downgrade_permission")) {
            try self.appendByte(@intFromEnum(CommandID.DowngradePermission));
            self.state = .Idle;
        } else if (std.mem.eql(u8, value, "get_mouse_position")) {
            try self.appendByte(@intFromEnum(CommandID.GetMousePosition));
            self.state = .Idle;
        } else if (std.mem.eql(u8, value, "set_mouse_position")) {
            try self.appendByte(@intFromEnum(CommandID.SetMousePosition));
            self.state = .Idle;
        } else if (std.mem.eql(u8, value, "mouse_event")) {
            try self.appendByte(@intFromEnum(CommandID.MouseClick));
            self.argc = 1;
        } else if (std.mem.eql(u8, value, "keyboard_event")) {
            try self.appendByte(@intFromEnum(CommandID.KeyboardAction));
            self.argc = 1;
        } else if (std.mem.eql(u8, value, "debug")) {
            try self.appendByte(@intFromEnum(CommandID.Debug));
            self.state = .Idle;
        } else {
            return AssemblerError.UnknownInstruction;
        }
    }

    /// Handles a number token by parsing and appending its bytecode.
    fn handleNumber(self: *Assembler, token: *const Token) AssemblerError!void {
        const value = token.getValueSlice();
        const number = std.fmt.parseInt(u16, value, 10) catch {
            return AssemblerError.InvalidNumber;
        };

        const high = @as(u8, @intCast((number >> 8) & 0xFF));
        const low = @as(u8, @intCast(number & 0xFF));

        try self.appendByte(high);
        try self.appendByte(low);
    }

    /// Handles a register token by appending its bytecode.
    fn handleRegister(self: *Assembler, token: *const Token) AssemblerError!void {
        switch (token.value[0]) {
            'A' => try self.appendByte(@intFromEnum(RegisterName.A)),
            'B' => try self.appendByte(@intFromEnum(RegisterName.B)),
            'C' => try self.appendByte(@intFromEnum(RegisterName.C)),
            'D' => try self.appendByte(@intFromEnum(RegisterName.D)),
            'E' => try self.appendByte(@intFromEnum(RegisterName.E)),
            'F' => try self.appendByte(@intFromEnum(RegisterName.F)),
            'I' => try self.appendByte(@intFromEnum(RegisterName.I)),
            else => return AssemblerError.InvalidRegister,
        }
    }
};
