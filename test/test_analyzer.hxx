#pragma once
#include "framework.hxx"
#include "../compiler/lexer/main.hxx"
#include "../compiler/parser/main.hxx"
#include "../compiler/analysis/main.hxx"
#include <stdexcept>
#include <string>

static void compile_ok(const std::string& src) {
    lexer l(src);
    auto toks = l.tokenize();
    parser p(std::move(toks));
    auto* prog = p.parse();
    analyze(prog); // should not throw
}

static void compile_fail(const std::string& src) {
    lexer l(src);
    auto toks = l.tokenize();
    parser p(std::move(toks));
    auto* prog = p.parse();
    analyze(prog); // expected to throw
}

TEST(Analyzer, ValidFunctionCall) {
    compile_ok("i32 add(i32 a, i32 b) { return a + b; } void main() { add(1, 2); }");
}

TEST(Analyzer, UndeclaredVariable) {
    ASSERT_THROWS(compile_fail("void f() { i32 x = y; }"), std::runtime_error);
}

TEST(Analyzer, UndeclaredFunction) {
    ASSERT_THROWS(compile_fail("void f() { foo(); }"), std::runtime_error);
}

TEST(Analyzer, TypeMismatchReturn) {
    ASSERT_THROWS(compile_fail("i32 f() { return; }"), std::runtime_error);
}

TEST(Analyzer, VoidReturnWithValue) {
    ASSERT_THROWS(compile_fail("void f() { return 42; }"), std::runtime_error);
}

TEST(Analyzer, ArityMismatch) {
    ASSERT_THROWS(compile_fail("void g(i32 x) {} void f() { g(1, 2); }"), std::runtime_error);
}

TEST(Analyzer, ScopeShadowing) {
    // Inner scope shadows outer; this should succeed.
    compile_ok("void f() { i32 x = 1; { i32 x = 2; } }");
}

TEST(Analyzer, BreakOutsideLoop) {
    ASSERT_THROWS(compile_fail("void f() { break; }"), std::runtime_error);
}

TEST(Analyzer, ContinueOutsideLoop) {
    ASSERT_THROWS(compile_fail("void f() { continue; }"), std::runtime_error);
}

TEST(Analyzer, BreakInsideLoop) {
    compile_ok("void f() { while (1) { break; } }");
}

TEST(Analyzer, ValidStruct) {
    compile_ok("struct P { i32 x; i32 y; } void f() { P p; }");
}

TEST(Analyzer, StructMemberAccess) {
    compile_ok("struct P { i32 x; } void f() { P p; i32 v = p.x; }");
}

TEST(Analyzer, PointerDecl) {
    compile_ok("void f() { i32* p; }");
}

TEST(Analyzer, ValidForLoop) {
    compile_ok("void f() { for (i32 i = 0; i < 10; i++) {} }");
}

TEST(Analyzer, NestedLoopsBreak) {
    compile_ok("void f() { while (1) { for (i32 i = 0; i < 5; i++) { break; } break; } }");
}

TEST(Analyzer, GlobalVar) {
    compile_ok("i32 g = 0; void f() { g = 1; }");
}

TEST(Analyzer, EnumUsage) {
    compile_ok("enum Color { Red, Green, Blue } void f() { i32 c = Red; }");
}

TEST(Analyzer, TypedefResolution) {
    compile_ok("typedef i32 MyInt; void f() { MyInt x = 5; }");
}

TEST(Analyzer, ValidWhileLoop) {
    compile_ok("void f() { i32 x = 0; while (x < 10) { x = x + 1; } }");
}

TEST(Analyzer, ValidIfElse) {
    compile_ok("void f() { i32 x = 1; if (x) { x = 2; } else { x = 3; } }");
}

TEST(Analyzer, VariadicFuncAccepted) {
    compile_ok("void myprintf(const i8* fmt, ...); void f() { myprintf(\"hi\"); }");
}
