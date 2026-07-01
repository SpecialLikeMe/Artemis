# 3. Types

## Integer Types

| Type   | Width   | Signed | Alias  |
|--------|---------|--------|--------|
| `i8`   | 8-bit   | Yes    | `char` |
| `i16`  | 16-bit  | Yes    |        |
| `i32`  | 32-bit  | Yes    | `int`  |
| `i64`  | 64-bit  | Yes    |        |
| `i128` | 128-bit | Yes    |        |
| `u8`   | 8-bit   | No     |        |
| `u16`  | 16-bit  | No     |        |
| `u32`  | 32-bit  | No     | `uint` |
| `u64`  | 64-bit  | No     |        |
| `u128` | 128-bit | No     |        |

```arc
i32 x   = 42;
u64 big = 1000000000000;
i8  c   = 'A';
```

Integer types convert implicitly in assignments; the value is truncated if narrowed (no warning — be deliberate).

## Floating-Point Types

| Type   | Width   | Alias   |
|--------|---------|---------|
| `f32`  | 32-bit  |         |
| `f64`  | 64-bit  | `float` |
| `f128` | 128-bit |         |

```arc
f64 pi = 3.14159;
f32 e  = 2.71828;
```

## Boolean Types

| Type  | Width  | Notes                  |
|-------|--------|------------------------|
| `bool`| 8-bit  | Standard boolean       |
| `b1`  | 1-bit  | Single-bit             |
| `b8`  | 8-bit  | Explicit-width boolean |
| `b32` | 32-bit | Explicit-width boolean |

```arc
bool ok     = true;
b1   flag   = false;
bool result = (5 > 3);  // true
```

## The Void Type

`void` is only valid as a function return type or as `void*` (generic pointer):
```arc
void  do_nothing() { }
void* ptr = 0;           // null pointer
```

## Type Conversions (Casting)

Use `(TargetType)expr` for explicit casts:
```arc
i32  x  = 300;
i8   y  = (i8)x;         // truncates to 44
f64  f  = (f64)x;        // int to float
void* p = (void*)(&x);   // pointer to void*
i32*  q = (i32*)p;       // void* back to i32*
```

---

[Prev: Getting Started](02_getting_started.md) | [Next: Variables and Constants](04_variables.md)
