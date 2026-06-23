#pragma once
#include <memory>
#include <vector>
#include <string>
#include <stdexcept>
#include "scope.hxx"
#include "types.hxx"
#include "../parser/main.hxx"

class analyzer {
public:
    void analyze(program_node* prog) {
        // global scope lives for the entire analysis
        scope.push();

        // Pass 1: register all top-level type/function names so bodies can reference
        // anything declared later in the file.
        for (auto* node : prog->decls) register_decl(node);

        // Pass 2: full type-check
        for (auto* node : prog->decls) visit_top_level(node);

        scope.pop();
    }

private:
    scope_manager scope;
    func_decl*    current_func  = nullptr;
    int           loop_depth    = 0;
    int           switch_depth  = 0;

    // Arenas so returned type_node* pointers stay valid for the lifetime of the analyzer.
    std::vector<std::unique_ptr<type_node>> owned_types;
    std::vector<std::unique_ptr<var_decl>>  owned_vars;  // synthetic var_decl for params

    // -------------------------------------------------------------- helpers

    std::string err(uint64_t line, const std::string& msg) const {
        return "Semantic Error at line " + std::to_string(line) + ": " + msg;
    }

    type_node* make_type(type_node t) {
        owned_types.push_back(std::make_unique<type_node>(std::move(t)));
        return owned_types.back().get();
    }

    type_node* prim(prim_type_t p) {
        type_node t; t.is_primitive = true; t.prim = p;
        return make_type(t);
    }

    type_node* ptr_to(type_node base, int depth = 1) {
        base.pointer_depth += depth;
        return make_type(base);
    }

    var_decl* make_param_var(type_node* type, const std::string& name, uint64_t line) {
        auto v = std::make_unique<var_decl>();
        v->type = type; v->name = name; v->line = line;
        owned_vars.push_back(std::move(v));
        return owned_vars.back().get();
    }

    static bool is_lvalue(const expr_node* e) {
        if (!e) return false;
        switch (e->kind) {
            case expr_kind::identifier: return true;
            case expr_kind::subscript:  return true;
            case expr_kind::member:     return true;
            case expr_kind::unary:      return e->uop == unary_op::deref;
            default:                    return false;
        }
    }

    // Validate that a named type is defined; check void not used as a variable type.
    void check_var_type(const type_node* t, uint64_t line) {
        if (!t) throw std::runtime_error(err(line, "null type"));
        if (t->is_primitive) {
            if (t->prim == prim_type_t::void_t && t->pointer_depth == 0)
                throw std::runtime_error(err(line, "Cannot declare a variable of type 'void'"));
            return;
        }
        const std::string& name = t->name.value_or("");
        if (!scope.is_known_type(name))
            throw std::runtime_error(err(line, "Unknown type '" + name + "'"));
    }

    void check_type_known(const type_node* t, uint64_t line) {
        if (!t || t->is_primitive) return;
        const std::string& name = t->name.value_or("");
        if (!scope.is_known_type(name))
            throw std::runtime_error(err(line, "Unknown type '" + name + "'"));
    }

    // Walk typedef chain and return the concrete underlying type (struct/union/enum/prim).
    type_node* resolve_typedef(type_node* t, uint64_t line) {
        int depth = 0;
        while (t && !t->is_primitive && t->name.has_value()) {
            const std::string& name = t->name.value();
            auto it = scope.typedefs.find(name);
            if (it == scope.typedefs.end()) break;
            t = it->second->underlying;
            if (++depth > 64)
                throw std::runtime_error(err(line, "Circular typedef chain"));
        }
        return t;
    }

    // -------------------------------------------------------------- pass 1: register

    void register_decl(ast_node* node) {
        if (auto* d = dynamic_cast<func_decl*>(node))    { scope.declare_func(d);    return; }
        if (auto* d = dynamic_cast<struct_decl*>(node))  { scope.declare_struct(d);  return; }
        if (auto* d = dynamic_cast<enum_decl*>(node))    { scope.declare_enum(d);    return; }
        if (auto* d = dynamic_cast<union_decl*>(node))   { scope.declare_union(d);   return; }
        if (auto* d = dynamic_cast<typedef_decl*>(node)) { scope.declare_typedef(d); return; }
        // global var_decl registered in pass 2 (needs type resolution first)
    }

