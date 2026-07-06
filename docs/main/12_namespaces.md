# 12. Namespaces

`namespace` groups related functions, types, and constants under a name, preventing collisions in large codebases.

---

## Declaring a Namespace

```arc
namespace Math {
    i32 abs(i32 x)                { return x < 0 ? -x : x; }
    i32 min(i32 a, i32 b)         { return a < b ? a : b; }
    i32 max(i32 a, i32 b)         { return a > b ? a : b; }
    i32 clamp(i32 v, i32 lo, i32 hi) {
        return Math.min(Math.max(v, lo), hi);
    }
}
```

---

## Accessing Namespace Members

Use dot notation to call namespace functions, access types, or read constants:

```arc
i32 x = Math.abs(-5);            // 5
i32 y = Math.clamp(15, 0, 10);   // 10
```

---

## Namespaces with Types

Define structs, istrucs, or enums inside a namespace:

```arc
namespace Geo {
    struct Point { f64 x; f64 y; }

    f64 dist_sq(Point a, Point b) {
        f64 dx = a.x - b.x;
        f64 dy = a.y - b.y;
        return dx * dx + dy * dy;
    }
}

Geo.Point p;
p.x = 3.0; p.y = 4.0;
f64 d = Geo.dist_sq(p, p);
```

---

## Nested Namespaces

```arc
namespace Outer {
namespace Inner {
    void fn() { }
}
}

Outer.Inner.fn();
```

Nested namespaces use multiple `.` separators.

---

## Standard Library Namespaces

The standard library is organized into nested namespaces. After `extern std.module;`:

```arc
extern std.fmt;
extern std.hash;

std.fmt.out_println("hello");
u64 h = std.hash.fnv_hash_str("key");
```

---

## Name Mangling

Namespace members are mangled as `NamespaceName__NS_funcname` in the generated IR — `Foo.bar` maps to `Foo__NS_bar`. This is an implementation detail; user code always uses `.` notation.

---

> **Challenge:** Create a `namespace Bits` with functions `set(u32 n, i32 bit) -> u32`, `clear(u32 n, i32 bit) -> u32`, and `test(u32 n, i32 bit) -> bool`. Test all three in `main`.

---

[Prev: Generics](11_generics.md) | [Next: Memory Management and Allocators](13_memory.md)
