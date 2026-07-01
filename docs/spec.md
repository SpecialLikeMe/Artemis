# Artemis Language Specification

**Version:** 0.1.0  
**Status:** Draft

---

## 1. Type System

### 1.1 Primitive Integer Types

| Type   | Width | Signed | Notes                          |
|--------|-------|--------|--------------------------------|
| `i8`   | 8     | Yes    | Also spelled `char`            |
| `i16`  | 16    | Yes    |                                |
| `i32`  | 32    | Yes    | Also spelled `int`             |
| `i64`  | 64    | Yes    |                                |
| `i128` | 128   | Yes    |                                |
| `i256` | 256   | Yes    | Software emulation             |
| `i512` | 512   | Yes    | Software emulation             |
| `u8`   | 8     | No     |                                |
| `u16`  | 16    | No     |                                |
| `u32`  | 32    | No     | Also spelled `uint`            |
| `u64`  | 64    | No     |                                |
| `u128` | 128   | No     |                                |
| `u256` | 256   | No     | Software emulation             |
| `u512` | 512   | No     | Software emulation             |

`char` is an alias for `i8`. `char*` (pointer to `char`) is the canonical string type, interchangeable with `i8*` and `u8*` when assigning.

Integer types are implicitly convertible to one another in assignments. Narrowing conversions (e.g. assigning an `i32` to a `u8`) are permitted without an explicit cast; the value is truncated to the destination width at runtime.

### 1.2 Primitive Floating-Point Types

| Type   | Format        | Notes                      |
|--------|---------------|----------------------------|
| `f8`   | 8-bit float   | Stored as i8 internally    |
| `f16`  | half          |                            |
| `f32`  | single        |                            |
| `f64`  | double        | Also spelled `float`       |
| `f128` | quad          |                            |
| `f256` | —             | Maps to fp128 (LLVM limit) |
| `f512` | —             | Maps to fp128 (LLVM limit) |
(use of f256 and f512 is heavily discourage until the map issue has been resolved)

### 1.3 Boolean Types

| Type   | Width | Notes                        |
|--------|-------|------------------------------|
| `bool` | 8     | Standard boolean             |
| `b1`   | 1     | Single-bit boolean           |
| `b8`   | 8     |                              |
| `b16`  | 16    |                              |
| `b32`  | 32    |                              |
| `b64`  | 64    |                              |
| `b128` | 128   |                              |
| `b256` | 256   |                              |
| `b512` | 512   |                              |

### 1.4 Void Type

`void` — used as a function return type to indicate no value is returned. `void*` is a generic pointer.

### 1.5 Derived Types

- **Pointer:** `T*`, `T**`, etc. Pointer depth is unlimited.
- **Array:** `T[N]` where `N` is a constant-size expression.
- **Struct:** aggregate type with named fields.
- **Union:** overlapping storage for multiple field types.
- **Enum:** named integer constants backed by `i32`.
- **Typedef:** alias for any type.
- **Function pointer:** `ret(param_types)*` — a pointer to a function. See §12.
- **Class (istruc):** object type with methods and inheritance. See §11.

### 1.6 Type Qualifiers and Storage Classes

| Keyword     | Meaning                                     |
|-------------|---------------------------------------------|
| `const`     | Value may not be modified after declaration |
| `extern`    | Symbol has external linkage                 |
| `extern std`| C standard library linkage                  |
| `extern "C"`| C ABI block — no name mangling              |
| `inline`    | Hint: expand call inline                    |
| `register`  | Hint: keep in CPU register                  |

---

## 2. Declarations

### 2.1 Variable Declarations

```
type_spec name [= initializer] ;
```

Examples:
```c
i32 x;
const f64 pi = 3.14159;
i32* ptr;
i32 arr[10];
extern i32 global;
```

### 2.2 Function Declarations

Prototype (forward declaration):
```
ret_type name ( param_list ) ;
```

Definition:
```
ret_type name ( param_list ) block
```

A variadic function appends `...` after the last named parameter:
```c
void printf(const i8* fmt, ...);
```

Multiple functions may share the same name if their parameter types differ (**overloading**). The compiler selects the best match at each call site and mangles IR names automatically. See §9.

The entry-point function **must** be named `main` and **must** return `i32`. The return value is the process exit code. Any other return type for `main` is a compile-time error.

