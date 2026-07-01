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
    compile_ok("i32 add(i32 a, i32 b) { return a + b; } void run() { add(1, 2); }");
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

TEST(Analyzer, ImplicitIntCast) {
    compile_ok("void f() { u8 a = 2; i16 b = 1000; u32 c = a; }");
}

TEST(Analyzer, ImplicitIntCastNarrowing) {
    compile_ok("void f() { u8 x = 300; }"); // allowed; truncation is the caller's problem
}

TEST(Analyzer, CharType) {
    compile_ok("void f() { char c = 'a'; }");
}

TEST(Analyzer, CharPointerString) {
    compile_ok("void f() { char* s = \"hello\"; }");
}

TEST(Analyzer, MainMustReturnI32) {
    ASSERT_THROWS(compile_fail("bool main() { return true; }"), std::runtime_error);
}

TEST(Analyzer, MainVoidRejected) {
    ASSERT_THROWS(compile_fail("void main() {}"), std::runtime_error);
}

TEST(Analyzer, MainI32OK) {
    compile_ok("i32 main() { return 0; }");
}

// ------------------------------------------------------------------ Method Overloading

TEST(Analyzer, OverloadTwoFunctions) {
    compile_ok(
        "i32 add(i32 a) { return a; }"
        "i32 add(i32 a, i32 b) { return a + b; }"
        "void run() { add(1); add(1, 2); }"
    );
}

TEST(Analyzer, OverloadDifferentParamTypes) {
    compile_ok(
        "void print(i32 x) {}"
        "void print(f64 x) {}"
        "void run() { print(1); }"
    );
}

TEST(Analyzer, OverloadNoMangleWhenUnique) {
    // A function that is NOT overloaded should not have a mangled name applied.
    compile_ok(
        "void unique_func(i32 x) {}"
        "void run() { unique_func(1); }"
    );
}

TEST(Analyzer, OverloadAmbiguousCallFails) {
    // Calling an overloaded function with args that match no overload must fail.
    ASSERT_THROWS(compile_fail(
        "void f(i32 x) {}"
        "void f(i32 a, i32 b) {}"
        "void run() { f(); }"  // zero args — no overload matches
    ), std::runtime_error);
}

// ------------------------------------------------------------------ extern "C"

TEST(Analyzer, ExternCBlockDecl) {
    compile_ok(
        "extern \"C\" { void c_foo(i32 x); }"
        "void run() { c_foo(5); }"
    );
}

TEST(Analyzer, ExternCBlockMultiple) {
    compile_ok(
        "extern \"C\" {"
        "  void c_a(i32 x);"
        "  i32 c_b(i32 a, i32 b);"
        "}"
        "void run() { c_a(1); c_b(2, 3); }"
    );
}

// ------------------------------------------------------------------ istruc (classes)

TEST(Analyzer, IstrucBasicDecl) {
    compile_ok(
        "istruc Point {"
        "  i32 x;"
        "  i32 y;"
        "}"
        "void f() { Point p; }"
    );
}

TEST(Analyzer, IstrucMethodEmptyBody) {
    compile_ok(
        "istruc Counter {"
        "  i32 value;"
        "  void reset(&self) {}"
        "}"
    );
}

TEST(Analyzer, IstrucInheritance) {
    compile_ok(
        "istruc Animal {"
        "  i32 legs;"
        "}"
        "istruc Dog : Animal {"
        "  i32 fur_length;"
        "}"
    );
}

TEST(Analyzer, IstrucUnknownBaseClassFails) {
    ASSERT_THROWS(compile_fail(
        "istruc Dog : NoSuchClass { i32 x; }"
    ), std::runtime_error);
}

TEST(Analyzer, IstrucMandatoryVirtualRequiresVirtual) {
    ASSERT_THROWS(compile_fail(
        "istruc Base { mandatory void foo(); }"
    ), std::runtime_error);
}

TEST(Analyzer, IstrucOverrideMissingBaseFails) {
    ASSERT_THROWS(compile_fail(
        "istruc A { void foo() override {} }"
    ), std::runtime_error);
}

// ------------------------------------------------------------------ Function Pointers

TEST(Analyzer, FuncPtrDecl) {
    compile_ok("void f() { void(i32 x)* fp; }");
}

TEST(Analyzer, FuncPtrAssignAddrOf) {
    compile_ok(
        "void target(i32 x) {}"
        "void f() { void(i32 x)* fp = &target; }"
    );
}

TEST(Analyzer, FuncPtrReturnType) {
    compile_ok(
        "i32 add(i32 a, i32 b) { return a + b; }"
        "void f() { i32(i32 a, i32 b)* fp = &add; }"
    );
}

// ------------------------------------------------------------------ defer

TEST(Analyzer, DeferBlock) {
    compile_ok(
        "void cleanup() {}"
        "void f() { defer { cleanup(); } i32 x = 1; }"
    );
}

TEST(Analyzer, DeferExpr) {
    compile_ok(
        "void cleanup() {}"
        "void f() { defer cleanup(); i32 x = 1; }"
    );
}

// ------------------------------------------------------------------ Arrow operator (desugared to (*base).field)

TEST(Analyzer, ArrowOperatorBasic) {
    compile_ok(
        "struct P { i32 x; i32 y; }"
        "void f() { P* p; i32 v = p->x; }"
    );
}

TEST(Analyzer, ArrowOperatorAssign) {
    compile_ok(
        "struct Node { i32 val; }"
        "void f() { Node* n; n->val = 42; }"
    );
}
