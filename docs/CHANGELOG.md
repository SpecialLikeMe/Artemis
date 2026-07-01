# 6/30/2026 — new syntax, self-param migration, stdlib migration

## Language
- **`typedef auto` form**: `typedef auto Alias = Type;` is now accepted as an alternative to `typedef Type Alias;`.
- **Trailing type for variables**: `auto name: Type = expr;` declares a variable with an explicit trailing type. Works at both global and local scope.
- **Trailing return type for functions**: `auto foo() RetType { }` specifies the return type after `()`. Also supports error unions: `auto foo() !T { }` and `auto foo() E!T { }`.
- **`using` contextual aliases**: `using name = Type;` creates a type alias resolvable in variable declarations. e.g. `using var = auto;` then `var x = 5;` infers the type. `using let = const auto;` creates an immutable-auto alias.
- **`auto` type inference**: Variables declared with `auto` (or a `using` alias that resolves to `auto`) infer their type from the initializer expression.
- **`?T` nullable types**: Parser and AST support. The `?` prefix marks any type as nullable (`is_nullable = true`). Non-nullable types cannot be null (enforced at compile time — IR implementation pending).
- **Range-based for loop**: `for (T name : expr) body` — parser and analyzer support. IR codegen emits a counted loop using GEP for pointer ranges.
- **`@pragma` directive**: Preprocessor silently accepts all `@pragma` directives (e.g. `@pragma once`).
- **`explicit` keyword**: Re-added as a no-op keyword for backward compatibility with existing code.
- **`const_resolve` macros**: `const_resolve name { ... }` is parsed (body consumed as opaque tokens). Execution of the macro body is not yet implemented.

## Migration
- **`&self` / `&const self` removed**: Legacy self-reference syntax is no longer supported. All method self parameters must use the explicit pointer form: `ClassName* self` or `const ClassName* self`.
- Updated all tests and stdlib files to use explicit self parameters.

## Stdlib
- All 6 alloc modules (`bump`, `arena`, `pool`, `ring`, `free_list`, `slab`), `arch/system.arc`, and `std/007` test migrated from `&self` to explicit self.

## Cleanup
- Removed migration Python scripts from project root (`fix_migration.py`, `migrate_self.py`, `qualify_stdlib_tests.py`, `wrap_namespaces.py`).

## Tests
- Added test 204: new syntax features (`typedef auto`, trailing types, `using` aliases, `auto` type inference).
- 194 integration tests — all passing.

---

# 6/30/2026 — namespace infrastructure, stdlib namespacing, explicit self

## Language
- **Explicit self parameter**: `&self` syntax removed. The first parameter of a method is now the self parameter if it is a pointer (const or mutable) to the enclosing class type. Any name works (`self`, `this`, `me`, etc.). `self` and `this` are also accepted as type keywords inside method parameter lists (e.g. `void get(const this* foo)`).
- **Stdlib namespace wrapping**: All stdlib modules now place their declarations inside a named namespace. Usage changes: `hash::sha256_hash_str(...)`, `fmt::print(...)`, `math::abs_i32(...)`, `encode::utf8_encode(...)`, `debug::poison(...)` etc.
- **Namespace intra-body resolution**: Code inside a namespace can now refer to types, variables, and functions in the same namespace by bare name (no `::` qualifier needed). Resolves across both the semantic analyser and the IR emitter.
- **Namespace struct/typedef/var mangling**: `struct`, `union`, `typedef`, and `constexpr` declarations inside a namespace are now correctly mangled (e.g. `sha256_digest` → `hash__NS_sha256_digest`) and accessible from outside via `hash::sha256_digest`.
- **Intra-namespace static method calls**: `ClassName.method()` inside a namespace now correctly resolves to the mangled class (e.g. `mat4.identity()` inside `namespace math`).
- **`noexcept` maps to LLVM `nounwind`**: `noexcept` on a function now attaches the LLVM `nounwind` attribute. Removed deprecated `const` method suffix (use `const ClassName* self` instead).

