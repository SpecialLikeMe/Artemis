# 4. Variables and Constants

---

## Local Variables

```arc
let mut x: i32 = 10;
let mut y: i32;        // zero-initialized (integers default to 0)
```

`let` declares a variable. Add `mut` to allow reassignment. Omit `mut` for an immutable binding.

### Default Initialization Rules

| Type | Default value |
|------|--------------|
| Integer (`iN`, `uN`) | `0` |
| Float (`fN`) | `0.0` |
| `bool` / `bN` | `false` |
| Pointer (`*T`) | `null` (0) |
| `*i8` / `*u8` | `null` |
| `?T` | `null` |
| `istruc` with zero-arg `__construct__` | constructor called automatically |
| `istruc` with no constructor | zeroed memory |
| Fixed array | elements zero-initialized |

---

## Global Variables

```arc
let mut global_counter: i32 = 0;

fn increment() void { global_counter = global_counter + 1; }
```

Global variables are zero-initialized if no explicit initializer is given.

---

## Immutable Bindings

Declaring with `let` (no `mut`) prevents reassignment after initialization:

```arc
let MAX_CONNECTIONS: i32 = 100;
let greeting: *i8 = "hello";

MAX_CONNECTIONS = 200;   // COMPILE ERROR
```

`let` applies to the variable binding — it does not make the pointed-to data immutable for pointer types.

---

## `comptime` — Compile-Time Constants

`comptime` marks a value as a compile-time constant. The value must be evaluable at compile time:

```arc
comptime MAX_SIZE: i32 = 256;
comptime TAU: f64 = 6.28318;
comptime BUF_WORDS: i32 = MAX_SIZE / @csizeof(i32);

let mut arr: [MAX_SIZE]i32;   // comptime as array size
```

---

## `comptime` — Manual Construction

`comptime` can also declare a variable without invoking its constructor. You call `__construct__` manually:

```arc
istruc Buffer {
    let mut data: *i32;
    let mut len: i32;
    fn __construct__(self: *Buffer, n: i32) void { /* allocate n ints */ }
}

comptime buf: Buffer;      // declared — NOT constructed yet
buf.__construct__(100);    // you construct it yourself
```

Useful for placement-new patterns or lazy initialization. See [Chapter 18](18_comptime.md).

---

## `static` Variables

Inside a function, `static` gives a variable process-lifetime storage initialized once:

```arc
fn call_count() i32 {
    static n: i32 = 0;
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
volatile status_reg: i32 = 0;

while (status_reg == 0) { }   // compiler must re-read each iteration
```

---

## Type Inference

Omitting the type annotation infers it from the initializer:

```arc
let x = 42;        // x : i32
let y = 3.14;      // y : f64
let s = "hello";   // s : *i8
```

---

## `@csizeof` and `@srsizeof`

```arc
let sz: u64 = @csizeof(i32);           // 4 — compile-time size
let sz2: u64 = @csizeof(MyStruct);
let sz3: u64 = @srsizeof(my_array);    // runtime shallow size
```

See [Chapter 18](18_comptime.md) for full coverage of compile-time builtins.

---

[Prev: Types](03_types.md) | [Next: Functions](05_functions.md)