    // -------------------------------------------------------------- pass 2: visit top-level

    void visit_top_level(ast_node* node) {
        if (auto* d = dynamic_cast<func_decl*>(node))    { visit_func_decl(d);        return; }
        if (auto* d = dynamic_cast<struct_decl*>(node))  { visit_struct_decl(d);      return; }
        if (auto* d = dynamic_cast<enum_decl*>(node))    { visit_enum_decl(d);        return; }
        if (auto* d = dynamic_cast<union_decl*>(node))   { visit_union_decl(d);       return; }
        if (auto* d = dynamic_cast<typedef_decl*>(node)) { visit_typedef_decl(d);     return; }
        if (auto* d = dynamic_cast<var_decl*>(node))     { visit_global_var_decl(d);  return; }
        throw std::runtime_error(err(node->line, "Unrecognised top-level declaration"));
    }

    void visit_struct_decl(struct_decl* d) {
        for (auto* f : d->fields) {
            check_var_type(f->type, f->line);
            if (f->init.has_value())
                throw std::runtime_error(err(f->line, "Struct field cannot have an initializer"));
        }
    }

    void visit_union_decl(union_decl* d) {
        for (auto* f : d->fields) {
            check_var_type(f->type, f->line);
            if (f->init.has_value())
                throw std::runtime_error(err(f->line, "Union field cannot have an initializer"));
        }
    }

    void visit_enum_decl(enum_decl* d) {
        for (auto& [name, val] : d->variants) {
            if (val.has_value()) {
                type_node* vt = visit_expr(val.value());
                if (!vt->is_primitive || !is_int_prim(vt->prim.value()))
                    throw std::runtime_error(err(d->line,
                        "Enum variant value must be an integer expression"));
            }
        }
    }

    void visit_typedef_decl(typedef_decl* d) {
        check_type_known(d->underlying, d->line);
    }

    void visit_global_var_decl(var_decl* d) {
        check_var_type(d->type, d->line);
        if (d->init.has_value()) {
            type_node* it = visit_expr(d->init.value());
            if (!assignable(d->type, it))
                throw std::runtime_error(err(d->line,
                    "Cannot initialise '" + type_to_str(d->type) +
                    "' with '" + type_to_str(it) + "'"));
        }
        scope.declare_var(d->name, d);
    }

    void visit_func_decl(func_decl* fd) {
        check_type_known(fd->ret_type, fd->line);

        if (fd->name == "main") {
            bool ok = fd->ret_type && fd->ret_type->is_primitive
                   && fd->ret_type->prim == prim_type_t::i32
                   && fd->ret_type->pointer_depth == 0;
            if (!ok)
                throw std::runtime_error(err(fd->line,
                    "Function 'main' must return i32 (the process exit code)"));
        }

        if (!fd->body) return; // forward declaration only

        func_decl* prev = current_func;
        current_func = fd;

        scope.push(); // parameter scope
        for (auto& p : fd->params) {
            check_var_type(p.type, p.line);
            if (!p.name.empty()) {
                var_decl* pv = make_param_var(p.type, p.name, p.line);
                scope.declare_var(p.name, pv);
            }
        }

        visit_block(fd->body);

        scope.pop(); // end parameter scope
        current_func = prev;
    }

    // -------------------------------------------------------------- statements

    void visit_stmt(ast_node* node) {
        if (!node) return;
        if (auto* n = dynamic_cast<block_stmt*>(node))    { visit_block(n);         return; }
        if (auto* n = dynamic_cast<if_stmt*>(node))       { visit_if(n);            return; }
        if (auto* n = dynamic_cast<while_stmt*>(node))    { visit_while(n);         return; }
        if (auto* n = dynamic_cast<for_stmt*>(node))      { visit_for(n);           return; }
        if (auto* n = dynamic_cast<switch_stmt*>(node))   { visit_switch(n);        return; }
        if (auto* n = dynamic_cast<return_stmt*>(node))   { visit_return(n);        return; }
        if (auto* n = dynamic_cast<break_stmt*>(node))    { visit_break(n);         return; }
        if (auto* n = dynamic_cast<continue_stmt*>(node)) { visit_continue(n);      return; }
        if (auto* n = dynamic_cast<var_decl*>(node))      { visit_local_var_decl(n); return; }
        if (auto* n = dynamic_cast<expr_stmt*>(node))     { visit_expr(n->expr);    return; }
        if (auto* n = dynamic_cast<asm_stmt*>(node))      { visit_asm_stmt(n);      return; }
        throw std::runtime_error(err(node->line, "Unknown statement kind"));
    }

