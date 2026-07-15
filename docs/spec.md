# Artemis Language Specification

**Version:** 0.1.1  
**Status:** Draft

---

## 1. Type System

### 1.1 Primitive Integer Types

| Type   | Width | Signed | Alias  |
|--------|-------|--------|--------|
| `i8`   | 8     | Yes    | `char` |
| `i16`  | 16    | Yes    |        |
| `i32`  | 32    | Yes    | `int`  |
| `i64`  | 64    | Yes    |        |
| `i128` | 128   | Yes    |        |
| `i256` | 256   | Yes    | software emulation |
| `i512` | 512   | Yes    | software emulation |
| `u8`   | 8     | No     |        |
| `u16`  | 16    | No     |        |
| `u32`  | 32    | No     | `uint` |
| `u64`  | 64    | No     |        |
| `u128` | 128   | No     |        |
| `u256` | 256   | No     | software emulation |
| `u512` | 512   | No     | software emulation |

`char` is an alias for `i8`. `char*` (pointer to `char`) is the canonical string type, interchangeable with `i8*` and `u8*`.

Integer types are implicitly convertible to one another. Narrowing conversions are permitted; the value is truncated to the destination width.

### 1.2 Primitive Floating-Point Types

| Type   | Format |
|--------|--------|
| `f8`   | 8-bit float (stored as i8 internally) |
| `f16`  | half precision |
| `f32`  | single precision |
| `f64`  | double precision (`float` alias) |
| `f128` | quad precision |
| `f256` | maps to fp128 (LLVM limit) |
| `f512` | maps to fp128 (LLVM limit) |

### 1.3 Boolean

`bool` — 1-bit logical. Literals: `true`, `false`. Widens to any integer; zero-extends.

Arbitrary-width booleans: `bN` (e.g. `b8`, `b32`).

### 1.4 Void

`void` — no value. Used as function return type when nothing is returned.

### 1.5 Pointers

```
T*          // mutable pointer to T
const T*    // pointer to immutable T
T* const    // immutable pointer (const pointer, mutable data)
T**         // pointer to pointer to T
```

Any pointer type may be cast to/from `void*`. The null pointer constant is `null`; it is assignable to any pointer or nullable type.

Pointer arithmetic: `ptr + n`, `ptr - n`, `ptr[n]` all supported.

### 1.6 Arrays

```
T name[N];      // fixed-size stack array of N elements
T name[N] = { v0, v1, ... };  // with initializer
```

`sizeof(name)` gives total byte size; `sizeof(name[0])` gives element size. Indexing: `arr[i]`.

### 1.7 Function Pointers

```
RetType(Param0, Param1, ...)* ptr_name;
```

Example:

```
i32(i32, i32)* op = &add;
i32 result = op(3, 4);
```

### 1.8 Nullable Types

`?T` marks a value that may be `null`. It is a wrapper that allows `null` assignment and null-check tests without requiring an explicit pointer.

```
?i32 x = null;
if (x == null) { ... }
```

### 1.9 Const / Volatile

`const T name` — immutable variable (value cannot be changed after initialization).  
`volatile T name` — volatile-qualified; inhibits optimization of reads/writes.

### 1.10 `auto` (Type Inference)

`auto` as a variable type infers the type from the initializer. In function signatures, `auto fn() !T` means the return type is an error union (see §10).

---

## 2. Declarations

### 2.1 Variable Declarations

```
T name;                        // zero-initialized
T name = expr;                 // copy-init (for class types: calls operator= if defined)
T name(arg0, arg1, ...);       // constructor call
T name{arg0, arg1, ...};       // constructor call (brace form)
T name = T { .field = val };   // named aggregate initializer
const T name = expr;           // immutable
comptime T name = expr;       // compile-time constant (evaluated at compile time)
comptime T name;              // user manages construction manually via __construct__
```

**Constructor invocation:** For `istruc` class types, the constructor is invoked by `()` or `{}` forms. The `= expr` form calls `operator=` if the class defines one, or performs a raw store otherwise. There is no implicit constructor invocation through `=` alone.

### 2.2 `extern`

```
extern T name;                  // external variable
extern RetType funcname(params); // external function declaration
extern "C" RetType funcname(params); // C-linkage (no name mangling)
extern "C" { ... }              // C-linkage block
extern std.module;              // import a standard library module
```

### 2.3 `static`

Inside a function: `static T name = expr;` — variable with static (process-lifetime) storage, initialized once.  
Inside an `istruc`: `static T name;` — class-level storage (one instance per type).

### 2.4 `using`

```
using OldType NewName;
```

### 2.5 `using`

```
using let = const auto;
```

Contextual alias for type expressions.

### 2.6 `inline` / ``

`inline` on a function: hint to inline at call sites.  
`` on a variable: hint to keep in .

---

## 3. Literals

| Literal | Example | Notes |
|---------|---------|-------|
| Integer | `42`, `0xFF`, `0b1010`, `0o17` | decimal, hex, binary, octal |
| Integer with suffix | `42u`, `42u64` | unsigned/width suffix |
| Float | `3.14`, `1.0e-5` | `f64` by default |
| String | `"hello"` | `i8*`; null-terminated |
| Char | `'a'` | `i8` value |
| Bool | `true`, `false` | |
| Null | `null` | null pointer / nullable |

String literals default-initialize a writable stack-allocated `""` when declared as `char*` with no value.

---

## 4. Expressions

### 4.1 Arithmetic

```
a + b    a - b    a * b    a / b    a % b
++a    a++    --a    a--
-a    +a
```

### 4.2 Comparison

```
a == b    a != b    a < b    a > b    a <= b    a >= b
```

### 4.3 Logical

