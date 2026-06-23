# Artemis Compiler — Production Readiness Prompt

## Context

You are working on **Artemis**, a C++-based compiler for a C-like language. It is approximately 3,600 LOC across ~19 files and is currently a working skeleton — not production-ready. The pipeline is: Lexer → Parser → Semantic Analyzer → LLVM IR generation. The code lives in a header-only layout:

```
compiler/
  lexer/main.hxx          (446 LOC) — full tokenizer
  parser/main.hxx         (820 LOC) — recursive descent parser, AST
  parser/expr.hxx          (99 LOC) — AST expression nodes
  analysis/analyzer.hxx   (709 LOC) — semantic analyzer, type checker
  analysis/scope.hxx       (91 LOC) — symbol table / scope management
  analysis/types.hxx      (213 LOC) — type utilities
  analysis/main.hxx        (11 LOC) — analysis entry point
  ir/context.hxx          (102 LOC) — IR generation state
  ir/types.hxx             (98 LOC) — type → LLVM type conversions
  ir/decls.hxx            (213 LOC) — IR for declarations
  ir/exprs.hxx            (476 LOC) — IR for expressions
  ir/stmts.hxx            (227 LOC) — IR for statements
  ir/main.hxx              (14 LOC) — IR entry point
  ir/include.h             (10 LOC) — LLVM C API includes
test/
  test.h                    (6 LOC) — empty stub
  read.h                   (54 LOC) — sys_exec / sys_getcmd utilities
```

**Tech stack:** C++17, LLVM C API (llvm-c/Core.h, llvm-c/Analysis.h, llvm-c/Target.h), STL.

---

## Your Task: Bring Artemis to Production Readiness

The following work is required, in priority order. Implement each item completely. Do not leave stubs, TODOs, or placeholder code.

---

### 1. Main Driver & CLI (`src/main.cpp`)

Create a proper entry point that:
- Accepts command-line arguments using a lightweight arg parser (no external deps; hand-roll it):
  - `artemis <source.art>` — compile to executable
  - `-o <output>` — specify output file
  - `-S` — emit LLVM IR only (`.ll`)
  - `-c` — emit object file only (`.o`)
  - `--emit-ast` — dump AST to stdout for debugging
  - `-O0 / -O1 / -O2 / -O3` — optimization level (default: `-O0`)
  - `--target <triple>` — LLVM target triple (default: host)
  - `-v / --verbose` — verbose output
  - `--version` — print version and exit
  - `-h / --help` — print usage and exit
- Reads the source file from disk, validates it exists and is readable
- Enforces a maximum input file size (e.g., 64 MB) with a clear error if exceeded
- Runs the full pipeline: Lexer → Parser → Analyzer → IR → (optional) optimization → emission
- Emits object files or executables via LLVM's `LLVMTargetMachineEmitToFile`
- Links to an executable using the system linker (invoke `cc` or `clang` for the final link step)
- Returns exit code 0 on success, 1 on compile error, 2 on internal error

---

### 2. Build System (`CMakeLists.txt` at root)

Create a complete CMake build:
- Minimum CMake version 3.20
- C++17 standard
- `find_package(LLVM REQUIRED CONFIG)` — use LLVM's CMake config
- Builds `artemis` as an executable target
- Installs to `${CMAKE_INSTALL_PREFIX}/bin/artemis`
- `enable_testing()` and a `ctest` integration that runs all tests
- Debug and Release build type configurations
- Export compile commands (`CMAKE_EXPORT_COMPILE_COMMANDS ON`) for tooling

---

### 3. Testing Framework (`test/`)

Replace the empty `test.h` stub with a real test suite. Implement using a lightweight hand-rolled framework (no external test lib unless the project already has one). The test suite must include:

#### 3a. Unit Tests
- **Lexer:** Test every token type, edge cases (empty input, EOF mid-token, unterminated strings, hex/binary literals, overflow literals)
- **Parser:** Test every grammar production, error recovery, malformed inputs
- **Analyzer:** Test type errors, undeclared variables, scope shadowing, loop/break validation, void misuse
- **IR:** Verify generated LLVM IR validates via `LLVMVerifyModule`

#### 3b. Integration / End-to-End Tests
Use `test/read.h`'s `sys_exec` to compile `.art` source snippets and verify:
- Programs that should compile succeed with exit code 0
- Programs with known errors fail with exit code 1 and specific error substrings in stderr
- Generated executables run and produce correct output (basic arithmetic, conditionals, loops, functions, structs)

Minimum 30 meaningful test cases across unit + integration.

#### 3c. Test Runner
- A `test/runner.cpp` that discovers and runs all tests, prints pass/fail counts, exits non-zero on any failure

---

### 4. Error Handling & Diagnostics

The current system throws exceptions with basic messages. Replace with a proper diagnostic system:

- A `Diagnostic` struct: `{ DiagLevel level; std::string message; int line; int col; }`
- Levels: `Error`, `Warning`, `Note`
- A `DiagnosticEngine` that collects diagnostics and emits them all at once (not one-and-done exception throwing)
- Continue analysis past the first error where possible (error recovery)
- Emit diagnostics in this format: `filename:line:col: error: message`
- Color output when stdout is a TTY (use ANSI codes, check `isatty`)
- Warning for: unused variables, unreachable code after return, implicit narrowing
- Hard limit: if error count exceeds 20, stop and report "too many errors"

---

### 5. Memory Safety

Audit and fix all raw pointer ownership issues in the AST and IR generation:

- All AST nodes must be owned by `std::unique_ptr` — no raw owning pointers
- All LLVM values (`LLVMValueRef`, `LLVMTypeRef`, etc.) must be properly released on error paths
- Wrap `LLVMModuleRef`, `LLVMBuilderRef`, `LLVMContextRef` in RAII wrappers with destructors that call the corresponding `LLVMDispose*` functions
- Verify no double-free or use-after-free with AddressSanitizer build (`-fsanitize=address`)

---

### 6. IR Completeness

Fix the known incomplete areas in IR generation:

- **Unions:** Implement correct memory-layout union representation — allocate storage for the largest member, bit-cast for access
- **Struct GEP:** Ensure `LLVMBuildGEP2` uses correct member indices from the struct layout map
- **Missing binary ops:** Ensure all operator types from the parser have corresponding IR emit paths (bitwise AND/OR/XOR/shift, comparison operators returning i1 with zero-extend to bool)
- **Variable initialization:** Local variables without initializers must be zero-initialized via `LLVMBuildAlloca` + `LLVMBuildStore(LLVMConstNull(...))`
- **Short-circuit evaluation:** `&&` and `||` must use conditional branching, not eager evaluation

---

### 7. Optimization Passes

Wire in LLVM optimization passes based on the `-O` flag:

- `-O0`: No passes
- `-O1`: `mem2reg`, `instcombine`, `simplifycfg`
- `-O2`: All `-O1` passes + `inline`, `loop-unroll`, `gvn`, `dce`
- `-O3`: All `-O2` passes + `vectorize`, `licm`, `sroa`

Use the LLVM PassManager C API (`LLVMCreatePassManager`, `LLVMRunPassManager`) or the new PassBuilder API if available.

---

### 8. CI/CD (`.github/workflows/ci.yml`)

Create a GitHub Actions workflow that:
- Triggers on push and pull_request to `main`
- Matrix: `ubuntu-latest` with LLVM 17 and 18
- Steps: checkout → install LLVM → cmake configure → cmake build → ctest
- Fail the build if any test fails
- Upload build artifacts (the `artemis` binary) on success from `main` branch builds
- Optionally: run with `-fsanitize=address,undefined` in a separate job

---

### 9. README (`README.md`)

Write a proper user-facing README covering:
- What Artemis is (one paragraph)
- Language feature overview (types supported, control flow, functions, structs, enums)
- Prerequisites (LLVM 17+, clang, cmake, C++17 compiler)
- Build instructions (cmake configure + build commands, both Debug and Release)
- Usage examples (compile a hello-world `.art` file, flags reference)
- A minimal working `.art` code example that demonstrates the language
- Known limitations / in-progress features
- License

---

### 10. Language Spec (`docs/spec.md`)

Write a minimal language specification covering:
- Type system (all supported types and their sizes)
- Declarations (variable, function, struct, enum, union, typedef)
- Expressions (precedence table, all operators)
- Statements (all control flow constructs)
- Annotations (`@` syntax and semantics)
- Calling convention and extern linkage

---

## Constraints

- Do not add any external C++ dependencies beyond LLVM (no Boost, no abseil, no third-party test frameworks unless already present)
- Do not break the existing lexer, parser, or analyzer logic — extend and fix, do not rewrite from scratch
- All new code must be C++17-compatible
- Prefer `std::string_view` over `const std::string&` for read-only string params
- Do not use `goto` or `longjmp`
- All files must compile without warnings under `-Wall -Wextra -Wpedantic`

## CLI

The artemis CLI should have the following:

For automatic compilation
atc <filename> -o <output>

For manual specification of target (flag indicates OS):
atc <filename> -[l|w|m] <output>

For help:
atc help

For immidiate execution:
atx run <filename>

For version:
artemis --version

## Definition of Done

The project is production-ready when:
1. `cmake --build . && ctest` passes with 0 failures
2. `artemis hello.art -o hello && ./hello` works for a basic program
3. CI green on GitHub Actions
4. `artemis --help` prints a useful usage message
5. Compiler errors include filename, line, and column
6. No memory leaks under AddressSanitizer for a clean compile run
7. CLI green

(NOTE THAT WHILE LOC IS NOT AN IMPORTANT METRIC, I WOULD BE VERY SURPRISED IF THIS COULD BE ACHIEVED IN LESSS THAN 20k LOC)