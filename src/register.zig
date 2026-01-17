pub const RegisterError = error{
    InvalidRegisterId,
};

pub const RegisterName = enum {
    A,
    B,
    C,
    D,
    E,
    F,

    pub fn toId(self: RegisterName) u8 {
        return switch (self) {
            .A => 0,
            .B => 1,
            .C => 2,
            .D => 3,
            .E => 4,
            .F => 5,
        };
    }

    pub fn fromId(self: u8) RegisterError!RegisterName {
        return switch (self) {
            0 => .A,
            1 => .B,
            2 => .C,
            3 => .D,
            4 => .E,
            5 => .F,
            else => RegisterError.InvalidRegisterId,
        };
    }
};

pub const Register = struct {
    values: [6]u16,

    pub fn init() Register {
        return Register{
            .values = [_]u16{ 0, 0, 0, 0, 0, 0 },
        };
    }

    pub fn get(self: *Register, name: RegisterName) u16 {
        return self.values[name.toId()];
    }

    pub fn set(self: *Register, name: RegisterName, value: u16) void {
        self.values[name.toId()] = value;
    }
};
