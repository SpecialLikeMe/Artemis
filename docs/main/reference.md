# Language Reference

## Keywords

| Keyword | Purpose |
|---------|---------|
| `i8`–`i512` | Signed integer types (also `char` = `i8`, `int` = `i32`) |
| `u8`–`u512` | Unsigned integer types (also `uint` = `u32`) |
| `f8`–`f512` | Floating-point types (also `float` = `f64`) |
| `bool`, `b1`–`bN` | Boolean types |
| `void` | No-value type / untyped pointer base (`void*`) |
| `null` | Null pointer / nullable constant |
| `true`, `false` | Boolean literals |
| `signed`, `unsigned` | Signedness qualifiers for integer types |
| `const` | Immutable variable / pointer-to-const-data qualifier |
| `volatile` | Volatile qualifier (inhibits optimization) |
| `register` | Register-allocation hint |
| `inline` | Inline function hint |
| `extern` | External linkage declaration |
| `extern "C"` | C-linkage block |
| `static` | Static storage / class-level member |
| `sizeof` | Size of type or expression in bytes (→ `u64`) |
| `if`, `else` | Conditional |
| `for`, `while` | Loops |
| `break`, `continue` | Loop control |
| `switch`, `case`, `default` | Multi-way branch |
| `return` | Return from function |
| `defer` | Run statement/block at scope exit |
| `errdefer` | Run statement/block at scope exit only when an error is propagated |
| `struct` | Plain C-style aggregate |
| `union` | Overlapping-storage aggregate |
| `enum` | Plain or ADT enum |
| `typedef` | Type alias |
| `istruc` | Class (struct with methods) |
| `interface` | Contract declaration |
| `namespace` | Group functions/types under a qualified name |
| `operator` | Operator overloading |
| `noexcept` | Non-throwing function annotation / compile-time test |
| `constexpr` | Compile-time constant variable |
| `consteval` | Manually-constructed variable |
| `auto` | Type inference / error-union placeholder |
| `using` | Contextual type alias (`using let = const auto;`) |
| `try` | Propagate error from `!T` expression |
| `except` | Catch error from `!T` expression |
| `res` | Error-handling resource block |
| `error` | Error literal (`error.Name`) |
| `memstr` | Allocator struct declaration |
| `sta` | Comptime type-erased parameter |
| `__asm__` | Inline assembly |
| `const_resolve` | Compile-time token-rewriting macro |
| `__token` | Custom token type in proc-macro bodies |

---

## Operator Precedence (High to Low)

| Operators | Associativity |
|-----------|---------------|
| `()` `[]` `.` `(*).` | Left |
| `!` `-` `~` `&` `*` `++` `--` (unary/prefix) | Right |
| `(type)` cast | Right |
| `*` `/` `%` | Left |
| `+` `-` | Left |
| `<<` `>>` | Left |
| `<` `>` `<=` `>=` | Left |
| `==` `!=` | Left |
| `&` (bitwise and) | Left |
| `^` (bitwise xor) | Left |
| `\|` (bitwise or) | Left |
| `&&` | Left |
| `\|\|` | Left |
| `? :` | Right |
| `??` | Left |
| `=` `+=` `-=` `*=` `/=` `%=` `&=` `\|=` `^=` `<<=` `>>=` | Right |

---

## Literal Forms

| Literal | Examples | Type |
|---------|----------|------|
| Decimal integer | `42`, `0`, `-1` | `i32` |
| Unsigned integer | `42u`, `0xFFu` | `u32` |
| Hex integer | `0xFF`, `0xDEAD` | `i32` |
| Binary integer | `0b1010` | `i32` |
| Octal integer | `0o17` | `i32` |
| Float | `3.14`, `1.0e-5` | `f64` |
| String | `"hello"` | `i8*` (null-terminated) |
| Character | `'A'`, `'\n'` | `i8` |
| Boolean | `true`, `false` | `bool` |
| Null | `null` | null literal |
| Error | `error.Name` | `i32` |

---

## Escape Sequences in String/Char Literals

| Sequence | Value |
|----------|-------|
| `\n` | Newline (0x0A) |
| `\t` | Tab (0x09) |
| `\r` | Carriage return (0x0D) |
| `\\` | Backslash |
| `\'` | Single quote |
| `\"` | Double quote |
| `\0` | Null byte |

---

## Compiler Flags

| Flag | Effect |
|------|--------|
| `-o <file>` | Output executable path |
| `-S` | Emit LLVM IR (`.ll`) |
| `-c` | Emit object file (`.o`) |
| `-O0`–`-O3` | Optimisation level |
| `--target <t>` | LLVM target triple |
| `-D <name>` | Pre-define preprocessor symbol |
| `-I <path>` | Add include search path |
| `-v` | Verbose output |
| `-l` | Target Linux |
| `-w` | Target Windows |
| `-m` | Target macOS |

---

## Internal Name Mangling

| Source pattern | Internal name |
|----------------|---------------|
| Method `m` on class `Foo` | `Foo__MT_m` |
| `operator=` on class `Foo` | `Foo__MT_operator=` |
| Namespace `ns`, member `bar` | `ns__NS_bar` |
| ADT variant `Enum.Variant` as type | `Enum__NS_Variant` |
| ADT istruc variant constructor | `Enum__NS_Variant__ctor` |

---

[Index](00_index.md)
