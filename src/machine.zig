const std = @import("std");

const Bytecode = @import("bytecode.zig").Bytecode;
const Command = @import("command.zig").Command;
const CommandID = @import("command.zig").CommandID;
const Register = @import("register.zig").Register;
const Stack = @import("stack.zig").Stack;

pub const MachineState = enum {
    Idle,
    Collect,
    Execute,
};

pub const MachineError = error{
    OutOfMemory,
};

pub const Machine = struct {
    allocator: std.mem.Allocator,

    bytecode: Bytecode,
    command: Command,
    register: Register,
    stack: Stack,
    state: MachineState,

    pub fn init(allocator: std.mem.Allocator, bytecode: Bytecode) MachineError!Machine {
        const register = Register.init();
        const stack = Stack.init(allocator) catch {
            return MachineError.OutOfMemory;
        };

        return Machine{
            .allocator = allocator,

            .bytecode = bytecode,
            .command = Command.init(.None),
            .register = register,
            .stack = stack,
            .state = .Idle,
        };
    }

    pub fn loop(self: *Machine) MachineError!void {
        var counter: usize = 0;

        self.bytecode.append(0) catch {
            return MachineError.OutOfMemory;
        }; // thats a bug fix :)

        while (true) {
            const opcode = self.bytecode.next();
            if (opcode != null) {
                const byte = opcode.?;

                if (self.state == .Execute) {
                    self.startExecution();
                    self.finishExecution();
                }

                if (self.state == .Idle) {
                    const command_id = CommandID.fromBytecode(byte);
                    if (command_id == null) {
                        continue;
                    }

                    counter = CommandID.argumentCount(command_id.?);
                    self.command = Command.init(command_id.?);

                    if (counter == 0) {
                        self.finishCollection();
                    } else {
                        self.startCollection();
                    }
                } else if (self.state == .Collect) {
                    self.command.pushArgument(byte);
                    counter -= 1;

                    if (counter == 0) {
                        self.finishCollection();
                    }
                }
            } else {
                break;
            }
        }
    }

    pub fn startCollection(self: *Machine) void {
        self.state = .Collect;
    }

    pub fn finishCollection(self: *Machine) void {
        self.state = .Execute;
    }

    pub fn startExecution(self: *Machine) void {
        std.debug.print("Executing Command: id={} args={any}\n", .{ self.command.id, self.command.arguments[0..self.command.count] });
    }

    pub fn finishExecution(self: *Machine) void {
        self.state = .Idle;
    }

    pub fn deinit(self: *Machine) void {
        self.stack.deinit();
    }
};
