//! Register definitions and utilities.
//! There are seven general-purpose registers named A to F and I.
//! Each register can hold a 16-bit unsigned integer value.

/// Represents errors that can occur during register operations.
pub const RegisterError = error{
    InvalidRegisterId,
};

/// Represents the names of the general-purpose registers.
pub const RegisterName = enum {
    A,
    B,
    C,
    D,
    E,
    F,
    I,

    /// Converts the register name to its corresponding ID.
    pub fn toId(self: RegisterName) u8 {
        return switch (self) {
            .A => 0,
            .B => 1,
            .C => 2,
            .D => 3,
            .E => 4,
            .F => 5,
            .I => 6,
        };
    }

    /// Converts a `u8` value to a `RegisterName` enum variant.
    /// Returns an error if the ID is invalid.
    pub fn fromId(self: u8) RegisterError!RegisterName {
        return switch (self) {
            0 => .A,
            1 => .B,
            2 => .C,
            3 => .D,
            4 => .E,
            5 => .F,
            6 => .I,
            else => RegisterError.InvalidRegisterId,
        };
    }
};

/// Represents a set of six general-purpose registers.
pub const Register = struct {
    values: [7]u16,

    /// Initializes a new set of registers with all values set to zero.
    pub fn init() Register {
        return Register{
            .values = [_]u16{ 0, 0, 0, 0, 0, 0, 0 },
        };
    }

    /// Retrieves the value of the specified register.
    pub fn get(self: *Register, name: RegisterName) u16 {
        return self.values[name.toId()];
    }

    /// Sets the value of the specified register.
    pub fn set(self: *Register, name: RegisterName, value: u16) void {
        self.values[name.toId()] = value;
    }
};
