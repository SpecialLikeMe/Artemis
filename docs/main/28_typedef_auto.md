# 28. Type Aliases and `auto`

---

## `typedef` — Named Type Aliases

`typedef` creates a transparent alias for any type. The alias and the underlying type are identical to the compiler:

```arc
typedef i32   ErrorCode;
typedef i8*   CStr;
typedef i32*  IntPtr;
```

### Struct / istruc Typedefs

```arc
istruc Vec2 { i32 x; i32 y; }
typedef Vec2 Point;

Point p;
p.x = 3;
p.y = 4;
```

### Function Pointer Typedefs

```arc
typedef i32(i32, i32)* BinOp;

BinOp op = &add;
i32 result = op(3, 4);
```

---

## `using` — Contextual Alias

`using` creates a contextual type alias, most commonly used with `const auto` to introduce a `let`-style binding:

```arc
using let = const auto;

let x = 42;        // const i32 x = 42
let y = "hello";   // const i8* y = "hello"
let z = 3.14;      // const f64 z = 3.14
```

`using` bindings are scoped to the enclosing block or file scope.

---

## `auto` Variables — Type Inference

`auto` infers the variable type from the initializer expression:

```arc
auto x = 42;       // x : i32
auto y = 3.14;     // y : f64
auto s = "hello";  // s : i8*
auto p = &x;       // p : i32*
```

The type is resolved at compile time — there is no runtime type erasure.

### `auto` in For Loops

```arc
auto count = 0;
for (; count < 10; count = count + 1) { }
```

### `auto` with Complex Expressions

```arc
auto result = some_func();   // type inferred from return type of some_func
```

---

## `auto` in Function Signatures — Error Unions

`auto` as a function return type, combined with `!T`, declares a fallible function:

```arc
auto parse_int(i8* s) !i32 {
    // returns either i32 or an error
    if (s == null) { return error.NullInput; }
    return 42;
}
```

See [Chapter 24](24_error_handling.md) for full error-handling coverage.

---

[Prev: Pointer Const Semantics](27_pointer_const.md) | [Next: Macros](29_macros.md)
