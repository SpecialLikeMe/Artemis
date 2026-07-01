#pragma once
#include "framework.hxx"
#include "../compiler/lexer/main.hxx"
#include "../compiler/parser/main.hxx"
#include <stdexcept>
#include <string>

// Keep parsers alive so returned program_node* (owned by the parser's arena) remains valid.
static std::vector<std::unique_ptr<parser>> _live_parsers;

static program_node* do_parse(const std::string& src) {
    lexer l(src);
    auto toks = l.tokenize();
    auto p = std::make_unique<parser>(std::move(toks));
    program_node* prog = p->parse();
    _live_parsers.push_back(std::move(p));
    return prog;
}

TEST(Parser, EmptyProgram) {
    auto* prog = do_parse("");
    ASSERT_TRUE(prog != nullptr);
    ASSERT_EQ(prog->decls.size(), 0u);
}

TEST(Parser, VarDeclNoInit) {
    auto* prog = do_parse("i32 x;");
    ASSERT_EQ(prog->decls.size(), 1u);
    auto* v = dynamic_cast<var_decl*>(prog->decls[0]);
    ASSERT_TRUE(v != nullptr);
    ASSERT_EQ(v->name, "x");
    ASSERT_FALSE(v->init.has_value());
}

TEST(Parser, VarDeclWithInit) {
    auto* prog = do_parse("i32 x = 42;");
    auto* v = dynamic_cast<var_decl*>(prog->decls[0]);
    ASSERT_TRUE(v != nullptr);
    ASSERT_TRUE(v->init.has_value());
    auto* lit = v->init.value();
    ASSERT_EQ(static_cast<int>(lit->kind), static_cast<int>(expr_kind::int_lit));
    ASSERT_EQ(lit->int_val, 42);
}

TEST(Parser, PointerVar) {
    auto* prog = do_parse("i32* p;");
    auto* v = dynamic_cast<var_decl*>(prog->decls[0]);
    ASSERT_TRUE(v != nullptr);
    ASSERT_EQ(v->type->pointer_depth, 1);
}

TEST(Parser, ArrayVar) {
    auto* prog = do_parse("i32 arr[10];");
    auto* v = dynamic_cast<var_decl*>(prog->decls[0]);
    ASSERT_TRUE(v != nullptr);
    ASSERT_TRUE(v->type->array_size.has_value());
}

TEST(Parser, FunctionDecl) {
    auto* prog = do_parse("i32 add(i32 a, i32 b) { return a + b; }");
    ASSERT_EQ(prog->decls.size(), 1u);
    auto* f = dynamic_cast<func_decl*>(prog->decls[0]);
    ASSERT_TRUE(f != nullptr);
    ASSERT_EQ(f->name, "add");
    ASSERT_EQ(f->params.size(), 2u);
    ASSERT_TRUE(f->body != nullptr);
}

TEST(Parser, FunctionPrototype) {
    auto* prog = do_parse("i32 foo(i32 x);");
    auto* f = dynamic_cast<func_decl*>(prog->decls[0]);
    ASSERT_TRUE(f != nullptr);
    ASSERT_TRUE(f->body == nullptr);
}

TEST(Parser, StructDecl) {
    auto* prog = do_parse("struct Point { i32 x; i32 y; };");
    auto* s = dynamic_cast<struct_decl*>(prog->decls[0]);
    ASSERT_TRUE(s != nullptr);
    ASSERT_EQ(s->name, "Point");
    ASSERT_EQ(s->fields.size(), 2u);
}

TEST(Parser, EnumDecl) {
    auto* prog = do_parse("enum Color { Red, Green, Blue };");
    auto* e = dynamic_cast<enum_decl*>(prog->decls[0]);
    ASSERT_TRUE(e != nullptr);
    ASSERT_EQ(e->name, "Color");
    ASSERT_EQ(e->variants.size(), 3u);
}

TEST(Parser, IfStatement) {
    auto* prog = do_parse("void f() { if (x) { y; } }");
    auto* f = dynamic_cast<func_decl*>(prog->decls[0]);
    auto* blk = dynamic_cast<block_stmt*>(f->body);
    auto* stmt = dynamic_cast<if_stmt*>(blk->stmts[0]);
    ASSERT_TRUE(stmt != nullptr);
    ASSERT_TRUE(stmt->else_body == nullptr);
}

TEST(Parser, IfElseStatement) {
    auto* prog = do_parse("void f() { if (x) { a; } else { b; } }");
    auto* f = dynamic_cast<func_decl*>(prog->decls[0]);
    auto* blk = dynamic_cast<block_stmt*>(f->body);
    auto* stmt = dynamic_cast<if_stmt*>(blk->stmts[0]);
    ASSERT_TRUE(stmt != nullptr);
    ASSERT_TRUE(stmt->else_body != nullptr);
}

