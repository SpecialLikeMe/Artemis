# 3. Types

Artemis uses explicit-width types for every numeric value. There are no platform-dependent widths — `i32` is always 32 bits on every target.

---

## Integer Types

| Type   | Width   | Signed | Alias  | Notes |
|--------|---------|--------|--------|-------|
| `i8`   | 8-bit   | Yes    | `char` | Also the character type |
| `i16`  | 16-bit  | Yes    |        |       |
| `i32`  | 32-bit  | Yes    | `int`  |       |
| `i64`  | 64-bit  | Yes    |        |       |
| `i128` | 128-bit | Yes    |        |       |
| `i256` | 256-bit | Yes    |        | Software emulation |
| `i512` | 512-bit | Yes    |        | Software emulation |
| `u8`   | 8-bit   | No     |        |       |
| `u16`  | 16-bit  | No     |        |       |
| `u32`  | 32-bit  | No     | `uint` |       |
| `u64`  | 64-bit  | No     |        |       |
| `u128` | 128-bit | No     |        |       |
| `u256` | 256-bit | No     |        | Software emulation |
| `u512` | 512-bit | No     |        | Software emulation |

The generic syntax is `iN` and `uN` for any `N` — for example `i24`, `u48`.

```arc
i32 x   = 42;
u64 big = 1000000000000u;
i8  c   = 'A';
```

Integer types are implicitly converted in assignments. Narrowing conversions (e.g., `i64` → `i32`) truncate the value silently — be deliberate.

### `signed` / `unsigned` Qualifiers

`signed` and `unsigned` can prefix a type to override its signedness:

```arc
signed   i32 a = -1;    // same as i32
unsigned i32 b = 255;   // same as u32
```

These are C-compatibility qualifiers. Prefer the explicit-width signed/unsigned types (`i32` / `u32`).

---

## Floating-Point Types

| Type   | Format         | Alias   | Notes |
|--------|----------------|---------|-------|
| `f8`   | 8-bit float    |         | Stored as i8 internally |
| `f16`  | Half precision |         |       |
| `f32`  | Single         |         |       |
| `f64`  | Double         | `float` |       |
| `f128` | Quad           |         |       |
| `f256` | —              |         | Maps to fp128 (LLVM limit) |
| `f512` | —              |         | Maps to fp128 (LLVM limit) |

The generic syntax is `fN` for any `N`.

```arc
f64 pi  = 3.14159;
f32 e   = 2.71828;
f128 h  = 6.626e-34;
```

---

## Boolean Types

| Type   | Width   | Notes                             |
|--------|---------|-----------------------------------|
| `bool` | 8-bit   | Standard boolean (`true`/`false`) |
| `b1`   | 1-bit   | Single-bit boolean                |
| `b8`   | 8-bit   | Explicit-width boolean            |
| `b16`  | 16-bit  | Explicit-width boolean            |
| `b32`  | 32-bit  | Explicit-width boolean            |

The generic syntax is `bN`.

```arc
bool ok     = true;
bool result = (5 > 3);    // true
b32  flags  = false;
```

---

## The `char` Type

`char` is an alias for `i8`. It is the canonical character type and the element type of C-style strings:

```arc
char  c   = 'A';        // single character
char* str = "hello";    // null-terminated string pointer (also i8*)
i8*   raw = "hello";    // identical
```

`char*`, `i8*`, and `u8*` are interchangeable string pointer types.

---

## The `void` Type

`void` is only valid as a function return type (indicating no return value) or as `void*` (a pointer to untyped memory):

```arc
void  nothing() { }
void* opaque  = (void*)(&x);
i32*  back    = (i32*)opaque;
```

---

## Nullable Types (`?T`)

The `?` prefix makes any type nullable — its value may be `null`. Unlike raw pointers, nullable types are tracked by the type system so accidental null dereferences are caught at compile time.

```arc
?i32  maybe = 42;   // holds a value
?i8*  name  = null; // holds null

if (maybe != null) {
    i32 val = maybe;   // safe inside the null check
}
```

Any type can be made nullable:

```arc
?i8*  name    = null;
?f64  reading = 3.14;
```

### Nullable Enforcement

A `?T` value **cannot** be silently coerced to a `T`. You must explicitly check for null:

```arc
?i32 maybe = get_value();

// COMPILE ERROR: cannot assign ?i32 to i32 without a null check
i32 val = maybe;

// Correct: conditional unwrap
i32 val;
if (maybe != null) {
    val = maybe;   // inside a null check, usage is safe
} else {
    val = 0;
}
```

Passing `?T` to a function expecting `T` is also rejected:

```arc
void process(i32 x) { ... }

?i32 m = get_value();
process(m);      // COMPILE ERROR: nullable arg to non-nullable param
process((i32)m); // explicit cast is the programmer's responsibility
```

### Nullable Pointers

`?T*` (nullable pointer) is distinct from `T*` (assumed non-null raw pointer):

```arc
i8*  raw  = get_str();   // assumed non-null
?i8* safe = get_str();   // caller documents it may return null
```

### Returning Nullable

```arc
?i32 find_index(i32* arr, i32 len, i32 target) {
    for (i32 i = 0; i < len; i = i + 1) {
        if (arr[i] == target) return i;
    }
    return null;
}
```

### The `??` Operator (Null Coalescing)

`lhs ?? rhs` evaluates to `lhs` if it is non-null/non-zero, and evaluates to `rhs` otherwise. This is equivalent to Zig's `orelse`:

```arc
?i32* find_ptr() { ... }

// Expression RHS — use a fallback value
i32* p = find_ptr() ?? &default_val;

// Block RHS — trigger an action when null (must be noreturn or terminate)
i32* q = find_ptr() ?? { panic("expected non-null"); };
```

`??` has lower precedence than the ternary `? :` operator, so the RHS is a full expression.

### If-Capture (`|var|`)

Bind the non-null condition value to a name inside the then-branch:

```arc
?i32* maybe = find_ptr();

if (maybe) |p| {
    // p has type i32*, guaranteed non-null
    use(*p);
}
```

`else |var|` captures the condition value in the else-branch (useful with error unions):

```arc
if (get_result()) |val| {
    use(val);
} else |err| {
    log_error(err);
}
```

---

## Type Conversions (Casting)

Use `(TargetType)expr` for explicit casts:

```arc
i32  x   = 300;
i8   y   = (i8)x;         // truncates to 44
f64  f   = (f64)x;        // integer → float
void* p  = (void*)(&x);   // pointer → void*
i32*  q  = (i32*)p;       // void* → typed pointer
u32  u   = (u32)(-1);     // -1 as unsigned: 4294967295
```

Casts between pointer types are always allowed and are zero-cost (reinterpret, no runtime work).

---

## Function Pointer Types

Function pointer types use the syntax `RetType(Param0, Param1, ...)*`:

```arc
i32(i32, i32)* op = &add;    // pointer to function taking two i32, returning i32
i32 result = op(3, 4);       // call through pointer
```

See [Chapter 19](19_function_pointers.md) for details.

---

## The `memstr` Allocator Type

`&memstr name` in a parameter list accepts any allocator-compatible struct (one declared with `memstr`). See [Chapter 13](13_memory.md).

---

## Extended Primitive Types

Beyond the core `iN`/`uN`/`fN`/`bN` families, Artemis provides several specialised prefix types.

| Prefix | Meaning | Backing storage |
|--------|---------|-----------------|
| `nN` | Natural number (≥ 0) | `uN` — unsigned integer of N bits |
| `zN` | Integer | `iN` — signed integer of N bits |
| `chN` | N-bit character | `uN` — unsigned, character semantics |
| `cN` | Complex number | `struct { fN re; fN im; }` |
| `qN` | Rational number | `struct { iN num; iN den; }` |

```arc
n8   a = 200u;          // 8-bit natural (unsigned byte)
z32  b = -42;           // 32-bit integer, same as i32
ch8  c = 'A';           // 8-bit character, same as u8

c64  z;                 // complex double
z.re = 1.0;
z.im = 2.5;

q32  r;                 // rational: 3/4
r.num = 3;
r.den = 4;
```

Complex and rational types produce struct types in the generated code — field access uses the normal `.re`, `.im`, `.num`, `.den` names.

---

## `comptime type` — First-Class Type Aliases

`comptime type` declares a compile-time type alias. The alias name can be used anywhere its underlying type would be valid:

```arc
comptime type MyInt   = i32;
comptime type MyFloat = f64;

MyInt   a = 100;
MyFloat f = 3.14;
```

This is distinct from `using` (which is a non-`comptime` alias). `comptime type` aliases can alias generic instantiations:

```arc
comptime type IntPair = Pair<i32>;

IntPair p(1, 2);
```

See [Chapter 18](18_comptime.md) for the full `comptime` feature set.

---

## Type Aliases

`using OldType NewName;` creates a transparent alias:

```arc
using i32   ErrorCode;
using i8*   CStr;
using i32*  IntPtr;
```

See [Chapter 28](28_typedef_auto.md) for `using` and `auto` inference.

---

[Prev: Getting Started](02_getting_started.md) | [Next: Variables and Constants](04_variables.md)