    void visit_block(block_stmt* blk) {
        scope.push();
        for (auto* s : blk->stmts) visit_stmt(s);
        scope.pop();
    }

    void visit_if(if_stmt* n) {
        type_node* ct = visit_expr(n->cond);
        if (!is_truthy(ct))
            throw std::runtime_error(err(n->line,
                "Condition must be numeric, bool, or pointer; got '" + type_to_str(ct) + "'"));
        visit_stmt(n->then_body);
        if (n->else_body) visit_stmt(n->else_body);
    }

    void visit_while(while_stmt* n) {
        type_node* ct = visit_expr(n->cond);
        if (!is_truthy(ct))
            throw std::runtime_error(err(n->line,
                "While condition must be numeric, bool, or pointer; got '" + type_to_str(ct) + "'"));
        loop_depth++;
        visit_stmt(n->body);
        loop_depth--;
    }

    void visit_for(for_stmt* n) {
        scope.push(); // for-init scope (encloses the body)
        if (n->init) visit_stmt(n->init);
        if (n->cond) {
            type_node* ct = visit_expr(n->cond);
            if (!is_truthy(ct))
                throw std::runtime_error(err(n->line,
                    "For condition must be numeric, bool, or pointer; got '" + type_to_str(ct) + "'"));
        }
        if (n->step) visit_expr(n->step);
        loop_depth++;
        visit_stmt(n->body);
        loop_depth--;
        scope.pop();
    }

    void visit_switch(switch_stmt* n) {
        type_node* st = visit_expr(n->subject);
        if (!st->is_primitive || !is_int_prim(st->prim.value()))
            throw std::runtime_error(err(n->line,
                "Switch subject must be an integer type; got '" + type_to_str(st) + "'"));

        switch_depth++;
        for (auto& [label, blk] : n->cases) {
            if (label.has_value()) {
                type_node* lt = visit_expr(label.value());
                if (!assignable(st, lt))
                    throw std::runtime_error(err(n->line,
                        "Case value type '" + type_to_str(lt) +
                        "' incompatible with switch subject '" + type_to_str(st) + "'"));
            }
            visit_block(blk);
        }
        switch_depth--;
    }

    void visit_return(return_stmt* n) {
        if (!current_func)
            throw std::runtime_error(err(n->line, "'return' outside of a function"));

        type_node* ret = current_func->ret_type;
        bool ret_void  = ret && ret->is_primitive && ret->prim == prim_type_t::void_t
                         && ret->pointer_depth == 0;

        if (!n->value.has_value()) {
            if (!ret_void)
                throw std::runtime_error(err(n->line,
                    "Non-void function '" + current_func->name + "' must return a value"));
            return;
        }

        if (ret_void)
            throw std::runtime_error(err(n->line,
                "Void function '" + current_func->name + "' cannot return a value"));

        type_node* vt = visit_expr(n->value.value());
        if (!assignable(ret, vt))
            throw std::runtime_error(err(n->line,
                "Return type mismatch in '" + current_func->name +
                "': expected '" + type_to_str(ret) +
                "', got '" + type_to_str(vt) + "'"));
    }

    void visit_break(break_stmt* n) {
        if (loop_depth == 0 && switch_depth == 0)
            throw std::runtime_error(err(n->line, "'break' outside loop or switch"));
    }

    void visit_continue(continue_stmt* n) {
        if (loop_depth == 0)
            throw std::runtime_error(err(n->line, "'continue' outside loop"));
    }