```
a && b    a || b    !a
```

### 4.4 Bitwise

```
a & b    a | b    a ^ b    ~a    a << b    a >> b
```

### 4.5 Assignment

```
a = b
a += b    a -= b    a *= b    a /= b    a %= b
a &= b    a |= b    a ^= b    a <<= b    a >>= b
```

Assignment to an `istruc` variable calls `operator=` if the class defines it. Otherwise it performs a raw store.

### 4.6 Ternary

```
cond ? then_expr : else_expr
```

### 4.7 Cast

```
(TargetType)expr
```

Explicit cast; supports numeric widening/narrowing, pointer reinterpretation, and void* conversions.

### 4.8 `sizeof`

```
sizeof(Type)
sizeof(expr)
```

Returns `u64` byte count.

### 4.9 Address-of / Dereference

```
&var        // address of variable → T*
*ptr        // dereference pointer
```

### 4.10 Member Access

```
obj.field       // direct member access (also works on pointer — auto-deref)
obj.method()    // method call (self pointer is implicit)
ptr->field      // explicit pointer member access (equivalent to (*ptr).field)
```

### 4.11 Subscript

```
arr[i]
```

### 4.12 Aggregate Initializer

```
TypeName { .field0 = val0, .field1 = val1 }    // named-field form
.{ .field0 = val0, .field1 = val1 }            // inferred-type form (type inferred from context)
```

### 4.13 Error Literals

```
error.Name
```

Produces an error tag value (i32) for use in error-union returning functions. See §10.

### 4.14 `try` Expression

```
T val = try fn_returning_error_union();
```

If the callee returned an error, `try` propagates it as the return value of the current (also `!T`) function. If it succeeded, unwraps the value.

### 4.15 `catch` Expression

```
fn_returning_error_union() catch |e| {
    // e is error_t { i32 code; i8* name; i8* payload; }
}
```

Catches an error from the preceding call. The handler block runs only if the call returned an error. See §10.

### 4.16 ``

```
bool b = (fn());
```

Returns `true` if the call expression would not throw (i.e., the called function is ``).

---

## 5. Statements

### 5.1 Block

```
{
    stmt1;
    stmt2;
}
```

### 5.2 `if` / `else`

```
if (cond) { ... }
if (cond) { ... } else { ... }
if (cond) { ... } else if (cond2) { ... }

comptime if (cond) { ... }        // compile-time branch
if comptime (cond) { ... }        // equivalent
```

### 5.3 `while`

```
while (cond) { ... }
```

### 5.4 `for`

```
for (init; cond; step) { ... }
```

`init` may be a variable declaration or expression statement.

### 5.5 `switch`

```
switch (expr) {
    case val0: { ... break; }
    case val1: { ... break; }
    default:   { ... }
}
```

Cases do not implicitly fall through.

### 5.6 `return`

```
return;           // void return
return expr;      // return value
```

### 5.7 `break` / `continue`

```
break;      // exit innermost loop or switch
continue;   // skip to next loop iteration
```

### 5.8 `defer`

```
defer stmt;           // execute stmt when current scope exits
defer { stmt1; stmt2; }  // defer a block
```

Deferred statements execute in LIFO order when the enclosing scope exits (including via `return`).

### 5.9 Inline Assembly

```
__asm__ {
    instruction text
    : input_name "constraint" (var)
    : output_name "=constraint" (var)
    : "clobber", ...
}
```

Constraint sections are optional. Use `"cca"` as a clobber to auto-detect clobbers.

---

## 6. Functions

### 6.1 Declaration

```
RetType funcname(ParamType param, ...) {
    ...
}
```

### 6.2 Trailing Return Type (Error Union)

```
auto funcname(params) !T {
    ...
}
```

The actual return type is `!T` — an error union of `T` and any `error.Name` value. See §10.

### 6.3 Variadic Functions

```
RetType funcname(T param, ...) { ... }
```

Accepts C-style variadic arguments.

### 6.4 ``

```
void funcname()  { ... }
```

Marks the function as non-throwing. `(fn())` tests this at compile time.

### 6.5 Generic Functions

```
T identity<T>(T x) { return x; }

// explicit instantiation
identity<i32>(42)

// inferred instantiation
identity(42)   // T inferred as i32
```

Type parameters go in `<>` after the function name.

### 6.6 Overloading

Artemis does not support function overloading by argument type. Each distinct function must have a unique name. Methods on `istruc` types may have the same name as free functions.

### 6.7 `const_resolve`

```
const_resolve funcname(params) { ... }
```

Function macro evaluated at compile time. Used for proc-macro expansion.

---

## 7. Namespaces

```
namespace Name {
    T func(params) { ... }
    istruc MyClass { ... }
}
```

Access with dot notation:

```
Name.func(args)
Name.MyClass var;
```

Namespaces may be nested:

```
namespace Outer {
namespace Inner {
    void fn() { ... }
}
}
Outer.Inner.fn();
```

---

## 8. Structs

```
struct Name {
    T field0;
    T field1;
};
```

Plain C-style aggregates. No methods. Initialize with aggregate initializer `{ .field = val }` or by direct field assignment.

```
struct Point { i32 x; i32 y; }
Point p = Point { .x = 1, .y = 2 };
```

---

## 9. Enums

Artemis has two distinct enum forms: plain C-style enums and ADT (Algebraic Data Type) enums.

### 9.1 Plain Enum

```
enum Color { red, green, blue }
```

Variants are integer constants starting at 0. Access as `Color.red`, etc.

```
i32 c = Color.green;
```

### 9.2 ADT Enum (Tagged Unions)

An ADT enum is a tagged union. The variable holds the tag and a payload. There are four variant forms.

