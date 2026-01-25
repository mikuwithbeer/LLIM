//! Virtual machine command definitions and utilities.

const std = @import("std");

/// This module defines the various commands that can be executed by the virtual machine.
pub const CommandID = enum(u8) {
    // Arithmetic and Data Management
    PushConst = 0x01,
    PopConst = 0x02,
    MoveConstToRegister = 0x03,
    CopyRegister = 0x04,
    AddRegister = 0x05,
    SubtractRegister = 0x06,
    MultiplyRegister = 0x07,
    DivideRegister = 0x08,
    ModuloRegister = 0x09,
    PushRegister = 0x0A,
    // Control Flow
    JumpConstConditional = 0x29,
    JumpConst = 0x30,
    CompareBiggerRegister = 0x31,
    CompareSmallerRegister = 0x32,
    CompareEqualRegister = 0x33,
    // OS Operations
    SleepSeconds = 0x60,
    SleepMilliseconds = 0x61,
    ExitMachine = 0x62,
    DowngradePermission = 0x63,
    // Input Controlling
    GetMousePosition = 0x90,
    SetMousePosition = 0x91,
    MouseClick = 0x92,
    KeyboardAction = 0x93,
    // Other
    None = 0x00,
    Debug = 0xFF,

    /// Converts a `u8` value to a `CommandID` enum variant.
    pub fn fromBytecode(value: u8) ?CommandID {
        return std.enums.fromInt(CommandID, value);
    }

    /// Returns the number of arguments required for the command.
    /// Later used for parsing bytecode instructions.
    pub fn argumentCount(self: CommandID) usize {
        return switch (self) {
            .PushConst => 2,
            .PopConst => 1,
            .MoveConstToRegister => 3,
            .CopyRegister => 2,
            .AddRegister => 3,
            .SubtractRegister => 3,
            .MultiplyRegister => 3,
            .DivideRegister => 3,
            .ModuloRegister => 3,
            .PushRegister => 1,

            .JumpConstConditional => 4,
            .JumpConst => 4,
            .CompareBiggerRegister => 2,
            .CompareSmallerRegister => 2,
            .CompareEqualRegister => 2,

            .SleepSeconds => 0,
            .SleepMilliseconds => 0,
            .ExitMachine => 0,
            .DowngradePermission => 0,

            .GetMousePosition => 0,
            .SetMousePosition => 0,
            .MouseClick => 2,
            .KeyboardAction => 2,

            .None => 0,
            .Debug => 0,
        };
    }
};

/// Represents a command with its ID and arguments.
pub const Command = struct {
    id: CommandID,
    count: usize,
    arguments: [4]u8,

    /// Initializes a new command with the given ID.
    pub fn init(id: CommandID) Command {
        return Command{
            .id = id,
            .count = 0,
            .arguments = [_]u8{ 0, 0, 0, 0 },
        };
    }

    /// Pushes an argument to the command.
    pub fn pushArgument(self: *Command, value: u8) void {
        if (self.count >= 4) {
            return;
        }

        self.arguments[self.count] = value;
        self.count += 1;
    }
};