```c
i32 main() { return 0; }
```

### 2.3 Struct Declarations

```
struct Name { field_list } ;
```

Fields are `var_decl` statements without initialisers. No bit-fields.

### 2.4 Union Declarations

```
union Name { field_list } ;
```

Storage is allocated for the widest field. All fields share the same starting address.

### 2.5 Enum Declarations

```
enum Name { variant [= expr] , ... } ;
```

Variants without an explicit value are auto-numbered from 0. Variants are globally scoped constants of type `i32`.

### 2.6 Typedef

```
typedef type alias ;
```

Creates an alias that is fully interchangeable with the underlying type.

---

## 3. Expressions

### 3.1 Operator Precedence (highest to lowest)

| Level | Operators                          | Associativity |
|-------|------------------------------------|---------------|
| 14    | `()` `[]` `.` `->` (postfix `++` `--`) | Left        |
| 13    | Unary `+` `-` `!` `~` `*` `&` `++` `--` `sizeof` `(cast)` | Right |
| 12    | `*` `/` `%`                        | Left          |
| 11    | `+` `-`                            | Left          |
| 10    | `<<` `>>`                          | Left          |
| 9     | `<` `>` `<=` `>=`                  | Left          |
| 8     | `==` `!=`                          | Left          |
| 7     | `&`                                | Left          |
| 6     | `^`                                | Left          |
| 5     | `\|`                               | Left          |
| 4     | `&&`                               | Left          |
| 3     | `\|\|`                             | Left          |
| 2     | `?:` (ternary)                     | Right         |
| 1     | `=` `+=` `-=` `*=` `/=` `%=` `&=` `\|=` `^=` `<<=` `>>=` | Right |

### 3.2 Operators

**Arithmetic:** `+` `-` `*` `/` `%`  
**Bitwise:** `&` `|` `^` `~` `<<` `>>`  
**Logical:** `&&` `||` `!`  
**Comparison:** `==` `!=` `<` `>` `<=` `>=`  
**Assignment:** `=` `+=` `-=` `*=` `/=` `%=` `&=` `|=` `^=` `<<=` `>>=`  
**Increment/decrement:** `++` `--` (prefix and postfix)  
**Address-of / dereference:** `&expr` `*expr`  
**Cast:** `(type)expr`  
**Sizeof:** `sizeof(type)` or `sizeof(expr)`  
**Ternary:** `cond ? then_expr : else_expr`  
**Member access:** `expr.field` (struct/union/class by value or pointer)  
**Arrow:** `expr->field` — shorthand for `(*expr).field`; works on any pointer-to-aggregate  
**Subscript:** `expr[index]`  
**Call:** `callee(arg, ...)`

### 3.3 Annotations

`@identifier` attaches a compile-time annotation tag to an expression. The annotation name is preserved in the AST for use by tooling or future language features. Currently no runtime effect.

---

## 4. Statements

### 4.1 Expression Statement

```
expr ;
```

### 4.2 Block

```
{ stmt* }
```

A block creates a new lexical scope.

### 4.3 Variable Declaration Statement

Any variable declaration inside a function body.

### 4.4 If / Else

```
if ( expr ) stmt
if ( expr ) stmt else stmt
```

The condition may be any scalar or pointer expression. Zero / null is falsy.

### 4.5 While

```
while ( expr ) stmt
```

### 4.6 For

```
for ( init ; cond ; step ) stmt
```

`init` may be a variable declaration or an expression statement. Any of the three clauses may be empty.

### 4.7 Switch

```
switch ( expr ) {
    case const_expr : stmt*
    ...
    default : stmt*
}
```

Cases fall through by default. Use `break` to stop. The switch expression must be an integer type.

### 4.8 Return

```
return ;
return expr ;
```

A `return` with no value is only valid in `void` functions.

### 4.9 Break / Continue

`break` exits the nearest enclosing `while`, `for`, or `switch`.  
`continue` skips to the next iteration of the nearest enclosing `while` or `for`.  
Both are errors outside a loop (or outside a `switch` for `break`).

### 4.10 Defer

```
defer expr ;
defer block
```

Schedules the expression or block to execute at the end of the current scope (or before any `return` that exits the scope). Multiple `defer` statements in the same scope run in **reverse order** (LIFO). See §13.5 for full semantics.

---

## 5. Annotations