    void visit_asm_stmt(asm_stmt* s) {
        // Validate all input/output variable names exist in scope.
        for (auto& in : s->inputs) {
            if (!scope.lookup_var(in.varname) && !scope.lookup_func(in.varname))
                throw std::runtime_error(err(s->line,
                    "Inline asm: unknown input operand '" + in.varname + "'"));
        }
        for (auto& out : s->outputs) {
            if (!scope.lookup_var(out.varname))
                throw std::runtime_error(err(s->line,
                    "Inline asm: unknown output operand '" + out.varname + "'"));
        }
        // Validate every %name in the instruction text is listed in a constraint section.
        const std::string& text = s->raw_instructions;
        for (size_t pos = 0; pos < text.size(); pos++) {
            if (text[pos] != '%') continue;
            pos++;
            std::string name;
            while (pos < text.size() &&
                   (std::isalnum((unsigned char)text[pos]) || text[pos] == '_'))
                name += text[pos++];
            pos--; // loop will increment
            if (name.empty()) continue;
            bool found = false;
            for (auto& e : s->inputs)  { if (e.varname == name) { found = true; break; } }
            for (auto& e : s->outputs) { if (e.varname == name) { found = true; break; } }
            if (!found)
                throw std::runtime_error(err(s->line,
                    "Inline asm: '%"+name+"' is not listed in any constraint section"));
        }
    }

    void visit_local_var_decl(var_decl* d) {
        check_var_type(d->type, d->line);
        if (d->init.has_value()) {
            type_node* it = visit_expr(d->init.value());
            if (!assignable(d->type, it))
                throw std::runtime_error(err(d->line,
                    "Cannot initialise '" + d->name + "' (type '" + type_to_str(d->type) +
                    "') with '" + type_to_str(it) + "'"));
        }
        scope.declare_var(d->name, d);
    }

    // -------------------------------------------------------------- expressions

    type_node* visit_expr(expr_node* e) {
        if (!e) throw std::runtime_error("Internal: null expression node");
        switch (e->kind) {
            case expr_kind::int_lit:    return visit_int_lit(e);
            case expr_kind::float_lit:  return visit_float_lit(e);
            case expr_kind::string_lit: return visit_string_lit(e);
            case expr_kind::char_lit:   return visit_char_lit(e);
            case expr_kind::bool_lit:   return visit_bool_lit(e);
            case expr_kind::identifier: return visit_identifier(e);
            case expr_kind::unary:      return visit_unary(e);
            case expr_kind::binary:     return visit_binary(e);
            case expr_kind::assign:     return visit_assign(e);
            case expr_kind::call:       return visit_call(e);
            case expr_kind::subscript:  return visit_subscript(e);
            case expr_kind::member:     return visit_member(e);
            case expr_kind::cast:       return visit_cast(e);
            case expr_kind::sizeof_e:   return visit_sizeof(e);
            case expr_kind::ternary:    return visit_ternary(e);
            case expr_kind::annotation: return prim(prim_type_t::void_t); // @id has no type
            default:
                throw std::runtime_error(err(e->line, "Unknown expression kind"));
        }
    }

    type_node* visit_int_lit(expr_node* /*e*/)   { return prim(prim_type_t::i32); }
    type_node* visit_float_lit(expr_node* /*e*/) { return prim(prim_type_t::f64); }
    type_node* visit_bool_lit(expr_node* /*e*/)  { return prim(prim_type_t::boolean); }

    type_node* visit_string_lit(expr_node* /*e*/) {
        type_node t; t.is_primitive = true; t.prim = prim_type_t::u8; t.pointer_depth = 1;
        return make_type(t);
    }

    type_node* visit_char_lit(expr_node* /*e*/) { return prim(prim_type_t::u8); }

    type_node* visit_identifier(expr_node* e) {
        var_decl* vd = scope.lookup_var(e->str_val);
        if (vd) return vd->type;

        // Check if it's a function being used as a value (not in call position).
        // For now this is an error; function pointer types are not in the type system.
        if (scope.lookup_func(e->str_val))
            throw std::runtime_error(err(e->line,
                "'" + e->str_val + "' is a function; use it in a call expression"));

        throw std::runtime_error(err(e->line,
            "Undeclared identifier '" + e->str_val + "'"));
    }

