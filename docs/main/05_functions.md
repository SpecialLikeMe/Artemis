# 5. Functions

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

## Overloading

Multiple functions can share the same name if their parameter lists differ:
```arc
i32 area(i32 side)     { return side * side; }
i32 area(i32 w, i32 h) { return w * h; }
f64 area(f64 r)        { return 3.14159 * r * r; }
```

The compiler selects the right overload at call sites based on argument types.

## Variadic Functions

```arc
extern "C" { i32 printf(i8* fmt, ...); }
```

`...` at the end of the parameter list marks a variadic function. Artemis can declare and call variadic functions; defining new ones currently requires C interop.

## Inline and Register Hints

```arc
inline   i32 fast_add(i32 a, i32 b) { return a + b; }
register i32 hot_var = 0;   // hint: keep in a CPU register
```

These are optimizer hints — the compiler may or may not honour them.

## `noexcept`

```arc
i32 safe_div(i32 a, i32 b) noexcept {
    if (b == 0) return 0;
    return a / b;
}
```

`noexcept` is informational; Artemis has no exceptions, so this documents intent.

## Forward Declarations

Declare a function without a body to call it before its definition:
```arc
i32 compute(i32 x);   // forward declaration

i32 main() { return compute(5); }

i32 compute(i32 x) { return x * x; }
```

## Allocator Discipline

Any top-level function that calls `malloc`, `calloc`, or `realloc` directly must declare a `&memstr` allocator parameter. This is enforced at compile time:

```arc
// COMPILE ERROR: heap allocation without allocator
void* make_thing(u64 n) { return malloc(n); }

// CORRECT: allocator is explicit
void* make_thing(u64 n, &memstr alloc) { return alloc.mmap(n); }
```

istruc methods are exempt — they can implement allocators themselves.

> **Challenge:** Write a function `i32* alloc_int_array(u64 count, &memstr alloc)` that allocates an array of `count` integers and returns a pointer to it. Write a matching `free_int_array`.

---

[Prev: Variables and Constants](04_variables.md) | [Next: Control Flow](06_control_flow.md)
