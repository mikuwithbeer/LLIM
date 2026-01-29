//! Bytecode management for virtual machine.

const std = @import("std");

/// The maximum size of the bytecode.
pub const BytecodeSize = 1024;

/// Represents errors that can occur during bytecode operations.
pub const BytecodeError = error{
    OutOfMemory,
    IndexOutOfRange,
    FailedToReadFile,
    FailedToGetSize,
};

/// A structure representing bytecode for a virtual machine.
pub const Bytecode = struct {
    allocator: std.mem.Allocator,

    cursor: usize,
    values: std.ArrayList(u8),

    /// Initializes a new bytecode instance with an initial capacity that can hold up to `BytecodeSize` bytes.
    /// Must be deinitialized with `deinit` when no longer needed.
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

    /// Loads bytecode from a file at the specified path.
    pub fn fromFile(allocator: std.mem.Allocator, path: []const u8) BytecodeError!Bytecode {
        const file = std.fs.cwd().openFile(path, .{ .mode = .read_only }) catch {
            return BytecodeError.FailedToReadFile;
        };
        defer file.close();

        const file_size = file.getEndPos() catch {
            return BytecodeError.FailedToGetSize;
        };

        const source = file.readToEndAlloc(allocator, file_size) catch {
            return BytecodeError.FailedToReadFile;
        };

        var bytecode = try Bytecode.init(allocator);
        errdefer bytecode.deinit();

        try bytecode.extend(source);

        return bytecode;
    }

    /// Appends a single byte to the bytecode.
    pub fn append(self: *Bytecode, value: u8) BytecodeError!void {
        self.values.append(self.allocator, value) catch {
            return BytecodeError.OutOfMemory;
        };
    }

    /// Appends a slice of bytes to the bytecode.
    pub fn extend(self: *Bytecode, other: []const u8) BytecodeError!void {
        self.values.appendSlice(self.allocator, other) catch {
            return BytecodeError.OutOfMemory;
        };
    }

    /// Returns the length of the bytecode.
    pub fn length(self: *Bytecode) usize {
        return self.values.items.len;
    }

    /// Retrieves the next byte from the bytecode, advancing the cursor.
    pub fn next(self: *Bytecode) ?u8 {
        if (self.cursor >= self.length()) {
            return null;
        }

        const value = self.values.items[self.cursor];
        self.cursor += 1;

        return value;
    }

    /// Moves the cursor to the specified position in the bytecode.
    pub fn moveCursor(self: *Bytecode, position: u32) BytecodeError!void {
        if (position >= self.length()) {
            return BytecodeError.IndexOutOfRange;
        }

        self.cursor = position;
    }

    /// Deinitializes the bytecode, freeing its resources.
    pub fn deinit(self: *Bytecode) void {
        self.values.deinit(self.allocator);
    }
};
