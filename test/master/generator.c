/*
 * generator.c — Artemis behavioral divergence test generator (TH3-style)
 *
 * Build:
 *   gcc -O2 -o generator generator.c
 *
 * Usage:
 *   generator <input.arc>
 *
 * For every LOC in <input.arc>, emits ~100,000 LOC of Artemis that
 * expresses the same computations in 10 structurally distinct ways and
 * cross-verifies them at runtime.  main() returns 0 on full agreement
 * across all variants; non-zero reveals optimizer divergence.
 *
 * The harness then compiles with -O0 / -O2 / -O3 and compares outputs —
 * a mismatch means the compiler introduced a wrong-answer transformation.
 *
 * Ten cluster types per LOC (1000 clusters × ~100 lines ≈ 100 k LOC/LOC):
 *   T0  triangular sum       — loop variants vs closed-form
 *   T1  count-to-n           — while / for / recursive / pointer
 *   T2  Euclidean GCD        — iterative vs recursive (gcd(2S,3S)=S)
 *   T3  array min            — fwd/bwd scan, struct wrapper, pointer
 *   T4  population count     — loop vs Kernighan vs lookup-table
 *   T5  reverse-then-sum     — array reversal methods all yield T(n)
 *   T6  Fibonacci            — recursive vs iterative vs unrolled memo
 *   T7  odd-count parity     — scan vs formula vs bitwise
 *   T8  dead-branch DCE      — result=S despite elaborate dead paths
 *   T9  inlining chain       — S through N-deep wrappers vs direct
 *
 * All cluster seeds S ∈ [2..47] so loops finish fast and i32 never
 * overflows.  Checker functions return 0 on pass, error-code on fail.
 * verify_{lno}() ORs all 1000 checkers; main() sums all verify results.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#ifdef _WIN32
#  include <direct.h>
static int xmkdir(const char *p) { return _mkdir(p); }
#else
#  include <sys/stat.h>
static int xmkdir(const char *p) { return mkdir(p, 0755); }
#endif

#define IO_BUF_SIZE      (1 << 20)
#define CLUSTERS_PER_LOC   200   /* ~54 lines/cluster × 200 ≈ 10k lines/LOC */
#define N_TYPES           10

/* Seed per LOC — S ∈ [2..47] so inner loops finish fast */
static int seed_for(long lno)
{
    return (int)((lno * 1009L + 13) % 46) + 2;
}

/* fib(n) for small n — used to bake expected values into checkers */
static int fib(int n)
{
    if (n <= 1) return n;
    int a = 0, b = 1;
    for (int i = 2; i <= n; i++) { int c = a + b; a = b; b = c; }
    return b;
}

/* popcount(n) for small n */
static int popcnt(int n)
{
    int c = 0;
    while (n) { n &= n - 1; c++; }
    return c;
}

/* ── utilities ─────────────────────────────────────────────────────────── */

static void get_basename(const char *path, char *out, size_t sz)
{
    const char *s = path, *last = path;
    while (*s) { if (*s == '/' || *s == '\\') last = s + 1; s++; }
    size_t i = 0;
    while (last[i] && last[i] != '.' && i + 1 < sz) { out[i] = last[i]; i++; }
    out[i] = '\0';
}

static long count_lines(const char *path)
{
    FILE *f = fopen(path, "r");
    if (!f) return 1;
    long n = 0; int c;
    while ((c = fgetc(f)) != EOF) if (c == '\n') n++;
    fclose(f);
    return n < 1 ? 1 : n;
}

static void ensure_dir(const char *path)
{
    if (xmkdir(path) != 0 && errno != EEXIST) {
        fprintf(stderr, "Cannot create '%s': %s\n", path, strerror(errno));
        exit(1);
    }
}

/* ════════════════════════════════════════════════════════════════════════
 * CLUSTER EMITTERS — each writes ~100 lines of live Artemis code.
 *
 * Naming:
 *   helper functions  →  t{T}_{lno}_{cidx}_{tag}
 *   checker function  →  ck_{lno}_{cidx}          (returns 0 on pass)
 *   stress function   →  st_{lno}_{cidx}           (extra cross-check)
 * ════════════════════════════════════════════════════════════════════════ */

/* ── T0: triangular sum — loop variants vs closed-form formula ─────────
 * T(n) = n*(n+1)/2 via:
 *   fwd   — forward for-loop
 *   bwd   — backward while-loop
 *   fml   — closed-form n*(n+1)/2
 *   twoptr— left+right simultaneous accumulation
 *   tr    — tail-recursive helper
 *   arr   — fill array [1..n] then sum it
 *   str2  — stride-2: sum odds first, then evens
 */
