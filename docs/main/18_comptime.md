# 18. Compile-Time Features

## `comptime` Variables

Values known at compile time. Can be used in array sizes, other comptime expressions, and `comptime if` conditions:

```arc
comptime i32 CACHE_LINE = 64;
comptime i32 BUCKETS    = CACHE_LINE * 4;   // 256
comptime u64 BUF_SIZE   = sizeof(i32) * BUCKETS;
```

## `comptime if`

The condition is evaluated at compile time. The dead branch is entirely eliminated from the binary — its code is never parsed into IR:

```arc
comptime i32 MODE = 1;

if comptime (MODE == 1) {
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

## `comptime` — Deferred Construction

Declare a variable without triggering its constructor, then call `__construct__` yourself:
```arc
comptime MyClass obj;
if (need_it) {
    obj.__construct__(arg1, arg2);
}
```

See [Chapter 4](04_variables.md) for more detail.

---

## `comptime type` — First-Class Type Aliases

`comptime type` declares a compile-time type alias. Unlike a plain `using` alias, the name may be used in any type position including generic instantiations and array sizes:

```arc
comptime type MyInt   = i32;
comptime type MyFloat = f64;

MyInt   a = 100;    // same as: i32 a = 100;
MyFloat f = 3.14;   // same as: f64 f = 3.14;
```

Aliasing a generic instantiation:

```arc
istruc Box<T> { T val; }

comptime type IntBox = Box<i32>;

IntBox b;
b.val = 42;
```

`comptime type` aliases are resolved entirely at compile time and produce no runtime overhead. They can also alias struct types:

```arc
istruc Point { i32 x; i32 y; }
comptime type Coord = Point;

Coord c;
c.x = 10;
c.y = 20;
```

See [Chapter 3](03_types.md) for the type system overview.

---

[Prev: Preprocessor](17_preprocessor.md) | [Next: Function Pointers](19_function_pointers.md)