Annotations use the `@` sigil followed by an identifier:

```c
@noinline foo();
@deprecated bar = 5;
```

The annotation is parsed as a unary prefix expression over the following expression. No semantics are defined in v0.1.0; they are intended as extension points for future attributes and for tooling.

---

## 6. Preprocessor

The Artemis preprocessor runs before lexing, driven by `@`-prefixed directives. Directives must appear at the start of a line.

### 6.1 `@define`

```
@define <NAME> <expansion>
@define <NAME> <>           // empty (flag) define
```

After definition, every occurrence of `NAME` in source text is replaced by the expansion. Expansions can be multi-token. Regex-capture defines are also supported:

```
@define <PREFIX_(.+)> <value_$1>
```

### 6.2 `@undef`

```
@undef NAME
```

Removes a previous definition.

### 6.3 `@ifdef` / `@ifndef` / `@elifdef` / `@elifndef` / `@else` / `@endif`

```
@ifdef  NAME
  // included only if NAME is defined
@elifdef  OTHER
  // included if OTHER is defined and NAME was not
@else
  // fallback
@endif

@ifndef NAME
  // included only if NAME is NOT defined
@endif
```

Conditional blocks can be nested. Source inside an inactive branch is completely discarded before parsing.

### 6.4 `@error`

```
@error "message"
```

Emits a compile-time error if the directive is in an active branch.

### 6.5 `@include`

```
@include "relative/path/to/file.arc"
```

Textually inserts the contents of the named file at the include site. Only the `""` (relative path) form is supported; paths are resolved relative to the current source file. The `<>` angle-bracket form is **not** valid syntax.

To import standard library packages use `extern std.<pkg>;` instead (see §16).

### 6.5.1 `extern std.*` — Standard Library Imports

```
extern std.math;
extern std.alloc.bump;
extern std.rand;
```

Imports a standard library package into the current compilation unit. The compiler locates the corresponding file under `compiler/std/include/` and textually includes it. Dot-separated paths map to directory separators (`std.alloc.bump` → `alloc/bump.arc`).

All types and functions from the package become available by their bare names (e.g., `bump`, `abs_i32`, `xoshiro_state`).

### 6.6 `@embed`

```
@embed <filename>
```

Includes the raw bytes of a file as an array initializer.

### 6.7 Built-in defines

| Name         | Value                   |
|--------------|-------------------------|
| `_WIN32`     | Defined on Windows      |
| `_LINUX`     | Defined on Linux        |
| `_MACOS`     | Defined on macOS        |

---

## 7. Calling Convention and Extern Linkage  <!-- was §6 -->

Functions without a storage class default to external (visible to the linker) if they are top-level definitions.

`extern T name(...)` — declares a symbol with external linkage. No body is emitted; the symbol is resolved at link time. Used to call C library functions:

```c
extern void* malloc(u64 size);
extern void  free(void* ptr);
```

`extern std` — identical to `extern`; signals that the function comes from the C standard library (for tooling and future safety analysis).

All function calls use the C calling convention on the target platform (LLVM default).

---

## 7. Interoperability

Artemis can call any C-ABI function by declaring it with `extern`. Artemis-compiled functions are also callable from C as long as their signatures map cleanly to C types.

Type correspondence:

| Artemis        | C                  |
|----------------|--------------------|
| `char` / `i8`  | `char` / `int8_t`  |
| `i32`          | `int32_t` / `int`  |
| `i64`          | `int64_t`          |
| `u64`          | `uint64_t`         |
| `f32`          | `float`            |
| `f64`          | `double`           |
| `void*`        | `void*`            |
| `char*` / `i8*`| `char*`            |

---

## 8. Grammar (informal)

```
program       ::= top_level*
top_level     ::= struct_decl | enum_decl | union_decl | typedef_decl | func_or_var
func_or_var   ::= type_spec identifier ( func_suffix | var_suffix )
func_suffix   ::= '(' param_list ')' ( block | ';' )
var_suffix    ::= ( '[' expr ']' )? ( '=' expr )? ';'
type_spec     ::= storage_class* qualifier* prim_type pointer_stars
storage_class ::= 'extern' | 'extern std' | 'inline' | 'register'
qualifier     ::= 'const' | 'volatile' | 'signed' | 'unsigned'
prim_type     ::= 'void' | 'char' | 'i8' | 'i16' | ... | 'u8' | ... | 'f32' | ... | 'bool' | 'b1' | ...
               | identifier  (struct/enum/union/typedef name)
pointer_stars ::= '*'*
param_list    ::= (type_spec identifier (',' type_spec identifier)* (',' '...')? )?
block         ::= '{' stmt* '}'
stmt          ::= block | var_decl_stmt | expr_stmt | if_stmt | while_stmt
               | for_stmt | switch_stmt | return_stmt | break_stmt | continue_stmt
expr          ::= assignment_expr
assignment_expr ::= ternary_expr ( assign_op assignment_expr )?
```

