//! Command definitions and utilities.

/// This module defines the various commands that can be executed by the virtual machine.
pub const CommandID = enum {
    None,
    PushConst,
    PopConst,
    MoveConstToRegister,
    CopyRegister,
    AddRegister,
    SubtractRegister,
    MultiplyRegister,
    DivideRegister,
    ModuloRegister,
    PushRegister,

    JumpConst,

    SleepSeconds,
    SleepMilliseconds,
    ExitMachine,

    GetMousePosition,
    SetMousePosition,
    MouseClick,
    KeyboardAction,

    Debug,

    /// Converts a `u8` value to a `CommandID` enum variant.
    pub fn fromBytecode(value: u8) ?CommandID {
        return switch (value) {
            // Arithmetic and Data Management
            0x00 => CommandID.None,
            0x01 => CommandID.PushConst,
            0x02 => CommandID.PopConst,
            0x03 => CommandID.MoveConstToRegister,
            0x04 => CommandID.CopyRegister,
            0x05 => CommandID.AddRegister,
            0x06 => CommandID.SubtractRegister,
            0x07 => CommandID.MultiplyRegister,
            0x08 => CommandID.DivideRegister,
            0x09 => CommandID.ModuloRegister,
            0x0A => CommandID.PushRegister,
            // Control Flow
            0x30 => CommandID.JumpConst,
            // OS Operations
            0x60 => CommandID.SleepSeconds,
            0x61 => CommandID.SleepMilliseconds,
            0x62 => CommandID.ExitMachine,
            // Input Controlling
            0x90 => CommandID.GetMousePosition,
            0x91 => CommandID.SetMousePosition,
            0x92 => CommandID.MouseClick,
            0x93 => CommandID.KeyboardAction,
            // Debugging
            0xFF => CommandID.Debug,
            else => null,
        };
    }

    /// Returns the number of arguments required for the command.
    /// Later used for parsing bytecode instructions.
    pub fn argumentCount(self: CommandID) usize {
        return switch (self) {
            .None => 0,
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

            .JumpConst => 4,

            .SleepSeconds => 0,
            .SleepMilliseconds => 0,
            .ExitMachine => 0,

            .GetMousePosition => 0,
            .SetMousePosition => 0,
            .MouseClick => 1,
            .KeyboardAction => 1,

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
