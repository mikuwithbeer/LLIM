const std = @import("std");

const Bytecode = @import("bytecode.zig").Bytecode;
const Machine = @import("machine.zig").Machine;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var bytecode = try Bytecode.init(allocator);
    defer bytecode.deinit();

    bytecode.extend(&[_]u8{
        0x00, //
        0x01, //
        0x00,
        0x2a,
        0x02, //
        0x00,
        0x00, //
        0x01, //
        0x00,
        0x03,
        0x01, //
        0xaa,
        0x03,
        0x02, //
        0x01,
        0xff, //
        0x03, //
        0x04,
        0x00,
        0x3A,
        0xff, //
        0xff, //
        0x05, //
        0x02,
        0x00,
        0x01,
        0xff, //
    }) catch |err| {
        std.debug.print("Error building bytecode: {}\n", .{err});
        return err;
    };

    var machine = try Machine.init(allocator, bytecode);
    defer machine.deinit();

    machine.loop() catch |err| {
        std.debug.print("Machine error: {}\n", .{err});
        return;
    };
}