    type_node* visit_unary(expr_node* e) {
        type_node* ot = visit_expr(e->operand);
        uint64_t   ln = e->line;

        switch (e->uop) {
            case unary_op::neg:
            case unary_op::pos:
                if (!ot->is_primitive || !is_numeric_prim(ot->prim.value()))
                    throw std::runtime_error(err(ln,
                        "Unary +/- requires numeric type, got '" + type_to_str(ot) + "'"));
                return ot;

            case unary_op::bit_not:
                if (!ot->is_primitive || !is_int_prim(ot->prim.value()))
                    throw std::runtime_error(err(ln,
                        "Bitwise NOT (~) requires integer type, got '" + type_to_str(ot) + "'"));
                return ot;

            case unary_op::log_not:
                if (!is_truthy(ot))
                    throw std::runtime_error(err(ln,
                        "Logical NOT (!) requires numeric, bool, or pointer type, got '" +
                        type_to_str(ot) + "'"));
                return prim(prim_type_t::boolean);

            case unary_op::pre_inc:
            case unary_op::pre_dec:
            case unary_op::post_inc:
            case unary_op::post_dec:
                if (!is_lvalue(e->operand))
                    throw std::runtime_error(err(ln, "Increment/decrement requires an lvalue"));
                if (!is_truthy(ot))
                    throw std::runtime_error(err(ln,
                        "Increment/decrement requires numeric or pointer type, got '" +
                        type_to_str(ot) + "'"));
                return ot;

            case unary_op::deref: {
                if (ot->pointer_depth < 1)
                    throw std::runtime_error(err(ln,
                        "Cannot dereference non-pointer type '" + type_to_str(ot) + "'"));
                type_node derefed = *ot;
                derefed.pointer_depth--;
                return make_type(derefed);
            }

            case unary_op::addr_of:
                if (!is_lvalue(e->operand))
                    throw std::runtime_error(err(ln, "Cannot take address of a non-lvalue"));
                {
                    type_node addr = *ot;
                    addr.pointer_depth++;
                    return make_type(addr);
                }

            default:
                throw std::runtime_error(err(ln, "Unknown unary operator"));
        }
    }

    type_node* visit_binary(expr_node* e) {
        type_node* lt = visit_expr(e->lhs);
        type_node* rt = visit_expr(e->rhs);
        uint64_t   ln = e->line;

        auto need_num = [&](const type_node* t, const char* side) {
            if (!t->is_primitive || !is_numeric_prim(t->prim.value()))
                throw std::runtime_error(err(ln,
                    std::string(side) + " operand must be numeric, got '" + type_to_str(t) + "'"));
        };
        auto need_int = [&](const type_node* t, const char* side) {
            if (!t->is_primitive || !is_int_prim(t->prim.value()))
                throw std::runtime_error(err(ln,
                    std::string(side) + " operand must be integer, got '" + type_to_str(t) + "'"));
        };

        switch (e->bop) {
            // ---- arithmetic ----
            case binary_op::add:
                if (lt->pointer_depth > 0) { need_int(rt, "right"); return lt; }
                if (rt->pointer_depth > 0) { need_int(lt, "left");  return rt; }
                need_num(lt, "left"); need_num(rt, "right");
                return prim(promote_prim(lt->prim.value(), rt->prim.value()));

            case binary_op::sub:
                if (lt->pointer_depth > 0 && rt->pointer_depth > 0) {
                    if (!types_equal(lt, rt))
                        throw std::runtime_error(err(ln, "Pointer subtraction requires matching pointer types"));
                    return prim(prim_type_t::i64);
                }
                if (lt->pointer_depth > 0) { need_int(rt, "right"); return lt; }
                need_num(lt, "left"); need_num(rt, "right");
                return prim(promote_prim(lt->prim.value(), rt->prim.value()));

            case binary_op::mul:
            case binary_op::div:
                need_num(lt, "left"); need_num(rt, "right");
                return prim(promote_prim(lt->prim.value(), rt->prim.value()));

            case binary_op::mod:
                need_int(lt, "left"); need_int(rt, "right");
                return prim(promote_prim(lt->prim.value(), rt->prim.value()));

            // ---- comparison ----
            case binary_op::eq:
            case binary_op::ne:
                if (!eq_comparable(lt, rt))
                    throw std::runtime_error(err(ln,
                        "Cannot compare '" + type_to_str(lt) + "' with '" + type_to_str(rt) + "'"));
                return prim(prim_type_t::boolean);

            case binary_op::lt:
            case binary_op::gt:
            case binary_op::lte:
            case binary_op::gte:
                if (!ord_comparable(lt, rt))
                    throw std::runtime_error(err(ln,
                        "Cannot order-compare '" + type_to_str(lt) +
                        "' with '" + type_to_str(rt) + "'"));
                return prim(prim_type_t::boolean);

            // ---- logical ----
            case binary_op::log_and:
            case binary_op::log_or:
                if (!is_truthy(lt) || !is_truthy(rt))
                    throw std::runtime_error(err(ln,
                        "Logical operator requires truthy (numeric/bool/pointer) operands"));
                return prim(prim_type_t::boolean);

            // ---- bitwise ----
            case binary_op::bit_and:
            case binary_op::bit_or:
            case binary_op::bit_xor:
                need_int(lt, "left"); need_int(rt, "right");
                return prim(promote_prim(lt->prim.value(), rt->prim.value()));

            case binary_op::shl:
            case binary_op::shr:
                need_int(lt, "left"); need_int(rt, "right");
                return lt; // result has the type of the left operand

            default:
                throw std::runtime_error(err(ln, "Unknown binary operator in binary expression"));
        }
    }

