const std = @import("std");

const Register = @import("register.zig").Register;
const RegisterName = @import("register.zig").RegisterName;

const Stack = @import("stack.zig").Stack;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var register = Register.init();

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

    register.set(.A, 1234);

    const reg_value = register.get(try RegisterName.fromId(0));
    std.debug.print("Register A value: {d}\n", .{reg_value});
}
