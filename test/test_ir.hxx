#pragma once
#include "framework.hxx"
#include "../compiler/lexer/main.hxx"
#include "../compiler/parser/main.hxx"
#include "../compiler/analysis/main.hxx"
#include "../compiler/ir/main.hxx"
#include <llvm-c/Analysis.h>
#include <stdexcept>
#include <string>

static LLVMModuleRef compile_to_ir(const std::string& src) {
    lexer l(src);
    auto toks = l.tokenize();
    parser p(std::move(toks));
    auto* prog = p.parse();
    analyze(prog);
    return ir_main(prog, "test_module");
}

static bool module_valid(LLVMModuleRef mod) {
    char* err = nullptr;
    bool bad = LLVMVerifyModule(mod, LLVMReturnStatusAction, &err) != 0;
    if (err) LLVMDisposeMessage(err);
    return !bad;
}

TEST(IR, EmptyFunction) {
    auto* mod = compile_to_ir("void f() {}");
    ASSERT_TRUE(module_valid(mod));
    LLVMDisposeModule(mod);
}

TEST(IR, ReturnConstant) {
    auto* mod = compile_to_ir("i32 f() { return 42; }");
    ASSERT_TRUE(module_valid(mod));
    LLVMDisposeModule(mod);
}

TEST(IR, LocalVarAndArithmetic) {
    auto* mod = compile_to_ir(
        "i32 f(i32 a, i32 b) { i32 c = a + b; return c; }");
    ASSERT_TRUE(module_valid(mod));
    LLVMDisposeModule(mod);
}

TEST(IR, IfElse) {
    auto* mod = compile_to_ir(
        "i32 abs_val(i32 x) { if (x < 0) { return -x; } else { return x; } }");
    ASSERT_TRUE(module_valid(mod));
    LLVMDisposeModule(mod);
}

TEST(IR, WhileLoop) {
    auto* mod = compile_to_ir(
        "i32 count() { i32 i = 0; while (i < 10) { i = i + 1; } return i; }");
    ASSERT_TRUE(module_valid(mod));
    LLVMDisposeModule(mod);
}

TEST(IR, ForLoop) {
    auto* mod = compile_to_ir(
        "i32 sum() { i32 s = 0; for (i32 i = 0; i < 5; i++) { s = s + i; } return s; }");
    ASSERT_TRUE(module_valid(mod));
    LLVMDisposeModule(mod);
}

TEST(IR, FunctionCall) {
    auto* mod = compile_to_ir(
        "i32 double_it(i32 x) { return x * 2; }"
        "i32 f() { return double_it(21); }");
    ASSERT_TRUE(module_valid(mod));
    LLVMDisposeModule(mod);
}

TEST(IR, StructDecl) {
    auto* mod = compile_to_ir(
        "struct Point { i32 x; i32 y; }"
        "void f() { Point p; }");
    ASSERT_TRUE(module_valid(mod));
    LLVMDisposeModule(mod);
}

TEST(IR, GlobalVariable) {
    auto* mod = compile_to_ir(
        "i32 g = 0; void f() { g = 1; }");
    ASSERT_TRUE(module_valid(mod));
    LLVMDisposeModule(mod);
}

TEST(IR, BitwiseOps) {
    auto* mod = compile_to_ir(
        "i32 f(i32 a, i32 b) { return (a & b) | (a ^ b); }");
    ASSERT_TRUE(module_valid(mod));
    LLVMDisposeModule(mod);
}

TEST(IR, CompoundAssign) {
    auto* mod = compile_to_ir(
        "void f() { i32 x = 10; x += 5; x -= 2; x *= 3; }");
    ASSERT_TRUE(module_valid(mod));
    LLVMDisposeModule(mod);
}

TEST(IR, TernaryExpr) {
    auto* mod = compile_to_ir(
        "i32 max(i32 a, i32 b) { return a > b ? a : b; }");
    ASSERT_TRUE(module_valid(mod));
    LLVMDisposeModule(mod);
}
