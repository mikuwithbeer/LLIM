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

    if (args.len != 4) {
        std.debug.print(
            \\usage:
            \\  llim compile <source> <target>
            \\  llim execute bytecode <target>
            \\
        , .{});
        return;
    }

    const firstly = args[1];
    const secondary = args[2];
    const target = args[3];

    if (std.mem.eql(u8, firstly, "compile")) {
        try compileFile(allocator, secondary, target);
    } else if (std.mem.eql(u8, firstly, "execute") and std.mem.eql(u8, secondary, "bytecode")) {
        try executeBytecodeFile(allocator, target);
    } else {
        unknownMode();
    }
}

fn compileFile(allocator: std.mem.Allocator, source: []const u8, target: []const u8) !void {
    var tokens: std.ArrayList(Token) = .empty;
    defer tokens.deinit(allocator);

    var lexer = try Lexer.init(allocator, source, &tokens);
    defer lexer.deinit();

    try lexer.loop();

    var assembler = try Assembler.init(allocator, &tokens);
    defer assembler.deinit();

    try assembler.prepare();
    try assembler.loop();

    try assembler.writeFile(target);

    std.debug.print("wrote {d} bytes.\n", .{assembler.bytes});
}

fn executeBytecodeFile(allocator: std.mem.Allocator, target: []const u8) !void {
    var bytecode = try Bytecode.fromFile(allocator, target);
    defer bytecode.deinit();

    var machine = try Machine.init(allocator, bytecode);
    defer machine.deinit();

    machine.setPermission(.Write);
    try machine.loop();
}

fn unknownMode() void {
    std.debug.print("unknown mode?\n", .{});
}