---

## 9. Method Overloading

Functions with the same name but different parameter types or counts are **overloads**. The compiler picks the best match at the call site.

```c
void print(i32 x) { ... }
void print(f64 x) { ... }

print(1);    // calls print(i32)
print(1.0);  // calls print(f64)
```

**Name mangling:** When a function is overloaded the compiler emits mangled IR names of the form `funcname__type1_type2`. A function that is **not** overloaded keeps its original name. There is no explicit syntax to trigger mangling; it is automatic.

---

## 10. `extern "C"` Blocks

Wrap C-ABI declarations in an `extern "C"` block to prevent name mangling and ensure standard C calling convention.

```c
extern "C" {
    void   c_init(i32 flags);
    i32    c_read(void* buf, u64 len);
}

void use() {
    c_init(0);
    c_read(nullptr, 0);
}
```

All declarations inside the block are treated as if individually declared `extern`. Functions inside an `extern "C"` block may themselves be overloaded (mangling is still suppressed for each individual declaration).

---

## 11. Classes (`istruc`)

Artemis uses `istruc` (short for *instance structure*) for class-like aggregate types with methods, inheritance, and virtual dispatch.

### 11.1 Basic Declaration

```c
istruc Point {
    i32 x;
    i32 y;

    void move(&self, i32 dx, i32 dy) {
        x = x + dx;
        y = y + dy;
    }
}
```

Default member access is **public**. The `istruc` keyword replaces `class`.

### 11.2 Self Parameter

Instance methods use `&self` (mutable) or `&const self` (immutable) as the first parameter. The parameter is **implicitly passed** by the caller — it does not appear in call sites. Inside the body, `self` refers to the current instance pointer, and all fields are also directly in scope.

```c
istruc Counter {
    i32 value;

    void increment(&self) { value = value + 1; }
    i32  get(&const self) { return value; }
}
```

### 11.3 Access Modifiers

Access modifiers are **per-member** (Java style), not section-based:

```c
istruc Foo {
    public  i32 visible;
    private i32 hidden;

    public void bar(&self) {}
    private void internal(&self) {}
}
```

### 11.4 Inheritance

Single inheritance via `:`:

```c++
istruc Animal {
    int legs;
    virtual void speak() {}
}

istruc Dog : Animal {
    int fur_length;
    void speak() override { /* ... */ }
}
```

All methods inherited from a base are automatically virtual unless the override is marked `final`.

### 11.5 Virtual Methods and `mandatory`

```c++
istruc Base {
    virtual void optional() {}            // base impl, override not required
    mandatory virtual void required();    // derived MUST implement
}
```

A `mandatory virtual` method must be overridden in every non-abstract derived class; failing to do so is a compile-time error.

### 11.6 Method Qualifiers

After `)` and before `{`:

| Qualifier  | Meaning                                           |
|------------|---------------------------------------------------|
| `const`    | Method does not mutate the instance               |
| `override` | Explicitly marks this as overriding a base method |
| `final`    | Prevents further overriding in derived classes    |

```c
void tick(&const self) const override final {}
```

### 11.7 Static Methods

```c
istruc Math {
    static i32 abs(i32 x) { return x < 0 ? -x : x; }
}
```

`static` methods belong to the class, not an instance. They do not receive `&self`.

### 11.8 Constructor and Destructor

The constructor is named `__construct__` and the destructor `__destruct__`. Constructor init-list syntax is supported:

```c
istruc Vec2 {
    i32 x; i32 y;
    __construct__(&self, i32 vx, i32 vy) : x(vx), y(vy) {}
    __destruct__(&self) {}
}
```

### 11.9 Operator Overloading