## IR
- **`llvm_type_of` namespace fallback**: Struct/typedef type lookups now try `ns__NS_typename` when the bare name isn't found and `current_namespace` is set.
- **`visit_func_decl_prototype` namespace context**: The namespace is now derived from the mangled function name during pass-1 prototype registration so return types referencing intra-namespace structs resolve correctly.
- **`visit_class_decl_methods_prototype` namespace context**: Same fix for class method prototypes.

## Stdlib
- `std.hash`, `std.fmt`, `std.encode`, `std.debug`, `std.math` all wrapped in namespaces.
- Stdlib tests 010–019 all pass (10/19; remaining 9 failures are pre-existing missing modules).

## Tests
- Added test 200: interface basic.
- Added test 201: explicit self parameter with custom names.
- Added test 202: namespace struct types and intra-namespace constant/type references.
- Added test 203: namespace istruc with intra-namespace type in method return/parameter.
- 193 integration tests, 157 unit tests — all passing.

---

# 6/29–6/30/2026 — comprehensive bug hunt and IR correctness pass

## Lexer / Parser
- **CRLF import fix**: `extern std.fmt;` with Windows line-endings (CRLF) no longer silently fails. The preprocessor now strips `\r` from module names during `extern std.*` resolution.
- **`kw_self` as parameter name**: Functions with `x self` (using the keyword `self` as a plain value parameter, not a reference) now parse and type-check correctly.
- **Context-inferred struct literal**: `foo(.{ .i = 4 })` (dot-brace literal with no explicit type) is now resolved by the analyzer from the callee's declared parameter type.

## IR — Unsigned Integer Correctness
All unsigned arithmetic, comparisons, and shifts now emit the correct LLVM instructions:

- **`homogenize_int_widths` truncation bug fixed**: For integer comparisons of mixed widths the old code truncated the wider operand to the narrower type (converting e.g. `u8(0x80)` to `i8(-128)` before a signed compare). Now the narrower operand is extended (`ZExt` for unsigned, `SExt` for signed) to the wider type.
- **Unsigned comparison predicates**: `<`, `>`, `<=`, `>=` on unsigned types now emit `LLVMIntULT/UGT/ULE/UGE` instead of the signed variants.
- **Unsigned division / modulo / right-shift**: `UDiv`/`URem`/`LShr` are now used when either operand is unsigned; previously `SDiv`/`SRem`/`AShr` were always emitted.
- **Compound assignment operators** (`/=`, `%=`, `>>=`) updated to use unsigned variants when the left-hand side is unsigned.

## IR — Signedness Tracking Infrastructure
Introduced a comprehensive signedness-tracking system so the IR emitter can determine at code-gen time whether an expression is unsigned:

- **`alloca_unsigned` map** in `ir_scope_frame`: each declared local now records whether its type is unsigned (`u8`–`u512`). Set at declaration time in `stmts.hxx` and for all function/method parameters in `decls.hxx`.
- **`struct_field_unsigned` map** in `ir_context`: parallel to `struct_field_types`, records which fields of a struct/union/class are unsigned primitives. Populated in `visit_struct_decl`, `visit_union_decl`, and `visit_class_decl_types`.
- **`is_unsigned_expr()` helper** in `exprs.hxx`: determines the signedness of any expression by inspecting cast types, local variable flags, struct field flags (via member/subscript/deref chains), and identifier lookups.

## IR — Constructor Overloading
Multiple `__construct__` methods (or any overloaded class/istruc method) on the same type now work correctly:

- **Unique IR names for overloads**: `visit_class_decl_methods_prototype` and `visit_class_decl_methods_body` detect when two methods share a name and use `build_mangled_name` to generate distinct LLVM function names (e.g. `Foo__MT___construct____i32` vs `Foo__MT___construct____i32_i32`).
- **Overload-aware call dispatch**: the method-call path in `visit_call_expr` and the implicit constructor path in `visit_var_decl_stmt` now fall back to a prefix scan (`ClassName__MT_method__*`) when the unmangled name is absent, selecting the overload whose parameter count matches the call-site argument count.

