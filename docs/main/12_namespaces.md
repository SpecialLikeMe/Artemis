# 12. Namespaces

`namespace` groups related functions, types, and constants under a name, preventing collisions in large codebases.

---

## Declaring a Namespace

```arc
namespace Math {
    fn abs(x: i32) i32                     { return x < 0 ? -x : x; }
    fn min(a: i32, b: i32) i32             { return a < b ? a : b; }
    fn max(a: i32, b: i32) i32             { return a > b ? a : b; }
    fn clamp(v: i32, lo: i32, hi: i32) i32 {
        return Math.min(Math.max(v, lo), hi);
    }
}
```

---

## Accessing Namespace Members

Use dot notation to call namespace functions, access types, or read constants:

```arc
let x: i32 = Math.abs(-5);            // 5
let y: i32 = Math.clamp(15, 0, 10);   // 10
```

---

## Namespaces with Types

Define structs, istrucs, or enums inside a namespace:

```arc
namespace Geo {
    struct Point {
        let x: f64;
        let y: f64;
    }

    fn dist_sq(a: Point, b: Point) f64 {
        let dx: f64 = a.x - b.x;
        let dy: f64 = a.y - b.y;
        return dx * dx + dy * dy;
    }
}

let mut p: Geo.Point;
p.x = 3.0; p.y = 4.0;
let d: f64 = Geo.dist_sq(p, p);
```

---

## Nested Namespaces

```arc
namespace Outer {
    namespace Inner {
        fn run() void { }
    }
}

Outer.Inner.run();
```

Nested namespaces use multiple `.` separators.

---

## Standard Library Namespaces

The standard library is organized into nested namespaces. After `extern std.module;`:

```arc
extern std.fmt;
extern std.hash;

std.fmt.out_println("hello");
let h: u64 = std.hash.fnv_hash_str("key");
```

---

## Name Mangling

Namespace members are mangled as `NamespaceName__NS_funcname` in the generated IR — `Foo.bar` maps to `Foo__NS_bar`. This is an implementation detail; user code always uses `.` notation.

---

> **Challenge:** Create a `namespace Bits` with functions `fn set(n: u32, bit: i32) u32`, `fn clear(n: u32, bit: i32) u32`, and `fn test(n: u32, bit: i32) bool`. Test all three in `main`.

---

[Prev: Generics](11_generics.md) | [Next: Memory Management and Allocators](13_memory.md)
