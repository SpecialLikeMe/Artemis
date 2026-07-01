# 12. Namespaces

`namespace` groups related functions under a name. Access members with `.` (preferred) or `::` (deprecated — emits a compiler warning).

## Declaring a Namespace

```arc
namespace Math {
    i32 abs(i32 x)               { return x < 0 ? -x : x; }
    i32 min(i32 a, i32 b)        { return a < b ? a : b; }
    i32 max(i32 a, i32 b)        { return a > b ? a : b; }
    i32 clamp(i32 v, i32 lo, i32 hi) {
        return Math.min(Math.max(v, lo), hi);
    }
}
```

## Using Namespace Members

```arc
i32 main() {
    i32 x = Math.abs(-5);           // 5
    i32 y = Math.clamp(15, 0, 10);  // 10
    return 0;
}
```

## Namespaces and Structs

You can define structs inside a namespace and use them in namespace function signatures:

```arc
namespace Geo {
    struct Point { f64 x; f64 y; }

    f64 dist_sq(Point a, Point b) {
        f64 dx = a.x - b.x;
        f64 dy = a.y - b.y;
        return dx * dx + dy * dy;
    }
}
```

## Name Mangling

Namespace functions are mangled as `NamespaceName__NS_funcname` in the generated IR. This is analogous to istruc's `ClassName__MT_methodname` mangling.

## `::` (Deprecated)

`Namespace::func()` still works but emits a compiler warning at every call site. Migrate to `Namespace.func()`.

> **Challenge:** Create a `namespace Bits` with functions `set(u32 n, i32 bit) -> u32`, `clear(u32 n, i32 bit) -> u32`, and `test(u32 n, i32 bit) -> bool`. Test all three in `main`.

---

[Prev: Generics](11_generics.md) | [Next: Memory Management and Allocators](13_memory.md)