**Variant form 1 — plain tag (no payload):**

```
enum Status { ok, fail }
Status s = Status.ok;
```

**Variant form 2 — tuple variant:**

```
enum Result {
    ok,
    err(const i8*, i32),
}
Result x = Result.err("bad input", 42);
const i8* msg  = (*x)[0];
i32       code = (*x)[1];
```

Payload fields are accessed by index via `(*var)[N]`.

**Variant form 3 — named struct variant:**

```
enum Event {
    none,
    key_press { i32 key; i32 modifiers; },
    mouse_move { f32 x; f32 y; },
}
Event e = Event.key_press { .key = 65, .modifiers = 0 };
i32 k = (*e).key;
```

Payload fields are accessed by name via `(*var).field`.

**Variant form 4 — istruc body variant:**

```
enum Msg {
    empty,
    text .{
        char* rc;
        void __construct__(Msg.text* self, char* a) {
            self.rc = a;
        }
    },
}
Msg bar = Msg.text("Hello world");
char* s = (*bar).rc;
```

The `.{ ... }` form embeds an `istruc`-like body with fields and methods. A user-defined `__construct__` can be declared; its self parameter uses the qualified name `EnumName.VariantName`. Constructor invocation uses `EnumName.VariantName(args...)`.

**Accessing payload — general rule:**

- The enum variable (`bar`) holds the tagged union value (the tag + raw bytes).
- `(*bar)` dereferences to the actual payload. Use `(*bar).field` for named struct/istruc variants, `(*bar)[N]` for tuple variants.

**Method calls on istruc body variants:**

```
e.get_code()   // equivalent to: find variant, deref, call method
```

Method calls directly on the enum variable are supported; the compiler resolves the variant's istruc method.

---

## 10. Error Unions

Error unions express fallible operations without exceptions.

### 10.1 Declaring a Fallible Function

```
auto maybe_divide(i32 a, i32 b) !i32 {
    if (b == 0) { return error.DivByZero; }
    return a / b;
}
```

The `!T` trailing return type marks the function as returning either `T` (success) or an error tag.

### 10.2 Error Literals

```
error.Name
```

A named error tag. Tags are `i32` values internally. Any name is valid; there is no enum declaration needed.

### 10.3 `catch` — Catching Errors

```
maybe_divide(10, 0) catch |e| {
    // e: error_t — has fields: i32 code, i8* name, i8* payload
    printf("Error: %s\n", e.name);
}
```

The `catch |varname| { ... }` block runs only if the preceding expression returned an error. If the expression succeeded, the block is skipped.

### 10.4 `try` — Propagating Errors

```
auto outer(i32 x) !i32 {
    i32 v = try inner(x);   // propagates error if inner fails
    return v * 2;
}
```

`try expr` unwraps the value if success, or propagates the error as the current function's return value (which must also be `!T`).

---

## 11. Nullable Types

```
?T name = null;
?i32 x  = some_value;

if (x == null) { ... }
if (x != null) { ... use x ... }
```

`?T` wraps any type to allow `null` as a valid value. This is distinct from pointer nullability.

---

## 12. `istruc` — Classes

`istruc` declares a class (named struct with methods).

### 12.1 Basic Declaration

```
istruc Point {
    i32 x;
    i32 y;

    void __construct__(Point* self, i32 a, i32 b) {
        self.x = a;
        self.y = b;
    }

    i32 sum(const Point* self) {
        return self.x + self.y;
    }
}
```

### 12.2 Construction

```
Point p(3, 4);          // parenthesis form
Point q{3, 4};          // brace form
Point r = Point { .x = 1, .y = 2 };  // aggregate init (if no __construct__)
```

The `= expr` form calls `operator=` if defined; otherwise raw store. It does not invoke the constructor.

### 12.3 Method Calls

```
p.sum()         // self pointer is implicit
p.scale(2)
```

Inside a method, `self` refers to the implicit first parameter (which must be declared explicitly).

### 12.4 `const` Methods

```
i32 get(const Point* self) { return self.x; }
```

Declare `self` as `const T*` to prevent mutation.

### 12.5 `static` Members

```
istruc Counter {
    static i32 count;
    ...
}
Counter.count = 0;
```

### 12.6 Operator Overloading

Supported operators: `operator[]`, `operator=`, and others declared via `operator` keyword.

```
istruc Vec {
    i32 data[4];
    i32 operator[](Vec* self, i32 i) { return self.data[i]; }
    void operator=(Vec* self, Vec* other) { ... }
}
```

`operator=` is called when assigning to an `istruc` variable if defined.

### 12.7 `comptime`

```
comptime Timer u;
u.__construct__(20);  // user calls constructor manually
```

`comptime` allocates the object without running any constructor. The user must call `__construct__` explicitly.

### 12.8 Generic `istruc`

```
istruc Box<T> {
    T value;
}
Box<i32> b;
b.value = 77;
```

Type parameters go in `<>` after the class name.

### 12.9 Interfaces

```
interface Describable {
    i32 describe(Describable* self);
}

istruc Point : Describable {
    i32 x; i32 y;
    i32 describe(Point* self) { return self.x * 100 + self.y; }
}
```

A class declares conformance to an interface with `: InterfaceName`. The compiler verifies that all declared methods and fields are present.

Interface field stubs:

```
interface HasId {
    i32 id;
    i8* name = (i8*)0;   // optional field with default value
}
```

Fields without defaults must be present in the implementing struct. Fields with defaults are optional.

### 12.10 Method Name Mangling

Methods are internally mangled as `ClassName__MT_methodname`. `operator=` is `ClassName__MT_operator=`. This is an implementation detail; user code uses the `.method()` syntax.

