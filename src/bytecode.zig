const std = @import("std");

pub const BytecodeSize = 1024;

pub const BytecodeError = error{
    OutOfMemory,
    IndexOutOfRange,
};

pub const Bytecode = struct {
    allocator: std.mem.Allocator,

    cursor: usize,
    values: std.ArrayList(u8),

    pub fn init(allocator: std.mem.Allocator) BytecodeError!Bytecode {
        const values = std.ArrayList(u8).initCapacity(allocator, BytecodeSize) catch {
            return BytecodeError.OutOfMemory;
        };

        return Bytecode{
            .allocator = allocator,
            .cursor = 0,
            .values = values,
        };
    }

    pub fn append(self: *Bytecode, value: u8) BytecodeError!void {
        self.values.append(self.allocator, value) catch {
            return BytecodeError.OutOfMemory;
        };
    }

    pub fn extend(self: *Bytecode, other: []const u8) BytecodeError!void {
        for (other) |value| {
            try self.append(value);
        }
    }

    pub fn length(self: *Bytecode) usize {
        return self.values.items.len;
    }

    pub fn next(self: *Bytecode) ?u8 {
        if (self.cursor >= self.length()) {
            return null;
        }

        const value = self.values.items[self.cursor];
        self.cursor += 1;

        return value;
    }

    pub fn deinit(self: *Bytecode) void {
        self.values.deinit(self.allocator);
    }
};
