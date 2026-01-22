## LLIM 

![License](https://img.shields.io/badge/license-MIT-green.svg)
![Platform](https://img.shields.io/badge/platform-macOS-blue.svg)
![Language](https://img.shields.io/badge/language-Zig-orange.svg)

![logo](/assets/logo.svg)

LLIM (**L**ow **L**evel **I**nput **M**anagement) is a small virtual machine focused on mouse and keyboard management for macOS. The virtual machine is written in Zig and aims to be safe, fast, and developer-friendly.

---

### Features

- 7 general-purpose 16-bit registers (`A`, `B`, `C`, `D`, `E`, `F`, `I`)
- Fixed size stack
- Permission system: `None`, `Read`, `Write`
- Mouse and keyboard controlling
- Memory safety
- Ships with built-in assembler

### Example

This program demonstrates the core syntax and capabilities of the LLIM IR (**I**ntermediate **R**epresentation).

```ruby
.set_register @A 100 # @A = 100
.set_register @B 1 # @B = 1
.set_register @I 4 # @I = 4

.get_mouse_position # @D = x, @E = y

<LOOP # save position as LOOP
  .add_register @D @A @D # @D = @D + @A
  .add_register @E @E @A # @E = @E + @A
  .sub_register @I @I @B # @I = @I - @B
  .set_mouse_position # uses @D (x), @E (y)

  # sleep for 1 second
  .push_const 1
  .sleep_seconds
>LOOP # if @I != 0 jump to LOOP

.mouse_event 0 # mouse left down

# wait for a short time (250ms) between mouse events
.push_const 250
.sleep_milliseconds

.mouse_event 1 # mouse left up
.debug # print registers and stack
```

### Contributing

Since the project is still evolving, please create an issue instead of PRs.

### License

LLIM is licensed under the MIT license.
