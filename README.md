# Artemis

Artemis is a compiled, statically-typed, C-like language that targets LLVM IR. It is designed to be simple, explicit, and fast. The compiler is written in C++17 and uses the LLVM C API for code generation.

---

## Language Features

- **Character type:** `char` (alias for `i8`); `char*` is the canonical string pointer type
- **Rich integer types:** `i8`, `i16`, `i32`/`int`, `i64`, `i128`, `i256`, `i512` and unsigned equivalents `u8` … `u512`; implicit integer conversion between all integer widths
- **Floating-point types:** `f32`, `f64`, `f128`, `f256`, `f512`
- **Boolean types:** `bool`, `b1` (1-bit), `b8`, `b16`, `b32`, `b64`, `b128`, `b256`, `b512`
- **Derived types:** pointers (`*`), fixed-size arrays (`[N]`), structs, unions, enums, typedefs
- **Control flow:** `if`/`else`, `while`, `for`, `switch`/`case`/`default`, `break`, `continue`, `return`
- **Functions:** first-class declarations, forward declarations (prototypes), variadic functions (`...`)
- **Storage class specifiers:** `extern`, `extern std`, `inline`, `register`, `const`
- **Operators:** full set of arithmetic, bitwise, logical, comparison, assignment, and compound-assignment operators; prefix/postfix increment/decrement; `sizeof`; ternary `?:`; address-of `&`; dereference `*`
- **Annotations:** `@identifier` syntax for attaching metadata to expressions
- **C interoperability:** `extern` linkage lets you call any C function

---

## Prerequisites

| Dependency | Minimum version |
|------------|----------------|
| LLVM       | 17              |
| clang / g++ | C++17 support  |
| CMake      | 3.20            |

On Ubuntu:

```bash
sudo apt-get install llvm-18-dev clang-18 cmake
```

On macOS (Homebrew):

```bash
brew install llvm cmake
```

---

## Building

```bash
# 1. Clone
git clone https://github.com/your-org/artemis.git
cd artemis

# 2. Configure (Debug)
cmake -B build -DCMAKE_BUILD_TYPE=Debug \
  -DLLVM_DIR=$(llvm-config --cmakedir)

# 3. Build
cmake --build build --parallel

# 4. Run tests
ctest --test-dir build --output-on-failure
```

For a Release build with optimisations:

```bash
cmake -B build_rel -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_DIR=$(llvm-config --cmakedir)
cmake --build build_rel --parallel
```

To enable AddressSanitizer + UBSan:

```bash
cmake -B build_asan -DENABLE_ASAN=ON \
  -DLLVM_DIR=$(llvm-config --cmakedir)
cmake --build build_asan --parallel
```

---

## Usage

### Compile to executable

```bash
artemis hello.art -o hello
./hello
```

### Compile with atc (automatic target)

```bash
atc hello.art -o hello          # host target
atc hello.art -l hello_linux    # Linux x86-64
atc hello.art -w hello.exe      # Windows x86-64
atc hello.art -m hello_mac      # macOS x86-64
atc run hello.art               # compile and run immediately
```

### Compile and run immediately

```bash
atx run hello.art
```

### Emit LLVM IR

```bash
artemis hello.art -S -o hello.ll
```

### Emit object file

```bash
artemis hello.art -c -o hello.o
```

### Dump AST

```bash
artemis hello.art --emit-ast
```

### Flags reference

| Flag                  | Description                              |
|-----------------------|------------------------------------------|
| `-o <file>`           | Output file (default: `a.out`)           |
| `-S`                  | Emit LLVM IR (`.ll`) only                |
| `-c`                  | Emit object file (`.o`) only             |
| `--emit-ast`          | Print AST to stdout and exit             |
| `-O0` / `-O1` / `-O2` / `-O3` | Optimisation level (default: `-O0`) |
| `--target <triple>`   | LLVM target triple (default: host)       |
| `-v` / `--verbose`    | Verbose output                           |
| `--version`           | Print version and exit                   |
| `-h` / `--help`       | Print usage and exit                     |

---

## Hello World

Save as `hello.art`:

```c
extern int puts(const i8* s);

int main() {
    puts("Hello, Artemis!");
    return 0;
}
```

Compile and run:

```bash
artemis hello.art -o hello && ./hello
# Hello, Artemis!
```

---

## A Larger Example

```c
// Fibonacci — recursive
int fib(int n) {
    if (n <= 1) { return n; }
    return fib(n - 1) + fib(n - 2);
}

// Generic max via ternary
int max_int(int a, int b) { return a > b ? a : b; }

// Struct and member access
struct Vec2 {
    f32 x;
    f32 y;
}

f32 dot(Vec2 a, Vec2 b) {
    return a.x * b.x + a.y * b.y;
}

// Enum
enum Direction { North, South, East, West }

// Typedef
typedef int Score;

extern void printf(const i8* fmt, ...);

int main() {
    Score s = fib(10);
    printf("fib(10) = %d\n", s);

    Vec2 v1; v1.x = 1.0; v1.y = 0.0;
    Vec2 v2; v2.x = 0.0; v2.y = 1.0;
    printf("dot = %f\n", dot(v1, v2));
    return 0;
}
```

---

## Known Limitations

- `&&` and `||` currently use eager evaluation — short-circuit semantics are planned.
- No first-class string type; use `i8*` + C stdlib
- No generics or templates
- No modules/import system
- `f256` and `f512` map to LLVM's `fp128` (nearest available hardware type)

---

## License

MIT — see `LICENSE.md`.
