# 16. C Interoperability

## Importing C Functions

Use `@unsafe extern fn` to import an external C symbol. The `@unsafe` marker is
required because external calls bypass the SMT's safety checks — the compiler cannot
verify what the C function does.

```arc
@unsafe extern fn printf(fmt: *i8, ...) i32;
@unsafe extern fn malloc(size: u64) *void;
@unsafe extern fn free(ptr: *void) void;
@unsafe extern fn strlen(s: *i8) i32;
```

You can group multiple declarations in an `@unsafe` block:

```arc
@unsafe {
    extern fn printf(fmt: *i8, ...) i32;
    extern fn puts(str: *i8) i32;
    extern fn malloc(n: u64) *void;
}
```

Each declaration must appear at file scope. Calling `extern fn` without `@unsafe`
is a compile error.

## Exporting Artemis Functions to C

Wrap Artemis code in an `extern "C" { }` block to export it with C calling
convention and no name mangling (analogous to C++ `extern "C"`):

```arc
extern "C" {
    i32 arc_add(i32 a, i32 b) { return a + b; }
    void arc_greet(i8* name)  { printf("hello, %s\n", name); }
}
```

Consumers of the compiled `.o` / `.a` see `arc_add` and `arc_greet` as plain
C symbols with no decoration.

## Calling Convention

`extern <decl>` uses C calling convention and the symbol name verbatim.
`extern "C" { <defs> }` marks Artemis-defined functions to be emitted with C ABI.

## Using aciso Packages

Import an installed package with `extern aciso.NAME`:
```arc
extern aciso.math;
extern aciso.strings;
```

The compiler expands this before parsing by prepending the package's source files.
Binary packages (`.a`/`.o`) are linked automatically. See [Chapter 22](22_package_manager.md).

## Using stdlib Packages

Import a standard-library package with `extern std.NAME`:
```arc
extern std.fmt;           // all of std.fmt
extern std.fmt.out;       // just the std.fmt.out namespace
extern std.fmt.out.printf; // a single function
```

The compiler resolves `compiler/std/` relative to the executable and prepends the
relevant `.arc` file before parsing. See [Chapter 17](17_preprocessor.md) for full
import rules.

---

[Prev: Inline Assembly](15_asm.md) | [Next: Preprocessor](17_preprocessor.md)