---

## 13. Allocators / `memstr`

Artemis does not have a built-in heap allocator keyword. Allocation is explicit via `malloc`/`free` or user-defined allocator structs.

The `memstr` type marker in function parameters indicates an allocator-compatible struct:

```
void push(vector* self, T val, &memstr a) {
    // a is an allocator passed by reference
    a.mmap(size);    // allocate
    a.deinit(ptr);   // free
}
```

`&memstr name` in a parameter list accepts any istruc that provides allocator methods. This is a structural duck-typing mechanism.

Standard allocator patterns:

- **Heap allocator**: wraps `malloc`/`free` in an `istruc`
- **Arena allocator**: bump-pointer allocator over a single block
- **Pool allocator**: fixed-size slab allocator

---

## 14. Generics

### 14.1 Generic Functions

```
T max<T>(T a, T b) { return a > b ? a : b; }

// usage
max<i32>(3, 5)    // explicit
max(3, 5)          // inferred
```

### 14.2 Generic Structs

```
istruc Pair<A, B> {
    A first;
    B second;
}

Pair<i32, f64> p;
p.first = 1;
p.second = 2.0;
```

### 14.3 `type` — Comptime Type-Erased Parameters

`type` marks a compile-time-erased parameter (structural typing without a concrete type name). Used internally for generic allocator passing.

---

## 15. Preprocessor

Preprocessor directives use `@`:

| Directive | Description |
|-----------|-------------|
| `@define <NAME> <value>` | Define a macro constant |
| `@undef <NAME>` | Undefine a macro |
| `@ifdef <NAME>` | Conditional: if defined |
| `@ifndef <NAME>` | Conditional: if not defined |
| `@else` | Else branch |
| `@elif <NAME>` | Else-if branch |
| `@elifdef <NAME>` | Else-if defined |
| `@elifndef <NAME>` | Else-if not defined |
| `@endif` | End conditional block |
| `@error <message>` | Emit compile error |
| `@include <file>` | Include source file |
| `@embed <file>` | Embed file contents as code |
| `@pragma once` | Include guard |

Example:

```
@define <DEBUG> <1>
@define <MAX_SIZE> <1024>

@ifdef DEBUG
    printf("debug mode\n");
@endif
```

---

## 16. Inline Assembly

```
__asm__ {
    instructions
    : inputname "constraint" (var)
    : outputname "=constraint" (var)
    : "clobbers"
}
```

- Instructions reference variables by `%name` or positional `*N`.
- Constraint modifiers: `"r"` (), `"m"` (memory), `"i"` (immediate).
- `"cca"` as a clobber string means auto-detect.
- All three `:` sections are optional.

Example:

```
i32 a = 3; i32 b = 4; i32 result;
__asm__ {
    add %a, %b
    : result "=r" (result)
    : a "r" (a), b "r" (b)
}
```

---

## 17. `comptime` / `comptime`

### 17.1 `comptime` Variables

```
comptime i32 N = 6;
comptime i32 M = N + 1;   // computed at compile time
```

`comptime` variables are compile-time constants usable as array sizes, template arguments, and in constant expressions.

### 17.2 `comptime if`

```
comptime if (SOME_CONST == 1) {
    ...
}
```

The branch that is not taken is not compiled.

### 17.3 `comptime` Variables

```
comptime Timer u;
u.__construct__(20);
```

`comptime` declares a variable without running its constructor. The user invokes `__construct__` manually. Useful when construction order must be controlled explicitly.

---

## 18. Type Reflection

```
@typeinfo(Type)
```

Returns compile-time type information for `Type`. Used for proc-macro and metaprogramming purposes.

---

## 19. Standard Library

Standard library modules are imported with:

```
extern std.module_name;
```

### 19.1 `std.fmt`

Full I/O and string formatting library.

**Stdout:**
```
std.fmt.out_print(i8* s)
std.fmt.out_println(i8* s)
std.fmt.out_print_i32(i32 v)
std.fmt.out_print_i64(i64 v)
std.fmt.out_print_u32(u32 v)
std.fmt.out_print_u64(u64 v)
std.fmt.out_print_f32(f32 v)
std.fmt.out_print_f64(f64 v)
std.fmt.out_print_bool(bool b)
std.fmt.out_print_char(i8 c)
std.fmt.out_print_hex(u64 v)
std.fmt.out_print_ptr(void* p)
std.fmt.out_flush()
```

**Stderr:**
```
std.fmt.err_print(i8* s)
std.fmt.err_println(i8* s)
std.fmt.err_print_i32(i32 v)
std.fmt.err_flush()
```

**Buffer formatting:**
```
i32 std.fmt.fmt_i32(i8* buf, u64 cap, i32 v)
i32 std.fmt.fmt_i64(i8* buf, u64 cap, i64 v)
i32 std.fmt.fmt_u32(i8* buf, u64 cap, u32 v)
i32 std.fmt.fmt_u64(i8* buf, u64 cap, u64 v)
i32 std.fmt.fmt_f64(i8* buf, u64 cap, f64 v)
i32 std.fmt.fmt_hex(i8* buf, u64 cap, u64 v)
i32 std.fmt.fmt_ptr(i8* buf, u64 cap, void* p)
```

**File I/O (low-level):**
```
void* std.fmt.file_open(i8* path, i8* mode)
i32   std.fmt.file_close(void* fp)
u64   std.fmt.file_read_bytes(void* fp, void* buf, u64 n)
u64   std.fmt.file_write_bytes(void* fp, void* buf, u64 n)
i64   std.fmt.file_read_all(i8* path, i8* buf, u64 cap)
bool  std.fmt.file_at_eof(void* fp)
bool  std.fmt.file_has_error(void* fp)
void  std.fmt.file_seek_start(void* fp, i64 off)
void  std.fmt.file_seek_cur(void* fp, i64 off)
void  std.fmt.file_seek_end(void* fp, i64 off)
i64   std.fmt.file_tell(void* fp)
void  std.fmt.file_flush(void* fp)
```