TEST(Parser, WhileLoop) {
    auto* prog = do_parse("void f() { while (1) {} }");
    auto* f = dynamic_cast<func_decl*>(prog->decls[0]);
    auto* blk = dynamic_cast<block_stmt*>(f->body);
    auto* w = dynamic_cast<while_stmt*>(blk->stmts[0]);
    ASSERT_TRUE(w != nullptr);
}

TEST(Parser, ForLoop) {
    auto* prog = do_parse("void f() { for (i32 i = 0; i < 10; i++) {} }");
    auto* f = dynamic_cast<func_decl*>(prog->decls[0]);
    auto* blk = dynamic_cast<block_stmt*>(f->body);
    auto* fl = dynamic_cast<for_stmt*>(blk->stmts[0]);
    ASSERT_TRUE(fl != nullptr);
    ASSERT_TRUE(fl->init != nullptr);
    ASSERT_TRUE(fl->cond != nullptr);
    ASSERT_TRUE(fl->step != nullptr);
}

TEST(Parser, SwitchStatement) {
    auto* prog = do_parse("void f() { switch (x) { case 1: break; default: break; } }");
    auto* f = dynamic_cast<func_decl*>(prog->decls[0]);
    auto* blk = dynamic_cast<block_stmt*>(f->body);
    auto* sw = dynamic_cast<switch_stmt*>(blk->stmts[0]);
    ASSERT_TRUE(sw != nullptr);
    ASSERT_EQ(sw->cases.size(), 2u);
}

TEST(Parser, ReturnVoid) {
    auto* prog = do_parse("void f() { return; }");
    auto* f = dynamic_cast<func_decl*>(prog->decls[0]);
    auto* blk = dynamic_cast<block_stmt*>(f->body);
    auto* r = dynamic_cast<return_stmt*>(blk->stmts[0]);
    ASSERT_TRUE(r != nullptr);
    ASSERT_FALSE(r->value.has_value());
}

TEST(Parser, ReturnExpr) {
    auto* prog = do_parse("i32 f() { return 42; }");
    auto* f = dynamic_cast<func_decl*>(prog->decls[0]);
    auto* blk = dynamic_cast<block_stmt*>(f->body);
    auto* r = dynamic_cast<return_stmt*>(blk->stmts[0]);
    ASSERT_TRUE(r != nullptr);
    ASSERT_TRUE(r->value.has_value());
}

TEST(Parser, BinaryExprPrecedence) {
    auto* prog = do_parse("i32 x = 1 + 2 * 3;");
    auto* v = dynamic_cast<var_decl*>(prog->decls[0]);
    auto* add = v->init.value();
    ASSERT_EQ(static_cast<int>(add->kind), static_cast<int>(expr_kind::binary));
    ASSERT_EQ(static_cast<int>(add->bop), static_cast<int>(binary_op::add));
    // rhs must be mul (higher precedence)
    auto* mul = add->rhs;
    ASSERT_EQ(static_cast<int>(mul->kind), static_cast<int>(expr_kind::binary));
    ASSERT_EQ(static_cast<int>(mul->bop), static_cast<int>(binary_op::mul));
}

TEST(Parser, CallExpr) {
    auto* prog = do_parse("void f() { foo(1, 2); }");
    auto* f = dynamic_cast<func_decl*>(prog->decls[0]);
    auto* blk = dynamic_cast<block_stmt*>(f->body);
    auto* es = dynamic_cast<expr_stmt*>(blk->stmts[0]);
    ASSERT_EQ(static_cast<int>(es->expr->kind), static_cast<int>(expr_kind::call));
    ASSERT_EQ(es->expr->args.size(), 2u);
}

TEST(Parser, CastExpr) {
    auto* prog = do_parse("void f() { (i32)x; }");
    auto* f = dynamic_cast<func_decl*>(prog->decls[0]);
    auto* blk = dynamic_cast<block_stmt*>(f->body);
    auto* es = dynamic_cast<expr_stmt*>(blk->stmts[0]);
    ASSERT_EQ(static_cast<int>(es->expr->kind), static_cast<int>(expr_kind::cast));
}

TEST(Parser, TernaryExpr) {
    auto* prog = do_parse("i32 x = a ? b : c;");
    auto* v = dynamic_cast<var_decl*>(prog->decls[0]);
    auto* t = v->init.value();
    ASSERT_EQ(static_cast<int>(t->kind), static_cast<int>(expr_kind::ternary));
}

TEST(Parser, TypedefDecl) {
    auto* prog = do_parse("typedef i32 MyInt;");
    auto* td = dynamic_cast<typedef_decl*>(prog->decls[0]);
    ASSERT_TRUE(td != nullptr);
    ASSERT_EQ(td->alias, "MyInt");
}

