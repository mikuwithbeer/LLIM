//! Virtual machine implementation for executing bytecode commands.
//! Manages registers, stack, and execution state.
//! Handles permissions and command execution.
//! Defines relevant error types.

const std = @import("std");

const Bytecode = @import("bytecode.zig").Bytecode;
const Command = @import("command.zig").Command;
const CommandID = @import("command.zig").CommandID;
const Input = @import("input.zig").Input;
const KeyboardEvent = @import("input.zig").KeyboardEvent;
const MouseEvent = @import("input.zig").MouseEvent;
const Register = @import("register.zig").Register;
const RegisterName = @import("register.zig").RegisterName;
const Stack = @import("stack.zig").Stack;

/// Represents errors that can occur during machine operations.
pub const MachineError = error{
    PermissionDenied,
    OutOfMemory,
    InvalidCommand,
    InvalidRegisterId,
    DivideByZero,
    FailedToGetMousePosition,
    FailedToSetMousePosition,
    InvalidMouseButton,
    FailedToClickMouse,
    FailedToJump,
    InvalidKeyboardEvent,
    FailedToUseKeyboard,
};

/// Represents the permission levels for the machine.
pub const MachinePermission = enum {
    None,
    Read,
    Write,

    /// Checks if the machine has permission to execute the given command.
    pub fn checkPermission(self: MachinePermission, command: Command) bool {
        return switch (command.id) {
            .SleepSeconds, .SleepMilliseconds => self == .Write,
            .GetMousePosition => self == .Read or self == .Write,
            .SetMousePosition => self == .Write,
            .MouseClick => self == .Write,
            .Debug => self == .Read or self == .Write,
            else => true,
        };
    }
};

/// Represents the current state of the machine.
pub const MachineState = enum {
    Idle,
    Collect,
    Execute,
    Exit,
};

