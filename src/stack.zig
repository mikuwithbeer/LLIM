const std = @import("std");

pub const StackError = error{
    StackOverflow,
    StackUnderflow,
    OutOfMemory,
};

pub const Stack = struct {
    allocator: std.mem.Allocator,

    capacity: usize,
    values: std.ArrayList(u16),

    pub fn init(allocator: std.mem.Allocator, capacity: usize) StackError!Stack {
        const values = std.ArrayList(u16).initCapacity(allocator, capacity) catch {
            return StackError.OutOfMemory;
        };

        return Stack{
            .allocator = allocator,

            .capacity = capacity,
            .values = values,
        };
    }

    pub fn push(self: *Stack, value: u16) StackError!void {
        if (self.values.items.len >= self.capacity) {
            return StackError.StackOverflow;
        }

        self.values.append(self.allocator, value) catch {
            return StackError.OutOfMemory;
        };
    }

    pub fn pop(self: *Stack) StackError!u16 {
        if (self.values.items.len == 0) {
            return StackError.StackUnderflow;
        }

        return self.values.pop().?;
    }

    pub fn deinit(self: *Stack) void {
        self.values.deinit(self.allocator);
    }
};
