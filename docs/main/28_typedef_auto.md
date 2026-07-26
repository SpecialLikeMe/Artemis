# 28. Type Aliases

---

## `using` — Named Type Aliases

`using` creates a transparent alias for any type. The alias and the underlying type are identical to the compiler:

```arc
using ErrorCode = i32;
using CStr = *i8;
using IntPtr = *i32;
```

### Struct / istruc Typedefs

```arc
istruc Vec2 {
    let x: i32;
    let y: i32;
}
using Point = Vec2;

let mut p: Point;
p.x = 3;
p.y = 4;
```

### Function Pointer Typedefs

```arc
using BinOp = *(i32, i32)i32;

let op: BinOp = add;
let result: i32 = op(3, 4);
```

---

## Type Inference with `let`

Omitting the type annotation from `let` infers the type from the initializer:

```arc
let x = 42;        // x : i32
let y = 3.14;      // y : f64
let s = "hello";   // s : *i8
let p = &x;        // p : *i32
```

The type is resolved at compile time — there is no runtime type erasure.

---

## `!T` — Error Union Return Type

Functions that may fail declare a `!T` return type:

```arc
fn parse_int(s: *i8) !i32 {
    if (s == null) { return error.NullInput; }
    return 42;
}
```

See [Chapter 24](24_error_handling.md) for full error-handling coverage.

---

[Prev: Pointer Const Semantics](27_pointer_const.md) | [Next: Macros](29_macros.md)
