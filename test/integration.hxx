#pragma once
#include "framework.hxx"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <fstream>
#include <sstream>

#ifdef _WIN32
#  include <io.h>
#  define popen  _popen
#  define pclose _pclose
#else
#  include <unistd.h>
#endif

// ------------------------------------------------------------------ helpers

static std::string artemis_bin() {
    // _dupenv_s is MSVC-only; getenv is safe for read-only use in MinGW and POSIX.
#if defined(_MSC_VER)
    char* val = nullptr;
    size_t len = 0;
    _dupenv_s(&val, &len, "ARTEMIS_BIN");
    std::string result = val ? val : "artemis";
    free(val);
    return result;
#else
    const char* env = std::getenv("ARTEMIS_BIN");
    return env ? env : "artemis";
#endif
}

struct exec_result {
    int         code    = -1;
    std::string output; // stdout + stderr combined
};

static exec_result exec_cmd(const std::string& cmd) {
    exec_result r;
    std::string full_cmd = cmd;

#ifdef _WIN32
    // Redirect stderr to stdout and capture exit code via echo.
    full_cmd = "(" + cmd + ") 2>&1";
#else
    full_cmd = "(" + cmd + ") 2>&1";
#endif

    FILE* pipe = popen(full_cmd.c_str(), "r");
    if (!pipe) { r.code = -1; return r; }

    char buf[512];
    while (fgets(buf, sizeof(buf), pipe)) r.output += buf;
    r.code = pclose(pipe);

#ifndef _WIN32
    // pclose returns the raw wait status; extract exit code.
    if (WIFEXITED(r.code)) r.code = WEXITSTATUS(r.code);
    else                   r.code = 1;
#else
    // On Windows pclose returns exit code directly.
#endif
    return r;
}

// Write src to a temp file and return its path.
static std::string write_temp(const std::string& src, const std::string& suffix = ".art") {
    static int counter = 0;
    std::string path = "artemis_test_" + std::to_string(++counter) + suffix;
    std::ofstream f(path);
    f << src;
    return path;
}

static exec_result compile(const std::string& art_src,
                            const std::string& extra_flags = "") {
    std::string path = write_temp(art_src);
    std::string cmd  = artemis_bin() + " " + path + " -S -o " + path + ".ll" + " " + extra_flags;
    auto r = exec_cmd(cmd);
    // Clean up temp files.
    std::remove(path.c_str());
    std::remove((path + ".ll").c_str());
    return r;
}

[[maybe_unused]] static exec_result compile_and_run(const std::string& art_src) {
    std::string path   = write_temp(art_src);
    std::string outbin = path + ".out";
    std::string compile_cmd = artemis_bin() + " " + path + " -o " + outbin;
    auto cr = exec_cmd(compile_cmd);
    std::remove(path.c_str());
    if (cr.code != 0) return cr;
    auto rr = exec_cmd(outbin);
    std::remove(outbin.c_str());
    return rr;
}

// ------------------------------------------------------------------ tests

TEST(Integration, HelloWorld) {
    // Basic compilation succeeds (exit 0).
    auto r = compile(R"(
        extern void puts(const i8* s);
        void main() { puts("hello"); }
    )");
    ASSERT_EQ(r.code, 0);
}

TEST(Integration, ReturnValue) {
    auto r = compile("i32 main() { return 0; }");
    ASSERT_EQ(r.code, 0);
}

TEST(Integration, ArithmeticCompiles) {
    auto r = compile("i32 f(i32 a, i32 b) { return a + b * 2 - 1; }");
    ASSERT_EQ(r.code, 0);
}

TEST(Integration, PointerCompiles) {
    auto r = compile("void f(i32* p) { *p = 42; }");
    ASSERT_EQ(r.code, 0);
}

TEST(Integration, StructCompiles) {
    auto r = compile(R"(
        struct Vec2 { f32 x; f32 y; }
        f32 len(Vec2 v) { return v.x + v.y; }
    )");
    ASSERT_EQ(r.code, 0);
}

TEST(Integration, EnumCompiles) {
    auto r = compile(R"(
        enum Dir { North, South, East, West }
        i32 f() { return North; }
    )");
    ASSERT_EQ(r.code, 0);
}

TEST(Integration, WhileLoopCompiles) {
    auto r = compile(R"(
        i32 count_to(i32 n) {
            i32 i = 0;
            while (i < n) { i = i + 1; }
            return i;
        }
    )");
    ASSERT_EQ(r.code, 0);
}

