# 7/3/2026 — Multi-level namespace types, stdlib fixes, test reorganization

## Language — Parser

- **Multi-level namespace-qualified types**: `parse_type()`, `is_type_start()`, and `is_cast_start()` now handle arbitrarily deep namespace paths (`ns1.ns2.ns3.Type`). Previously only one `.` level was supported, causing `std.test.runner`, `std.ifo.ifo_field_t`, and similar stdlib types to fail to parse. Fixed by replacing single-check `if` with `while` loops in the type-start lookahead and the type parser.
- **Namespace-qualified pointer casts**: `is_cast_start()` now correctly recognises `(ns1.ns2.Type*)expr` casts by skipping namespace qualifiers before counting `*` tokens.

## Stdlib

- **`std.alloc.bump` implements `&memstr`**: Added `mmap(bump* self, u64 n) -> void*` and `rmap(bump* self, void* p, u64 n) -> void` methods so `std.alloc.bump` satisfies the allocator interface and can be passed to functions expecting `&memstr`.

## Tests

- **Fail tests moved to `tcon/fail/`**: `208_nullable_assign_fail`, `209_nullable_arg_fail`, and `210_derive_bad_arg_fail` relocated from `tcon/test/` to `tcon/fail/` (renumbered 118, 119, 120) where they are run by the fail-test runner that inverts pass/fail logic.

## Docs

- **Notation fix**: All changelog entries now use `std.vector` (dot) instead of `std.vector` (double-colon). Namespaces in Artemis use `.` as the accessor; `.` is the internal mangling separator only.

---

# 7/3/2026 — `std.vector<T>` generic class + `&memstr` vtable dispatch

## Language — Generic Class Improvements

- **Overloaded methods in generic classes**: Generic class instantiation (`instantiate_generic_class`) no longer segfaults when a class has two methods with the same base name (e.g. two `__construct__` overloads). Methods with duplicate base IR names are now suffixed `__OL1`, `__OL2`, etc. in both the prototype and body passes. The constructor call site searches overloaded variants when the base ctor param count doesn't match.
- **`sizeof(T)` in generic method bodies**: `visit_sizeof_expr` now checks `ctx->type_subst` before falling to the expression-eval path, so `sizeof(T)` in a generic body correctly returns the size of the substituted concrete type (e.g. `sizeof(i32)` = 4) instead of throwing "IR: Unknown identifier 'T'".
- **Pointer field subscript element type**: `subscript_elem_ptr` previously set `elem_t_out = ptr` (opaque pointer) for all pointer struct fields, causing load/return type mismatches for methods like `T at()` and `T operator[]()`. The new `struct_field_pointee_types` map (populated in `visit_class_decl_types`) records the correct element type per pointer field, so `self.data[i]` resolves to `i32` when `data: i32*`.
- **`&memstr` fat-pointer dispatch**: `&memstr` is now lowered to a two-word fat pointer `{ptr data, ptr vtable}` instead of a bare `i8*`. Each `memstr` class gets a compile-time global vtable `{mmap_fn, rmap_fn, deinit_fn}`. At call sites, concrete struct values are automatically coerced to fat pointers when passed to `&memstr` parameters. Inside generic method bodies, `a.mmap(n)`, `a.rmap(p, n)`, and `a.deinit()` dispatch through the vtable using canonical function types.
- **Range-based `for` over struct values**: `visit_for_range_stmt` now handles the case where the range is a plain identifier (no `cast_type` annotation) by inspecting the local variable's LLVM struct type and searching for a `length`/`size` field. This enables `for (i32 x : v)` where `v: std.vector<i32>`.

## Tests

- **`223_for_range_vector`**: Now passes. Tests `std.vector<i32>` construction with a `HeapBump` allocator, three `push` calls, and a range-based `for` loop summing the elements.
- **211 tests pass, 3 intentional fail-tests.**

---

# 7/2/2026 — Proc macros, derive macros, nullable enforcement, docs overhaul

## Language — Proc Macros and Attributes