```c++
istruc Vec2 {
    i32 x; i32 y;

    Vec2 operator+(&const self, Vec2 rhs) const {
        Vec2 result;
        result.x = x + rhs.x;
        result.y = y + rhs.y;
        return result;
    }
}
```

### 11.10 Conversion Operators

```c++
istruc MyFloat {
    f64 val;
    operator f64() const { return val; }
    operator int() const { return (i32)val; }
}
```

### 11.11 `local` (Friend-like)

`local` grants access to private members of the class, similar to C++ `friend`:

```c++
istruc Secret {
    private i32 hidden;
    local void expose(Secret* s);
}
```

### 11.12 Virtual Data Members

```c
istruc Node {
    virtual i32 id;   // must be same type in every derived class
}
```

---

## 12. Function Pointers

Syntax: `returntype(paramlist)* varname`

```c
i32 add(i32 a, i32 b) { return a + b; }

void demo() {
    i32(i32 a, i32 b)* fp = &add;
    i32 result = fp(3, 4);   // indirect call
}
```

Parameter names in the function pointer type are optional; only the types are significant:

```c
void(i32, i32)* callback;   // no param names — legal
```

Taking the address of a function:

```c
void(i32 x)* p = &my_func;
```

Function pointers can be stored in structs, passed as parameters, and returned from functions.

---

## 13. Allocators (`memstr`)

Artemis uses Zig-style allocators for explicit, composable heap control.

### 13.1 The `memstr` Interface

Every allocator exposes three operations through a vtable:

| Method   | Signature                         | Description                          |
|----------|-----------------------------------|--------------------------------------|
| `.mmap`  | `void*(u128 size) -> void*`       | Allocate `size` bytes                |
| `.rmap`  | `void*(void* ptr, u128 new_size)` | Reallocate an existing allocation    |
| `.deinit`| `void()`                          | Release all resources in the allocator |

### 13.2 Accepting an Allocator

Any function that allocates heap memory must take `&memstr <name>` as a parameter:

```c
void* create_buffer(&memstr alloc, u64 size) {
    return alloc.mmap(size);
}
```

### 13.3 Passing an Allocator

Allocators are passed explicitly. An implicit default allocator (backed by `malloc`/`realloc`/`free`) is used when no allocator is provided:

```c
void* buf = create_buffer(size);         // implicit default allocator
void* buf2 = create_buffer(my_alloc, size); // explicit custom allocator
```

### 13.4 Deinitialising

Call `.uinit()` to run the allocator's `deinit` function and release all tracked memory:

```c
alloc.uinit();
```

### 13.5 `memstr` vs `&memstr` — Declaration vs Reference

**`memstr TypeName { }`** declares a type that manages its own heap memory. Types from `std.alloc` (bump, arena, pool, etc.) are all `memstr` types. They can be created as ordinary stack variables:

```arc
bump a(4096);   // stack variable — fine, bump is a memstr type
a.alloc_bytes(64);
a.deinit();
```

The compiler does NOT require a `&memstr` context just to create or use a `memstr` value. The constraint is only in the other direction: a function that accepts `&memstr alloc` can receive any `memstr` instance.

**`&memstr name`** in a function parameter means "accept any memstr-compatible allocator by reference". The allocator's concrete type is erased; only its `alloc_raw`, `realloc`, and `free` interface is used. This is how generic allocating functions are written.

A plain `istruc` that contains `malloc`/`free` calls directly is rejected by the compiler — only types declared with `memstr` may manage heap memory internally.

### 13.6 `defer` — Scope-Exit Execution

The `defer` keyword schedules an expression or block to run at the end of the current scope (LIFO order if multiple). Deferred items also run before any `return` in the scope.

```c
void use_allocator(&memstr alloc) {
    defer alloc.uinit();              // runs on scope exit

    void* buf = alloc.mmap(1024);
    defer alloc.rmap(buf, 0);         // frees buf on scope exit (after uinit? reversed)

    // ... use buf ...
}   // deferred items run here in reverse order
```

`defer` with a block:

```c
void f() {
    defer {
        log("cleanup");
        flush();
    }
    // ... work ...
}
```

---

## 14. Updated Grammar

The grammar from §8 is extended with the new constructs:

```
top_level ::= ... | istruc_decl | extern_c_block | memstr_decl | func_or_var

istruc_decl ::= 'istruc' identifier (':' identifier)? '{' class_member* '}'
class_member ::= access_modifier? field_decl
               | access_modifier? method_decl

access_modifier ::= 'public' | 'private' | 'protected'

field_decl  ::= ['virtual'] type_spec identifier ';'
method_decl ::= ['static'] ['mandatory'] ['virtual'] type_spec identifier
                '(' method_params ')' method_qualifiers (block | ';')
method_params  ::= ('&self' | '&const self')? (',' param)*
method_qualifiers ::= ('const' | 'override' | 'final')*

extern_c_block ::= 'extern' '"C"' '{' func_or_var_proto* '}'

func_ptr_type  ::= type_spec '(' param_list ')' '*'
type_spec      ::= ... | func_ptr_type | '&self' | '&const self' | '&memstr'

stmt ::= ... | defer_stmt
defer_stmt ::= 'defer' (block | expr ';')

expr ::= ... | expr '->' identifier    (desugars to (*expr).identifier)
```

## 15. Additional Features

### 15.1 `noexcept`

`noexcept` may appear as a method/function modifier (after `)` before `{`, or
among the leading modifiers of a class method). It is also valid as a unary
operator `noexcept(expr)`, which evaluates to a compile-time `bool` (currently
always `true`). `noexcept` is informational only; it does not affect codegen.

```
void foo() noexcept {}
i32  bar() noexcept const override {}     // inside a class
bool b = noexcept(foo());
```

### 15.2 `explicit`

`explicit` may be applied to a class constructor (`__construct__`). It is parsed
and recorded (`class_method.is_explicit`) but currently does not change codegen.

```
explicit void __construct__(&self, i32 a) { self.v = a; }
```

### 15.3 Stackable method modifiers

Class method modifiers may now appear in any combination/order, subject to:
an access modifier (`public`/`private`/`protected`) comes first; the return type
is directly before the name and `(`; and `const`/`override`/`final`/`noexcept`
may also appear after `)`. The set `virtual`, `mandatory`, `static`, `explicit`,
`noexcept`, `const`, `override`, `final` is accepted in any stack.

```
public final void x() noexcept const override {}
```

### 15.4 Implicit constructors

A variable declaration may invoke a constructor directly:

```
Point p(3, 4);     // equivalent to: Point p; p.__construct__(3, 4);
Point q{10, 20};   // brace form
Counter c;         // auto-calls a no-arg __construct__ if one exists
```

The constructor is resolved by walking the class inheritance chain for
`ClassName__MT___construct__`. A zero-argument (self-only) constructor is invoked
automatically even without explicit `()`.

### 15.5 Virtual inheritance rules

A method/field is virtual in a derived class only if it is explicitly declared
`virtual` (or `mandatory virtual`), or it is `override`/`final` of a method that
occupies a base vtable slot. Non-overriding plain methods in a derived class are
NOT virtual and do not enter the vtable.

### 15.6 Class value initialization

Named-field struct initialization is supported for class types, with an explicit
type name or a context-inferred `.{ ... }`:

```
Token x = Token { .id = 5, .kind = 6 };
Token y = .{ .id = 1, .kind = 2 };       // type inferred from the variable
```

### 15.7 Generics (monomorphization)

Functions and istruc/struct declarations may declare type parameters in `<...>`.
Concrete uses are monomorphized: a specialized instance is emitted on first use
for each distinct set of type arguments (mangled as `name__G_<t1>_<t2>...`).
Type arguments may be explicit or inferred from argument types.

```c++
T identity<T>(T x) { return x; }
i32 a = identity(42);        // T inferred as i32
i64 b = identity<i64>(99);   // explicit

istruc Box<T> { T value; }
Box<i32> b;
```

### 15.8 `constexpr`

`constexpr` constant variables, `constexpr if` / `if constexpr` (compile-time
branch elimination), and `constexpr { ... }` blocks are supported. The `sta`
keyword is reserved for comptime type-erased parameters.

```
constexpr i32 N = 6;
if constexpr (1 < 2) { ... } else { ... }   // only the taken branch is emitted
constexpr if (COND) { ... }
```

### 15.9 Inline Assembly (`__asm__`)

Artemis supports Intel-syntax inline assembly via the `__asm__` statement. The body is a `{ }` block whose content is split into sections by lines whose first non-whitespace character is `:`.