TEST(Integration, ForLoopCompiles) {
    auto r = compile(R"(
        i32 sum_n(i32 n) {
            i32 s = 0;
            for (i32 i = 0; i < n; i++) { s = s + i; }
            return s;
        }
    )");
    ASSERT_EQ(r.code, 0);
}

TEST(Integration, RecursionCompiles) {
    auto r = compile(R"(
        i32 fib(i32 n) {
            if (n <= 1) { return n; }
            return fib(n - 1) + fib(n - 2);
        }
    )");
    ASSERT_EQ(r.code, 0);
}

TEST(Integration, ArrayCompiles) {
    auto r = compile("void f() { i32 a[5]; a[0] = 1; }");
    ASSERT_EQ(r.code, 0);
}

TEST(Integration, TernaryCompiles) {
    auto r = compile("i32 max(i32 a, i32 b) { return a > b ? a : b; }");
    ASSERT_EQ(r.code, 0);
}

TEST(Integration, SwitchCompiles) {
    auto r = compile(R"(
        i32 f(i32 x) {
            switch (x) {
                case 1: return 10;
                case 2: return 20;
                default: return 0;
            }
        }
    )");
    ASSERT_EQ(r.code, 0);
}

TEST(Integration, TypedefCompiles) {
    auto r = compile(R"(
        typedef i32 Score;
        Score compute() { return 100; }
    )");
    ASSERT_EQ(r.code, 0);
}

TEST(Integration, UnionCompiles) {
    auto r = compile(R"(
        union Val { i32 i; f32 f; }
        void f() { Val v; v.i = 42; }
    )");
    ASSERT_EQ(r.code, 0);
}

TEST(Integration, GlobalVarCompiles) {
    auto r = compile(R"(
        i32 counter = 0;
        void increment() { counter = counter + 1; }
    )");
    ASSERT_EQ(r.code, 0);
}

TEST(Integration, OptLevelO1) {
    auto r = compile("i32 f(i32 x) { return x + 1; }", "-O1");
    ASSERT_EQ(r.code, 0);
}

TEST(Integration, OptLevelO2) {
    auto r = compile("i32 f(i32 x) { return x + 1; }", "-O2");
    ASSERT_EQ(r.code, 0);
}

TEST(Integration, UndeclaredVarErrors) {
    auto r = compile("void f() { i32 x = y; }");
    ASSERT_NE(r.code, 0);
}

TEST(Integration, TypeErrorExit1) {
    auto r = compile("i32 f() { return; }");
    ASSERT_NE(r.code, 0);
}

TEST(Integration, ArityErrorExit1) {
    auto r = compile("void g(i32 x) {} void f() { g(1, 2); }");
    ASSERT_NE(r.code, 0);
}

TEST(Integration, MissingSemicolon) {
    auto r = compile("void f() { i32 x = 5 }");
    ASSERT_NE(r.code, 0);
}

TEST(Integration, HelpFlag) {
    std::string cmd = artemis_bin() + " --help";
    auto r = exec_cmd(cmd);
    ASSERT_EQ(r.code, 0);
    ASSERT_CONTAINS(r.output, "Usage");
}

TEST(Integration, VersionFlag) {
    std::string cmd = artemis_bin() + " --version";
    auto r = exec_cmd(cmd);
    ASSERT_EQ(r.code, 0);
    ASSERT_CONTAINS(r.output, "artemis");
}

TEST(Integration, EmitAstFlag) {
    std::string path = write_temp("i32 x = 5;");
    std::string cmd  = artemis_bin() + " " + path + " --emit-ast";
    auto r = exec_cmd(cmd);
    std::remove(path.c_str());
    ASSERT_EQ(r.code, 0);
    ASSERT_CONTAINS(r.output, "Program");
}

TEST(Integration, MultipleDecls) {
    auto r = compile(R"(
        i32 square(i32 x) { return x * x; }
        i32 cube(i32 x) { return x * square(x); }
        struct Pair { i32 a; i32 b; }
        typedef i32 Int;
        enum Side { Left, Right }
    )");
    ASSERT_EQ(r.code, 0);
}

TEST(Integration, BreakInLoop) {
    auto r = compile(R"(
        void f() {
            while (1) {
                break;
            }
        }
    )");
    ASSERT_EQ(r.code, 0);
}

TEST(Integration, NestedFunctions) {
    auto r = compile(R"(
        i32 add(i32 a, i32 b) { return a + b; }
        i32 mul(i32 a, i32 b) { return a * b; }
        i32 fma_op(i32 a, i32 b, i32 c) { return add(mul(a, b), c); }
    )");
    ASSERT_EQ(r.code, 0);
}
