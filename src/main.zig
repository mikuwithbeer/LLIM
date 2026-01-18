const std = @import("std");

const Bytecode = @import("bytecode.zig").Bytecode;
const Machine = @import("machine.zig").Machine;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var bytecode = try Bytecode.fromFile(allocator, "test.llimb");
    defer bytecode.deinit();

    var machine = try Machine.init(allocator, bytecode);
    defer machine.deinit();

    machine.setPermission(.Write);

    machine.loop() catch |err| {
        std.debug.print("Machine error: {}\n", .{err});
        return;
    };
}