- **`#[attr]` and `#[attr(args)]` syntax**: Attribute annotations can now be placed on `istruc`, `interface`, and function declarations. Attributes are parsed as `proc_attr` records and stored on `func_decl.attributes` / `class_decl.attributes`. Keywords are valid attribute names (e.g. `#[inline]`).
- **`proc_macro name(input) -> tokenstream { body }`**: Declare user-defined proc macros. The body is parsed and stored as a `proc_macro_decl` AST node; it is not compiled to IR in this release but the declaration is syntactically complete.
- **`#[derive(Debug, Clone, Default)]`**: Three built-in derive macros are processed by the analyzer and IR emitter:
  - `Debug` → synthesises `void __derive_Debug_T(T* self)` (stub, no-op body)
  - `Clone` → synthesises `T __derive_Clone_T(T* self)` (memberwise load-and-return)
  - `Default` → synthesises `T __derive_Default_T()` (returns zero-initialised struct)
- **`quote{}`**: Parse-time tokenstream literal — collects enclosed tokens and returns them as a string-encoded tokenstream. Used inside `proc_macro` bodies.
- **`ast(expr)` / `tks(expr)`**: Proc macro intrinsics — recognised by the parser and emitted as placeholder int literals. Full implementation deferred to proc macro runtime.
- **`tokenstream` stdlib type** (`compiler/std/include/proc_macro.arc`): Defines `std.tokenstream` with `tokens: i8*`, `length: i32`, `len()`, and `is_empty()`.

## Language — Nullable `?T` Enforcement

- **Assignment mismatch**: `?T` cannot be silently assigned to `T` — `assignable()` now returns false for nullable→non-nullable non-pointer assignments. Compile error at assignment site.
- **Argument mismatch**: `visit_call()` in the analyzer now checks each argument: if a `?T` value is passed to a non-nullable, non-pointer parameter, a descriptive error is raised ("unwrap it explicitly").

## Language — Error System (`!T`, `except |e|`)

- **`error_t` struct**: `{i32 code, i8* name}` — bound by `except |e|`. The `code` field holds the raw FNV-1a hash; `name` is resolved at runtime via `__artemis_error_name(i32 code)`.
- **`ensure_error_name_fn`**: Per-module function emitted once that maps error codes to their string names (one branch per registered `error.Variant` literal in the module).
- **`except |e|` IR**: Creates an `error_t` alloca, stores err_tag into `.code`, calls `__artemis_error_name` into `.name`, declares the binding as a struct variable.

## Bug Fixes

- **`soa.arc` `istruc` prefix on return type**: `istruc soa_layout make_soa(...)` was invalid (parser read `istruc` as the start of a class declaration). Fixed by removing the `istruc` prefix from the return type.
- **`&self` NOT restored**: Confirmed that `parse_type()` does not re-add `&self` shorthand. All tests using `Counter* self` explicit form.

## Docs

- **`05_functions.md`**: Removed overloading section (overloading not supported). Updated `noexcept` description to reflect it is a documentation annotation, not enforced.
- **New: `24_error_handling.md`** — `!T`, `try`, `except`, `res`, `error_t`, error literals
- **New: `25_nullable.md`** — `?T`, null assignment, enforcement, nullable pointers
- **New: `26_interfaces.md`** — interface contracts, required/default methods, multiple interfaces
- **New: `27_pointer_const.md`** — `const T`, `const T*`, `T* const`, method const self
- **New: `28_typedef_auto.md`** — `typedef`, `typedef auto`, `auto` inference, trailing type annotation
- **New: `29_macros.md`** — `const_resolve` (patterns, rules, fragments), proc macros, `quote{}`, `#[derive]`
- **New: `30_generics_guidance.md`** — three informal generic boundaries (not enforced)
- **`00_index.md`**: Added chapters 24–30

## Tests

- **Pass tests added**: `211_derive_debug`, `212_derive_clone`, `213_derive_default`, `214_proc_macro_decl`, `215_attr_parse`, `216_typedef_auto`, `217_trailing_type`
- **Fail tests added**: `208_nullable_assign_fail`, `209_nullable_arg_fail`, `210_derive_bad_arg_fail`
- **161 unit tests, 0 failures.**

---