static void emit_t0(FILE *f, long lno, long cidx, int S)
{
    char p[64];
    snprintf(p, sizeof p, "t0_%ld_%ld", lno, cidx);
    int expected = S * (S + 1) / 2;

    fprintf(f, "i32 %s_fwd(i32 n) {\n", p);
    fprintf(f, "    i32 s = 0;\n");
    fprintf(f, "    for (i32 i = 1; i <= n; i++) { s = s + i; }\n");
    fprintf(f, "    return s;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 %s_bwd(i32 n) {\n", p);
    fprintf(f, "    i32 s = 0; i32 i = n;\n");
    fprintf(f, "    while (i > 0) { s = s + i; i = i - 1; }\n");
    fprintf(f, "    return s;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 %s_fml(i32 n) { return (n * (n + 1)) / 2; }\n\n", p);

    fprintf(f, "i32 %s_twoptr(i32 n) {\n", p);
    fprintf(f, "    i32 lo = 1; i32 hi = n; i32 s = 0;\n");
    fprintf(f, "    while (lo < hi) { s = s + lo + hi; lo++; hi--; }\n");
    fprintf(f, "    if (lo == hi) { s = s + lo; }\n");
    fprintf(f, "    return s;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 %s_trh(i32 i, i32 s, i32 n) {\n", p);
    fprintf(f, "    if (i > n) { return s; }\n");
    fprintf(f, "    return %s_trh(i + 1, s + i, n);\n", p);
    fprintf(f, "}\n");
    fprintf(f, "i32 %s_tr(i32 n) { return %s_trh(1, 0, n); }\n\n", p, p);

    fprintf(f, "i32 %s_arr(i32 n) {\n", p);
    fprintf(f, "    i32[50] a;\n");
    fprintf(f, "    for (i32 i = 0; i < n; i++) { a[i] = i + 1; }\n");
    fprintf(f, "    i32 s = 0;\n");
    fprintf(f, "    for (i32 i = 0; i < n; i++) { s = s + a[i]; }\n");
    fprintf(f, "    return s;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 %s_str2(i32 n) {\n", p);
    fprintf(f, "    i32 s = 0;\n");
    fprintf(f, "    for (i32 i = 1; i <= n; i = i + 2) { s = s + i; }\n");
    fprintf(f, "    for (i32 i = 2; i <= n; i = i + 2) { s = s + i; }\n");
    fprintf(f, "    return s;\n");
    fprintf(f, "}\n\n");

    /* Checker: all 7 variants must equal expected */
    fprintf(f, "i32 ck_%ld_%ld() {\n", lno, cidx);
    fprintf(f, "    i32 S = %d; i32 E = %d;\n", S, expected);
    fprintf(f, "    i32 a = %s_fwd(S);    if (a != E) { return 10; }\n", p);
    fprintf(f, "    i32 b = %s_bwd(S);    if (b != E) { return 11; }\n", p);
    fprintf(f, "    i32 c = %s_fml(S);    if (c != E) { return 12; }\n", p);
    fprintf(f, "    i32 d = %s_twoptr(S); if (d != E) { return 13; }\n", p);
    fprintf(f, "    i32 e = %s_tr(S);     if (e != E) { return 14; }\n", p);
    fprintf(f, "    i32 g = %s_arr(S);    if (g != E) { return 15; }\n", p);
    fprintf(f, "    i32 h = %s_str2(S);   if (h != E) { return 16; }\n", p);
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n\n");

    /* Stress: verify all loop variants agree with formula for n in [1..S] */
    fprintf(f, "i32 st_%ld_%ld() {\n", lno, cidx);
    fprintf(f, "    for (i32 n = 1; n <= %d; n++) {\n", S);
    fprintf(f, "        i32 r = %s_fml(n);\n", p);
    fprintf(f, "        if (%s_fwd(n)    != r) { return n; }\n", p);
    fprintf(f, "        if (%s_bwd(n)    != r) { return n + 100; }\n", p);
    fprintf(f, "        if (%s_twoptr(n) != r) { return n + 200; }\n", p);
    fprintf(f, "        if (%s_arr(n)    != r) { return n + 300; }\n", p);
    fprintf(f, "    }\n");
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n\n");
}

