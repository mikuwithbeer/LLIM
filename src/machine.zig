const std = @import("std");

const Bytecode = @import("bytecode.zig").Bytecode;
const Command = @import("command.zig").Command;
const CommandID = @import("command.zig").CommandID;
const Register = @import("register.zig").Register;
const RegisterName = @import("register.zig").RegisterName;
const Stack = @import("stack.zig").Stack;

pub const MachineState = enum {
    Idle,
    Collect,
    Execute,
};

pub const MachineError = error{
    OutOfMemory,
    InvalidCommand,
    InvalidRegisterId,
    DivideByZero,
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
                    try self.startExecution();
                    self.finishExecution();
                }

                if (self.state == .Idle) {
                    const command_id = CommandID.fromBytecode(byte);
                    if (command_id == null) {
                        return MachineError.InvalidCommand;
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

    pub fn startExecution(self: *Machine) MachineError!void {
        switch (self.command.id) {
            .None => {},
            .PushConst => {
                const high = self.command.arguments[0];
                const low = self.command.arguments[1];
                const value: u16 = (@as(u16, high) << 8) | @as(u16, low);

                self.stack.push(value) catch {
                    return MachineError.OutOfMemory;
                };
            },
            .PopConst => {
                const register_id = self.command.arguments[0];
                const register = RegisterName.fromId(register_id) catch {
                    return MachineError.InvalidRegisterId;
                };

                const value = self.stack.pop() catch {
                    return MachineError.OutOfMemory;
                };

                self.register.set(register, value);
            },
            .MoveConstToRegister => {
                const register_id = self.command.arguments[0];
                const register = RegisterName.fromId(register_id) catch {
                    return MachineError.InvalidRegisterId;
                };

                const high = self.command.arguments[1];
                const low = self.command.arguments[2];
                const value: u16 = (@as(u16, high) << 8) | @as(u16, low);

                self.register.set(register, value);
            },
            .CopyRegister => {
                const source_register_id = self.command.arguments[0];
                const target_register_id = self.command.arguments[1];

                const source_register = RegisterName.fromId(source_register_id) catch {
                    return MachineError.InvalidRegisterId;
                };
                const target_register = RegisterName.fromId(target_register_id) catch {
                    return MachineError.InvalidRegisterId;
                };

                const value = self.register.get(source_register);
                self.register.set(target_register, value);
            },
            .AddRegister, .SubtractRegister, .MultiplyRegister, .DivideRegister, .ModuloRegister => {
                const destination_register_id = self.command.arguments[0];
                const left_register_id = self.command.arguments[1];
                const right_register_id = self.command.arguments[2];

                const destination_register = RegisterName.fromId(destination_register_id) catch {
                    return MachineError.InvalidRegisterId;
                };
                const left_register = RegisterName.fromId(left_register_id) catch {
                    return MachineError.InvalidRegisterId;
                };
                const right_register = RegisterName.fromId(right_register_id) catch {
                    return MachineError.InvalidRegisterId;
                };

                const left_value = self.register.get(left_register);
                const right_value = self.register.get(right_register);

                if ((self.command.id == .DivideRegister or self.command.id == .ModuloRegister) and (right_value == 0)) {
                    return MachineError.DivideByZero;
                }

                const result = switch (self.command.id) {
                    .AddRegister => left_value + right_value,
                    .SubtractRegister => left_value - right_value,
                    .MultiplyRegister => left_value * right_value,
                    .DivideRegister => left_value / right_value,
                    .ModuloRegister => left_value % right_value,
                    else => unreachable,
                };

                self.register.set(destination_register, result);
            },
            .PushRegister => {
                const register_id = self.command.arguments[0];
                const register = RegisterName.fromId(register_id) catch {
                    return MachineError.InvalidRegisterId;
                };

                const value = self.register.get(register);

                self.stack.push(value) catch {
                    return MachineError.OutOfMemory;
                };
            },
            .Debug => {
                std.debug.print("Registers:\n", .{});
                std.debug.print("| A = 0x{X}\n", .{self.register.get(.A)});
                std.debug.print("| B = 0x{X}\n", .{self.register.get(.B)});
                std.debug.print("| C = 0x{X}\n", .{self.register.get(.C)});
                std.debug.print("| D = 0x{X}\n", .{self.register.get(.D)});
                std.debug.print("| E = 0x{X}\n", .{self.register.get(.E)});
                std.debug.print("| F = 0x{X}\n", .{self.register.get(.F)});

                std.debug.print("Stack:\n", .{});
                for (self.stack.values.items) |value| {
                    std.debug.print("| 0x{X}\n", .{value});
                }
            },
        }
    }

    pub fn finishExecution(self: *Machine) void {
        self.state = .Idle;
    }

    pub fn deinit(self: *Machine) void {
        self.stack.deinit();
    }
};