**String operations:**
```
i32  std.fmt.str_len(i8* s)
bool std.fmt.str_eq(i8* a, i8* b)
void std.fmt.str_copy(i8* dst, i8* src, u64 cap)
void std.fmt.str_append(i8* dst, i8* src, u64 cap)
bool std.fmt.str_starts_with(i8* s, i8* prefix)
bool std.fmt.str_ends_with(i8* s, i8* suffix)
i32  std.fmt.str_find(i8* haystack, i8* needle)
i32  std.fmt.str_to_i32(i8* s)
i64  std.fmt.str_to_i64(i8* s)
```

### 19.2 `std.fs`

File system operations.

**`istruc std.fs.file`** — file handle:
```
bool open(file* self, i8* path, i8* mode)
void close(file* self)
u64  read_bytes(file* self, void* buf, u64 n)
u64  write_bytes(file* self, void* buf, u64 n)
bool write_str(file* self, i8* s)
i32  read_char(file* self)
bool read_line(file* self, i8* buf, i32 cap)
void seek_start(file* self, i64 off)
void seek_cur(file* self, i64 off)
void seek_end(file* self, i64 off)
i64  tell(file* self)
i64  size(file* self)
i64  read_all(file* self, i8* buf, u64 cap)
bool at_eof(file* self)
bool has_error(file* self)
bool is_open(file* self)
void flush(file* self)
```

**Path utilities (`std.fs.path`):**
```
bool std.fs.path.exists(i8* p)
bool std.fs.path.is_readable(i8* p)
bool std.fs.path.is_writable(i8* p)
i32  std.fs.path.basename_start(i8* path)
i32  std.fs.path.extension_start(i8* path)
void std.fs.path.join(i8* out, u64 cap, i8* dir, i8* name)
```

**Directory / misc:**
```
bool std.fs.make_dir(i8* path)
bool std.fs.remove_file(i8* path)
bool std.fs.remove_dir(i8* path)
bool std.fs.rename_path(i8* old, i8* new)
i8*  std.fs.cwd(i8* buf, u64 cap)
bool std.fs.cd(i8* path)
```

**Constants:** `std.fs.F_OK`, `R_OK`, `W_OK`, `X_OK`

### 19.3 `std.vector`

Dynamic resizable array.

```
extern std.vector;

std.vector<i32> v;              // default construct
std.vector<i32> v(cap, alloc); // with initial capacity
```

**Methods:**
```
void push(vector* self, T val, &memstr a)
T    pop(vector* self)
T    at(vector* self, i32 i)
T*   get(vector* self, i32 i)
void set(vector* self, i32 i, T val)
void insert(vector* self, i32 idx, T val, &memstr a)
void remove_at(vector* self, i32 idx)
void clear(vector* self)
bool is_empty(vector* self)
i32  size(vector* self)
i32  capacity(vector* self)
T*   raw(vector* self)
bool contains(vector* self, T val)
i32  index_of(vector* self, T val)
void reserve(vector* self, i32 new_cap, &memstr a)
void resize(vector* self, i32 new_len, T fill, &memstr a)
void reverse(vector* self)
void grow(vector* self, &memstr a)
void deinit(vector* self, &memstr a)
T    operator[](vector* self, i32 i)
```

**Free functions:**
```
std.vector<T> std.make_vector<T>(T* ptr, i32 len)
T*             std.make_ptr<T>(vector<T>* v)
```

### 19.4 `std.hash`

Non-cryptographic and cryptographic hash functions.

**Wyhash:**
```
u64 std.hash.wyhash_hash_bytes(u8* data, u64 len, u64 seed)
u64 std.hash.wyhash_hash_str(i8* s, u64 seed)
u64 std.hash.wyhash_hash_i64(i64 v, u64 seed)
u64 std.hash.wyhash_hash_u64(u64 v, u64 seed)
u64 std.hash.wyhash_hash_f64(f64 v, u64 seed)
```

**FNV-1a:**
```
u64 std.hash.fnv_hash_bytes(u8* data, u64 len)
u64 std.hash.fnv_hash_str(i8* s)
u32 std.hash.fnv_hash32_bytes(u8* data, u64 len)
```

**SHA-256:**
```
struct std.hash.sha256_digest { u8 bytes[32]; }

istruc std.hash.sha256_ctx {
    void __construct__(sha256_ctx* self)
    void update(sha256_ctx* self, u8* data, u64 len)
    sha256_digest finalize(sha256_ctx* self)
}

std.hash.sha256_digest std.hash.sha256_hash_bytes(u8* data, u64 len)
std.hash.sha256_digest std.hash.sha256_hash_str(i8* s)
```

**Constants:** `std.hash.FNV_OFFSET`, `std.hash.FNV_PRIME`, `WYHASH_SECRET0`–`WYHASH_SECRET3`

### 19.5 `std.atomic`

Atomic-style primitives (currently implemented as direct field ops — not yet hardware-atomic).

**Types:** `std.atomic.i32_t`, `i64_t`, `bool_t`, `ptr_t`, `spin_lock`, `ref_count`

