# Artemis

Artemis is a compiled, statically-typed systems language that targets LLVM IR. The compiler is **self-hosting** — it is written in Arc (the Artemis language) and compiles itself.

---

## Status

| Test suite | Passing |
|------------|---------|
| Compiler tests (`tcon/test/`) | 254 |
| Standard library tests (`tcon/std/`) | 23 |
| SMT safety tests (`tcon/smt/`) | 8 |
| Compile-error tests (`tcon/fail/`) | 120 |
| **Total** | **405** |

---

## Language Overview

### Types

**Primitives:**

| Kind | Examples | Notes |
|------|----------|-------|
| Signed integers | `i8`, `i16`, `i32`, `i64`, `i128` | `int` = `i32` alias |
| Unsigned integers | `u8`, `u16`, `u32`, `u64`, `u128` | `uint` = `u32` alias |
| Floats | `f32`, `f64`, `f128` | `float` = `f64` alias |
| Booleans | `bool`, `b8`, `b32` | |
| Natural numbers | `n8` … `nN` | distinct unsigned semantic type |
| Integer ring | `z8` … `zN` | distinct signed semantic type |
| Real numbers | `r32`, `r64` … | distinct float semantic type |
| Algebraic | `a32` … | always `f64` at runtime |
| Characters | `ch8`, `ch16`, `ch32` | N-bit character |
| Strings | `str8`, `str16` | pointer to `chN` |
| Rationals | `q32`, `q64` | `{ iN num; iN den; }` layout |
| Complex | `c64`, `c128` | `{ fN re; fN im; }` layout |
| Arbitrary-width | `i[_]`, `u[_]`, `f[_]` | maps to `i128` / `f128` |
| Void | `void` | |
| Character | `char` = `i8` | |

**Derived types:** pointers (`T*`), arrays (`T[N]`), function pointers.

**Nullable types:** `?T` accepts `null`. Assigning `null` to a plain non-pointer type is a compile-time error.

**Error unions:** `!T` — functions may return `error.Name`; callers use `try` to propagate or `except |e| {}` to handle.

### Structs and Interfaces

```arc
struct Vec2 { f32 x; f32 y; }

istruc Counter {
    i32 count;
    void __construct__(Counter* self) { self.count = 0; }
    void inc(Counter* self) { self.count = self.count + 1; }
    i32  get(Counter* self) { return self.count; }
}

interface Printable {
    void print();
}
istruc MyType : Printable {
    i32 val;
    void print(MyType* self) { /* ... */ }
}
```

- `istruc X : Interface` implements an interface (vtable dispatch)
- Class inheritance (`istruc A : B` where B is an istruc) is not supported
- Method overloading is not supported — each method name must be unique

### Generics

```arc
istruc Box<T> {
    T val;
    void set(Box<T>* self, T v) { self.val = v; }
    T    get(Box<T>* self)      { return self.val; }
}
Box<i32> b;
b.set(42);
```

Generic functions, istrucs, enums, and unions are all supported. Monomorphization is performed at instantiation.

### Comptime

```arc
comptime i32 N = 10;
comptime type MyInt = i32;

comptime if (N > 5) {
    // emitted; else-branch is dropped
}
```

`comptime` variables are LLVM constants. `comptime type T = U` creates a type alias.

### First-Class Types

```arc
comptime type T = i32;
T x = 42;
```

### Range-For

```arc
i32 arr[5] = {1, 2, 3, 4, 5};
for (i32 v : arr) { /* ... */ }

// For istrucs with begin()/end() methods:
for (auto item : my_vec) { /* ... */ }
```

### Lambda

```arc
auto add = [](i32 a, i32 b) i32 { return a + b; };
i32 r = add(3, 4);

// Capture by value:
i32 x = 10;
auto fn = [x](i32 y) i32 { return x + y; };
```

### Error Handling

```arc
auto divide(i32 a, i32 b) !i32 {
    if (b == 0) { return error.DivideByZero; }
    return a / b;
}

i32 result = try divide(10, 2);

auto result2 = divide(10, 0);
except |e| { /* handle error */ }
```

### Proc Macros

```arc
tokenstream* log_calls(&memstr alloc, tokenstream* input) attr {
    return input;  // pass-through
}

#[log_calls]
i32 my_func(i32 x) { return x * 2; }
```

Proc macros are compiler-native. `attr` macros can modify the token stream; `derive` macros append to it.

### Reflection

```arc
type_info* ti = @typeinfo(i32);
// ti.kind == 0 (primitive), ti.bits == 32, ti.size == 4

type_info* ts = @typeinfo(MyStruct);
// ts.kind == 2 (struct), ts.field_count, ts.fields, ts.field_names
```

`@typeinfo(T)` is a compiler builtin — no `extern` needed.

### Ref Operator

```arc
i32 x = 42;
i32* p = ref x;    // depth 1
i32** pp = ref x;  // depth 2 — all levels heap-allocated
```

### Copy and Move

```arc
y = x;           // shallow copy (default)
y = @shcopy(x);  // explicit shallow copy
y = @decopy(x);  // deep copy (recurses into pointer fields)
@move(x, &y);    // transfer ownership (x zeroed after)
```

