//! Stack implementation for managing `u16` values.
//! Defines a fixed stack size and relevant error types.

const std = @import("std");

/// The maximum size of the stack.
pub const StackSize = 512;

/// Represents errors that can occur during stack operations.
pub const StackError = error{
    StackOverflow,
    StackUnderflow,
    OutOfMemory,
};

/// A stack data structure for managing `u16` values.
/// Provides methods for pushing, popping, and deinitializing the stack.
pub const Stack = struct {
    allocator: std.mem.Allocator,

    capacity: usize,
    values: std.ArrayListUnmanaged(u16),

    /// Initializes a new stack with a fixed capacity.
    /// Must be deinitialized with `deinit` when no longer needed.
    pub fn init(allocator: std.mem.Allocator) StackError!Stack {
        const values = std.ArrayListUnmanaged(u16).initCapacity(allocator, StackSize) catch {
            return StackError.OutOfMemory;
        };

        return Stack{
            .allocator = allocator,

            .capacity = StackSize,
            .values = values,
        };
    }

    /// Pushes a value onto the stack.
    pub fn push(self: *Stack, value: u16) StackError!void {
        if (self.values.items.len >= self.capacity) {
            return StackError.StackOverflow;
        }

        self.values.append(self.allocator, value) catch {
            return StackError.OutOfMemory;
        };
    }

    /// Pops a value from the stack.
    pub fn pop(self: *Stack) StackError!u16 {
        if (self.values.items.len == 0) {
            return StackError.StackUnderflow;
        }

        return self.values.pop().?;
    }

    /// Deinitializes the stack, freeing its resources.
    pub fn deinit(self: *Stack) void {
        self.values.deinit(self.allocator);
    }
};
