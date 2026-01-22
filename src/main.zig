const std = @import("std");

const Assembler = @import("assembler.zig").Assembler;
const Bytecode = @import("bytecode.zig").Bytecode;
const Machine = @import("machine.zig").Machine;
const Lexer = @import("lexer.zig").Lexer;
const Token = @import("token.zig").Token;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        std.debug.print("usage: llim run|asm <file>\n", .{});
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
    } else if (std.mem.eql(u8, mode, "asm")) {
        var tokens: std.ArrayList(Token) = .empty;
        defer tokens.deinit(allocator);

        var lexer = try Lexer.init(allocator, file, &tokens);
        defer lexer.deinit();

        try lexer.loop();

        var assembler = try Assembler.init(allocator, &tokens);
        defer assembler.deinit();

        try assembler.prepare();
        try assembler.loop();

        for (assembler.bytecode.values.items) |byte| {
            std.debug.print("0x{X} ", .{byte});
        }
        std.debug.print("\n", .{});
    } else {
        std.debug.print("unknown mode: {s}\n", .{mode});
    }
}
