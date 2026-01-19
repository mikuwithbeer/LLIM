const std = @import("std");

const Bytecode = @import("bytecode.zig").Bytecode;
const Machine = @import("machine.zig").Machine;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        std.debug.print("usage: llim run <file>\n", .{});
        return;
    }

    const mode = args[1];
    const file = args[2];

    var bytecode = try Bytecode.fromFile(allocator, file);
    defer bytecode.deinit();

    if (std.mem.eql(u8, mode, "run")) {
        var machine = try Machine.init(allocator, bytecode);
        defer machine.deinit();

        machine.setPermission(.Write);
        try machine.loop();
    } else {
        std.debug.print("unknown mode: {s}\n", .{mode});
    }
}
