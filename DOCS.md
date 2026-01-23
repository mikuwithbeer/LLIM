## Architecture

### Registers

The VM features seven unsigned 16-bit general-purpose registers:

- `@A`, `@B`, `@C`: General purpose storage.
- `@D`, `@E`, `@F`: Used as an input/output for instructions.
- `@I`: Used by conditional jumps.

### Stack

- Fixed-size unsigned 16-bit stack for temporary storage.
- Used by arithmetic operations and OS calls.

---

## Assembly

### Syntax Rules

- **Instructions**: Start with a dot (e.g., `.push_const`).
- **Numbers**: Defined as base 10, unsigned 16-bit (min `0`, max `65535`) integer.
  - **Note**: Character `'` might be used for numbers to make them more readable (e.g., `65'535`).
- **Registers**: Prefixed with `@` (e.g., `@A`).
- **Labels**: Defined with `<LABEL_NAME` and jumped to with `>LABEL_NAME`.
- **Comments**: Start with `#` and continues until next line.

### Instruction Reference

#### Data Management

| Mnemonic | Arguments | Description |
| :--- | :--- | :--- |
| `.noop` | None | No operation. |
| `.set_register` | `<reg> <val>` | Sets the register to a 16-bit constant value. |
| `.copy_register` | `<src> <dst>` | Copies the value from source register to destination. |
| `.push_const` | `<val>` | Pushes a 16-bit constant onto the stack. |
| `.push_register` | `<reg>` | Pushes the value of a register onto the stack. |
| `.pop_const` | `<reg>` | Pops the top value of the stack into a register. |

#### Arithmetic

| Mnemonic | Arguments | Description |
| :--- | :--- | :--- |
| `.add_register` | `<dst> <r1> <r2>`| `dst = r1 + r2` |
| `.sub_register` | `<dst> <r1> <r2>`| `dst = r1 - r2` |
| `.mul_register` | `<dst> <r1> <r2>`| `dst = r1 * r2` |
| `.div_register` | `<dst> <r1> <r2>`| `dst = r1 / r2` |
| `.mod_register` | `<dst> <r1> <r2>`| `dst = r1 % r2` |

#### Control Flow

| Mnemonic | Arguments | Description |
| :--- | :--- | :--- |
| `<NAME` | None | Defines a label at the current position. |
| `>NAME` | None | Jumps to label `NAME` if register `@I` is **not** zero. |
| `.compare_bigger` | `<r1> <r2>` | Sets `@I = 1` if `r1 > r2`, else `0`. |
| `.compare_smaller`| `<r1> <r2>` | Sets `@I = 1` if `r1 < r2`, else `0`. |
| `.compare_equal`  | `<r1> <r2>` | Sets `@I = 1` if `r1 == r2`, else `0`. |
| `.exit` | None | Terminates the VM execution. |

#### Input & OS

| Mnemonic | Arguments | Description |
| :--- | :--- | :--- |
| `.get_mouse_position` | None | Sets `@D = x` and `@E = y` of the current cursor. |
| `.set_mouse_position` | None | Moves cursor to coordinates stored in `@D` and `@E`. |
| `.mouse_event` | `<id>` | Performs mouse action (`id` 0: Left Down, 1: Left Up, 2: Right Down, 3: Right Up). |
| `.keyboard_event` | `<id> <key>` | Performs keyboard action (`id` 0: Down, 1: Up; `key` is macOS keycode). |
| `.sleep_seconds` | None | Pops value `N` from stack and sleeps for `N` seconds. |
| `.sleep_milliseconds`| None | Pops value `N` from stack and sleeps for `N` milliseconds. |
| `.downgrade_permission` | None | Downgrades virtual machine permission at runtime. (Write -> Read -> None <-) |

#### Debugging

| Mnemonic | Arguments | Description |
| :--- | :--- | :--- |
| `.debug` | None | Prints the current state of all registers and the stack. |

---

## Appendix

### Register Map

All registers are 16-bit unsigned integers (`u16`):

| Name | ID |
| :--- | :--- |
| `@A` | `0x00` |
| `@B` | `0x01` |
| `@C` | `0x02` |
| `@D` | `0x03` |
| `@E` | `0x04` |
| `@F` | `0x05` |
| `@I` | `0x06` |

### Event Tables

#### Mouse Events

| ID | Type |
| :--- | :--- |
| `0` | Left Down |
| `1` | Left Up |
| `2` | Right Down |
| `3` | Right Up |

#### Keyboard Events

| ID | Type |
| :--- | :--- |
| `0` | Key Down |
| `1` | Key Up |

*Note: The second argument for keyboard event instruction is the macOS virtual keycode, more information can be found at following [gist](https://gist.github.com/eegrok/949034).*
