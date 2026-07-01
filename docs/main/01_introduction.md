# 1. Introduction

Artemis is a compiled, statically typed systems programming language that generates native machine code via LLVM. It is designed for low-level control with ergonomic syntax — think C's power with modern safety features layered on top.

## Core Philosophy

- **Zero hidden cost** — what you write is what runs. No garbage collector, no runtime.
- **Allocator-explicit** — heap memory is always tied to an explicit allocator; no raw `malloc` calls in application code.
- **C-compatible** — call any C library, export functions that C can call back.
- **Practical** — `istruc` gives you classes without virtual dispatch overhead unless you ask for it.

## Compiler Invocation

```
arc file.arc -o output       # compile to executable
arc file.arc -S              # emit LLVM IR
arc file.arc -c              # emit object file
arc run file.arc             # compile and run immediately
```

---

[Next: Getting Started](02_getting_started.md)