---

## Standard Library

Import with `extern std.NAME`:

| Module | What it provides |
|--------|-----------------|
| `std.vector` | Dynamic array `Vector<T>` |
| `std.hash` | FNV-1a, wyhash, SHA-256 |
| `std.map` | Red-black tree map |
| `std.unordered_map` | Hash map |
| `std.set` / `std.unordered_set` | Set containers |
| `std.regex` | In-house NFA/DFA regex engine |
| `std.json` | JSON parser |
| `std.toml` | TOML parser |
| `std.fs` | File system operations |
| `std.net` | TCP/UDP networking |
| `std.atomic` | Atomic operations |
| `std.thread` | Threads |
| `std.fmt` | String formatting |
| `std.math` | Math functions |
| `std.test` | Test framework |
| `std.soa` | Struct-of-arrays helpers |
| `std.encode` | UTF-8 encoding |
| `std.debug` | Poison / debug tools |

---

## Building

### Prerequisites

| Dependency | Notes |
|------------|-------|
| LLVM 22 | `lLLVM-22` must be linkable |
| `llc` | LLVM static compiler (part of LLVM) |
| `g++` | C++17 for the bootstrap |

### Bootstrap and rebuild the self-hosting compiler

```bash
# Step 1: Compile compiler/main.arc → LLVM IR
build/artemis_bootstrap_cxx.exe compiler/main.arc --unsafe \
    -S -I compiler/std/include -o build/artemis_boot.ll

# Step 2: Assemble to object file
llc -O2 -filetype=obj -o build/artemis_boot.o build/artemis_boot.ll

# Step 3: Link
g++ -O2 build/artemis_boot.o build/llvm_init.o \
    -o build/artemis.exe -lLLVM-22 -lstdc++ -lm
```

The resulting `build/artemis.exe` is the self-hosting compiler.

### Run tests

```bash
# Compiler correctness tests
build/run_tcon.exe

# Standard library tests
build/run_std.exe

# SMT safety proofs
build/run_tcon.exe tcon/smt

# Compile-error (rejection) tests
build/run_tcon.exe tcon/fail
```

---

## Usage

```bash
# Compile to executable
build/artemis.exe hello.arc -o hello.exe

# Emit LLVM IR only
build/artemis.exe hello.arc -S -o hello.ll

# Emit object file
build/artemis.exe hello.arc -c -o hello.o

# With stdlib
build/artemis.exe hello.arc -I compiler/std/include -o hello.exe
```

### Flags

| Flag | Description |
|------|-------------|
| `-o <file>` | Output file |
| `-S` | Emit LLVM IR (`.ll`) |
| `-c` | Emit object file (`.o`) |
| `--unsafe` | Disable safety checks (needed for compiler self-compilation) |
| `--use-mir` | Enable experimental MIR/LIR pipeline |
| `-I <path>` | Add directory to include search path |
| `-O0` / `-O2` | Optimization level |
| `-D <name>` | Define preprocessor symbol |

---

## Hello World

```arc
extern i32 puts(i8* s);

i32 main() {
    puts("Hello, Artemis!");
    return 0;
}
```

```bash
build/artemis.exe hello.arc -o hello.exe && ./hello.exe
# Hello, Artemis!
```

---

## Larger Example

```arc
extern i32 printf(i8* fmt, ...);
extern void* malloc(u64 n);
extern void  free(void* p);

// Generic stack
istruc Stack<T> {
    T*  data;
    i32 len;
    i32 cap;

    void __construct__(Stack<T>* self) {
        self.data = (T*)0;
        self.len  = 0;
        self.cap  = 0;
    }

    void push(Stack<T>* self, T val, &memstr a) {
        if (self.len >= self.cap) {
            i32 nc = self.cap == 0 ? 8 : self.cap * 2;
            self.data = (T*)realloc((i8*)self.data, (u64)(nc * (i32)sizeof(T)));
            self.cap  = nc;
        }
        self.data[self.len] = val;
        self.len = self.len + 1;
    }

    T pop(Stack<T>* self) {
        self.len = self.len - 1;
        return self.data[self.len];
    }
}

// Error union
auto safe_div(i32 a, i32 b) !i32 {
    if (b == 0) { return error.DivByZero; }
    return a / b;
}

i32 main() {
    // Generic istruc
    Stack<i32> s;
    s.push(10);
    s.push(20);
    printf("popped: %d\n", s.pop());  // 20

    // Error handling
    auto r = safe_div(10, 2);
    except |e| { printf("error\n"); return 1; }
    printf("10/2 = %d\n", r);

    // Reflection
    type_info* ti = @typeinfo(i32);
    printf("i32: size=%d bits=%d\n", ti.size, ti.bits);

    return 0;
}
```

---

## Known Limitations

- `&&` and `||` use eager evaluation — short-circuit semantics are planned
- No first-class string type; use `i8*` with C stdlib
- MIR/LIR pipeline is experimental (`--use-mir`)
- SMT data-race and iterator-invalidation detection is work in progress
- The `@cstype` builtin (construct-type-from-typeinfo) is not yet implemented

---

## License

MIT — see `LICENSE.md`
