//! Assembler module for turning instructions into bytecode.

const std = @import("std");

const Bytecode = @import("bytecode.zig").Bytecode;
const CommandID = @import("command.zig").CommandID;
const RegisterName = @import("register.zig").RegisterName;
const Token = @import("token.zig").Token;

/// Information about an instruction.
const InstructionInfo = struct {
    id: CommandID,
    argc: usize,
};

/// Table mapping instruction names to their information.
const InstructionTable = std.StaticStringMap(InstructionInfo).initComptime(.{
    .{ "push_const", InstructionInfo{ .id = .PushConst, .argc = 1 } },
    .{ "pop_const", InstructionInfo{ .id = .PopConst, .argc = 1 } },
    .{ "set_register", InstructionInfo{ .id = .MoveConstToRegister, .argc = 2 } },
    .{ "copy_register", InstructionInfo{ .id = .CopyRegister, .argc = 2 } },
    .{ "add_register", InstructionInfo{ .id = .AddRegister, .argc = 3 } },
    .{ "sub_register", InstructionInfo{ .id = .SubtractRegister, .argc = 3 } },
    .{ "mul_register", InstructionInfo{ .id = .MultiplyRegister, .argc = 3 } },
    .{ "div_register", InstructionInfo{ .id = .DivideRegister, .argc = 3 } },
    .{ "mod_register", InstructionInfo{ .id = .ModuloRegister, .argc = 3 } },
    .{ "push_register", InstructionInfo{ .id = .PushRegister, .argc = 1 } },

    .{ "compare_bigger_register", InstructionInfo{ .id = .CompareBiggerRegister, .argc = 2 } },
    .{ "compare_smaller_register", InstructionInfo{ .id = .CompareSmallerRegister, .argc = 2 } },
    .{ "compare_equal_register", InstructionInfo{ .id = .CompareEqualRegister, .argc = 2 } },

    .{ "sleep_seconds", InstructionInfo{ .id = .SleepSeconds, .argc = 0 } },
    .{ "sleep_milliseconds", InstructionInfo{ .id = .SleepMilliseconds, .argc = 0 } },
    .{ "exit", InstructionInfo{ .id = .ExitMachine, .argc = 0 } },
    .{ "downgrade_permission", InstructionInfo{ .id = .DowngradePermission, .argc = 0 } },
    .{ "get_mouse_position", InstructionInfo{ .id = .GetMousePosition, .argc = 0 } },
    .{ "set_mouse_position", InstructionInfo{ .id = .SetMousePosition, .argc = 0 } },
    .{ "mouse_event", InstructionInfo{ .id = .MouseClick, .argc = 1 } },
    .{ "keyboard_event", InstructionInfo{ .id = .KeyboardAction, .argc = 1 } },

    .{ "noop", InstructionInfo{ .id = .None, .argc = 0 } },
    .{ "debug", InstructionInfo{ .id = .Debug, .argc = 0 } },
});

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
                .Instruction, .Register => self.bytes += 1,
                .Number => self.bytes += 2,
                .Jump, .JumpConditional => self.bytes += 5,
                .Label => {
                    if (self.labels.contains(token.value)) {
                        return AssemblerError.LabelAlreadyDefined;
                    }

                    self.labels.put(token.value, self.bytes) catch {
                        return AssemblerError.OutOfMemory;
                    };
                },
                .None => unreachable,
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
                        .Jump, .JumpConditional => try self.handleJump(&token),
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

            switch (token.name) {
                .JumpConditional => try self.appendByte(@intFromEnum(CommandID.JumpConstConditional)),
                .Jump => try self.appendByte(@intFromEnum(CommandID.JumpConst)),
                else => unreachable,
            }

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

        if (InstructionTable.get(value)) |instruction| {
            try self.appendByte(@intFromEnum(instruction.id));

            self.argc = instruction.argc;
            if (self.argc == 0) {
                self.state = .Idle;
            }
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
