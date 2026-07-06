# 17. Preprocessor

The Artemis preprocessor runs before the lexer. All directives are prefixed with `@`. They are not part of the grammar — they are handled by a dedicated preprocessor pass that transforms the source text before it is tokenized.

---

## `@define`

Defines a textual substitution macro:

```arc
@define <ANSWER> <42>
@define <PI_APPROX> <3.14159>
@define <MAX_SIZE> <256>
```

The angle-bracket syntax is required: `@define <NAME> <value>`. After definition, any occurrence of `NAME` in the source is replaced with `value` before parsing. Macros are purely textual and do not participate in the type system.

```arc
@define <BUF_SIZE> <1024>

i32 buf[BUF_SIZE];    // expands to: i32 buf[1024];
```

---

## `@undef`

Removes a previously defined macro:

```arc
@define <TEMP> <99>
// ... use TEMP ...
@undef <TEMP>
// TEMP is no longer defined here
```

---

## Conditional Compilation

### `@ifdef` / `@endif`

```arc
@ifdef DEBUG
    // compiled only when DEBUG is defined
    printf("debug mode\n");
@endif
```

### `@ifndef` / `@endif`

```arc
@ifndef NDEBUG
    // compiled only when NDEBUG is NOT defined
    run_assertions();
@endif
```

### `@else`

```arc
@ifdef RELEASE
    constexpr bool DEBUG = false;
@else
    constexpr bool DEBUG = true;
@endif
```

### `@elif`

```arc
@ifdef PLATFORM_WIN
    // Windows path
@elif PLATFORM_MAC
    // Mac path
@else
    // Linux / other
@endif
```

### `@elifdef` / `@elifndef`

```arc
@ifdef FAST
    constexpr i32 OPT = 3;
@elifdef SAFE
    constexpr i32 OPT = 1;
@elifndef TINY
    constexpr i32 OPT = 2;
@else
    constexpr i32 OPT = 0;
@endif
```

---

## `@include`

Includes another source file in-place before parsing:

```arc
@include <inc/platform.arc>     // searches -I include paths
@include "my_module.arc"        // relative to current file
```

All top-level declarations in the included file become available to the including file.

---

## `@embed`

Embeds the contents of a file literally as source code:

```arc
@embed <inc/embed_code.inc>
```

The file is inserted verbatim — it must contain valid Artemis declarations or code fragments that are syntactically valid in context.

---

## `@error`

Emits a compile-time error from inside a conditional block:

```arc
@ifndef REQUIRED_SYMBOL
@error "REQUIRED_SYMBOL must be defined before including this file"
@endif
```

---

## `@pragma once`

Marks the current file as an include guard — it will not be re-included if `@include`d a second time:

```arc
@pragma once

// ... declarations ...
```

Place `@pragma once` at the top of any file intended to be shared across multiple include points.

---

## Order of Processing

1. `@pragma once` guards are resolved — duplicate includes are dropped.
2. `@include` files are inlined recursively.
3. `@embed` file contents are inserted.
4. `extern std.X` imports are expanded to the standard library source file.
5. `@define` / `@undef` substitutions are recorded.
6. Conditional blocks (`@ifdef` / `@ifndef` / `@elif` / `@elifdef` / `@elifndef` / `@else` / `@endif`) are evaluated; dead branches are dropped.
7. Macro substitutions are applied to the remaining text.
8. The result is handed to the lexer.

---

## Command-Line Defines

Symbols can be defined from the compiler command line with `-D`:

```
arc file.arc -D RELEASE -D PLATFORM_WIN -o output
```

These behave identically to `@define <NAME> <1>`.

---

[Prev: C Interoperability](16_c_interop.md) | [Next: Compile-Time Features](18_comptime.md)
