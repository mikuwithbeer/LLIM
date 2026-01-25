## LLIM 

![License](https://img.shields.io/badge/license-MIT-green.svg)
![Platform](https://img.shields.io/badge/platform-macOS-blue.svg)
![Language](https://img.shields.io/badge/language-Zig-orange.svg)

![logo](/assets/logo.svg)

**LLIM** (**L**ow **L**evel **I**nput **M**anagement) is a high-performance, lightweight virtual machine designed specifically for macOS input automation. Written in **Zig**, it provides a safe and low-level interface to simulate mouse and keyboard events using a custom 16-bit architecture. 🔋

---

### Features

- **Register**: 7 general-purpose 16-bit registers (`A`, `B`, `C`, `D`, `E`, `F`, `I`).
- **Stack**: Provides fixed size 16-bit stack.
- **Memory**: Built-in stack and register management with safety checks.
- **Permission**: Control over script execution (`None`, `Read`, `Write`).
- **Native**: Directly interfaces with macOS API.
- **Assembler**: Compile readable intermediate representation into compact binary.

### Compatibility

#### Requirements

- **Operating System**: macOS `10.15` or later.
- **Zig**: Version `0.15.2`.

#### Permission

To function correctly, the compiled binary might require Accessibility Permissions. 

### Assembly

This program demonstrates the core syntax and capabilities of the **LLIM IR**.

```php
.set_register @A 100 # @A = 100
.set_register @B 1 # @B = 1
.set_register @I 4 # @I = 4

.get_mouse_position # @D = x, @E = y

:LOOP # save position as LOOP
  .add_register @D @A @D # @D = @D + @A
  .add_register @E @E @A # @E = @E + @A
  .sub_register @I @I @B # @I = @I - @B
  .set_mouse_position # uses @D (x), @E (y)

  # sleep for 1 second
  .push_const 1
  .sleep_seconds
?LOOP # if @I != 0 jump to LOOP

.mouse_event 0 # mouse left down

# wait for a short time (250ms) between mouse events
.push_const 250
.sleep_milliseconds

.mouse_event 1 # mouse left up
.debug # print registers and stack
```

### Documentation

For a full list of instructions and register details, please consult the [DOCS.md](./DOCS.md).

### Contributing

The project is currently in active development. If you find a bug or have a request, please open an issue.

### License

LLIM is licensed under the MIT license.
