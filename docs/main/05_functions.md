# 5. Functions

---

## Basic Functions

```arc
i32 add(i32 a, i32 b) { return a + b; }

void greet(i8* name) {
    // ... use name ...
}
```

`main` must return `i32` (the process exit code):

```arc
i32 main() { return 0; }
```

---

## Fallible Functions — `!T` Return Type

A function that may fail uses `auto` as its declared return type and appends `!T` after the parameter list:

```arc
auto maybe_divide(i32 a, i32 b) !i32 {
    if (b == 0) {
        return error.DivByZero;
    }
    return a / b;
}
```

Return an error with `return error.Name;`. Return a value normally otherwise. See [Chapter 24](24_error_handling.md) for full error-handling coverage.

---

## Variadic Functions

`...` at the end of the parameter list marks a variadic function:

```arc
extern i32 printf(i8* fmt, ...);

// calling a variadic function:
printf("Value: %d\n", 42);
```

---

## `inline` and `register` Hints

`inline` is a hint to inline the function at call sites. `register` hints to keep a parameter or local in a CPU register:

```arc
inline   i32 fast_add(i32 a, i32 b) { return a + b; }
register i32 hot_var = 0;
```

These are optimizer hints — the compiler may ignore them.

---

## `noexcept`

`noexcept` signals that the function will never return an error. Using `try`, `except`, or `return error.X` inside a `noexcept` function is a compile error:

```arc
i32 safe_div(i32 a, i32 b) noexcept {
    if (b == 0) return 0;
    return a / b;
}

bool b = noexcept(safe_div(10, 2));   // true at compile time
```

---

## Forward Declarations

Declare a function without a body to call it before its definition:

```arc
i32 compute(i32 x);   // forward declaration

i32 main() { return compute(5); }

i32 compute(i32 x) { return x * x; }
```

---

## Generics

Type parameters go in `<>` after the function name:

```arc
T max<T>(T a, T b) { return a > b ? a : b; }

i32 x = max<i32>(3, 7);    // explicit
f64 y = max(1.5, 2.5);     // inferred: T = f64
```

See [Chapter 11](11_generics.md) for details.

---

## `const_resolve` — Compile-Time Function Macros

`const_resolve` defines a macro that rewrites token patterns at parse time:

```arc
const_resolve double_it {
    ($x:expr) => { (($x) + ($x)) }
}

i32 result = double_it(21);   // expands to ((21) + (21)) = 42
```

See [Chapter 29](29_macros.md) for the full macro system.

---

## Allocator Parameter Convention

Functions that need heap memory should accept an allocator parameter rather than calling `malloc` directly. The `&memstr` type accepts any `memstr`-declared allocator:

```arc
void* make_buffer(u64 n, &memstr alloc) {
    return alloc.mmap(n);
}
```

`istruc` methods may allocate internally since they implement the allocator themselves. See [Chapter 13](13_memory.md).

---

## `sta` — Comptime Type-Erased Parameters

`sta` marks a parameter as compile-time type-erased — the type is resolved at the call site but erased from the mangled name. This is used primarily by the standard library for generic allocator passing:

```arc
void process(sta x) { /* ... */ }
```

User code rarely needs `sta` directly.

---

## `extern "C"` Functions

To export an Artemis-defined function with C linkage (no name mangling):

```arc
extern "C" {
    i32 arc_add(i32 a, i32 b) { return a + b; }
}
```

To import a C function:

```arc
extern i32 printf(i8* fmt, ...);
```

See [Chapter 16](16_c_interop.md).

---

[Prev: Variables and Constants](04_variables.md) | [Next: Control Flow](06_control_flow.md)