**`i32_t` methods:**
```
i32  load(i32_t* self)
void store(i32_t* self, i32 v)
i32  fetch_add(i32_t* self, i32 delta)
i32  fetch_sub(i32_t* self, i32 delta)
i32  fetch_and(i32_t* self, i32 mask)
i32  fetch_or(i32_t* self, i32 mask)
i32  fetch_xor(i32_t* self, i32 mask)
i32  compare_exchange(i32_t* self, i32 expected, i32 desired)
bool cas(i32_t* self, i32 expected, i32 desired)
i32  inc(i32_t* self)
i32  dec(i32_t* self)
```

**Fence stubs:** `std.atomic.fence_acquire()`, `fence_release()`, `fence_seq_cst()`

**Constants:** `RELAXED`, `ACQUIRE`, `RELEASE`, `ACQ_REL`, `SEQ_CST`

### 19.6 `std.encode`

Unicode encode/decode utilities.

**UTF-8:**
```
u32 std.encode.utf8_decode_one(u8* buf, u64 len, u64* pos)
i32 std.encode.utf8_encode_one(u32 cp, u8* buf)
bool std.encode.utf8_validate(u8* buf, u64 len)
i32  std.encode.utf8_count(u8* buf, u64 len)
```

**`istruc std.encode.utf8_string`** — UTF-8 string wrapper:
```
i32  len_bytes(utf8_string* self)
u8*  raw(utf8_string* self)
i8*  c_str(utf8_string* self)
bool eq(utf8_string* self, utf8_string* o)
```

**UTF-16:**
```
u32 std.encode.utf16_decode_one(u16* buf, u64 len_units, u64* pos)
i32 std.encode.utf16_encode_one(u32 cp, u16* buf)
```

**`istruc std.encode.utf16_string`**, **`istruc std.encode.utf32_string`** — analogous wrappers.

### 19.7 `std.debug`

Assertions and panic.

```
void std.debug.panic(i8* msg)
void std.debug.panic_fmt(i8* fmt, i32 val)
void std.debug.bounds_check(i32 idx, i32 len, i8* context)
void std.debug.null_check(void* p, i8* context)
void std.debug.assert(bool cond, i8* msg)   // only active when @define <DEBUG> <1>
void std.debug.poison(void* p, u64 n)
bool std.debug.is_poisoned(void* p, u64 n)
void std.debug.breakpoint()
```

### 19.8 `std.test`

Test runner and assertion framework.

**`istruc std.test.runner`** — test runner:
```
void begin(runner* self, i8* name)
void record_fail(runner* self)
void end(runner* self)
i32  finish(runner* self)   // returns 1 if any tests failed, 0 otherwise
```

**`istruc std.test.test_alloc`** — tracking allocator:
```
void* alloc(test_alloc* self, u64 size)
void  dealloc(test_alloc* self, void* p, u64 size)
bool  has_leaks(test_alloc* self)
i32   leak_count(test_alloc* self)
void  report_leaks(test_alloc* self)
```

**Hard assertions (abort on failure):**
```
void std.test.assert_true(bool cond, i8* msg, i8* file, i32 line)
void std.test.assert_false(bool cond, i8* msg, i8* file, i32 line)
void std.test.assert_eq_i32(i32 a, i32 b, i8* msg, i8* file, i32 line)
void std.test.assert_eq_i64(i64 a, i64 b, i8* msg, i8* file, i32 line)
void std.test.assert_eq_f64(f64 a, f64 b, f64 eps, i8* msg, i8* file, i32 line)
void std.test.assert_eq_str(i8* a, i8* b, i8* msg, i8* file, i32 line)
void std.test.assert_null(void* p, i8* msg, i8* file, i32 line)
void std.test.assert_not_null(void* p, i8* msg, i8* file, i32 line)
```

**Soft assertions (record failure, continue):**
```
void std.test.expect_true(runner* r, bool cond, i8* msg)
void std.test.expect_eq_i32(runner* r, i32 a, i32 b, i8* msg)
void std.test.expect_eq_str(runner* r, i8* a, i8* b, i8* msg)
void std.test.expect_null(runner* r, void* p, i8* msg)
void std.test.expect_not_null(runner* r, void* p, i8* msg)
```

---

## 20. Compiler Flags

| Flag | Description |
|------|-------------|
| `-O0` | No optimization |
| `-O1` | Basic optimization |
| `-O2` | Standard optimization |
| `-O3` | Aggressive optimization |
| `-emit-llvm` | Emit LLVM IR instead of native binary |
| `-o <file>` | Output file path |
| `-I <dir>` | Add include search directory |
| `--no-std` | Do not include standard library |

---

## 21. Default Initialization Rules

| Type | Default value |
|------|--------------|
| Integer (`iN`, `uN`) | `0` |
| Float (`fN`) | `0.0` |
| Bool | `false` |
| Pointer (`T*`) | `null` (0) |
| `char*` / `i8*` / `u8*` | writable stack-allocated `""` |
| `?T` | `null` |
| `istruc` with zero-arg `__construct__` | constructor called |
| `istruc` without constructor | zeroed memory |
| Array | elements zero-initialized |

---

## Appendix A: Keyword Reference

| Keyword | Description |
|---------|-------------|
| `if`, `else` | Conditional |
| `while` | While loop |
| `for` | For loop |
| `switch`, `case`, `default` | Switch statement |
| `return` | Return from function |
| `break`, `continue` | Loop control |
| `true`, `false` | Boolean literals |
| `null` | Null pointer / nullable |
| `void` | No-value type |
| `const` | Immutable qualifier |
| `volatile` | Volatile qualifier |
| `static` | Static storage |
| `extern` | External linkage / import |
| `inline` | Inline hint |
| `sizeof` | Size of type/expr |
| `struct` | Plain aggregate |
| `enum` | Enum or ADT enum |
| `union` | C-style union |
| `istruc` | Class (struct with methods) |
| `interface` | Contract declaration |
| `namespace` | Namespace scope |
| `using` | Type alias |
| `using` | Contextual alias |
| `operator` | Operator overload |
| `comptime` | Compile-time constant |
| `comptime` | Manual-construction marker |
| `auto` | Type inference / error-union placeholder |
| `defer` | Deferred execution |
| `try` | Error propagation |
| `catch` | Error catching |
| `error` | Error literal (`error.Name`) |
| `__asm__` | Inline assembly |
| `type` | Comptime type-erased parameter |