# 7/1/2026 — const_resolve macro engine, &self fix, overloading test sync

## Language — `const_resolve` Macro System
- **`const_resolve name { rules... }`**: Define hygienic token-rewriting macros similar to Rust's `macro_rules!`. Rules are: `(pattern) => { expansion }` or `[pattern] => { expansion }`.
- **Pattern fragments**: `$name:expr`, `$name:ident`, `$name:literal`, `$name:ty`, `$name:tt`, `$name:stmt`, `$name:block`, `$name:path`. Variadic groups: `$grp($pat)*`, `$grp($pat)+`, `$grp($pat)?`.
- **Literal token matchers**: `"word"` in a `[]` pattern matches an identifier with that value, enabling custom keyword syntax.
- **Invocation forms**: `name(args)`, `name[args]`, `name{args}` — all expand identically by splicing the expansion tokens in-place in the token stream.
- **Expression and statement contexts**: Macros expand correctly wherever an expression or statement is expected, including inside `i32 x = macro(...)`.
- **`$` token**: Added `dollar` token type to the lexer for macro fragment sigils.

## Bug Fixes
- **`&self` parameter parsing**: Restored recognition of `&self` as a self-reference parameter (broken when `kw_self` was removed). Now handled by recognising `&` followed by an identifier named `"self"` in `parse_type()`, setting `is_self_type=true`.
- **Overloading unit tests**: Updated `Analyzer.OverloadTwoFunctions` and `Analyzer.OverloadDifferentParamTypes` to expect compile failure (`ASSERT_THROWS`) since free-function overloading is not supported.

## Tests
- **Pass tests added**: `205_macro_simple`, `206_macro_multi_capture`, `207_macro_stmt_expand`
- **Unit tests added**: `Parser.MacroDefinitionRegistered`, `Parser.MacroInvocationExpandsInExpr`, `Parser.MacroInvocationExpandsInStmt`
- **200 pass tests, 0 failures. 161 unit tests, 0 failures.**

---

# 7/1/2026 — noexcept enforcement, nullable null_lit, ifo_t reflection, overloading removal

## Language
- **`noexcept` enforcement**: Compiler now rejects `try` expressions, `res {}` blocks, and `!T` return types inside `noexcept` functions. Error messages identify the offending function by name.
- **`?T` nullable — null enforcement**: `null` is now a distinct `null_lit` expression kind (no longer `int_lit(0)`). Assigning `null` to a non-pointer, non-nullable type is a compile-time semantic error. `null` is assignable to any pointer (`T*`) or nullable (`?T`) type.
- **Free function overloading removed**: Only one definition per function name is allowed for free functions. Declaring two functions with the same name but different signatures now produces `"Function overloading is not supported"`. Forward declarations of the same signature still work (body→prototype update).

## Compiler
- **`--analyze-only` flag**: New compiler flag — runs preprocess→lex→parse→analyze and exits with no codegen and no output file. Cross-platform. Used by `aciso sta` (static analysis) to avoid the Windows `NUL` output-path issue.

## Tooling — `aciso sta`
- **Fixed Windows static analysis**: `aciso sta` now invokes the compiler with `--analyze-only` instead of `-c -o NUL`. Eliminates "filename syntax incorrect" error on Windows. Output is filtered to suppress empty lines.

## IR
- **Vtable / inheritance code removed**: `class_ir_info` no longer carries vtable fields (`vtable_type`, `vtable_global`, `vtable_slots`, `has_virtual`). `visit_class_decl_types()` no longer tries to inherit base-class fields or build vtable globals. Safe to remove because the analyzer now rejects all `virtual`/`override`/`final`/inheritance at the semantic stage.
- **`null_lit` IR emission**: `expr_kind.null_lit` emits `LLVMConstNull` of `i8*` — a typed null pointer constant.
- **`visit_get_ifo_t_expr` — full implementation**: `get_ifo_t(T)` is now fully implemented. Determines kind (prim/ptr/struct/union/istruc/unknown), size, alignment, bit-width, and signedness from the LLVM type at compile time. Creates a private constant global of type `ifo__NS_ifo_t` and returns a pointer to it. No `LLVMTargetDataRef` needed — sizes derived from LLVM integer widths.