/// Represents the virtual machine.
/// Manages bytecode execution, registers, stack, and permissions.
pub const Machine = struct {
    allocator: std.mem.Allocator,

    block: bool,
    bytecode: *Bytecode,
    command: Command,
    permission: MachinePermission,
    register: Register,
    stack: Stack,
    state: MachineState,

    /// Initializes a new machine with the given bytecode and allocator.
    /// Must be deinitialized with `deinit` when no longer needed.
    pub fn init(allocator: std.mem.Allocator, bytecode: *Bytecode) MachineError!Machine {
        const register = Register.init();
        const stack = Stack.init(allocator) catch {
            return MachineError.OutOfMemory;
        };

        return Machine{
            .allocator = allocator,

            .block = false,
            .bytecode = bytecode,
            .command = Command.init(.None),
            .permission = .None,
            .register = register,
            .stack = stack,
            .state = .Idle,
        };
    }

    /// Sets the permission level for the machine.
    pub fn setPermission(self: *Machine, permission: MachinePermission) void {
        self.permission = permission;
    }

    /// Main execution loop of the machine.
    /// Processes bytecode instructions until completion.
    pub fn loop(self: *Machine) MachineError!void {
        var counter: usize = 0; // temporary counter for arguments

        self.bytecode.*.append(0) catch {
            return MachineError.OutOfMemory;
        }; // thats a bug fix :)

        while (true) {
            const opcode = self.bytecode.*.next();
            if (opcode) |byte| {
                if (self.state == .Execute) {
                    try self.startExecution();
                    try self.doExecution();

                    if (self.state == .Exit) {
                        break;
                    } else {
                        self.finishExecution();
                    }
                }

                // block after execution for jumps
                if (self.block) {
                    self.block = false;
                    continue;
                }

                if (self.state == .Idle) {
                    const command_id = CommandID.fromBytecode(byte);
                    if (command_id == null) {
                        return MachineError.InvalidCommand;
                    }

                    counter = CommandID.argumentCount(command_id.?);
                    self.command = Command.init(command_id.?);

                    if (counter == 0) {
                        self.finishCollection(); // if no arguments, execute immediately
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

    /// Deinitializes the machine, freeing its resources.
    pub fn deinit(self: *Machine) void {
        self.stack.deinit();
    }

    fn startCollection(self: *Machine) void {
        self.state = .Collect;
    }

    fn finishCollection(self: *Machine) void {
        self.state = .Execute;
    }

    fn startExecution(self: *Machine) MachineError!void {
        if (!self.permission.checkPermission(self.command)) {
            return MachineError.PermissionDenied;
        }
    }

    fn doExecution(self: *Machine) MachineError!void {
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

            .JumpConst => {
                if (self.register.get(.I) == 0) {
                    return;
                }

                const high = self.command.arguments[0];
                const mid_high = self.command.arguments[1];
                const mid_low = self.command.arguments[2];
                const low = self.command.arguments[3];

                const position = (@as(u32, high) << 24) | (@as(u32, mid_high) << 16) | (@as(u32, mid_low) << 8) | @as(u32, low);
                self.bytecode.*.moveCursor(position) catch {
                    return MachineError.FailedToJump;
                };

                self.block = true;
            },
            .CompareBiggerRegister, .CompareSmallerRegister, .CompareEqualRegister => {
                const left_register_id = self.command.arguments[0];
                const right_register_id = self.command.arguments[1];

                const left_register = RegisterName.fromId(left_register_id) catch {
                    return MachineError.InvalidRegisterId;
                };
                const right_register = RegisterName.fromId(right_register_id) catch {
                    return MachineError.InvalidRegisterId;
                };

                const left_value = self.register.get(left_register);
                const right_value = self.register.get(right_register);

                const result: u16 = switch (self.command.id) {
                    .CompareBiggerRegister => if (left_value > right_value) 1 else 0,
                    .CompareSmallerRegister => if (left_value < right_value) 1 else 0,
                    .CompareEqualRegister => if (left_value == right_value) 1 else 0,
                    else => unreachable,
                };

                self.register.set(.I, result);
            },

            .SleepSeconds, .SleepMilliseconds => {
                const seconds = self.stack.pop() catch {
                    return MachineError.OutOfMemory;
                };

                const multiplier: u64 = if (self.command.id == .SleepSeconds)
                    std.time.ns_per_s
                else
                    std.time.ns_per_ms;

                std.Thread.sleep(@as(u64, seconds) * multiplier);
            },
            .ExitMachine => {
                self.state = .Exit;
            },

            .GetMousePosition => {
                const cursor = Input.getMousePosition();
                if (cursor) |positions| {
                    self.register.set(.D, positions[0]);
                    self.register.set(.E, positions[1]);
                } else {
                    return MachineError.FailedToGetMousePosition;
                }
            },
            .SetMousePosition => {
                const x = self.register.get(.D);
                const y = self.register.get(.E);

                Input.setMousePosition(x, y) catch {
                    return MachineError.FailedToSetMousePosition;
                };
            },
            .MouseClick => {
                const high = self.command.arguments[0];
                const low = self.command.arguments[1];

                const button_id: u16 = (@as(u16, high) << 8) | @as(u16, low);
                const button = MouseEvent.fromId(button_id) orelse {
                    return MachineError.InvalidMouseButton;
                };

                Input.clickMouse(button) catch {
                    return MachineError.FailedToClickMouse;
                };
            },
            .KeyboardAction => {
                const key_code = self.register.get(.D);

                const high = self.command.arguments[0];
                const low = self.command.arguments[1];
                const event_type: u16 = (@as(u16, high) << 8) | @as(u16, low);

                if (KeyboardEvent.fromId(event_type)) |event| {
                    Input.useKeyboardEvent(event, key_code) catch {
                        return MachineError.FailedToUseKeyboard;
                    };
                } else {
                    return MachineError.InvalidKeyboardEvent;
                }
            },

            .Debug => {
                std.debug.print("Registers:\n", .{});
                std.debug.print("| A = 0x{X}\n", .{self.register.get(.A)});
                std.debug.print("| B = 0x{X}\n", .{self.register.get(.B)});
                std.debug.print("| C = 0x{X}\n", .{self.register.get(.C)});
                std.debug.print("| D = 0x{X}\n", .{self.register.get(.D)});
                std.debug.print("| E = 0x{X}\n", .{self.register.get(.E)});
                std.debug.print("| F = 0x{X}\n", .{self.register.get(.F)});
                std.debug.print("| I = 0x{X}\n", .{self.register.get(.I)});

                std.debug.print("Stack:\n", .{});
                for (self.stack.values.items) |value| {
                    std.debug.print("| 0x{X}\n", .{value});
                }
            },
        }
    }

    fn finishExecution(self: *Machine) void {
        self.state = .Idle;
    }
};