    type_node* visit_assign(expr_node* e) {
        if (!is_lvalue(e->lhs))
            throw std::runtime_error(err(e->line, "Left-hand side of assignment is not an lvalue"));

        type_node* lt = visit_expr(e->lhs);
        type_node* rt = visit_expr(e->rhs);
        uint64_t   ln = e->line;

        if (lt->is_const)
            throw std::runtime_error(err(ln, "Cannot assign to a const-qualified variable"));

        if (e->bop == binary_op::assign) {
            if (!assignable(lt, rt))
                throw std::runtime_error(err(ln,
                    "Cannot assign '" + type_to_str(rt) + "' to '" + type_to_str(lt) + "'"));
            return lt;
        }

        // Compound assignments: validate operand constraints
        bool lnum = lt->is_primitive && is_numeric_prim(lt->prim.value());
        bool rnum = rt->is_primitive && is_numeric_prim(rt->prim.value());
        bool lint = lt->is_primitive && is_int_prim(lt->prim.value());
        bool rint = rt->is_primitive && is_int_prim(rt->prim.value());
        bool lptr = lt->pointer_depth > 0;

        switch (e->bop) {
            case binary_op::add_assign:
            case binary_op::sub_assign:
                if (!(lnum && rnum) && !(lptr && rint))
                    throw std::runtime_error(err(ln,
                        "+= / -= requires numeric types or pointer += integer"));
                break;
            case binary_op::mul_assign:
            case binary_op::div_assign:
                if (!lnum || !rnum)
                    throw std::runtime_error(err(ln, "*= / /= requires numeric types"));
                break;
            case binary_op::mod_assign:
            case binary_op::and_assign:
            case binary_op::or_assign:
            case binary_op::xor_assign:
            case binary_op::shl_assign:
            case binary_op::shr_assign:
                if (!lint || !rint)
                    throw std::runtime_error(err(ln,
                        "%= / &= / |= / ^= / <<= / >>= requires integer types"));
                break;
            default:
                throw std::runtime_error(err(ln, "Unknown compound assignment operator"));
        }
        return lt;
    }

    type_node* visit_call(expr_node* e) {
        uint64_t ln = e->line;

        // Resolve callee: identifier → function name lookup
        if (e->callee->kind != expr_kind::identifier) {
            // Expression callee (function pointer). We can't verify the signature
            // without a function-pointer type, so just type-check the arguments.
            visit_expr(e->callee);
            for (auto* arg : e->args) visit_expr(arg);
            return prim(prim_type_t::void_t);
        }

        const std::string& fname = e->callee->str_val;
        func_decl* fd = scope.lookup_func(fname);
        if (!fd)
            throw std::runtime_error(err(ln, "Call to undeclared function '" + fname + "'"));

        size_t expected = fd->params.size();
        size_t got      = e->args.size();

        if (fd->is_variadic) {
            if (got < expected)
                throw std::runtime_error(err(ln,
                    "Too few arguments to '" + fname + "': expected at least " +
                    std::to_string(expected) + ", got " + std::to_string(got)));
        } else {
            if (got != expected)
                throw std::runtime_error(err(ln,
                    "Wrong number of arguments to '" + fname + "': expected " +
                    std::to_string(expected) + ", got " + std::to_string(got)));
        }

        for (size_t i = 0; i < expected; i++) {
            type_node* at = visit_expr(e->args[i]);
            type_node* pt = fd->params[i].type;
            if (!assignable(pt, at))
                throw std::runtime_error(err(e->args[i]->line,
                    "Argument " + std::to_string(i + 1) + " to '" + fname +
                    "': cannot pass '" + type_to_str(at) +
                    "' as '" + type_to_str(pt) + "'"));
        }
        for (size_t i = expected; i < got; i++) visit_expr(e->args[i]);

        return fd->ret_type;
    }

