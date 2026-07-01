# 17. Preprocessor

The Artemis preprocessor runs before lexing. Directives are prefixed with `@`.

## `@include`

```arc
@include "other_file.arc"
@include <system_header.arc>   // searches -I include paths
```

## Conditional Compilation

```arc
@ifdef RELEASE
    constexpr bool DEBUG = false;
@else
    constexpr bool DEBUG = true;
@endif
```

Define symbols from the command line with `-D`:
```
arc file.arc -D RELEASE -o output
```

`@ifndef` tests that a symbol is *not* defined:
```arc
@ifndef NDEBUG
    // debug-only code
@endif
```

## `@define`

```arc
@define MAX_RETRIES 5
@define PI_APPROX   3.14159
```

Defined names are substituted textually before parsing. They do not participate in the type system.

## Order of Processing

1. `@include` files are inlined
2. `extern aciso.NAME` packages are expanded
3. `@define` substitutions are applied
4. `@ifdef`/`@ifndef`/`@endif` blocks are resolved
5. The resulting source is handed to the lexer

---

[Prev: C Interoperability](16_c_interop.md) | [Next: Compile-Time Features](18_comptime.md)
