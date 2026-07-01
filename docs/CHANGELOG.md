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