    type_node* visit_subscript(expr_node* e) {
        type_node* ot = visit_expr(e->object);
        type_node* it = visit_expr(e->index);
        uint64_t   ln = e->line;

        if (ot->pointer_depth < 1 && !ot->array_size.has_value())
            throw std::runtime_error(err(ln,
                "Subscript operator requires a pointer or array type, got '" +
                type_to_str(ot) + "'"));
        if (!it->is_primitive || !is_int_prim(it->prim.value()))
            throw std::runtime_error(err(ln,
                "Array index must be an integer type, got '" + type_to_str(it) + "'"));

        type_node elem = *ot;
        if (ot->pointer_depth > 0) elem.pointer_depth--;
        else                       elem.array_size.reset();
        return make_type(elem);
    }

    type_node* visit_member(expr_node* e) {
        type_node* ot = visit_expr(e->object);
        uint64_t   ln = e->line;

        if (ot->pointer_depth > 1)
            throw std::runtime_error(err(ln,
                "Member access on multi-level pointer is not allowed; dereference first"));
        if (ot->is_primitive)
            throw std::runtime_error(err(ln,
                "Cannot access member '" + e->member_name + "' of primitive type '" +
                type_to_str(ot) + "'"));

        // Resolve typedefs to find the underlying struct/union
        type_node* resolved = resolve_typedef(ot, ln);
        if (!resolved || resolved->is_primitive)
            throw std::runtime_error(err(ln,
                "Cannot access member '" + e->member_name + "': type is not a struct or union"));

        const std::string tname = resolved->name.value_or("");

        if (scope.structs.count(tname)) {
            for (auto* f : scope.structs[tname]->fields)
                if (f->name == e->member_name) return f->type;
            throw std::runtime_error(err(ln,
                "No field '" + e->member_name + "' in struct '" + tname + "'"));
        }
        if (scope.unions.count(tname)) {
            for (auto* f : scope.unions[tname]->fields)
                if (f->name == e->member_name) return f->type;
            throw std::runtime_error(err(ln,
                "No field '" + e->member_name + "' in union '" + tname + "'"));
        }
        throw std::runtime_error(err(ln,
            "Type '" + tname + "' is not a struct or union"));
    }

    type_node* visit_cast(expr_node* e) {
        visit_expr(e->operand); // type-check the expression being cast
        if (!e->cast_type)
            throw std::runtime_error(err(e->line, "Cast has no target type"));
        check_type_known(e->cast_type, e->line);
        return e->cast_type;
    }

    type_node* visit_sizeof(expr_node* e) {
        // sizeof always yields u64
        if (e->cast_type)  check_type_known(e->cast_type, e->line);
        else if (e->operand) visit_expr(e->operand);
        return prim(prim_type_t::u64);
    }

    type_node* visit_ternary(expr_node* e) {
        type_node* ct = visit_expr(e->cond);
        if (!is_truthy(ct))
            throw std::runtime_error(err(e->line,
                "Ternary condition must be numeric, bool, or pointer, got '" +
                type_to_str(ct) + "'"));

        type_node* tt = visit_expr(e->then_e);
        type_node* et = visit_expr(e->else_e);

        // Both branches must have compatible types; return the wider one.
        if (assignable(tt, et)) return tt;
        if (assignable(et, tt)) return et;

        throw std::runtime_error(err(e->line,
            "Ternary branches have incompatible types: '" +
            type_to_str(tt) + "' vs '" + type_to_str(et) + "'"));
    }
};
