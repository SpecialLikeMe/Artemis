# 16. C Interoperability

## Importing C Functions

Use a plain `extern` declaration (no `"C"` qualifier) to import an external C symbol.
The compiler applies C linkage (no mangling) automatically:

```arc
extern i32   printf(i8* fmt, ...);
extern void* malloc(u64 size);
extern void  free(void* ptr);
extern i32   strlen(i8* s);
```

Each declaration must appear at file scope. Multiple declarations are just repeated
`extern` lines — there is no block form for importing.

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