/* ── T1: count-to-n — same result (=n) via structurally different loops ─ */
static void emit_t1(FILE *f, long lno, long cidx, int S)
{
    char p[64];
    snprintf(p, sizeof p, "t1_%ld_%ld", lno, cidx);

    fprintf(f, "i32 %s_whl(i32 n) {\n", p);
    fprintf(f, "    i32 r = 0; i32 i = 0;\n");
    fprintf(f, "    while (i < n) { r++; i++; }\n");
    fprintf(f, "    return r;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 %s_for(i32 n) {\n", p);
    fprintf(f, "    i32 r = 0;\n");
    fprintf(f, "    for (i32 i = 0; i < n; i++) { r = r + 1; }\n");
    fprintf(f, "    return r;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 %s_rec(i32 n) {\n", p);
    fprintf(f, "    if (n <= 0) { return 0; }\n");
    fprintf(f, "    return 1 + %s_rec(n - 1);\n", p);
    fprintf(f, "}\n\n");

    /* Count via pointer: store n in local, read through pointer */
    fprintf(f, "i32 %s_ptr(i32 n) {\n", p);
    fprintf(f, "    i32 x = n;\n");
    fprintf(f, "    i32* p2 = &x;\n");
    fprintf(f, "    i32 r = 0;\n");
    fprintf(f, "    while (*p2 > 0) { r++; *p2 = *p2 - 1; }\n");
    fprintf(f, "    return r;\n");
    fprintf(f, "}\n\n");

    /* Count using subtraction until zero */
    fprintf(f, "i32 %s_sub(i32 n) {\n", p);
    fprintf(f, "    i32 r = n;\n");
    fprintf(f, "    i32 z = 0;\n");
    fprintf(f, "    while (r > z) { z++; }\n");
    fprintf(f, "    return z;\n");
    fprintf(f, "}\n\n");

    /* Count with stride + remainder */
    fprintf(f, "i32 %s_strided(i32 n) {\n", p);
    fprintf(f, "    i32 r = 0;\n");
    fprintf(f, "    for (i32 i = 0; i + 1 < n; i = i + 2) { r = r + 2; }\n");
    fprintf(f, "    if (n %% 2 != 0) { r = r + 1; }\n");
    fprintf(f, "    return r;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 ck_%ld_%ld() {\n", lno, cidx);
    fprintf(f, "    i32 S = %d;\n", S);
    fprintf(f, "    if (%s_whl(S)     != S) { return 20; }\n", p);
    fprintf(f, "    if (%s_for(S)     != S) { return 21; }\n", p);
    fprintf(f, "    if (%s_rec(S)     != S) { return 22; }\n", p);
    fprintf(f, "    if (%s_ptr(S)     != S) { return 23; }\n", p);
    fprintf(f, "    if (%s_sub(S)     != S) { return 24; }\n", p);
    fprintf(f, "    if (%s_strided(S) != S) { return 25; }\n", p);
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 st_%ld_%ld() {\n", lno, cidx);
    fprintf(f, "    for (i32 n = 1; n <= %d; n++) {\n", S);
    fprintf(f, "        if (%s_whl(n) != n) { return n; }\n", p);
    fprintf(f, "        if (%s_for(n) != n) { return n + 100; }\n", p);
    fprintf(f, "        if (%s_rec(n) != n) { return n + 200; }\n", p);
    fprintf(f, "    }\n");
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n\n");
}

/* ── T2: GCD — gcd(2*S, 3*S) = S via Euclidean and binary algorithms ─── */
static void emit_t2(FILE *f, long lno, long cidx, int S)
{
    char p[64];
    snprintf(p, sizeof p, "t2_%ld_%ld", lno, cidx);

    /* Iterative Euclidean */
    fprintf(f, "i32 %s_iter(i32 a, i32 b) {\n", p);
    fprintf(f, "    while (b != 0) { i32 t = b; b = a %% b; a = t; }\n");
    fprintf(f, "    return a;\n");
    fprintf(f, "}\n\n");

    /* Recursive Euclidean */
    fprintf(f, "i32 %s_rec(i32 a, i32 b) {\n", p);
    fprintf(f, "    if (b == 0) { return a; }\n");
    fprintf(f, "    return %s_rec(b, a %% b);\n", p);
    fprintf(f, "}\n\n");

    /* Binary GCD (Stein's algorithm) */
    fprintf(f, "i32 %s_bin(i32 a, i32 b) {\n", p);
    fprintf(f, "    if (a == 0) { return b; }\n");
    fprintf(f, "    if (b == 0) { return a; }\n");
    fprintf(f, "    i32 shift = 0;\n");
    fprintf(f, "    while (((a | b) & 1) == 0) { a = a / 2; b = b / 2; shift++; }\n");
    fprintf(f, "    while ((a & 1) == 0) { a = a / 2; }\n");
    fprintf(f, "    while (b != 0) {\n");
    fprintf(f, "        while ((b & 1) == 0) { b = b / 2; }\n");
    fprintf(f, "        if (a > b) { i32 t = a; a = b; b = t; }\n");
    fprintf(f, "        b = b - a;\n");
    fprintf(f, "    }\n");
    fprintf(f, "    i32 r = a;\n");
    fprintf(f, "    for (i32 i = 0; i < shift; i++) { r = r * 2; }\n");
    fprintf(f, "    return r;\n");
    fprintf(f, "}\n\n");

    /* Subtraction-only GCD */
    fprintf(f, "i32 %s_sub(i32 a, i32 b) {\n", p);
    fprintf(f, "    while (a != b) {\n");
    fprintf(f, "        if (a > b) { a = a - b; } else { b = b - a; }\n");
    fprintf(f, "    }\n");
    fprintf(f, "    return a;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 ck_%ld_%ld() {\n", lno, cidx);
    fprintf(f, "    i32 a = %d; i32 b = %d; i32 E = %d;\n", 2*S, 3*S, S);
    fprintf(f, "    if (%s_iter(a, b) != E) { return 30; }\n", p);
    fprintf(f, "    if (%s_rec(a, b)  != E) { return 31; }\n", p);
    fprintf(f, "    if (%s_bin(a, b)  != E) { return 32; }\n", p);
    fprintf(f, "    if (%s_sub(a, b)  != E) { return 33; }\n", p);
    fprintf(f, "    if (%s_iter(a, b) != %s_rec(a, b))  { return 34; }\n", p, p);
    fprintf(f, "    if (%s_iter(a, b) != %s_bin(a, b))  { return 35; }\n", p, p);
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n\n");

    /* Stress: verify gcd properties hold for (n, n+S) pairs */
    fprintf(f, "i32 st_%ld_%ld() {\n", lno, cidx);
    fprintf(f, "    for (i32 n = 1; n <= %d; n++) {\n", S);
    fprintf(f, "        i32 g1 = %s_iter(n * 2, n * 3);\n", p);
    fprintf(f, "        i32 g2 = %s_rec(n * 2, n * 3);\n", p);
    fprintf(f, "        if (g1 != n) { return n; }\n");
    fprintf(f, "        if (g2 != n) { return n + 100; }\n");
    fprintf(f, "    }\n");
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n\n");
}

/* ── T3: array min — min of known array equals S ───────────────────────
 * Array = { S+5, S+3, S+1, S, S+2, S+4 }  → min = S always
 */
static void emit_t3(FILE *f, long lno, long cidx, int S)
{
    char p[64];
    snprintf(p, sizeof p, "t3_%ld_%ld", lno, cidx);
    int a0 = S+5, a1 = S+3, a2 = S+1, a3 = S, a4 = S+2, a5 = S+4;

    /* Forward scan of 6 explicit values */
    fprintf(f, "i32 %s_fwd(i32 v0, i32 v1, i32 v2, i32 v3, i32 v4, i32 v5) {\n", p);
    fprintf(f, "    i32 m = v0;\n");
    fprintf(f, "    if (v1 < m) { m = v1; }\n");
    fprintf(f, "    if (v2 < m) { m = v2; }\n");
    fprintf(f, "    if (v3 < m) { m = v3; }\n");
    fprintf(f, "    if (v4 < m) { m = v4; }\n");
    fprintf(f, "    if (v5 < m) { m = v5; }\n");
    fprintf(f, "    return m;\n");
    fprintf(f, "}\n\n");

    /* Backward scan */
    fprintf(f, "i32 %s_bwd(i32 v0, i32 v1, i32 v2, i32 v3, i32 v4, i32 v5) {\n", p);
    fprintf(f, "    i32 m = v5;\n");
    fprintf(f, "    if (v4 < m) { m = v4; }\n");
    fprintf(f, "    if (v3 < m) { m = v3; }\n");
    fprintf(f, "    if (v2 < m) { m = v2; }\n");
    fprintf(f, "    if (v1 < m) { m = v1; }\n");
    fprintf(f, "    if (v0 < m) { m = v0; }\n");
    fprintf(f, "    return m;\n");
    fprintf(f, "}\n\n");

    /* Ternary tournament */
    fprintf(f, "i32 %s_ternary(i32 v0, i32 v1, i32 v2, i32 v3, i32 v4, i32 v5) {\n", p);
    fprintf(f, "    i32 m01 = v0 < v1 ? v0 : v1;\n");
    fprintf(f, "    i32 m23 = v2 < v3 ? v2 : v3;\n");
    fprintf(f, "    i32 m45 = v4 < v5 ? v4 : v5;\n");
    fprintf(f, "    i32 m03 = m01 < m23 ? m01 : m23;\n");
    fprintf(f, "    return m03 < m45 ? m03 : m45;\n");
    fprintf(f, "}\n\n");

    /* Via struct */
    fprintf(f, "struct T3S_%ld_%ld { i32 v; }\n", lno, cidx);
    fprintf(f, "i32 %s_struct(i32 v0, i32 v1, i32 v2, i32 v3, i32 v4, i32 v5) {\n", p);
    fprintf(f, "    T3S_%ld_%ld best; best.v = v0;\n", lno, cidx);
    fprintf(f, "    if (v1 < best.v) { best.v = v1; }\n");
    fprintf(f, "    if (v2 < best.v) { best.v = v2; }\n");
    fprintf(f, "    if (v3 < best.v) { best.v = v3; }\n");
    fprintf(f, "    if (v4 < best.v) { best.v = v4; }\n");
    fprintf(f, "    if (v5 < best.v) { best.v = v5; }\n");
    fprintf(f, "    return best.v;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 ck_%ld_%ld() {\n", lno, cidx);
    fprintf(f, "    i32 E = %d;\n", S);
    fprintf(f, "    if (%s_fwd(%d,%d,%d,%d,%d,%d)    != E) { return 40; }\n", p,a0,a1,a2,a3,a4,a5);
    fprintf(f, "    if (%s_bwd(%d,%d,%d,%d,%d,%d)    != E) { return 41; }\n", p,a0,a1,a2,a3,a4,a5);
    fprintf(f, "    if (%s_ternary(%d,%d,%d,%d,%d,%d) != E) { return 42; }\n", p,a0,a1,a2,a3,a4,a5);
    fprintf(f, "    if (%s_struct(%d,%d,%d,%d,%d,%d)  != E) { return 43; }\n", p,a0,a1,a2,a3,a4,a5);
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 st_%ld_%ld() {\n", lno, cidx);
    fprintf(f, "    i32 r1 = %s_fwd(%d,%d,%d,%d,%d,%d);\n", p,a0,a1,a2,a3,a4,a5);
    fprintf(f, "    i32 r2 = %s_bwd(%d,%d,%d,%d,%d,%d);\n", p,a0,a1,a2,a3,a4,a5);
    fprintf(f, "    i32 r3 = %s_ternary(%d,%d,%d,%d,%d,%d);\n", p,a0,a1,a2,a3,a4,a5);
    fprintf(f, "    if (r1 != r2 || r2 != r3) { return 1; }\n");
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n\n");
}

/* ── T4: population count — number of set bits in S ────────────────────
 * Expected = popcount(S) baked in at generation time
 */
static void emit_t4(FILE *f, long lno, long cidx, int S)
{
    char p[64];
    snprintf(p, sizeof p, "t4_%ld_%ld", lno, cidx);
    int expected = popcnt(S);

    /* Loop shift-and-test */
    fprintf(f, "i32 %s_loop(i32 x) {\n", p);
    fprintf(f, "    i32 c = 0;\n");
    fprintf(f, "    while (x != 0) { c = c + (x & 1); x = x / 2; }\n");
    fprintf(f, "    return c;\n");
    fprintf(f, "}\n\n");

    /* Kernighan: x &= x-1 clears lowest set bit */
    fprintf(f, "i32 %s_kern(i32 x) {\n", p);
    fprintf(f, "    i32 c = 0;\n");
    fprintf(f, "    while (x != 0) { x = x & (x - 1); c++; }\n");
    fprintf(f, "    return c;\n");
    fprintf(f, "}\n\n");

    /* Lookup table on nibbles */
    fprintf(f, "i32 %s_lut(i32 x) {\n", p);
    fprintf(f, "    i32[16] t;\n");
    fprintf(f, "    t[0]=0; t[1]=1; t[2]=1; t[3]=2;\n");
    fprintf(f, "    t[4]=1; t[5]=2; t[6]=2; t[7]=3;\n");
    fprintf(f, "    t[8]=1; t[9]=2; t[10]=2; t[11]=3;\n");
    fprintf(f, "    t[12]=2; t[13]=3; t[14]=3; t[15]=4;\n");
    fprintf(f, "    i32 c = 0;\n");
    fprintf(f, "    while (x != 0) { c = c + t[x & 15]; x = x / 16; }\n");
    fprintf(f, "    return c;\n");
    fprintf(f, "}\n\n");

    /* Parallel bit-sum (Hamming weight) */
    fprintf(f, "i32 %s_par(i32 x) {\n", p);
    fprintf(f, "    x = x - ((x / 2) & 0x55555555);\n");
    fprintf(f, "    x = (x & 0x33333333) + ((x / 4) & 0x33333333);\n");
    fprintf(f, "    x = (x + (x / 16)) & 0x0F0F0F0F;\n");
    fprintf(f, "    return x %% 255;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 ck_%ld_%ld() {\n", lno, cidx);
    fprintf(f, "    i32 S = %d; i32 E = %d;\n", S, expected);
    fprintf(f, "    if (%s_loop(S) != E) { return 50; }\n", p);
    fprintf(f, "    if (%s_kern(S) != E) { return 51; }\n", p);
    fprintf(f, "    if (%s_lut(S)  != E) { return 52; }\n", p);
    fprintf(f, "    if (%s_par(S)  != E) { return 53; }\n", p);
    fprintf(f, "    if (%s_loop(S) != %s_kern(S)) { return 54; }\n", p, p);
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 st_%ld_%ld() {\n", lno, cidx);
    fprintf(f, "    for (i32 n = 1; n <= %d; n++) {\n", S);
    fprintf(f, "        if (%s_loop(n) != %s_kern(n)) { return n; }\n", p, p);
    fprintf(f, "        if (%s_kern(n) != %s_lut(n))  { return n + 100; }\n", p, p);
    fprintf(f, "    }\n");
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n\n");
}

/* ── T5: reverse-then-sum — fill [1..n], reverse, sum = T(n) ────────── */
static void emit_t5(FILE *f, long lno, long cidx, int S)
{
    char p[64];
    snprintf(p, sizeof p, "t5_%ld_%ld", lno, cidx);
    int expected = S * (S + 1) / 2;

    /* Fill + reverse in-place + sum */
    fprintf(f, "i32 %s_rev_sum(i32 n) {\n", p);
    fprintf(f, "    i32[50] a;\n");
    fprintf(f, "    for (i32 i = 0; i < n; i++) { a[i] = i + 1; }\n");
    fprintf(f, "    i32 lo = 0; i32 hi = n - 1;\n");
    fprintf(f, "    while (lo < hi) {\n");
    fprintf(f, "        i32 t = a[lo]; a[lo] = a[hi]; a[hi] = t;\n");
    fprintf(f, "        lo++; hi--;\n");
    fprintf(f, "    }\n");
    fprintf(f, "    i32 s = 0;\n");
    fprintf(f, "    for (i32 i = 0; i < n; i++) { s = s + a[i]; }\n");
    fprintf(f, "    return s;\n");
    fprintf(f, "}\n\n");

    /* Fill + copy-reverse into second array + sum */
    fprintf(f, "i32 %s_copyrev_sum(i32 n) {\n", p);
    fprintf(f, "    i32[50] a; i32[50] b;\n");
    fprintf(f, "    for (i32 i = 0; i < n; i++) { a[i] = i + 1; }\n");
    fprintf(f, "    for (i32 i = 0; i < n; i++) { b[i] = a[n - 1 - i]; }\n");
    fprintf(f, "    i32 s = 0;\n");
    fprintf(f, "    for (i32 i = 0; i < n; i++) { s = s + b[i]; }\n");
    fprintf(f, "    return s;\n");
    fprintf(f, "}\n\n");

    /* XOR swap reverse + sum */
    fprintf(f, "i32 %s_xorrev_sum(i32 n) {\n", p);
    fprintf(f, "    i32[50] a;\n");
    fprintf(f, "    for (i32 i = 0; i < n; i++) { a[i] = i + 1; }\n");
    fprintf(f, "    for (i32 i = 0; i < n / 2; i++) {\n");
    fprintf(f, "        a[i] = a[i] ^ a[n-1-i];\n");
    fprintf(f, "        a[n-1-i] = a[i] ^ a[n-1-i];\n");
    fprintf(f, "        a[i] = a[i] ^ a[n-1-i];\n");
    fprintf(f, "    }\n");
    fprintf(f, "    i32 s = 0;\n");
    fprintf(f, "    for (i32 i = 0; i < n; i++) { s = s + a[i]; }\n");
    fprintf(f, "    return s;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 ck_%ld_%ld() {\n", lno, cidx);
    fprintf(f, "    i32 S = %d; i32 E = %d;\n", S, expected);
    fprintf(f, "    if (%s_rev_sum(S)     != E) { return 60; }\n", p);
    fprintf(f, "    if (%s_copyrev_sum(S) != E) { return 61; }\n", p);
    fprintf(f, "    if (%s_xorrev_sum(S)  != E) { return 62; }\n", p);
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 st_%ld_%ld() {\n", lno, cidx);
    fprintf(f, "    for (i32 n = 1; n <= %d; n++) {\n", S);
    fprintf(f, "        i32 r = %s_rev_sum(n);\n", p);
    fprintf(f, "        if (%s_copyrev_sum(n) != r) { return n; }\n", p);
    fprintf(f, "        if (%s_xorrev_sum(n)  != r) { return n + 100; }\n", p);
    fprintf(f, "    }\n");
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n\n");
}

/* ── T6: Fibonacci — recursive vs iterative vs memo ────────────────────
 * N = (S % 10) + 2  so N ∈ [2..11],  fib(11) = 89  (safe for i32)
 */
static void emit_t6(FILE *f, long lno, long cidx, int S)
{
    char p[64];
    snprintf(p, sizeof p, "t6_%ld_%ld", lno, cidx);
    int N = (S % 10) + 2;
    int expected = fib(N);

    /* Recursive */
    fprintf(f, "i32 %s_rec(i32 n) {\n", p);
    fprintf(f, "    if (n <= 1) { return n; }\n");
    fprintf(f, "    return %s_rec(n - 1) + %s_rec(n - 2);\n", p, p);
    fprintf(f, "}\n\n");

    /* Iterative */
    fprintf(f, "i32 %s_iter(i32 n) {\n", p);
    fprintf(f, "    if (n <= 1) { return n; }\n");
    fprintf(f, "    i32 a = 0; i32 b = 1;\n");
    fprintf(f, "    for (i32 i = 2; i <= n; i++) { i32 c = a + b; a = b; b = c; }\n");
    fprintf(f, "    return b;\n");
    fprintf(f, "}\n\n");

    /* Memoized (array on stack) */
    fprintf(f, "i32 %s_memo(i32 n) {\n", p);
    fprintf(f, "    i32[15] m;\n");
    fprintf(f, "    m[0] = 0; m[1] = 1;\n");
    fprintf(f, "    for (i32 i = 2; i <= n; i++) { m[i] = m[i-1] + m[i-2]; }\n");
    fprintf(f, "    return m[n];\n");
    fprintf(f, "}\n\n");

    /* Tail-recursive with accumulator */
    fprintf(f, "i32 %s_trh(i32 n, i32 a, i32 b) {\n", p);
    fprintf(f, "    if (n == 0) { return a; }\n");
    fprintf(f, "    return %s_trh(n - 1, b, a + b);\n", p);
    fprintf(f, "}\n");
    fprintf(f, "i32 %s_tr(i32 n) { return %s_trh(n, 0, 1); }\n\n", p, p);

    fprintf(f, "i32 ck_%ld_%ld() {\n", lno, cidx);
    fprintf(f, "    i32 N = %d; i32 E = %d;\n", N, expected);
    fprintf(f, "    if (%s_rec(N)  != E) { return 70; }\n", p);
    fprintf(f, "    if (%s_iter(N) != E) { return 71; }\n", p);
    fprintf(f, "    if (%s_memo(N) != E) { return 72; }\n", p);
    fprintf(f, "    if (%s_tr(N)   != E) { return 73; }\n", p);
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 st_%ld_%ld() {\n", lno, cidx);
    fprintf(f, "    for (i32 n = 2; n <= %d; n++) {\n", N);
    fprintf(f, "        i32 r = %s_iter(n);\n", p);
    fprintf(f, "        if (%s_rec(n)  != r) { return n; }\n", p);
    fprintf(f, "        if (%s_memo(n) != r) { return n + 100; }\n", p);
    fprintf(f, "        if (%s_tr(n)   != r) { return n + 200; }\n", p);
    fprintf(f, "    }\n");
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n\n");
}

/* ── T7: odd-count parity — count odd integers in [1..n] = ceil(n/2) ──
 * Verified via scan, formula, and bitwise test
 */
static void emit_t7(FILE *f, long lno, long cidx, int S)
{
    char p[64];
    snprintf(p, sizeof p, "t7_%ld_%ld", lno, cidx);
    int expected = (S + 1) / 2;

    /* Forward scan */
    fprintf(f, "i32 %s_scan(i32 n) {\n", p);
    fprintf(f, "    i32 c = 0;\n");
    fprintf(f, "    for (i32 i = 1; i <= n; i++) { if (i %% 2 != 0) { c++; } }\n");
    fprintf(f, "    return c;\n");
    fprintf(f, "}\n\n");

    /* Formula */
    fprintf(f, "i32 %s_fml(i32 n) { return (n + 1) / 2; }\n\n", p);

    /* Bitwise test in loop */
    fprintf(f, "i32 %s_bit(i32 n) {\n", p);
    fprintf(f, "    i32 c = 0;\n");
    fprintf(f, "    for (i32 i = 1; i <= n; i++) { c = c + (i & 1); }\n");
    fprintf(f, "    return c;\n");
    fprintf(f, "}\n\n");

    /* Backward scan */
    fprintf(f, "i32 %s_bwd(i32 n) {\n", p);
    fprintf(f, "    i32 c = 0;\n");
    fprintf(f, "    for (i32 i = n; i >= 1; i--) { if ((i & 1) != 0) { c++; } }\n");
    fprintf(f, "    return c;\n");
    fprintf(f, "}\n\n");

    /* Array-based: fill, filter odds, count */
    fprintf(f, "i32 %s_arr(i32 n) {\n", p);
    fprintf(f, "    i32[50] a; i32 k = 0;\n");
    fprintf(f, "    for (i32 i = 1; i <= n; i++) { if (i %% 2 != 0) { a[k] = i; k = k + 1; } }\n");
    fprintf(f, "    return k;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 ck_%ld_%ld() {\n", lno, cidx);
    fprintf(f, "    i32 S = %d; i32 E = %d;\n", S, expected);
    fprintf(f, "    if (%s_scan(S) != E) { return 80; }\n", p);
    fprintf(f, "    if (%s_fml(S)  != E) { return 81; }\n", p);
    fprintf(f, "    if (%s_bit(S)  != E) { return 82; }\n", p);
    fprintf(f, "    if (%s_bwd(S)  != E) { return 83; }\n", p);
    fprintf(f, "    if (%s_arr(S)  != E) { return 84; }\n", p);
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 st_%ld_%ld() {\n", lno, cidx);
    fprintf(f, "    for (i32 n = 1; n <= %d; n++) {\n", S);
    fprintf(f, "        i32 r = %s_fml(n);\n", p);
    fprintf(f, "        if (%s_scan(n) != r) { return n; }\n", p);
    fprintf(f, "        if (%s_bit(n)  != r) { return n + 100; }\n", p);
    fprintf(f, "    }\n");
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n\n");
}

/* ── T8: dead-branch DCE stress — result = S despite elaborate dead paths
 * Tests that optimizers correctly eliminate if(0) blocks at multiple
 * nesting levels without corrupting the live value S.
 */
static void emit_t8(FILE *f, long lno, long cidx, int S)
{
    char p[64];
    snprintf(p, sizeof p, "t8_%ld_%ld", lno, cidx);

    /* Shallow dead branches */
    fprintf(f, "i32 %s_shallow(i32 x) {\n", p);
    fprintf(f, "    if (0) { x = x + 1000; }\n");
    fprintf(f, "    if (0) { x = x * 2; }\n");
    fprintf(f, "    if (1) { i32 unused = x + 1; }\n");
    fprintf(f, "    if (0) { return -1; }\n");
    fprintf(f, "    return x;\n");
    fprintf(f, "}\n\n");

    /* Nested dead branches */
    fprintf(f, "i32 %s_nested(i32 x) {\n", p);
    fprintf(f, "    if (0) {\n");
    fprintf(f, "        if (1) { x = x + 999; }\n");
    fprintf(f, "        x = x - 1;\n");
    fprintf(f, "    }\n");
    fprintf(f, "    i32 y = x;\n");
    fprintf(f, "    if (0) { y = y + 500; }\n");
    fprintf(f, "    if (1) {\n");
    fprintf(f, "        if (0) { y = -y; }\n");
    fprintf(f, "    }\n");
    fprintf(f, "    return y;\n");
    fprintf(f, "}\n\n");

    /* Dead via always-false condition (constant folding) */
    fprintf(f, "i32 %s_const_fold(i32 x) {\n", p);
    fprintf(f, "    i32 flag = 5 - 5;\n");
    fprintf(f, "    if (flag != 0) { x = x + 777; }\n");
    fprintf(f, "    i32 cond = 3 * 4 - 12;\n");
    fprintf(f, "    if (cond > 0)  { x = x + 888; }\n");
    fprintf(f, "    return x;\n");
    fprintf(f, "}\n\n");

    /* Dead via SSA: assign then immediately overwrite */
    fprintf(f, "i32 %s_ssa(i32 x) {\n", p);
    fprintf(f, "    i32 r = x + 1000;\n");
    fprintf(f, "    r = x;\n");
    fprintf(f, "    i32 q = r + 500;\n");
    fprintf(f, "    q = r;\n");
    fprintf(f, "    return q;\n");
    fprintf(f, "}\n\n");

    /* Dead loop: while(0) */
    fprintf(f, "i32 %s_deadloop(i32 x) {\n", p);
    fprintf(f, "    while (0) { x = x * 999; }\n");
    fprintf(f, "    for (i32 i = 0; i < 0; i++) { x = x - 1; }\n");
    fprintf(f, "    return x;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 ck_%ld_%ld() {\n", lno, cidx);
    fprintf(f, "    i32 S = %d;\n", S);
    fprintf(f, "    if (%s_shallow(S)    != S) { return 90; }\n", p);
    fprintf(f, "    if (%s_nested(S)     != S) { return 91; }\n", p);
    fprintf(f, "    if (%s_const_fold(S) != S) { return 92; }\n", p);
    fprintf(f, "    if (%s_ssa(S)        != S) { return 93; }\n", p);
    fprintf(f, "    if (%s_deadloop(S)   != S) { return 94; }\n", p);
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 st_%ld_%ld() {\n", lno, cidx);
    fprintf(f, "    for (i32 n = 1; n <= %d; n++) {\n", S);
    fprintf(f, "        if (%s_shallow(n)  != n) { return n; }\n", p);
    fprintf(f, "        if (%s_nested(n)   != n) { return n + 100; }\n", p);
    fprintf(f, "        if (%s_ssa(n)      != n) { return n + 200; }\n", p);
    fprintf(f, "    }\n");
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n\n");
}

/* ── T9: inlining chain — S through N-deep wrapper chain vs direct ─────
 * Chain depth D = (S % 8) + 4 so D ∈ [4..11].
 * Each wrapper in the chain performs identity: return inner(x) + 0.
 * After inlining + simplification the optimizer should get return x.
 */
static void emit_t9(FILE *f, long lno, long cidx, int S)
{
    char p[64];
    snprintf(p, sizeof p, "t9_%ld_%ld", lno, cidx);
    int D = (S % 8) + 4;   /* chain depth: 4..11 */

    /* Emit chain leaf → root (leaf defined first so no forward decl needed) */
    fprintf(f, "i32 %s_c%d(i32 x) { return x; }\n", p, D);
    for (int d = D - 1; d >= 0; d--) {
        /* Each wrapper adds a dead computation then delegates */
        fprintf(f, "i32 %s_c%d(i32 x) {\n", p, d);
        fprintf(f, "    i32 unused = x * %d - x * %d;\n", d+2, d+2);
        fprintf(f, "    return %s_c%d(x) + 0;\n", p, d+1);
        fprintf(f, "}\n");
    }
    fprintf(f, "\n");

    /* Direct function for comparison */
    fprintf(f, "i32 %s_direct(i32 x) { return x; }\n\n", p);

    /* Function that calls chain twice and verifies */
    fprintf(f, "i32 %s_via_chain(i32 x) { return %s_c0(x); }\n\n", p, p);

    /* Wrapper that calls chain with S+k for different k */
    fprintf(f, "i32 %s_multi(i32 base) {\n", p);
    fprintf(f, "    i32 s = 0;\n");
    fprintf(f, "    for (i32 k = 0; k < %d; k++) {\n", S);
    fprintf(f, "        s = s + (%s_c0(base + k) - %s_direct(base + k));\n", p, p);
    fprintf(f, "    }\n");
    fprintf(f, "    return s;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 ck_%ld_%ld() {\n", lno, cidx);
    fprintf(f, "    i32 S = %d;\n", S);
    fprintf(f, "    if (%s_via_chain(S) != %s_direct(S)) { return 100; }\n", p, p);
    fprintf(f, "    if (%s_via_chain(0) != 0)             { return 101; }\n", p);
    fprintf(f, "    if (%s_multi(S)     != 0)             { return 102; }\n", p);
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n\n");

    fprintf(f, "i32 st_%ld_%ld() {\n", lno, cidx);
    fprintf(f, "    for (i32 n = 1; n <= %d; n++) {\n", S);
    fprintf(f, "        if (%s_c0(n) != n) { return n; }\n", p);
    fprintf(f, "        if (%s_c0(n) != %s_direct(n)) { return n + 100; }\n", p, p);
    fprintf(f, "    }\n");
    fprintf(f, "    return 0;\n");
    fprintf(f, "}\n\n");
}

/* ════════════════════════════════════════════════════════════════════════
 * CLUSTER DISPATCHER
 * ════════════════════════════════════════════════════════════════════════ */

static void emit_cluster(FILE *f, long lno, long cidx, int S)
{
    int type = (int)(cidx % N_TYPES);
    switch (type) {
    case 0: emit_t0(f, lno, cidx, S); break;
    case 1: emit_t1(f, lno, cidx, S); break;
    case 2: emit_t2(f, lno, cidx, S); break;
    case 3: emit_t3(f, lno, cidx, S); break;
    case 4: emit_t4(f, lno, cidx, S); break;
    case 5: emit_t5(f, lno, cidx, S); break;
    case 6: emit_t6(f, lno, cidx, S); break;
    case 7: emit_t7(f, lno, cidx, S); break;
    case 8: emit_t8(f, lno, cidx, S); break;
    case 9: emit_t9(f, lno, cidx, S); break;
    }
}

/* ── Per-LOC verify function — aggregates all cluster checkers ───────── */
static void emit_verify_fn(FILE *f, long lno, long n_clusters)
{
    fprintf(f, "i32 vfy_%ld() {\n", lno);
    fprintf(f, "    i32 fail = 0;\n");
    for (long cidx = 0; cidx < n_clusters; cidx++) {
        fprintf(f, "    fail = fail | ck_%ld_%ld();\n", lno, cidx);
        fprintf(f, "    fail = fail | st_%ld_%ld();\n", lno, cidx);
    }
    fprintf(f, "    return fail;\n");
    fprintf(f, "}\n\n");
}

/* ── main() — calls all verify functions ─────────────────────────────── */
static void emit_main_fn(FILE *f, long nloc)
{
    fprintf(f, "i32 main() {\n");
    fprintf(f, "    i32 total = 0;\n");
    for (long lno = 0; lno < nloc; lno++)
        fprintf(f, "    total = total | vfy_%ld();\n", lno);
    fprintf(f, "    return total;\n");
    fprintf(f, "}\n");
}

/* ── copy original seed next to the mangled file (for reference) ────── */
static void copy_seed(const char *src_path, const char *outdir, const char *base)
{
    FILE *in = fopen(src_path, "r");
    if (!in) return;
    char dst[1024];
    snprintf(dst, sizeof dst, "%s/%s.original.arc", outdir, base);
    FILE *out = fopen(dst, "w");
    if (!out) { fclose(in); return; }
    char buf[8192]; size_t n;
    while ((n = fread(buf, 1, sizeof buf, in)) > 0) fwrite(buf, 1, n, out);
    fclose(in); fclose(out);
}

/* ── harness.cpp ─────────────────────────────────────────────────────── */
static void write_harness(const char *path, const char *base)
{
    FILE *f = fopen(path, "w");
    if (!f) { perror("open harness"); exit(1); }

#define W(s) fputs(s "\n", f)
    W("// Auto-generated test harness — do not edit");
    W("#include <cstdio>");
    W("#include <cstdlib>");
    W("#include <cstring>");
    W("#ifdef _WIN32");
    W("#  define popen  _popen");
    W("#  define pclose _pclose");
    W("#else");
    W("#  include <sys/wait.h>");
    W("#endif");
    W("");
    W("struct RunResult { int code; char out[1 << 17]; };");
    W("");
    W("static RunResult shell(const char *cmd) {");
    W("    RunResult r = {};");
    W("    char full[8192];");
    W("    snprintf(full, sizeof full, \"(%s) 2>&1\", cmd);");
    W("    FILE *p = popen(full, \"r\");");
    W("    if (!p) { r.code = -1; return r; }");
    W("    size_t n = fread(r.out, 1, sizeof r.out - 1, p);");
    W("    r.out[n] = '\\0';");
    W("    r.code = pclose(p);");
    W("#ifndef _WIN32");
    W("    if (WIFEXITED(r.code)) r.code = WEXITSTATUS(r.code);");
    W("    else                   r.code = 1;");
    W("#endif");
    W("    return r;");
    W("}");
    W("");
    W("int main(void) {");
    W("    const char *artemis = getenv(\"ARTEMIS_BIN\");");
    W("    if (!artemis) artemis = \"atc\";");
    W("");
    fprintf(f, "    const char *src = \"%s.mangled.arc\";\n", base);
    W("    const char *opts[3] = {\"-O0\", \"-O2\", \"-O3\"};");
    W("    static int      codes[3];");
    W("    static RunResult runs[3];");
    W("    int fail = 0;");
    W("");
    W("    for (int i = 0; i < 3; ++i) {");
    W("        char bin[512];");
    W("#ifdef _WIN32");
    fprintf(f, "        snprintf(bin, sizeof bin, \"__test_%s_%%d.exe\", i);\n", base);
    W("#else");
    fprintf(f, "        snprintf(bin, sizeof bin, \"__test_%s_%%d.out\", i);\n", base);
    W("#endif");
    W("        char cmd[4096];");
    W("        snprintf(cmd, sizeof cmd, \"%s %s -o %s %s\",");
    W("                 artemis, src, bin, opts[i]);");
    W("        RunResult cr = shell(cmd);");
    W("        if (cr.code != 0) {");
    W("            fprintf(stderr,");
    W("                    \"FAIL  compile %s (exit %d):\\n--- compiler output ---\\n%s\\n\",");
    W("                    opts[i], cr.code, cr.out);");
    W("            codes[i] = -1; runs[i].code = -1; runs[i].out[0] = '\\0';");
    W("            ++fail; continue;");
    W("        }");
    W("        char runbuf[512];");
    W("#ifdef _WIN32");
    W("        snprintf(runbuf, sizeof runbuf, \".\\\\%s\", bin);");
    W("#else");
    W("        snprintf(runbuf, sizeof runbuf, \"./%s\", bin);");
    W("#endif");
    W("        runs[i] = shell(runbuf);");
    W("        codes[i] = runs[i].code;");
    W("        remove(bin);");
    W("    }");
    W("");
    W("    /* All three opt levels must agree AND return exit-code 0 (all checks pass) */");
    W("    for (int i = 0; i < 3; ++i) {");
    W("        if (codes[i] != 0) {");
    W("            fprintf(stderr, \"BEHAVIORAL FAIL [%s]: exit=%d (variant disagreement)\\n\",");
    W("                    opts[i], codes[i]);");
    W("            ++fail;");
    W("        }");
    W("    }");
    W("    for (int i = 1; i < 3; ++i) {");
    W("        if (codes[i] != codes[0] || strcmp(runs[i].out, runs[0].out) != 0) {");
    W("            fprintf(stderr, \"OPTIMIZER DIVERGENCE [%s vs -O0]:\\n\", opts[i]);");
    W("            fprintf(stderr, \"  exit: -O0=%d  %s=%d\\n\", codes[0], opts[i], codes[i]);");
    W("            if (strcmp(runs[i].out, runs[0].out) != 0) {");
    W("                fprintf(stderr, \"  --- -O0 output ---\\n%s\\n\", runs[0].out);");
    W("                fprintf(stderr, \"  --- %s output ---\\n%s\\n\", opts[i], runs[i].out);");
    W("            }");
    W("            ++fail;");
    W("        }");
    W("    }");
    W("");
    W("    if (!fail) { puts(\"ALL PASSED\"); return 0; }");
    W("    fprintf(stderr, \"%d test(s) FAILED\\n\", fail);");
    W("    return 1;");
    W("}");
#undef W
    fclose(f);
}

/* ════════════════════════════════════════════════════════════════════════
 * MAIN
 * ════════════════════════════════════════════════════════════════════════ */

int main(int argc, char *argv[])
{
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <input.arc>\n", argv[0]);
        return 1;
    }
    const char *input = argv[1];

    char base[256];
    get_basename(input, base, sizeof base);
    if (base[0] == '\0') {
        fprintf(stderr, "Cannot derive basename from '%s'\n", input);
        return 1;
    }

    long nloc = count_lines(input);
    printf("Input  : %s\n", input);
    printf("LOC    : %ld\n", nloc);
    printf("Clusters: %ld  (%ld LOC × %d)\n",
           nloc * (long)CLUSTERS_PER_LOC, nloc, CLUSTERS_PER_LOC);

    ensure_dir("out");
    char outdir[512];
    snprintf(outdir, sizeof outdir, "out/%s", base);
    ensure_dir(outdir);

    char art_path[1024];
    snprintf(art_path, sizeof art_path, "%s/%s.mangled.arc", outdir, base);

    FILE *out = fopen(art_path, "w");
    if (!out) { perror("fopen output"); return 1; }

    static char iobuf[IO_BUF_SIZE];
    setvbuf(out, iobuf, _IOFBF, IO_BUF_SIZE);

    /* Emit clusters per LOC, then per-LOC verify function */
    for (long lno = 0; lno < nloc; lno++) {
        int S = seed_for(lno);
        for (long cidx = 0; cidx < CLUSTERS_PER_LOC; cidx++)
            emit_cluster(out, lno, cidx, S);
        emit_verify_fn(out, lno, CLUSTERS_PER_LOC);

        if (lno % 10 == 0) {
            fflush(out);
            printf("  LOC %ld / %ld ...\r", lno + 1, nloc);
            fflush(stdout);
        }
    }
    printf("  LOC %ld / %ld ... done\n", nloc, nloc);

    /* Emit main() — the generated file is self-contained; seed copied separately */
    emit_main_fn(out, nloc);

    fclose(out);
    printf("Written: %s\n", art_path);

    copy_seed(input, outdir, base);
    printf("Copied : %s/%s.original.arc\n", outdir, base);

    char harness_path[1024];
    snprintf(harness_path, sizeof harness_path, "%s/harness.cpp", outdir);
    write_harness(harness_path, base);
    printf("Written: %s\n", harness_path);

    return 0;
}
