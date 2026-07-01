# 18. Compile-Time Features

## `constexpr` Variables

Values known at compile time. Can be used in array sizes, other constexpr expressions, and `constexpr if` conditions:

```arc
constexpr i32 CACHE_LINE = 64;
constexpr i32 BUCKETS    = CACHE_LINE * 4;   // 256
constexpr u64 BUF_SIZE   = sizeof(i32) * BUCKETS;
```

## `constexpr if`

The condition is evaluated at compile time. The dead branch is entirely eliminated from the binary — its code is never parsed into IR:

```arc
constexpr i32 MODE = 1;

if constexpr (MODE == 1) {
    // compiled in
} else {
    // eliminated — not even type-checked
}
```

This is the primary tool for zero-cost platform-specific or configuration-specific branches.

## Generic Monomorphisation

Every distinct instantiation of a generic function or istruc produces a full specialised copy at compile time. There is no boxing, no vtable, no type erasure:

```arc
T identity<T>(T x) { return x; }

// Produces two distinct compiled functions:
i32 a = identity<i32>(1);
f64 b = identity<f64>(1.0);
```

## `consteval` — Deferred Construction

Declare a variable without triggering its constructor, then call `__construct__` yourself:
```arc
consteval MyClass obj;
if (need_it) {
    obj.__construct__(arg1, arg2);
}
```

See [Chapter 4](04_variables.md) for more detail.

---

[Prev: Preprocessor](17_preprocessor.md) | [Next: Function Pointers](19_function_pointers.md)