TEST(Parser, UnionDecl) {
    auto* prog = do_parse("union Data { i32 i; f32 f; };");
    auto* u = dynamic_cast<union_decl*>(prog->decls[0]);
    ASSERT_TRUE(u != nullptr);
    ASSERT_EQ(u->name, "Data");
    ASSERT_EQ(u->fields.size(), 2u);
}

TEST(Parser, AnnotationExpr) {
    auto* prog = do_parse("void f() { @attr; }");
    auto* f = dynamic_cast<func_decl*>(prog->decls[0]);
    auto* blk = dynamic_cast<block_stmt*>(f->body);
    auto* es = dynamic_cast<expr_stmt*>(blk->stmts[0]);
    ASSERT_EQ(static_cast<int>(es->expr->kind), static_cast<int>(expr_kind::annotation));
    ASSERT_EQ(es->expr->str_val, "attr");
}

TEST(Parser, BreakContinue) {
    auto* prog = do_parse("void f() { while (1) { break; continue; } }");
    auto* f = dynamic_cast<func_decl*>(prog->decls[0]);
    auto* blk = dynamic_cast<block_stmt*>(f->body);
    auto* w = dynamic_cast<while_stmt*>(blk->stmts[0]);
    auto* wblk = dynamic_cast<block_stmt*>(w->body);
    ASSERT_TRUE(dynamic_cast<break_stmt*>(wblk->stmts[0]) != nullptr);
    ASSERT_TRUE(dynamic_cast<continue_stmt*>(wblk->stmts[1]) != nullptr);
}

TEST(Parser, SizeofExpr) {
    auto* prog = do_parse("void f() { sizeof(i32); }");
    auto* f = dynamic_cast<func_decl*>(prog->decls[0]);
    auto* blk = dynamic_cast<block_stmt*>(f->body);
    auto* es = dynamic_cast<expr_stmt*>(blk->stmts[0]);
    ASSERT_EQ(static_cast<int>(es->expr->kind), static_cast<int>(expr_kind::sizeof_e));
}

TEST(Parser, ConstQualifier) {
    auto* prog = do_parse("const i32 x = 5;");
    auto* v = dynamic_cast<var_decl*>(prog->decls[0]);
    ASSERT_TRUE(v != nullptr);
    ASSERT_TRUE(v->type->is_const);
}

TEST(Parser, ExternStorage) {
    auto* prog = do_parse("extern i32 x;");
    auto* v = dynamic_cast<var_decl*>(prog->decls[0]);
    ASSERT_TRUE(v != nullptr);
    ASSERT_TRUE(v->type->is_extern);
}

TEST(Parser, VariadicFunction) {
    auto* prog = do_parse("void printf(const i8* fmt, ...);");
    auto* f = dynamic_cast<func_decl*>(prog->decls[0]);
    ASSERT_TRUE(f != nullptr);
    ASSERT_TRUE(f->is_variadic);
}

TEST(Parser, MemberAccess) {
    auto* prog = do_parse("void f() { p.x; }");
    auto* f = dynamic_cast<func_decl*>(prog->decls[0]);
    auto* blk = dynamic_cast<block_stmt*>(f->body);
    auto* es = dynamic_cast<expr_stmt*>(blk->stmts[0]);
    ASSERT_EQ(static_cast<int>(es->expr->kind), static_cast<int>(expr_kind::member));
    ASSERT_EQ(es->expr->member_name, "x");
}

TEST(Parser, Subscript) {
    auto* prog = do_parse("void f() { arr[5]; }");
    auto* f = dynamic_cast<func_decl*>(prog->decls[0]);
    auto* blk = dynamic_cast<block_stmt*>(f->body);
    auto* es = dynamic_cast<expr_stmt*>(blk->stmts[0]);
    ASSERT_EQ(static_cast<int>(es->expr->kind), static_cast<int>(expr_kind::subscript));
}

TEST(Parser, UnexpectedToken) {
    // Missing semicolon at top-level forces parse error / error recovery
    // Parser synchronizes so it shouldn't crash, and the bad decl isn't added.
    auto* prog = do_parse("i32 @@;");
    // Either empty or contains valid partial parse; main check: no crash.
    ASSERT_TRUE(prog != nullptr);
}

// ------------------------------------------------------------------ New feature: istruc

TEST(Parser, IstrucBasic) {
    auto* prog = do_parse("istruc Point { i32 x; i32 y; }");
    ASSERT_EQ(prog->decls.size(), 1u);
    auto* cd = dynamic_cast<class_decl*>(prog->decls[0]);
    ASSERT_TRUE(cd != nullptr);
    ASSERT_EQ(cd->name, "Point");
    ASSERT_EQ(cd->fields.size(), 2u);
    ASSERT_EQ(cd->base_name, "");
}

