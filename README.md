## LLIM 

![License](https://img.shields.io/badge/license-MIT-green.svg)
![Platform](https://img.shields.io/badge/platform-macOS-blue.svg)
![Language](https://img.shields.io/badge/language-Zig-orange.svg)

![logo](/assets/logo.svg)

LLIM (**L**ow **L**evel **I**nput **M**anagement) is a small virtual machine focused on mouse and keyboard management for macOS. The virtual machine is written in Zig and aims to be safe, fast, and developer-friendly.

### Features

- 7 general-purpose 16-bit registers (A..F + I)
- Stack-based operations and push/pop semantics
- Arithmetic operations between registers
- Permission system: None, Read, Write
- Platform input helpers
- Debug command to print registers and stack contents
- Clear failure modes and memory safety

### Contributing

Since the project is still evolving, please create an issue instead of PRs.

### License

LLIM is licensed under the MIT license.
