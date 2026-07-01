#pragma once
#include <memory>
#include <vector>
#include <string>
#include <stdexcept>
#include <unordered_map>
#include <unordered_set>
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
    std::string   current_class;   // name of the class whose method body is being analyzed
    int           loop_depth    = 0;
    int           switch_depth  = 0;

    // Generic templates (not type-checked here; instantiated by the IR via monomorphization).
    std::unordered_map<std::string, func_decl*> generic_templates;
    std::unordered_set<std::string>             generic_class_names;

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

    // Resolve one level of typedef aliasing; returns the underlying type if the
    // named type is a typedef, otherwise returns t unchanged.
    const type_node* resolve_alias(const type_node* t) const {
        if (!t || t->is_primitive || !t->name.has_value()) return t;
        auto it = scope.typedefs.find(t->name.value());
        if (it == scope.typedefs.end()) return t;
        // Preserve pointer depth from the alias if needed
        return it->second->underlying;
    }

    bool assignable_td(const type_node* lhs, const type_node* rhs) const {
        // Leniency for generics: a non-primitive named type whose name is not a known
        // concrete type is treated as an (unbound) type parameter and is compatible with
        // anything. Concrete-type validity is enforced separately by check_var_type.
        if (is_type_param_like(lhs) || is_type_param_like(rhs)) return true;
        return assignable(resolve_alias(lhs), resolve_alias(rhs));
    }

    bool is_type_param_like(const type_node* t) const {
        if (!t || t->is_primitive || t->is_func_ptr) return false;
        if (!t->name) return false;
        return !scope.is_known_type(*t->name);
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
        if (t->is_func_ptr || t->is_self_ref || t->is_memstr_ref) return;
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
        if (auto* d = dynamic_cast<func_decl*>(node)) {
            // Generic function templates are recorded, not declared as concrete functions.
            if (!d->type_params.empty()) { generic_templates[d->name] = d; return; }
            scope.declare_func(d);    return;
        }
        if (auto* d = dynamic_cast<struct_decl*>(node))  { scope.declare_struct(d);  return; }
        if (auto* d = dynamic_cast<enum_decl*>(node))    { scope.declare_enum(d);    return; }
        if (auto* d = dynamic_cast<union_decl*>(node))   { scope.declare_union(d);   return; }
        if (auto* d = dynamic_cast<typedef_decl*>(node)) { scope.declare_typedef(d); return; }
        if (auto* d = dynamic_cast<class_decl*>(node)) {
            // Generic class templates: only register the name as a known type; skip method
            // registration (their signatures reference unbound type parameters).
            if (!d->type_params.empty()) { generic_class_names.insert(d->name); scope.declare_class(d); return; }
            register_class_decl(d);   return;
        }
        if (auto* d = dynamic_cast<extern_c_block*>(node)) {
            for (auto* decl : d->decls) {
                if (auto* fd = dynamic_cast<func_decl*>(decl)) {
                    fd->is_extern_c = true;
                    scope.declare_func(fd);
                } else register_decl(decl);
            }
            return;
        }
        // global var_decl registered in pass 2 (needs type resolution first)
    }

    void register_class_decl(class_decl* d) {
        scope.declare_class(d);
        // Register methods as global functions with mangled names ClassName__MT_methodname
        for (auto* m : d->methods) {
            // Build a synthetic func_decl for each method so call resolution works
            auto* fd = new func_decl(); // lives for lifetime of analysis; OK for now
            fd->line = m->line;
            fd->name = d->name + "__MT_" + m->name;
            fd->ret_type = m->ret_type;
            fd->is_variadic = m->is_variadic;
            fd->is_extern_c = false;
            // Add implicit self param if needed
            if (m->has_self) {
                param_decl sp;
                auto* st = new type_node();
                st->is_primitive = false; st->name = d->name; st->pointer_depth = 1;
                sp.type = st; sp.name = "self"; sp.line = m->line;
                fd->params.push_back(sp);
            }
            for (auto& p : m->params) fd->params.push_back(p);
            fd->body = m->body;
            m->mangled_name = fd->name;
            scope.declare_func(fd);
        }
    }

    // -------------------------------------------------------------- pass 2: visit top-level

    void visit_top_level(ast_node* node) {
        // Generic templates are not type-checked until instantiated (monomorphization).
        if (auto* d = dynamic_cast<func_decl*>(node))  { if (!d->type_params.empty()) return; }
        if (auto* d = dynamic_cast<class_decl*>(node)) { if (!d->type_params.empty()) return; }
        if (auto* d = dynamic_cast<func_decl*>(node))      { visit_func_decl(d);        return; }
        if (auto* d = dynamic_cast<struct_decl*>(node))    { visit_struct_decl(d);      return; }
        if (auto* d = dynamic_cast<enum_decl*>(node))      { visit_enum_decl(d);        return; }
        if (auto* d = dynamic_cast<union_decl*>(node))     { visit_union_decl(d);       return; }
        if (auto* d = dynamic_cast<typedef_decl*>(node))   { visit_typedef_decl(d);     return; }
        if (auto* d = dynamic_cast<var_decl*>(node))       { visit_global_var_decl(d);  return; }
        if (auto* d = dynamic_cast<class_decl*>(node))     { visit_class_decl(d);       return; }
        if (auto* d = dynamic_cast<extern_c_block*>(node)) { visit_extern_c_block(d);   return; }
        if (dynamic_cast<memstr_decl*>(node))               { return; } // stub: just skip for now
        throw std::runtime_error(err(node->line, "Unrecognised top-level declaration"));
    }

    void visit_extern_c_block(extern_c_block* blk) {
        for (auto* d : blk->decls) {
            if (auto* fd = dynamic_cast<func_decl*>(d)) { fd->is_extern_c = true; visit_func_decl(fd); }
            else visit_top_level(d);
        }
    }

    void visit_class_decl(class_decl* d) {
        // Check base class exists
        if (!d->base_name.empty() && !scope.is_known_type(d->base_name))
            throw std::runtime_error(err(d->line, "Unknown base class '" + d->base_name + "'"));

        // Check all fields
        for (auto* f : d->fields) {
            check_var_type(f->type, f->line);
        }

        // Check all methods
        for (auto* m : d->methods) {
            // Validate mandatory virtual: only allowed with virtual
            if (m->is_mandatory_virtual && !m->is_virtual)
                throw std::runtime_error(err(m->line,
                    "Method '" + m->name + "': 'mandatory' requires 'virtual'"));

            // Check override requires base class
            if (m->is_override && d->base_name.empty())
                throw std::runtime_error(err(m->line,
                    "Method '" + m->name + "': 'override' requires a base class"));

            if (!m->body) continue; // forward declaration, skip body check

            // Type-check method body
            func_decl* prev = current_func;
            std::string prev_class = current_class;
            // Build a synthetic func_decl for type-checking
            auto* fd = owned_funcs_for_methods.emplace_back(std::make_unique<func_decl>()).get();
            fd->line = m->line; fd->name = m->mangled_name; fd->ret_type = m->ret_type;
            fd->is_variadic = m->is_variadic;
            current_func = fd;
            current_class = d->name;

            scope.push();
            // Declare self
            if (m->has_self) {
                auto* st = make_type(type_node{});
                st->is_primitive = false; st->name = d->name; st->pointer_depth = 1;
                st->is_const = m->self_const;
                var_decl* sv = make_param_var(st, "self", m->line);
                scope.declare_var("self", sv);
            }
            // Declare params
            for (auto& p : m->params) {
                check_var_type(p.type, p.line);
                if (!p.name.empty()) {
                    var_decl* pv = make_param_var(p.type, p.name, p.line);
                    scope.declare_var(p.name, pv);
                }
            }
            // Declare class fields as accessible via self
            for (auto* f : d->fields) {
                var_decl* fv = make_param_var(f->type, f->name, f->line);
                scope.declare_var(f->name, fv);
            }
            visit_block(m->body);
            scope.pop();
            current_func = prev;
            current_class = prev_class;
        }
    }

    std::vector<std::unique_ptr<func_decl>> owned_funcs_for_methods;

    // Returns true if child_name == parent_name or child inherits from parent (transitively).
    bool is_derived_from(const std::string& child_name, const std::string& parent_name) const {
        if (child_name == parent_name) return true;
        auto it = scope.classes.find(child_name);
        if (it == scope.classes.end()) return false;
        std::string base = it->second->base_name;
        int guard = 0;
        while (!base.empty() && ++guard < 64) {
            if (base == parent_name) return true;
            auto bit = scope.classes.find(base);
            if (bit == scope.classes.end()) break;
            base = bit->second->base_name;
        }
        return false;
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
            if (!assignable_td(d->type, it))
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

        // Params and function body share one scope frame so that re-declaring a
        // param name inside the body is caught as a redeclaration.
        scope.push();
        for (auto& p : fd->params) {
            check_var_type(p.type, p.line);
            if (!p.name.empty()) {
                var_decl* pv = make_param_var(p.type, p.name, p.line);
                scope.declare_var(p.name, pv);
            }
        }
        // Iterate body statements directly (not via visit_block, which would push a
        // fresh frame and hide the param-redeclaration check).
        if (fd->body)
            for (auto* s : fd->body->stmts) visit_stmt(s);

        scope.pop();
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
        if (auto* n = dynamic_cast<defer_stmt*>(node))    { visit_defer_stmt(n);    return; }
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
                if (!assignable_td(st, lt))
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
        if (!assignable_td(ret, vt))
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

    void visit_defer_stmt(defer_stmt* n) {
        if (n->expr) visit_expr(n->expr);
        else if (n->blk) visit_block(n->blk);
    }

    void visit_local_var_decl(var_decl* d) {
        check_var_type(d->type, d->line);
        // consteval means the user will call __construct__ manually; passing ctor args
        // at the declaration site (consteval T v(args)) is an error.
        if (d->is_consteval && !d->ctor_args.empty())
            throw std::runtime_error(err(d->line,
                "A 'consteval' declaration cannot have constructor arguments at the declaration site; "
                "call '" + d->name + ".__construct__(...)' explicitly after the declaration."));
        if (d->init.has_value()) {
            expr_node* init_e = d->init.value();
            type_node* it = visit_expr(init_e);
            // Context-inferred class initializer .{...} adopts the variable's type; skip check.
            bool inferred_init = (init_e->kind == expr_kind::class_init && !init_e->init_type);
            if (!inferred_init && !assignable_td(d->type, it))
                throw std::runtime_error(err(d->line,
                    "Cannot initialise '" + d->name + "' (type '" + type_to_str(d->type) +
                    "') with '" + type_to_str(it) + "'"));
        }
        // Implicit constructor arguments: Type v(args...) / v{args...}
        for (auto* a : d->ctor_args) visit_expr(a);
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
            case expr_kind::class_init: return visit_class_init(e);
            default:
                throw std::runtime_error(err(e->line, "Unknown expression kind"));
        }
    }

    type_node* visit_class_init(expr_node* e) {
        // Type-check field initializer expressions; the field-name validity and stores
        // are handled by the IR. Returns the named type (or void for context-inferred .{}).
        for (auto& fi : e->field_inits) visit_expr(fi.second);
        if (e->init_type) return e->init_type;
        return prim(prim_type_t::void_t);
    }

    type_node* visit_int_lit(expr_node* /*e*/)   { return prim(prim_type_t::i32); }
    type_node* visit_float_lit(expr_node* /*e*/) { return prim(prim_type_t::f64); }
    type_node* visit_bool_lit(expr_node* /*e*/)  { return prim(prim_type_t::boolean); }

    type_node* visit_string_lit(expr_node* /*e*/) {
        type_node t; t.is_primitive = true; t.prim = prim_type_t::char_t;
        t.pointer_depth = 1; t.is_const = true;
        return make_type(t);
    }

    type_node* visit_char_lit(expr_node* /*e*/) { return prim(prim_type_t::char_t); }

    type_node* visit_identifier(expr_node* e) {
        var_decl* vd = scope.lookup_var(e->str_val);
        if (vd) return vd->type;

        // Function used as value (e.g. address-of for function pointer)
        func_decl* fd = scope.lookup_func(e->str_val);
        if (fd) {
            // Return a function type (depth=0); addr_of will increment to 1 for pointer syntax
            auto* fpt = make_type(type_node{});
            fpt->is_func_ptr  = true;
            fpt->fp_ret       = fd->ret_type;
            for (auto& p : fd->params) fpt->fp_params.push_back(p.type);
            fpt->fp_variadic  = fd->is_variadic;
            fpt->pointer_depth = 0;
            return fpt;
        }

        // Enum variant used as integer constant
        if (scope.enum_variants.count(e->str_val))
            return prim(prim_type_t::i32);

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
                // Resolve typedef aliases so `typedef i32* IntPtr; *p` works.
                if (ot && !ot->is_primitive && ot->pointer_depth == 0 && ot->name.has_value())
                    ot = resolve_typedef(ot, ln);
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

    // Returns the method return type if the class (named tname) has operator op, else nullptr.
    // Also enforces access modifier on the matched method.
    type_node* find_class_op(const std::string& tname, const std::string& op_str, uint64_t ln = 0) {
        std::string search = tname;
        while (!search.empty() && scope.classes.count(search)) {
            class_decl* cd = scope.classes[search];
            for (auto* m : cd->methods) {
                if (m->is_operator_overload && m->operator_str == op_str) {
                    if (m->access == access_mod::priv && current_class != search)
                        throw std::runtime_error(err(ln,
                            "Cannot use private 'operator" + op_str + "' of '" + search +
                            "' from outside the class"));
                    if (m->access == access_mod::prot && !is_derived_from(current_class, search))
                        throw std::runtime_error(err(ln,
                            "Cannot use protected 'operator" + op_str + "' of '" + search +
                            "' from unrelated context"));
                    return m->ret_type;
                }
            }
            search = cd->base_name;
        }
        return nullptr;
    }

    type_node* visit_binary(expr_node* e) {
        type_node* lt = visit_expr(e->lhs);
        type_node* rt = visit_expr(e->rhs);
        uint64_t   ln = e->line;

        // Typedefs are transparent for operator type-checking: a `typedef i32 Score`
        // behaves exactly like i32 in arithmetic/comparison. Resolve scalar aliases
        // (pointer-depth 0 named types) to their underlying type before checking.
        if (lt && !lt->is_primitive && lt->pointer_depth == 0 && lt->name.has_value())
            lt = resolve_typedef(lt, ln);
        if (rt && !rt->is_primitive && rt->pointer_depth == 0 && rt->name.has_value())
            rt = resolve_typedef(rt, ln);

        // Generic leniency: operands of unbound type-parameter type defer all checking
        // to the monomorphized instantiation. Comparisons yield bool; others yield the
        // concrete operand type when available.
        if (is_type_param_like(lt) || is_type_param_like(rt)) {
            switch (e->bop) {
                case binary_op::eq: case binary_op::ne:
                case binary_op::lt: case binary_op::gt:
                case binary_op::lte: case binary_op::gte:
                case binary_op::log_and: case binary_op::log_or:
                    return prim(prim_type_t::boolean);
                default:
                    return is_type_param_like(lt) ? rt : lt;
            }
        }

        // Check for class operator overloads first.
        auto bop_to_str = [](binary_op op) -> std::string {
            switch (op) {
                case binary_op::add: return "+";
                case binary_op::sub: return "-";
                case binary_op::mul: return "*";
                case binary_op::div: return "/";
                case binary_op::mod: return "%";
                case binary_op::eq:  return "==";
                case binary_op::ne:  return "!=";
                case binary_op::lt:  return "<";
                case binary_op::lte: return "<=";
                case binary_op::gt:  return ">";
                case binary_op::gte: return ">=";
                default:             return "";
            }
        };
        if (!lt->is_primitive && lt->pointer_depth == 0 && lt->name.has_value()) {
            std::string op_str = bop_to_str(e->bop);
            if (!op_str.empty()) {
                type_node* res = find_class_op(lt->name.value(), op_str, ln);
                if (res) return res;
            }
        }

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
            if (!assignable_td(lt, rt))
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

        // Static method call via dot: ClassName.method(args) where ClassName is a class, not a var.
        // Rewrite callee in-place so the rest of visit_call sees it as an identifier call.
        if (e->callee->kind == expr_kind::member &&
            e->callee->object &&
            e->callee->object->kind == expr_kind::identifier) {
            const std::string& maybe_class = e->callee->object->str_val;
            if (!scope.lookup_var(maybe_class) && scope.classes.count(maybe_class)) {
                std::string mangled = maybe_class + "__MT_" + e->callee->member_name;
                e->callee->kind    = expr_kind::identifier;
                e->callee->str_val = mangled;
            }
        }

        // Resolve callee: identifier → function name lookup with overload resolution
        if (e->callee->kind != expr_kind::identifier) {
            // Check for explicit obj.__construct__() or obj->__construct__() call:
            // only allowed on variables declared with the 'consteval' keyword.
            if (e->callee->kind == expr_kind::member &&
                e->callee->member_name == "__construct__" &&
                e->callee->object) {
                // Support both dot access (object is identifier) and arrow access
                // (object is deref of identifier, because -> desugars to (*ptr).field).
                expr_node* obj_expr = e->callee->object;
                if (obj_expr->kind == expr_kind::unary && obj_expr->uop == unary_op::deref)
                    obj_expr = obj_expr->operand;
                if (obj_expr && obj_expr->kind == expr_kind::identifier) {
                    const std::string& obj_name = obj_expr->str_val;
                    var_decl* vd = scope.lookup_var(obj_name);
                    if (vd && !vd->is_consteval)
                        throw std::runtime_error(err(ln,
                            "Cannot call '__construct__' explicitly on '" + obj_name +
                            "': declare it with 'consteval' to enable manual construction, "
                            "or use '" + obj_name + "(args)' implicit-constructor syntax"));
                }
            }

            // Expression callee (function pointer or method).
            type_node* ct = visit_expr(e->callee);
            for (auto* arg : e->args) visit_expr(arg);
            if (ct && ct->is_func_ptr && ct->fp_ret) return ct->fp_ret;
            return prim(prim_type_t::void_t);
        }

        const std::string& fname = e->callee->str_val;

        // Generic function call: type-check arguments leniently and infer the return type.
        // The concrete instantiation is produced later by the IR (monomorphization).
        {
            auto git = generic_templates.find(fname);
            if (git != generic_templates.end()) {
                func_decl* tmpl = git->second;
                std::vector<type_node*> arg_types;
                for (auto* arg : e->args) arg_types.push_back(visit_expr(arg));
                // If the return type is a bare type parameter, infer it from the matching argument.
                if (tmpl->ret_type && !tmpl->ret_type->is_primitive
                    && tmpl->ret_type->name && tmpl->ret_type->pointer_depth == 0) {
                    const std::string& rname = *tmpl->ret_type->name;
                    for (size_t i = 0; i < tmpl->params.size() && i < arg_types.size(); ++i) {
                        auto* pt = tmpl->params[i].type;
                        if (pt && !pt->is_primitive && pt->name && *pt->name == rname && arg_types[i])
                            return arg_types[i];
                    }
                }
                return tmpl->ret_type ? tmpl->ret_type : prim(prim_type_t::void_t);
            }
        }

        // Function pointer variable call: fp(args)
        var_decl* fp_vd = scope.lookup_var(fname);
        if (fp_vd && fp_vd->type && fp_vd->type->is_func_ptr) {
            for (auto* arg : e->args) visit_expr(arg);
            return fp_vd->type->fp_ret ? fp_vd->type->fp_ret : prim(prim_type_t::void_t);
        }

        const std::vector<func_decl*>* overloads = scope.lookup_overloads(fname);
        if (!overloads || overloads->empty())
            throw std::runtime_error(err(ln, "Call to undeclared function '" + fname + "'"));

        // Type-check arguments first
        std::vector<type_node*> arg_types;
        arg_types.reserve(e->args.size());
        for (auto* arg : e->args) arg_types.push_back(visit_expr(arg));

        // Find best matching overload
        func_decl* fd = resolve_overload(fname, overloads, arg_types, ln);
        e->resolved_overload = fd;

        // Access check for static method calls (Class__MT_method mangled name).
        {
            auto mt = fname.find("__MT_");
            if (mt != std::string::npos) {
                std::string owner_class = fname.substr(0, mt);
                std::string meth_name   = fname.substr(mt + 5);
                if (scope.classes.count(owner_class)) {
                    class_decl* cd = scope.classes[owner_class];
                    for (auto* m : cd->methods) {
                        if (m->name == meth_name) {
                            if (m->access == access_mod::priv && current_class != owner_class)
                                throw std::runtime_error(err(ln,
                                    "Cannot call private method '" + meth_name + "' of '" +
                                    owner_class + "' from outside the class"));
                            if (m->access == access_mod::prot && !is_derived_from(current_class, owner_class))
                                throw std::runtime_error(err(ln,
                                    "Cannot call protected method '" + meth_name + "' of '" +
                                    owner_class + "' from unrelated context"));
                            break;
                        }
                    }
                }
            }
        }

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

        return fd->ret_type;
    }

    func_decl* resolve_overload(const std::string& fname,
                                const std::vector<func_decl*>* overloads,
                                const std::vector<type_node*>& arg_types,
                                uint64_t ln) {
        // Single overload: no selection needed
        if (overloads->size() == 1) return (*overloads)[0];

        // Try exact match first, then relaxed (assignable) match
        func_decl* best = nullptr;
        for (auto* fd : *overloads) {
            size_t np = fd->params.size();
            if (!fd->is_variadic && np != arg_types.size()) continue;
            if (fd->is_variadic && arg_types.size() < np) continue;
            bool match = true;
            for (size_t i = 0; i < np; i++) {
                if (!assignable_td(fd->params[i].type, arg_types[i])) { match = false; break; }
            }
            if (match) {
                if (best) {
                    // Ambiguous: prefer exact type match
                    bool cur_exact = true, best_exact = true;
                    for (size_t i = 0; i < np; i++) {
                        if (!types_equal(fd->params[i].type, arg_types[i])) cur_exact = false;
                        if (!types_equal(best->params[i].type, arg_types[i])) best_exact = false;
                    }
                    if (cur_exact && !best_exact) best = fd;
                    // If still ambiguous, keep first match (could emit warning)
                } else {
                    best = fd;
                }
            }
        }
        if (!best)
            throw std::runtime_error(err(ln,
                "No matching overload of '" + fname + "' for given arguments"));
        return best;
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
        if (ot->array_size.has_value()) elem.array_size.reset();
        else                            elem.pointer_depth--;
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
        if (scope.classes.count(tname)) {
            // Helper: enforce access modifier from current_class context.
            auto check_access = [&](access_mod am, const std::string& owner, const std::string& mname) {
                if (am == access_mod::pub) return;
                if (am == access_mod::priv) {
                    if (current_class != owner)
                        throw std::runtime_error(err(ln,
                            "Cannot access private member '" + mname + "' of '" + owner + "'"));
                } else { // protected
                    if (!is_derived_from(current_class, owner))
                        throw std::runtime_error(err(ln,
                            "Cannot access protected member '" + mname + "' of '" + owner + "' from unrelated context"));
                }
            };

            class_decl* cd = scope.classes[tname];
            for (auto* f : cd->fields)
                if (f->name == e->member_name) { check_access(f->access, tname, f->name); return f->type; }
            // Check methods (returns a function pointer type)
            for (auto* m : cd->methods) {
                if (m->name == e->member_name) {
                    check_access(m->access, tname, m->name);
                    auto* fpt = make_type(type_node{});
                    fpt->is_func_ptr = true; fpt->fp_ret = m->ret_type;
                    for (auto& p : m->params) fpt->fp_params.push_back(p.type);
                    fpt->pointer_depth = 1;
                    return fpt;
                }
            }
            // Walk the base class chain for fields and methods
            std::string base_name = cd->base_name;
            while (!base_name.empty() && scope.classes.count(base_name)) {
                class_decl* base = scope.classes[base_name];
                for (auto* f : base->fields)
                    if (f->name == e->member_name) { check_access(f->access, base_name, f->name); return f->type; }
                for (auto* m : base->methods) {
                    if (m->name == e->member_name) {
                        check_access(m->access, base_name, m->name);
                        auto* fpt = make_type(type_node{});
                        fpt->is_func_ptr = true; fpt->fp_ret = m->ret_type;
                        for (auto& p : m->params) fpt->fp_params.push_back(p.type);
                        fpt->pointer_depth = 1;
                        return fpt;
                    }
                }
                base_name = base->base_name;
            }
            throw std::runtime_error(err(ln,
                "No member '" + e->member_name + "' in class '" + tname + "'"));
        }
        throw std::runtime_error(err(ln,
            "Type '" + tname + "' is not a struct, union, or class"));
    }

    type_node* visit_cast(expr_node* e) {
        type_node* src = visit_expr(e->operand); // type-check the expression being cast
        if (!e->cast_type)
            throw std::runtime_error(err(e->line, "Cast has no target type"));
        check_type_known(e->cast_type, e->line);
        // Check access on conversion operators: (TargetType)obj where obj is a class type
        // routes through operator TargetType. Enforce its access modifier.
        if (src && !src->is_primitive && src->pointer_depth == 0 && src->name.has_value()) {
            std::string src_class = src->name.value();
            if (scope.classes.count(src_class)) {
                class_decl* cd = scope.classes[src_class];
                for (auto* m : cd->methods) {
                    if (m->is_conversion_op) {
                        if (m->access == access_mod::priv && current_class != src_class)
                            throw std::runtime_error(err(e->line,
                                "Cannot use private conversion operator of '" + src_class +
                                "' from outside the class"));
                        if (m->access == access_mod::prot && !is_derived_from(current_class, src_class))
                            throw std::runtime_error(err(e->line,
                                "Cannot use protected conversion operator of '" + src_class +
                                "' from unrelated context"));
                    }
                }
            }
        }
        return e->cast_type;
    }

    type_node* visit_sizeof(expr_node* e) {
        // sizeof always yields u64
        // sizeof(TypeName): the parser produces an identifier operand when the name is
        // not a variable. If it names a known type (struct/union/enum/typedef) and not a
        // variable, rewrite it into a type operand so analysis and IR treat it uniformly.
        if (!e->cast_type && e->operand &&
            e->operand->kind == expr_kind::identifier &&
            !scope.lookup_var(e->operand->str_val) &&
            scope.is_known_type(e->operand->str_val)) {
            // Allocate in the AST (persistent) arena, not the analyzer's owned_types,
            // since this node must outlive analysis and be read during IR generation.
            auto* t = new type_node();
            t->is_primitive = false;
            t->name = e->operand->str_val;
            e->cast_type = t;
            e->operand = nullptr;
        }
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
        if (assignable_td(tt, et)) return tt;
        if (assignable_td(et, tt)) return et;

        throw std::runtime_error(err(e->line,
            "Ternary branches have incompatible types: '" +
            type_to_str(tt) + "' vs '" + type_to_str(et) + "'"));
    }
};