```
__asm__ {
    <instructions>
    : "modifier"(input_var), ...
    : "=modifier"(output_var), ...
    : "clobber_reg", ...
}
```

Sections after the second `:` list clobbered registers. Any section may be empty or absent. Inside the instruction text, `%varname` is replaced by the corresponding LLVM operand index (`$N`).

```c
i32 a = 7, b = 5, result = 0;
__asm__ {
    mov eax, %a
    add eax, %b
    mov %result, eax
    : "r"(a), "r"(b)
    : "=r"(result)
    : "eax"
}
// result == 12
```

Rules:
- All variables referenced with `%name` in the instruction text must appear in an input or output constraint section.
- Output constraints must use the `"=modifier"` form.
- The `__asm__` without any constraint sections is valid (useful for `nop` or side-effect instructions):
  `__asm__ { nop }`

### 15.10 Access Modifier Enforcement

The semantic analyser enforces access modifiers on class members:

| Modifier    | Accessible from                              |
|-------------|----------------------------------------------|
| `public`    | Anywhere                                     |
| `private`   | Only methods of the **same** class           |
| `protected` | Methods of the same class or any derived class |

Accessing a `private` or `protected` member from a disallowed context is a compile-time error:

```c++
istruc Wallet {
    private i32 balance;
    public i32 get(&const self) { return self.balance; }  // OK: same class
}

i32 main() {
    Wallet w;
    i32 x = w.balance;  // ERROR: 'balance' is private
    i32 y = w.get();    // OK: public method
}
```

### 15.11 Grammar additions

```
func_decl   ::= type_spec identifier type_params? '(' params ')' 'noexcept'? (block | ';')
istruc_decl ::= 'istruc' identifier type_params? (':' identifier)? '{' class_member* '}'
type_params ::= '<' identifier (',' identifier)* '>'
type_spec   ::= ... | identifier type_args?
type_args   ::= '<' type_spec (',' type_spec)* '>'

method_modifiers  ::= ('virtual'|'mandatory'|'static'|'explicit'|'noexcept'
                       |'const'|'override'|'final')*
method_qualifiers ::= ('const'|'override'|'final'|'noexcept')*

call        ::= identifier type_args? '(' args ')'
expr        ::= ... | type_name '{' field_init (',' field_init)* '}'
              | '.{' field_init (',' field_init)* '}'      (context-inferred)
              | 'noexcept' '(' expr ')'
field_init  ::= '.' identifier '=' expr
var_decl    ::= type_spec identifier ( '(' args ')' | '{' args '}' )? ('=' expr)? ';'

stmt        ::= ... | 'constexpr'? 'if' '(' expr ')' stmt ('else' stmt)?
              | 'if' 'constexpr' '(' expr ')' stmt ('else' stmt)?
              | 'constexpr' type_spec identifier '=' expr ';'
              | 'constexpr' block
              | '__asm__' asm_body

asm_body    ::= '{' asm_instructions (':' asm_constraints)* '}'
asm_constraints ::= ('"' modifier '"' '(' varname ')' (',' ...)*)?
```

---

## 16. Standard Library (`extern std.*`)

The standard library lives under `compiler/std/include/`. Each package is a single `.arc` file (or `pkg/module.arc` for sub-packages). Import with:

```arc
extern std.<pkg>;          // e.g. extern std.math;
extern std.<pkg>.<mod>;   // e.g. extern std.alloc.bump;
```

All exported types and functions are accessible by their bare (unqualified) names after import.

### 16.1 `std.alloc` — Allocators

Sub-packages: `std.alloc.bump`, `std.alloc.arena`, `std.alloc.pool`, `std.alloc.ring`, `std.alloc.free_list`, `std.alloc.slab`.

Each allocator is an `istruc` (same name as the sub-package, e.g. `bump`) that implements a `memstr`-compatible interface: `alloc`, `realloc`, `free`, and `reset` / `destroy` where applicable. Constructor takes allocator-specific parameters (capacity in bytes, object size, etc.).

| Type | Strategy |
|------|----------|
| `bump` | Linear bump pointer; O(1) alloc, O(1) reset |
| `arena` | Multi-block bump with automatic growth |
| `pool` | Fixed-size object pool; O(1) alloc and free |
| `ring` | Circular ring buffer allocator |
| `free_list` | Intrusive free-list; arbitrary-size coalescing |
| `slab` | Page-based slab for small fixed-size objects |

