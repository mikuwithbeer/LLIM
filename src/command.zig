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
    Debug,

    pub fn fromBytecode(value: u8) ?CommandID {
        return switch (value) {
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
            0xFF => CommandID.Debug,
            else => null,
        };
    }

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
            .Debug => 0,
        };
    }
};

pub const Command = struct {
    id: CommandID,
    count: usize,
    arguments: [4]u8,

    pub fn init(id: CommandID) Command {
        return Command{
            .id = id,
            .count = 0,
            .arguments = [_]u8{ 0, 0, 0, 0 },
        };
    }

    pub fn pushArgument(self: *Command, value: u8) void {
        if (self.count >= 4) {
            return;
        }

        self.arguments[self.count] = value;
        self.count += 1;
    }
};
