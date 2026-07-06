# 4. Variables and Constants

---

## Local Variables

```arc
i32 x = 10;
i32 y;        // zero-initialized (integers default to 0)
```

### Default Initialization Rules

| Type | Default value |
|------|--------------|
| Integer (`iN`, `uN`) | `0` |
| Float (`fN`) | `0.0` |
| `bool` / `bN` | `false` |
| Pointer (`T*`) | `null` (0) |
| `char*` / `i8*` / `u8*` | writable stack-allocated `""` |
| `?T` | `null` |
| `istruc` with zero-arg `__construct__` | constructor called automatically |
| `istruc` with no constructor | zeroed memory |
| Fixed array | elements zero-initialized |

---

## Global Variables

```arc
i32 global_counter = 0;

void increment() { global_counter = global_counter + 1; }
```

Global variables are zero-initialized if no explicit initializer is given.

---

## `const` — Immutable Variables

`const` prevents reassignment after initialization:

```arc
const i32 MAX_CONNECTIONS = 100;
const i8* greeting        = "hello";

MAX_CONNECTIONS = 200;   // COMPILE ERROR
```

`const` applies to the variable binding — it does not make the pointed-to data immutable for pointer types. See [Pointer Const Semantics](27_pointer_const.md) for `const T*` vs `T* const`.

---

## `constexpr` — Compile-Time Constants

`constexpr` marks a value as a compile-time constant. The value must be evaluable at compile time (literal, arithmetic on other constexprs, `sizeof`):

```arc
constexpr i32 MAX_SIZE  = 256;
constexpr f64 TAU       = 6.28318;
constexpr i32 BUF_WORDS = MAX_SIZE / sizeof(i32);

i32 arr[MAX_SIZE];   // constexpr as array size
```

---

## `consteval` — Manual Construction

`consteval` declares a variable without invoking its constructor. You call `__construct__` manually:

```arc
istruc Buffer {
    i32* data;
    i32  len;
    void __construct__(Buffer* self, i32 n) { /* allocate n ints */ }
}

consteval Buffer buf;    // declared — NOT constructed yet
buf.__construct__(100);  // you construct it yourself
```

Useful for placement-new patterns, lazy initialization, or careful construction ordering. See [Chapter 18](18_comptime.md).

---

## `static` Variables

Inside a function, `static` gives a variable process-lifetime storage initialized once:

```arc
i32 call_count() {
    static i32 n = 0;
    n = n + 1;
    return n;
}

call_count();  // 1
call_count();  // 2
call_count();  // 3
```

Inside an `istruc`, `static` declares a class-level variable (one copy shared across all instances).

---

## `volatile` Variables

`volatile` prevents the compiler from caching or reordering reads/writes to the variable. Use it for memory-mapped I/O or variables modified by external hardware:

```arc
volatile i32 status_reg = 0;

while (status_reg == 0) { }   // compiler must re-read each iteration
```

---

## `register` Hint

`register` hints the compiler to keep a variable in a CPU register. This is a non-binding hint — the compiler may ignore it:

```arc
register i32 hot_counter = 0;
```

---

## `using` — Type Alias

`using` creates a contextual alias, typically used with `const auto`:

```arc
using let = const auto;

let x = 42;      // equivalent to: const auto x = 42;  →  const i32 x = 42
let y = "hi";    // const i8* y = "hi"
```

---

## `auto` — Type Inference

`auto` infers the variable's type from the initializer:

```arc
auto x = 42;       // x : i32
auto y = 3.14;     // y : f64
auto s = "hello";  // s : i8*
```

`auto` is also used in function signatures for error-union return types (`auto fn() !T`). See [Chapter 24](24_error_handling.md).

---

## `sizeof`

```arc
u64 sz  = sizeof(i32);          // 4
u64 sz2 = sizeof(MyStruct);
u64 sz3 = sizeof(arr[0]);       // element size from expression
```

`sizeof` returns a `u64` byte count evaluated at compile time.

---

[Prev: Types](03_types.md) | [Next: Functions](05_functions.md)
