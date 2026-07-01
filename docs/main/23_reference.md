# 23. Language Reference

## Keywords

| Keyword                      | Purpose                                    |
|------------------------------|--------------------------------------------|
| `i8`–`i512`                  | Signed integer types                       |
| `u8`–`u512`                  | Unsigned integer types                     |
| `f8`–`f512`                  | Floating-point types                       |
| `bool`, `b1`–`b512`          | Boolean types                              |
| `char`                       | Alias for `i8`                             |
| `void`                       | No-value type / generic pointer base       |
| `null`                       | Null pointer constant                      |
| `true`, `false`              | Boolean literals                           |
| `if`, `else`                 | Conditional                                |
| `for`, `while`               | Loops                                      |
| `break`, `continue`          | Loop control                               |
| `switch`, `case`, `default`  | Multi-way branch                           |
| `return`                     | Return from function                       |
| `struct`                     | Aggregate type                             |
| `union`                      | Overlapping-storage aggregate              |
| `enum`                       | Named integer constants                    |
| `typedef`                    | Type alias                                 |
| `istruc`                     | Class (struct with methods)                |
| `namespace`                  | Group functions and types under a name     |
| `public`, `private`, `protected` | Access modifiers                       |
| `static`                     | Static class method                        |
| `virtual`, `override`, `final` | Virtual dispatch                         |
| `mandatory`                  | Force subclass override                    |
| `operator`                   | Operator overloading                       |
| `explicit`                   | Explicit conversion operator               |
| `const`                      | Const qualifier                            |
| `constexpr`                  | Compile-time constant                      |
| `consteval`                  | Manually constructed variable              |
| `extern`                     | External linkage                           |
| `extern "C"`                 | C linkage block                            |
| `extern aciso.NAME`          | Import installed package                   |
| `inline`                     | Inline hint                                |
| `register`                   | Register-allocation hint                   |
| `sizeof`                     | Type/value size in bytes                   |
| `volatile`                   | Volatile qualifier                         |
| `defer`                      | Run at scope exit                          |
| `memstr`                     | Allocator interface declaration            |
| `self`                       | Method receiver reference                  |
| `local`                      | Friend-like declaration inside istruc      |
| `sta`                        | Compile-time type-erased parameter         |
| `noexcept`                   | No-exception annotation                    |
| `__asm__`                    | Inline assembly                            |

---

## Operator Precedence (High to Low)

| Operators                    | Associativity |
|------------------------------|---------------|
| `()` `[]` `.` `(*).`         | Left          |
| `!` `-` `~` `&` `*` (unary) | Right         |
| `(type)` cast                | Right         |
| `*` `/` `%`                  | Left          |
| `+` `-`                      | Left          |
| `<<` `>>`                    | Left          |
| `<` `>` `<=` `>=`            | Left          |
| `==` `!=`                    | Left          |
| `&` (bit-and)                | Left          |
| `^` (bit-xor)                | Left          |
| `\|` (bit-or)                | Left          |
| `&&`                         | Left          |
| `\|\|`                       | Left          |
| `? :`                        | Right         |
| `=`                          | Right         |

---

## Compiler Flags

| Flag           | Effect                              |
|----------------|-------------------------------------|
| `-o <file>`    | Output executable path              |
| `-S`           | Emit LLVM IR (`.ll`)                |
| `-c`           | Emit object file (`.o`)             |
| `--emit-ast`   | Print parsed AST to stdout          |
| `-O0`–`-O3`    | Optimisation level                  |
| `--target <t>` | LLVM target triple                  |
| `-D <name>`    | Predefine preprocessor symbol       |
| `-I <path>`    | Add include search path             |
| `-v`           | Verbose output                      |
| `-l <out>`     | Target Linux                        |
| `-w <out>`     | Target Windows                      |
| `-m <out>`     | Target macOS                        |

---

[Prev: Package Manager](22_package_manager.md) | [Index](00_index.md)