## Stdlib
- **`compiler/std/include/ifo.arc`** (new): `namespace ifo` — defines `ifo_t` (type reflection struct), `ifo_field_t`, and all `IFO_KIND_*` constants. Used as the return type of `get_ifo_t(T)`.

## Tests
- **Pass tests added**: `199_noexcept_pass`, `200_nullable_null_assign`, `201_error_union_try`
- **Fail tests added**: `114_noexcept_try`, `115_noexcept_error_union`, `116_null_to_nonptr`, `117_free_func_overload`
- **Tests 127, 170 updated**: Rewrote overload tests to use distinct function names (overloading is removed).
- **197 pass tests, 0 failures. 117 fail tests, 0 unexpected passes.**

---

# 7/1/2026 — new error system, IR error unions, lexer/parser cleanup

## Language — Error System (replaces setjmp/longjmp exceptions)
- **`!T` return types**: Functions declared `auto foo() !T {}` return an error-union struct `{i32 err_tag, T value}`. `err_tag == 0` means success; non-zero is the FNV-1a hash of the error name.
- **`return error.Name`**: Returns a named error from a `!T` function. The error name is hashed to a non-zero i32 at compile time.
- **`expr except |e| { body }`**: Catches an error from a `!T` expression. `e` is bound to the i32 error tag inside the handler. Handler only runs if `err_tag != 0`. No semicolon required after the closing `}`.
- **`try expr`**: In expression context, propagates an error from a `!T` call upward to the enclosing `!T` function. Yields the ok value on success.
- **`try expr;`**: Statement form — propagates error upward, discards the ok value.
- **`res { }` block**: Inline block that can return errors (parsed; IR emits body normally).
- **`error` and `res` keywords**: Now proper keywords in the lexer (previously contextual/missing).

## Language — Removed
- **`throw`/`try`/`except (Type e)` old exception system**: Removed from lexer keyword map. The `kw_throw`, `kw_virtual`, `kw_override`, `kw_final`, `kw_mandatory`, `kw_derive`, `kw_attr`, `kw_macro`, `kw_verify`, `kw_quote` token types removed.
- **`virtual`/`override`/`final`/`mandatory`**: No longer reserved words.

## IR
- **Error-union function IR**: `!T` functions emit `{ i32, T }` struct return type. `!void` functions emit `i32` (the error tag only).
- **`visit_return_stmt` error detection**: Uses AST expression kind (`error_lit`) to distinguish `return error.Name` from `return value`, enabling correct struct wrapping even when T == i32.
- **`visit_try_expr_func`**: Evaluates a `!T` expression, branches on error tag; on error propagates to caller; on success yields T value.
- **`visit_except_expr_func`**: Evaluates a `!T` expression, branches into handler block on error, binds error tag to named variable.
- **`visit_error_lit_expr`**: Emits FNV-1a hash of error name as i32 constant.
- **`visit_get_ifo_t_expr`**: Stub — returns null pointer (full reflection pending).
- **Removed setjmp/longjmp exception IR**: `visit_throw_stmt`, `visit_try_stmt`, and all setjmp/longjmp helpers removed from `stmts.hxx`.

## Tests
- Updated tests 196/197/198 for new error system syntax (previously used old `throw`/`try`/`except (T e)` syntax).
- All 194 integration tests pass.

---

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
- **Stdlib namespace wrapping**: All stdlib modules now place their declarations inside a named namespace. Usage changes: `hash.sha256_hash_str(...)`, `fmt.print(...)`, `math.abs_i32(...)`, `encode.utf8_encode(...)`, `debug.poison(...)` etc.
- **Namespace intra-body resolution**: Code inside a namespace can now refer to types, variables, and functions in the same namespace by bare name (no `.` qualifier needed). Resolves across both the semantic analyser and the IR emitter.
- **Namespace struct/typedef/var mangling**: `struct`, `union`, `typedef`, and `constexpr` declarations inside a namespace are now correctly mangled (e.g. `sha256_digest` → `hash__NS_sha256_digest`) and accessible from outside via `hash.sha256_digest`.
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