### 16.2 `std.math` — Mathematics

Import: `extern std.math;`

**Constants:** `PI`, `TAU`, `E`, `PHI`, `SQRT2`, `LN2`, `LN10`, `INF`, `NAN_V`

**Integer utilities:** `abs_i32`, `abs_i64`, `min_i32`, `max_i32`, `min_i64`, `max_i64`, `min_f32`, `max_f32`, `min_f64`, `max_f64`, `clamp_i32`, `clamp_f32`, `clamp_f64`, `sign_i32`, `sign_f64`, `gcd`, `lcm`, `div_ceil`, `div_floor`, `is_even`, `is_odd`, `is_power_of_two`, `next_power_of_two`, `popcount_u32`, `clz_u32`, `ctz_u32`, `bit_reverse_u32`

**Floating-point:** `lerp`, `lerp_f32`, `deg_to_rad`, `rad_to_deg`, `snap`, `log_base`

**Geometry:** `istruc vec2`, `istruc vec3`, `istruc mat4`, `istruc quat` — all with standard arithmetic operators and methods (add, sub, dot, cross, normalize, len, rotate, etc.)

**Statistics** (behind `extern std.math;`): `mean`, `variance`, `std_dev` — operate on `f64*` arrays.

C libm externs (`sin`, `cos`, `sqrt`, `fabs`, `floor`, `ceil`, `pow`, etc.) are re-exported by this module.

### 16.3 `std.rand` — Random Number Generation

Import: `extern std.rand;`

| Type | Algorithm |
|------|-----------|
| `xoshiro_state` | Xoshiro256** — high-quality 64-bit generator |
| `pcg_state` | PCG32 — 32-bit generator with stream control |

**`xoshiro_state` constructor:** `xoshiro_state rng(seed_u64)`

**`xoshiro_state` methods:** `next_u64`, `next_u32`, `next_f64`, `next_f32`, `next_bool`, `range_i32(lo, hi)`, `range_f64(lo, hi)`, `fill_bytes(buf, n)`

**`pcg_state` constructor:** `pcg_state rng(seed_u64, seq_u64)`

**`pcg_state` methods:** `next_u32`, `next_f64`, `next_bool`, `range_i32(lo, hi)`

**Free function:** `gaussian(xoshiro_state* rng, f64 mean, f64 std_dev)` — Box-Muller normal distribution.

### 16.4 `std.hash` — Hashing

Import: `extern std.hash;`

**FNV-1a:** `fnv1a_32(u8* data, u64 len)` → `u32`, `fnv1a_64(u8* data, u64 len)` → `u64`

**WyHash:** `wyhash(u8* data, u64 len, u64 seed)` → `u64` — fast non-cryptographic hash.

**DJB2:** `djb2(u8* data, u64 len)` → `u64`

### 16.5 `std.atomic` — Atomic Operations

Import: `extern std.atomic;`

Thin wrappers over GCC/Clang built-in atomics (`__atomic_*`). Provides `istruc atomic_i32`, `istruc atomic_i64`, `istruc atomic_u32`, `istruc atomic_u64`, `istruc atomic_bool` — each with `load`, `store`, `add`, `sub`, `cas` (compare-and-swap), and `exchange` methods.

### 16.6 Future Packages

The following packages are specified and will be implemented:

| Package | Description |
|---------|-------------|
| `std.vector` | Growable array |
| `std.map` | Sorted key-value map (red-black tree) |
| `std.unordered_map` | Hash map |
| `std.set` | Sorted set |
| `std.unordered_set` | Hash set |
| `std.sll` | Singly-linked list |
| `std.dll` | Doubly-linked list |
| `std.soa` | Struct-of-arrays container |
| `std.arch.system` | OS detection, env vars, exit |
| `std.fs` | File I/O, directory listing |
| `std.net` | TCP/UDP sockets |
| `std.process` | Process spawn and pipes |
| `std.thread` | POSIX / Win32 thread abstraction |
| `std.fmt` | String formatting and printing |
| `std.encode` | UTF-8, base64, hex codecs |
| `std.json` | JSON parse and serialize |
| `std.toml` | TOML parse |
| `std.test` | Unit test framework |
| `std.debug` | Stack traces, assertions, memory checking |
| `std.arch.simd` | SIMD intrinsic wrappers |