## Standard Library
- **`std.hash` (sha256, fnv, wyhash)**, **`std.encode` (utf8)**: All 10 stdlib packages (tests 010–019) now pass. The unsigned-comparison fixes were the root cause of both sha256 and encode_utf8 runtime failures.
- Added stdlib tests 010–019 (`tcon/std/`).

## Tests
- Added tests 196–199: try/throw (basic, no-throw, nested), and constructor overloading.
- 199 compiler tests + 19 stdlib tests = **218 total, all passing**.

---

# 6/25/2026
major changes: introducing allocators and OOP.

# 6/26/2026 — documentation, tests, and access-enforcement pass
- Complete spec.md coverage: inline ASM (§15.9), access modifier enforcement (§15.10),
  grammar for all new features, updated §14 grammar.
- Added 21 new passing tests (159–179) covering: inline ASM, sizeof, constexpr blocks,
  protected access, mandatory virtual, final override, virtual data members, 3-level
  inheritance, 4-overload functions, multiple operator overloads, generic structs with
  methods, explicit generic calls, inline/register, private-self access, nested defer,
  function-pointer multi-param, conversion operators, constexpr if chains.
- Added tcon/fail/ directory with 12 compile-error tests: private/protected access
  violations, non-existent member, unknown type, break/continue outside loop,
  undefined variable, unknown base class, override without base, mandatory without virtual.
- Added tcon/run_fail.cc runner: compiles each .arc in tcon/fail/ and reports PASS when
  the compiler correctly rejects it.
- Implemented access modifier enforcement in the semantic analyser: private, protected,
  and public are now checked at every member-access site.

# 6/26/26
NOOOOOOOO I FORGOT TO COMMIT MY CHANGES. IN A FEW DAYS THERE WILL BE LIKE "84098203480593485348590348509348590348" LOC ADDED :(

# 6/27/2026 — stdlib, IR fixes, test expansion

## IR fixes
- **Subscript of cast expression as lvalue**: `((i32*)a)[0] = v` no longer errors with "Expression is not an lvalue". The subscript code path now uses `visit_expr` for non-identifier base objects and derives the element type from the cast's type node.
- **Deref of cast expression load type**: `*((u64*)ptr)` now loads the correct width (i64) instead of falling back to i8.

## Lexer / Parser
- Hex and binary literals now consume `u`/`U`/`l`/`L` suffixes (e.g. `0x55555555u`).
- Large u64 constants that exceed INT64_MAX (e.g. `0x9e3779b97f4a7c15u`) are now parsed with `strtoull` instead of `stoll` to avoid overflow exceptions.

## Standard library
- `extern std.<pkg>;` import mechanism implemented end-to-end: preprocessor resolves dot-path to file, compiler/std/include/ is located relative to the executable.
- **std.alloc**: All 6 allocators (bump, arena, pool, ring, free_list, slab) compile and pass tests.
- **std.math**: Removed namespace wrapper so free functions (`abs_i32`, `gcd`, etc.) are accessible by bare name. Fixed vec2/vec3/quat constructor parameter names to not shadow struct fields.
- **std.rand**: Removed unsupported generic method `shuffle<T>`, renamed conflicting `state` types to `xoshiro_state`/`pcg_state`, moved extern declarations to global scope, inlined xoshiro256** rotate operations.

## Tests
- Added `tcon/std/` directory with 9 passing stdlib tests:
  - 001–006: alloc sub-packages (bump, arena, pool, ring, free_list, slab)
  - 007: memstr type safety
  - 008: std.math (abs, min, max, clamp, gcd, lcm, is_power_of_two)
  - 009: std.rand (xoshiro256** seeding, next_u64/u32/bool, pcg32)
- All 195 original compiler tests continue to pass.

## Docs
- spec.md §6.5: Corrected `@include` — only `"relative/path"` form is valid; `<>` form does not exist anymore.
- spec.md §6.5.1: Documented `extern std.*;` import syntax.
- spec.md §16: Added comprehensive Standard Library specification (§16.1–16.6) covering all implemented and planned packages.
## Note
It is amazing how nicely everything maps. Everything is just an abstraction over an ASM concept or two, and I have found that keeping that in mind drastically increases my devlopment velocity (as exemplified by the scope of what has been done in the past few days).