TEST(Parser, IstrucInheritance) {
    auto* prog = do_parse("istruc Dog : Animal { i32 age; }");
    auto* cd = dynamic_cast<class_decl*>(prog->decls[0]);
    ASSERT_TRUE(cd != nullptr);
    ASSERT_EQ(cd->base_name, "Animal");
}

TEST(Parser, IstrucWithMethod) {
    auto* prog = do_parse(
        "istruc Counter { i32 value; void reset(&self) {} }"
    );
    auto* cd = dynamic_cast<class_decl*>(prog->decls[0]);
    ASSERT_TRUE(cd != nullptr);
    ASSERT_EQ(cd->methods.size(), 1u);
    ASSERT_TRUE(cd->methods[0]->has_self);
}

// ------------------------------------------------------------------ New feature: extern "C"

TEST(Parser, ExternCBlockSingle) {
    auto* prog = do_parse("extern \"C\" { void c_func(i32 x); }");
    ASSERT_EQ(prog->decls.size(), 1u);
    auto* ecb = dynamic_cast<extern_c_block*>(prog->decls[0]);
    ASSERT_TRUE(ecb != nullptr);
    ASSERT_EQ(ecb->decls.size(), 1u);
}

TEST(Parser, ExternCBlockMultiple) {
    auto* prog = do_parse(
        "extern \"C\" { void a(); i32 b(i32 x); }"
    );
    auto* ecb = dynamic_cast<extern_c_block*>(prog->decls[0]);
    ASSERT_TRUE(ecb != nullptr);
    ASSERT_EQ(ecb->decls.size(), 2u);
}

// ------------------------------------------------------------------ New feature: function pointers

TEST(Parser, FuncPtrVarDecl) {
    auto* prog = do_parse("void f() { void(i32 x)* fp; }");
    auto* fn = dynamic_cast<func_decl*>(prog->decls[0]);
    auto* blk = dynamic_cast<block_stmt*>(fn->body);
    auto* vd = dynamic_cast<var_decl*>(blk->stmts[0]);
    ASSERT_TRUE(vd != nullptr);
    ASSERT_TRUE(vd->type->is_func_ptr);
}

TEST(Parser, FuncPtrAddrOf) {
    auto* prog = do_parse("void f() { void(i32 x)* fp = &target; }");
    auto* fn = dynamic_cast<func_decl*>(prog->decls[0]);
    auto* blk = dynamic_cast<block_stmt*>(fn->body);
    auto* vd = dynamic_cast<var_decl*>(blk->stmts[0]);
    ASSERT_TRUE(vd != nullptr);
    ASSERT_TRUE(vd->init.has_value());
    ASSERT_EQ(static_cast<int>(vd->init.value()->kind), static_cast<int>(expr_kind::unary));
}

// ------------------------------------------------------------------ New feature: defer

TEST(Parser, DeferBlock) {
    auto* prog = do_parse("void f() { defer { i32 x = 0; } }");
    auto* fn = dynamic_cast<func_decl*>(prog->decls[0]);
    auto* blk = dynamic_cast<block_stmt*>(fn->body);
    auto* ds = dynamic_cast<defer_stmt*>(blk->stmts[0]);
    ASSERT_TRUE(ds != nullptr);
    ASSERT_TRUE(ds->blk != nullptr);
    ASSERT_TRUE(ds->expr == nullptr);
}

TEST(Parser, DeferExpr) {
    auto* prog = do_parse("void f() { defer cleanup(); }");
    auto* fn = dynamic_cast<func_decl*>(prog->decls[0]);
    auto* blk = dynamic_cast<block_stmt*>(fn->body);
    auto* ds = dynamic_cast<defer_stmt*>(blk->stmts[0]);
    ASSERT_TRUE(ds != nullptr);
    ASSERT_TRUE(ds->expr != nullptr);
    ASSERT_TRUE(ds->blk == nullptr);
}

// ------------------------------------------------------------------ New feature: arrow operator (desugar)

TEST(Parser, ArrowDesugaredToDerefMember) {
    auto* prog = do_parse("void f() { p->x; }");
    auto* fn = dynamic_cast<func_decl*>(prog->decls[0]);
    auto* blk = dynamic_cast<block_stmt*>(fn->body);
    auto* es = dynamic_cast<expr_stmt*>(blk->stmts[0]);
    // p->x desugars to (*p).x — should be a member expr whose object is a deref
    ASSERT_EQ(static_cast<int>(es->expr->kind), static_cast<int>(expr_kind::member));
    ASSERT_EQ(es->expr->member_name, "x");
    auto* obj = es->expr->object;
    ASSERT_EQ(static_cast<int>(obj->kind), static_cast<int>(expr_kind::unary));
    ASSERT_EQ(static_cast<int>(obj->uop), static_cast<int>(unary_op::deref));
}
