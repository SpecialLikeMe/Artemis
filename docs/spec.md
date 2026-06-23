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

### 1.6 Type Qualifiers and Storage Classes

| Keyword     | Meaning                                     |
|-------------|---------------------------------------------|
| `const`     | Value may not be modified after declaration |
| `extern`    | Symbol has external linkage                 |
| `extern std`| C standard library linkage                  |
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
**Member access:** `expr.field` (struct/union by value)  
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

---

## 5. Annotations

Annotations use the `@` sigil followed by an identifier:

```c
@noinline foo();
@deprecated bar = 5;
```

The annotation is parsed as a unary prefix expression over the following expression. No semantics are defined in v0.1.0; they are intended as extension points for future attributes and for tooling.

---

## 6. Calling Convention and Extern Linkage

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
