pub const CommandID = enum {
    None,
    PushConst,
    PopConst,
    Debug,

    pub fn fromBytecode(value: u8) ?CommandID {
        return switch (value) {
            0x00 => CommandID.None,
            0x01 => CommandID.PushConst,
            0x02 => CommandID.PopConst,
            0xFF => CommandID.Debug,
            else => null,
        };
    }

    pub fn argumentCount(self: CommandID) usize {
        return switch (self) {
            .None => 0,
            .PushConst => 2,
            .PopConst => 1,
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