---

## Appendix B: Name Mangling

| Pattern | Mangled form |
|---------|-------------|
| Method `method` on class `Foo` | `Foo__MT_method` |
| `operator=` on class `Foo` | `Foo__MT_operator=` |
| Namespace `ns` + name `bar` | `ns__NS_bar` |
| ADT istruc variant `Enum.Variant` | `Enum__NS_Variant` (as a type name) |
| ADT variant constructor | `EnumName__VariantName__ctor` |

Scope resolution `.` in source code maps to `__NS_` in internal names.

---

## Appendix C: Grammar (Partial)

```
program       .= decl*
decl          .= var_decl | func_decl | struct_decl | enum_decl | istruc_decl
                | namespace_decl | interface_decl | using | extern_decl | extern_std

type          .= prim_type | id ('<' type_args '>')?  | type ('*')+ | '?' type
                | type '[' expr ']' | ret_type '(' param_types ')' '*'
                | 'const' type | 'volatile' type | '&' 'memstr'

var_decl      .= type id ('=' expr | '(' args ')' | '{' args '}')? ';'
                | 'comptime' type id '=' expr ';'
                | 'comptime' type id ';'

func_decl     .= type id ('<' tparams '>')? '(' params ')' ('')? block
                | 'auto' id ('<' tparams '>')? '(' params ')' '!' type block

enum_decl     .= 'enum' id '{' variant (',' variant)* ','? '}'
variant       .= id
                | id '(' types ')'
                | id '{' fields '}'
                | id '.{' class_body '}'

istruc_decl   .= 'istruc' id ('<' tparams '>')? (':' id)? '{' member* '}'
member        .= var_decl | func_decl | 'static' var_decl

namespace_decl .= 'namespace' id '{' decl* '}'

interface_decl .= 'interface' id '{' interface_member* '}'
interface_member .= func_decl_sig | var_decl

stmt          .= block | if_stmt | while_stmt | for_stmt | switch_stmt
                | return_stmt | break_stmt | continue_stmt | defer_stmt
                | asm_stmt | var_decl | expr_stmt

expr          .= literal | id | unary_op expr | expr binary_op expr
                | expr '?' expr ':' expr | '(' type ')' expr
                | expr '(' args ')' | expr '[' expr ']' | expr '.' id
                | 'sizeof' '(' type_or_expr ')' | 'error' '.' id
                | 'try' expr | expr 'catch' '|' id '|' block
                | 'null' | type '{' field_inits '}'
                | '.' '{' field_inits '}'
```

---

## §18. Generics — istruc, enum, union

Generic types use the same `<T>` syntax as generic functions.

### 18.1 Generic istruc

```arc
istruc Pair<T> {
    T first;
    T second;
    void __construct__(Pair<T>* self, T a, T b) { self.first = a; self.second = b; }
}

Pair<i32> p(1, 2);
Pair<f64> q(3.14, 2.71);
```

At each use site the compiler monomorphizes the struct, creating `Pair__mono_i32` and `Pair__mono_f64` LLVM struct types.

### 18.2 Generic enum

```arc
enum Maybe<T> { nothing, something, }

Maybe<i32> m;
m = nothing;    // variant value 0
m = something;  // variant value 1
```

Generic enums have the same integer representation as plain enums. The type parameter is informational for the programmer; variants use bare names.

### 18.3 Generic union

```arc
union Either<T> { T val; i32 tag; }

Either<f32> e;
e.tag = 1;
```

All fields share the same memory region (max-field-size bytes). Generic unions are monomorphized at use sites.

---

## §19. Range-for (`for (T x : container)`)

Two forms are supported.

### 19.1 Array range-for

```arc
i32 arr[5];
for (i32 x : arr) { /* x iterates arr[0..4] */ }
```

The compiler emits a counter loop from 0 to the statically-known length.

### 19.2 begin()/end() range-for

Any istruc with `begin()` and `end()` methods returning a pointer type works:

```arc
istruc Span {
    i32* ptr;
    i32  len;
    i32* begin(Span* self) { return self.ptr; }
    i32* end(Span*   self) { return self.ptr + self.len; }
}

Span s;
for (i32 x : s) { /* x is each element via iterator */ }
```

The desugared form is:

```arc
T* __it  = s.begin();
T* __end = s.end();
while (__it != __end) { T x = *__it; BODY; __it = __it + 1; }
```

`auto` as the element type infers from `*begin()`.

---

## §20. `comptime type` — First-Class Type Aliases

```arc
comptime type MyInt = i32;
comptime type Vec2  = Pair<i32>;

MyInt a = 42;
Vec2  v(1, 2);
```

`comptime type T = Expr;` at top-level declares `T` as a compile-time alias for the type `Expr`. It is equivalent to `using T = Expr;` with explicit comptime semantics.

---

## §21. New Primitive Types

| Prefix | Meaning | Backing type |
|--------|---------|--------------|
| `nN`   | natural number (≥0) | `uN` |
| `zN`   | integer | `iN` |
| `chN`  | N-bit character | `uN` |
| `cN`   | complex (re + im) | struct `{ fN re; fN im; }` |
| `qN`   | rational (num / den) | struct `{ iN num; iN den; }` |

