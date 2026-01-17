const std = @import("std");
const Stack = @import("stack.zig").Stack;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var stack = try Stack.init(allocator, 10);
    defer stack.deinit();

    try stack.push(31);
    try stack.push(69);
    try stack.push(420);

    var value = try stack.pop();
    std.debug.print("Popped 1 value: {d}\n", .{value});
    value = try stack.pop();
    std.debug.print("Popped 2 value: {d}\n", .{value});
    value = try stack.pop();
    std.debug.print("Popped 3 value: {d}\n", .{value});
}
