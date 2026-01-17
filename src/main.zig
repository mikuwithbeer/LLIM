const std = @import("std");

const Bytecode = @import("bytecode.zig").Bytecode;

const Register = @import("register.zig").Register;
const RegisterName = @import("register.zig").RegisterName;

const Stack = @import("stack.zig").Stack;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var bytecode = try Bytecode.init(allocator);
    defer bytecode.deinit();

    bytecode.extend(&[_]u8{
        0x01, 0x00, 0x0A, // LOAD_CONST 10
        0x01, 0x01, 0x14, // LOAD_CONST 20
        0x02, 0x00, 0x01, // ADD R0, R1
        0x03, 0x00, // PRINT R0
    }) catch |err| {
        std.debug.print("Error building bytecode: {}\n", .{err});
        return err;
    };

    std.debug.print("length {}\n", .{bytecode.length()});

    std.debug.print("g1 {}\n", .{try bytecode.get(0)});
    std.debug.print("g2 {}\n", .{try bytecode.get(2)});
    std.debug.print("g3 {}\n", .{try bytecode.get(11)});
}