```arc
n8  a = 200u;        // unsigned 8-bit natural
z32 b = -100;        // signed 32-bit integer
ch8 c = 'A';         // 8-bit character
c64 z;  z.re = 1.0;  z.im = 2.0;
q32 r;  r.num = 3;   r.den = 4;
```

---

## §22. Proc Macros

### 22.1 Declaration

```arc
tokenstream* log_calls(&memstr alloc, tokenstream* input) attr { return input; }
tokenstream* add_debug(&memstr alloc, tokenstream* input) derive { return input; }
```

`attr` macros may modify any part of the decorated declaration. `derive` macros may only append new declarations. `attr verify` additionally syntax-checks the token stream before the macro receives it.

### 22.2 Application

```arc
#[log_calls]
i32 my_func(i32 x) { return x * 2; }

#derive[add_debug]
istruc MyType { i32 val; }

#![log_calls]   // applies to the whole file
```

### 22.3 Token stream type

```arc
struct token {
    i32  kind;   // lexer token_type value
    i8*  text;   // raw source text
    u64  line;
    u64  col;
}
// tokenstream = token* (array; len passed separately or null-terminated)
```

Compiler-provided helpers: `quote { code }` → `token*`, `ast(token*)` → opaque AST, `tks(void*)` → `token*`.

---

## §23. `@typeinfo` — Compile-time Type Reflection

```arc
type_info* ti = @typeinfo(i32);
type_info* ts = @typeinfo(MyStruct);
```

Returns a pointer to a compiler-generated constant `type_info` struct.

### 23.1 `type_info` layout

| Field | Type | Description |
|-------|------|-------------|
| `name` | `i8*` | type name |
| `size` | `i32` | byte size |
| `align` | `i32` | byte alignment |
| `kind` | `i32` | see table below |
| `bits` | `i32` | bit width (primitives) |
| `is_signed` | `i32` | 1 if signed integer |
| `field_count` | `i32` | struct field count |
| `fields` | `type_info_field*` | array of field descriptors |
| `elem_type` | `type_info*` | pointee type (pointer kinds) |
| `method_count` | `i32` | method count |
| `methods` | `type_info_method*` | array of method descriptors |

### 23.2 Kind constants

| Value | Meaning |
|-------|---------|
| 0 | `IFO_KIND_PRIM` — primitive |
| 1 | `IFO_KIND_PTR` — pointer |
| 2 | `IFO_KIND_STRUCT` — struct |
| 3 | `IFO_KIND_UNION` — union |
| 4 | `IFO_KIND_ENUM` — enum |
| 5 | `IFO_KIND_ISTRUC` — istruc |
| 6 | `IFO_KIND_ARRAY` — fixed array |
| 7 | `IFO_KIND_FUNC` — function pointer |
| 8 | `IFO_KIND_UNKNOWN` — unresolved |

### 23.3 `type_info_field` layout

| Field | Type | Description |
|-------|------|-------------|
| `name` | `i8*` | field name |
| `offset` | `i32` | byte offset within struct |
| `size` | `i32` | field byte size |
| `align` | `i32` | field alignment |

No `extern` statement is needed; `type_info`, `type_info_field`, and `type_info_method` are compiler builtins.

---

## §24. MIR / LIR Pipeline (experimental, `--use-mir`)

The compiler includes a mid-level (MIR) and low-level (LIR) intermediate representation layer gated behind the `--use-mir` flag. When supplied, the pipeline is:

```
AST → Semantic Analysis → MIR → LIR → SMT → LLVM IR
```

Without `--use-mir`, the pipeline goes directly `AST → LLVM IR`.

**MIR** (`compiler/mir/`): Three-address, single-assignment form. All loops are flattened to label/branch; compound conditions are split; struct field accesses normalized to byte offsets.

**LIR** (`compiler/lir/`): Scalar-only form derived from MIR. All aggregate values become pointer + scalar loads/stores. Includes `LI_RTCHECK_NULL` and `LI_RTCHECK_BOUNDS` pseudo-instructions for SMT injection points.

Both passes are currently scaffolded; the full lowering implementation is a work in progress.

---

## §25. `std.regex` — In-house Regex Engine

The standard library provides a native regex engine with no external dependencies.

```arc
extern std.regex;

regex_t r("\\d+", 0u);
if (r.is_valid()) { /* ... */ }
if (r.test("123", 3)) { /* matches */ }
```

### 25.1 API

| Method | Description |
|--------|-------------|
| `regex_t(pattern, flags)` | Compile pattern |
| `r.is_valid()` | True if compilation succeeded |
| `r.test(str, len)` | True if pattern matches anywhere in str |
| `r.find(str, len, cap)` | Fills `capture_t cap[10]`; returns match count |
| `std.regex.find_offset(r, str, len, offset)` | Match starting from byte offset |

### 25.2 Flags

| Constant | Meaning |
|----------|---------|
| `std.regex.REGEX_CASELESS` | Case-insensitive matching |
| `std.regex.REGEX_MULTILINE` | `^`/`$` match line boundaries |
| `std.regex.REGEX_DOTALL` | `.` matches `\n` |

### 25.3 Character class escapes

`\d` digits, `\w` word characters, `\s` whitespace, `\D \W \S` negated forms. Character classes `[...]` and negated classes `[^...]` are supported. Quantifiers: `*`, `+`, `?`, `{n}`, `{n,m}`. Alternation `|` and capture groups `(...)`.

### 25.4 `capture_t`

```arc
struct capture_t { i32 start; i32 len; }
```

`REGEX_MAX_CAPTURES` = 10.
