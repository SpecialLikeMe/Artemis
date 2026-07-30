# tcon/time — performance benchmarks

Arc **run times** against C, and Arc **compile times** against Go.

```sh
./tcon/time/run_bench.sh          # from the repo root
REPS=9 ./tcon/time/run_bench.sh   # more repetitions
```

Each benchmark exists three times — `.arc`, `.c`, `.go` — implementing the same
algorithm with the same constants. Every one prints a checksum, and the harness refuses
to time a benchmark whose three implementations disagree: a run that computed something
else is not a faster run.

| benchmark | what it stresses |
|-----------|------------------|
| `sieve`   | byte array writes, 10M elements × 8 repetitions |
| `fib`     | function call overhead, naive `fib(35)` |
| `matmul`  | nested loops and indexing, dense 600×600 `f64` |
| `nbody`   | floating point, 20M integration steps |

## Reading the numbers

**Arc `-O2` is effectively `-march=native`.** The driver builds its target machine with
`LLVMGetHostCPUName` / `LLVMGetHostCPUFeatures`, so an Arc `-O2` binary may use AVX and
friends. A baseline `clang -O2` binary does not. The harness therefore builds C twice —
`c` (baseline x86-64) and `cn` (`-march=native`) — and takes the ratio against `cn`,
which is the honest comparison. Comparing against the baseline column would flatter Arc
for a reason that has nothing to do with Arc.

**Go's build cache makes a naive compile-time measurement meaningless.** Rebuilding
unchanged source is a cache hit and reports ~50 ms regardless of file size. The harness
prepends a unique comment before each timed build so the cache always misses. Arc has no
build cache and is always cold.

**Arc compile time includes machine-code generation and linking.** Arc emits the object
itself via `LLVMTargetMachineEmitToFile` and then shells out to `g++` only to link, so
"source to executable" covers the whole path. The external linker is a small part of it
(~93 ms on the compiler's own source); LLVM's object codegen is the large part. Use
`--time-phases` for the breakdown.

**Workloads are sized so compute dominates.** Process startup is ~10-17 ms here, so the
earlier, smaller versions of these benchmarks were half noise. Anything under ~100 ms
should be treated as indicative only; `nbody` is the most trustworthy figure.

## Measured, 2026-07-27

Windows 11 / x86-64, clang 22.1.2, go 1.26.3, Arc `build/artemis_y1.exe`.

Run time, median of 9, ms:

| benchmark | Arc `-O2` | clang `-O2` | clang native | Go  | Arc / clang native |
|-----------|-----------|-------------|--------------|-----|--------------------|
| sieve     | 146       | 153         | 148          | 176 | 0.99x |
| fib       | 47        | 41          | 40           | 55  | 1.18x |
| matmul    | 40        | 55          | 45           | 106 | 0.89x |
| nbody     | 910       | 819         | 814          | 1068| 1.12x |

Compile time, cold, source to executable, ms. "before" is prior to the hash-indexed
symbol tables:

| lines  | Arc before | Arc now | Go  | now/go |
|--------|-----------|---------|-----|--------|
| 6056   | 192       | 202     | 443 | 0.46x |
| 12056  | 295       | 241     | 372 | 0.65x |
| 24056  | 513       | 377     | 370 | 1.02x |
| 48056  | 1213      | 705     | 374 | 1.89x |

Arc is now ≈ 135 ms fixed + 12 ms per 1000 lines (~83k lines/s), up from 22 ms per 1000
(~45k lines/s). Go is essentially flat across this range — ~370 ms of fixed toolchain
overhead and very little per line — so Arc wins below ~24k lines on startup alone, and
Go wins above it.

Real-world anchor — the compiler compiling itself (25,497 lines), by `--time-phases`,
before and after the hash-indexed symbol tables:

| stage | before | after |
|-------|-------:|------:|
| preprocess / lex / parse | 18 / 52 / 40 | unchanged |
| analyze | 190 | **30** |
| smt (AST) | 23 | 23 |
| mir + lir + smt | 52 | 52 |
| llvm ir construction | 230 | **94** |
| front-end total (`-S`) | 640 | **328** |
| llvm object codegen | ~1300 | ~1300 |
| external linker (g++) | 93 | 93 |

Name resolution now goes through a hash index (`compiler/hash.arc`) instead of scanning
a list with `strcmp`, and `pop_scope` walks only the entries it drops instead of the
whole table. On 48k lines `analyze` fell from 391 ms to 17 ms. What is left of a full
build is dominated by LLVM's object codegen, which no amount of front-end work touches —
beating Go outright would need a direct LIR-to-object backend for `-O0`.

**Do not build the compiler itself with `-O2` yet.** It self-compiles to byte-identical
IR and is ~2x faster, but it *hangs* on some inputs (`tcon/fail/105_no_virtual.arc`,
`109_no_mandatory_virtual.arc`). Optimising the same `-O0` IR with `clang -O2` hangs
identically, so this is undefined behaviour in the compiler's own source that any
optimiser exposes — not Arc's pass pipeline. `-O0` is the supported way to build it.

Compiling *user* code at `-O1`/`-O2`/`-O3` is fine; those crashed the compiler until
2026-07-27 — `LLVMRunPasses` was given a
bare `"O2"` where the new pass manager wants `"default<O2>"`, and the rejected-pipeline
path then consumed the LLVM error twice and corrupted the heap. Every test had always
run at `-O0`, so nothing noticed.

## Compile-throughput benchmark

`gen_big.py` writes `big.arc` and `big.go` — the same N independent functions in both
languages, differing only in syntax. 2000 functions gives ~24k lines of Arc and ~28k
lines of Go.

```sh
python tcon/time/gen_big.py 2000
```

`bin/` holds built executables and is disposable.
