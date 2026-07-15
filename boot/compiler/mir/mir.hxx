#pragma once
// compiler/mir/mir.hxx — Mid-level IR for safety analysis.
// AST is lowered into a CFG of basic blocks (all control flow explicit, all
// expressions flattened to named temporaries).  This IR is NOT used for code
// generation — the existing AST→LLVM path is unchanged.

#include <string>
#include <vector>
#include <optional>
#include <unordered_map>
#include <unordered_set>
#include <cstdint>
#include "../parser/main.hxx"

// ============================================================ Values ========

enum class mvk : uint8_t {
    i_const, f_const, b_const, null_val, str_const,
    tmp,     // result of an instruction (immutable)
    local,   // alloca slot (mutable via load/store)
    param,   // function parameter
    global,  // global variable
};

struct mir_val {
    mvk         kind = mvk::i_const;
    std::string name;
    int64_t     ival = 0;
    double      fval = 0.0;
    type_node*  type = nullptr;

    static mir_val i(int64_t v, type_node* t = nullptr)
        { return {mvk::i_const, "", v, 0.0, t}; }
    static mir_val f(double v, type_node* t = nullptr)
        { return {mvk::f_const, "", 0, v, t}; }
    static mir_val b(bool v) { return {mvk::b_const, "", v ? 1 : 0}; }
    static mir_val null_()   { return {mvk::null_val, "", 0, 0.0, nullptr}; }
    static mir_val tmp(const std::string& n, type_node* t = nullptr)
        { return {mvk::tmp, n, 0, 0, t}; }
    static mir_val local_(const std::string& n, type_node* t = nullptr)
        { return {mvk::local, n, 0, 0, t}; }
    static mir_val param_(const std::string& n, type_node* t = nullptr)
        { return {mvk::param, n, 0, 0, t}; }
    static mir_val global_(const std::string& n, type_node* t = nullptr)
        { return {mvk::global, n, 0, 0, t}; }

    bool is_iconst_zero() const { return kind == mvk::i_const && ival == 0; }
    bool is_null()        const { return kind == mvk::null_val; }
};

// ============================================================ Instructions ==

enum class mik : uint8_t {
    // Local variable management
    alloca_,      // dest = alloca type       (declare local slot)
    load_local,   // dest = *slot             (read local)
    store_local,  // *slot = val              (write local)
    // Scalar operations
    binop_,       // dest = ops[0] bop ops[1]
    unop_,        // dest = uop ops[0]
    cast_,        // dest = (type) ops[0]
    call_,        // [dest =] callee(ops...)
    // Safety-critical sites — analyzer focuses here
    arr_ptr_,     // dest = &arr[idx]         SAFETY: bounds  idx in [0, arr_size)
    deref_,       // dest = *ptr              SAFETY: null    ptr != null
    field_,       // dest = &base.field       SAFETY: null if base is ptr
    load_ptr_,    // dest = *ptr_val          (load through deref_/arr_ptr_/field_ result)
    store_ptr_,   // *ptr_val = val           (store through pointer)
    div_,         // dest = lhs / rhs         SAFETY: zero    rhs != 0
    rem_,         // dest = lhs % rhs         SAFETY: zero    rhs != 0
    // LIR only
    phi_,         // dest = phi [(val,pred)...]
    // Catch-all for unanalyzable ops
    opaque_,      // dest = ?                 analyzer returns UNKNOWN
};

struct mir_phi_arg { mir_val val; std::string pred; };

struct mir_instr {
    mik          kind    = mik::opaque_;
    std::string  dest;              // result temp ("" = void result)
    type_node*   type    = nullptr; // result type or alloca element type
    binary_op    bop     = binary_op::add;
    unary_op     uop     = unary_op::neg;
    std::vector<mir_val> ops;
    std::string  callee;            // for call_
    int64_t      arr_size = 0;      // for arr_ptr_: static array size (0 = unknown)
    std::string  field_name;        // for field_
    std::vector<mir_phi_arg> phi_args; // for phi_
    uint64_t     line    = 0;
    expr_node*   src     = nullptr; // back-link to AST node (for check injection)
};

// ============================================================ Terminators ==

enum class mtk : uint8_t { br_, condbr_, ret_, ret_void_, unreachable_ };

struct mir_term {
    mtk         kind  = mtk::unreachable_;
    mir_val     cond;
    std::string true_lbl, false_lbl;  // for condbr_; true_lbl also used by br_
    mir_val     ret_val;              // for ret_
};

// ============================================================ Blocks / Func =

struct mir_block {
    std::string              label;
    std::vector<mir_instr>   instrs;
    mir_term                 term;
    std::vector<std::string> preds;
};

struct mir_func {
    std::string name;
    std::vector<std::pair<std::string, type_node*>> params;
    type_node*  ret_type       = nullptr;
    bool        is_error_union = false;
    std::vector<mir_block>                      blocks;
    std::unordered_map<std::string, type_node*> slot_types; // slot → elem type

    mir_block* find_block(const std::string& lbl) {
        for (auto& b : blocks) if (b.label == lbl) return &b;
        return nullptr;
    }
    const mir_block* find_block(const std::string& lbl) const {
        for (const auto& b : blocks) if (b.label == lbl) return &b;
        return nullptr;
    }
};

struct mir_module {
    std::vector<mir_func>                           funcs;
    std::vector<std::pair<std::string, type_node*>> globals;
    std::unordered_set<std::string>                 global_names;
};

// ============================================================ Lower context =

struct mir_ctx {
    mir_module* mod;
    mir_func*   func       = nullptr;
    std::string cur_bb;
    bool        terminated = false;
    uint32_t    tmp_n      = 0;
    uint32_t    lbl_n      = 0;

    struct loop_t { std::string brk, cont; };
    std::vector<loop_t> loop_stack;

    std::vector<std::unordered_map<std::string, std::string>> scopes;
    const std::unordered_set<std::string>* globals_ref = nullptr;

    std::string new_tmp() { return "t" + std::to_string(tmp_n++); }
    std::string new_lbl(const char* h = "bb")
        { return std::string(h) + std::to_string(lbl_n++); }

    mir_block& cur() {
        if (auto* b = func->find_block(cur_bb)) return *b;
        throw std::runtime_error("MIR: lost current block '" + cur_bb + "'");
    }

    void emit(mir_instr i)  { if (!terminated) cur().instrs.push_back(std::move(i)); }
    void set_term(mir_term t) {
        if (!terminated) { cur().term = std::move(t); terminated = true; }
    }
    void br(const std::string& lbl)  { set_term({mtk::br_, {}, lbl, {}, {}}); }

    std::string start_bb(const std::string& lbl) {
        func->blocks.push_back(mir_block{lbl, {}, {}, {}});
        cur_bb = lbl; terminated = false;
        return lbl;
    }

    void switch_bb(const std::string& lbl) {
        cur_bb = lbl;
        terminated = false; // we'll re-evaluate at emit time
    }

    void push_scope() { scopes.emplace_back(); }
    void pop_scope()  { if (!scopes.empty()) scopes.pop_back(); }

    void decl_var(const std::string& name, const std::string& slot) {
        if (!scopes.empty()) scopes.back()[name] = slot;
    }

    std::optional<std::string> find_var(const std::string& name) const {
        for (auto it = scopes.rbegin(); it != scopes.rend(); ++it)
            if (auto f = it->find(name); f != it->end()) return f->second;
        return std::nullopt;
    }

    bool is_global(const std::string& name) const {
        return globals_ref && globals_ref->count(name);
    }
};

// ============================================================ Helpers =======

static mir_val emit_load_local(const std::string& slot, type_node* t,
                               uint64_t line, mir_ctx& ctx) {
    std::string r = ctx.new_tmp();
    mir_instr i; i.kind = mik::load_local; i.dest = r; i.type = t; i.line = line;
    i.ops.push_back(mir_val::local_(slot, t));
    ctx.emit(std::move(i));
    return mir_val::tmp(r, t);
}

static void emit_store_local(const std::string& slot, mir_val v,
                             uint64_t line, mir_ctx& ctx) {
    mir_instr i; i.kind = mik::store_local; i.line = line;
    i.ops.push_back(std::move(v));
    i.ops.push_back(mir_val::local_(slot));
    ctx.emit(std::move(i));
}

// Extract static array size from type_node (0 if unknown/dynamic).
static int64_t static_array_size(type_node* t) {
    if (!t || !t->array_size.has_value()) return 0;
    expr_node* sz_e = *t->array_size;
    if (sz_e && sz_e->kind == expr_kind::int_lit) return sz_e->int_val;
    return 0;
}

// ============================================================ Expr lowering =

static mir_val lower_expr(expr_node* e, mir_ctx& ctx);
static void    lower_stmt(ast_node* n, mir_ctx& ctx);

static mir_val lower_expr(expr_node* e, mir_ctx& ctx) {
    if (!e) return mir_val::i(0);

    switch (e->kind) {

    case expr_kind::int_lit:
        return mir_val::i(e->int_val);

    case expr_kind::float_lit:
        return mir_val::f(e->flt_val);

    case expr_kind::bool_lit:
        return mir_val::b(e->bool_val);

    case expr_kind::null_lit:
        return mir_val::null_();

    case expr_kind::char_lit:
        return mir_val::i(e->str_val.empty() ? 0 : (uint8_t)e->str_val[0]);

    case expr_kind::string_lit: {
        mir_val v; v.kind = mvk::str_const; v.name = e->str_val;
        return v;
    }

    case expr_kind::identifier: {
        const std::string& nm = e->str_val;
        if (auto slot = ctx.find_var(nm)) {
            type_node* t = ctx.func->slot_types.count(*slot)
                         ? ctx.func->slot_types.at(*slot) : nullptr;
            return emit_load_local(*slot, t, e->line, ctx);
        }
        if (ctx.is_global(nm)) return mir_val::global_(nm);
        // Param or unknown — opaque
        std::string r = ctx.new_tmp();
        mir_instr i; i.kind = mik::opaque_; i.dest = r; i.line = e->line; i.src = e;
        ctx.emit(std::move(i));
        return mir_val::tmp(r);
    }

    case expr_kind::unary: {
        if (e->uop == unary_op::deref) {
            mir_val ptr = lower_expr(e->operand, ctx);
            // SAFETY: null check
            std::string dp = ctx.new_tmp();
            mir_instr di; di.kind = mik::deref_; di.dest = dp; di.line = e->line;
            di.src = e; di.ops.push_back(ptr);
            ctx.emit(std::move(di));
            // Load through the pointer
            std::string lr = ctx.new_tmp();
            mir_instr li; li.kind = mik::load_ptr_; li.dest = lr; li.line = e->line;
            li.ops.push_back(mir_val::tmp(dp));
            ctx.emit(std::move(li));
            return mir_val::tmp(lr);
        }
        if (e->uop == unary_op::addr_of && e->operand &&
            e->operand->kind == expr_kind::identifier) {
            if (auto slot = ctx.find_var(e->operand->str_val))
                return mir_val::local_(*slot);
        }
        mir_val op = lower_expr(e->operand, ctx);
        std::string r = ctx.new_tmp();
        mir_instr i; i.kind = mik::unop_; i.dest = r; i.uop = e->uop;
        i.line = e->line; i.ops.push_back(op);
        ctx.emit(std::move(i));
        return mir_val::tmp(r);
    }

    case expr_kind::binary: {
        mir_val lhs = lower_expr(e->lhs, ctx);
        mir_val rhs = lower_expr(e->rhs, ctx);
        std::string r = ctx.new_tmp();
        // SAFETY: division by zero
        if (e->bop == binary_op::div || e->bop == binary_op::mod) {
            mir_instr i; i.kind = (e->bop == binary_op::div ? mik::div_ : mik::rem_);
            i.dest = r; i.bop = e->bop; i.line = e->line; i.src = e;
            i.ops = {lhs, rhs};
            ctx.emit(std::move(i));
        } else {
            mir_instr i; i.kind = mik::binop_; i.dest = r; i.bop = e->bop;
            i.line = e->line; i.ops = {lhs, rhs};
            ctx.emit(std::move(i));
        }
        return mir_val::tmp(r);
    }

    case expr_kind::assign: {
        mir_val rhs = lower_expr(e->rhs, ctx);
        if (e->lhs && e->lhs->kind == expr_kind::identifier) {
            if (auto slot = ctx.find_var(e->lhs->str_val)) {
                emit_store_local(*slot, rhs, e->line, ctx);
                return rhs;
            }
        }
        // Complex LHS (subscript, member): opaque
        lower_expr(e->lhs, ctx);
        std::string r = ctx.new_tmp();
        mir_instr i; i.kind = mik::opaque_; i.dest = r; i.line = e->line; i.src = e;
        ctx.emit(std::move(i));
        return mir_val::tmp(r);
    }

    case expr_kind::subscript: {
        mir_val base = lower_expr(e->object, ctx);
        mir_val idx  = lower_expr(e->index, ctx);
        // Get static array size from object's declared type (may be 0 if dynamic)
        int64_t sz = 0;
        if (e->object && e->object->kind == expr_kind::identifier) {
            if (auto slot = ctx.find_var(e->object->str_val))
                if (ctx.func->slot_types.count(*slot))
                    sz = static_array_size(ctx.func->slot_types.at(*slot));
        }
        // SAFETY: bounds check
        std::string pr = ctx.new_tmp();
        mir_instr pi; pi.kind = mik::arr_ptr_; pi.dest = pr; pi.line = e->line;
        pi.src = e; pi.arr_size = sz; pi.ops = {base, idx};
        ctx.emit(std::move(pi));
        // Load element
        std::string lr = ctx.new_tmp();
        mir_instr li; li.kind = mik::load_ptr_; li.dest = lr; li.line = e->line;
        li.ops.push_back(mir_val::tmp(pr));
        ctx.emit(std::move(li));
        return mir_val::tmp(lr);
    }

    case expr_kind::member: {
        // Struct field or namespace member access
        mir_val base = lower_expr(e->object, ctx);
        std::string fr = ctx.new_tmp();
        mir_instr fi; fi.kind = mik::field_; fi.dest = fr; fi.line = e->line;
        fi.field_name = e->member_name; fi.src = e; fi.ops.push_back(base);
        ctx.emit(std::move(fi));
        std::string lr = ctx.new_tmp();
        mir_instr li; li.kind = mik::load_ptr_; li.dest = lr; li.line = e->line;
        li.ops.push_back(mir_val::tmp(fr));
        ctx.emit(std::move(li));
        return mir_val::tmp(lr);
    }

    case expr_kind::call: {
        std::string callee_name;
        if (e->callee) {
            if (e->callee->kind == expr_kind::identifier)
                callee_name = e->callee->str_val;
            else if (e->callee->kind == expr_kind::member)
                callee_name = e->callee->member_name;
        }
        std::vector<mir_val> args;
        for (auto* a : e->args) args.push_back(lower_expr(a, ctx));
        std::string r = ctx.new_tmp();
        mir_instr i; i.kind = mik::call_; i.dest = r; i.callee = callee_name;
        i.line = e->line; i.src = e; i.ops = std::move(args);
        ctx.emit(std::move(i));
        return mir_val::tmp(r);
    }

    case expr_kind::cast: {
        mir_val src = lower_expr(e->operand, ctx);
        std::string r = ctx.new_tmp();
        mir_instr i; i.kind = mik::cast_; i.dest = r; i.type = e->cast_type;
        i.line = e->line; i.ops.push_back(src);
        ctx.emit(std::move(i));
        return mir_val::tmp(r);
    }

    case expr_kind::ternary: {
        mir_val cv = lower_expr(e->cond, ctx);
        std::string t_lbl = ctx.new_lbl("trt"), f_lbl = ctx.new_lbl("trf");
        std::string m_lbl = ctx.new_lbl("trm");
        ctx.set_term({mtk::condbr_, cv, t_lbl, f_lbl, {}});

        ctx.start_bb(t_lbl);
        mir_val tv = lower_expr(e->then_e, ctx);
        std::string t_exit = ctx.cur_bb; bool t_term = ctx.terminated;
        if (!ctx.terminated) ctx.br(m_lbl);

        ctx.start_bb(f_lbl);
        mir_val fv = lower_expr(e->else_e, ctx);
        std::string f_exit = ctx.cur_bb; bool f_term = ctx.terminated;
        if (!ctx.terminated) ctx.br(m_lbl);

        ctx.start_bb(m_lbl);
        if (!t_term || !f_term) {
            std::string r = ctx.new_tmp();
            mir_instr phi; phi.kind = mik::phi_; phi.dest = r;
            if (!t_term) phi.phi_args.push_back({tv, t_exit});
            if (!f_term) phi.phi_args.push_back({fv, f_exit});
            ctx.emit(std::move(phi));
            return mir_val::tmp(r);
        }
        return mir_val::i(0);
    }

    case expr_kind::null_coal: {
        // lhs ?? rhs: evaluate lhs, null-check it, evaluate rhs, return opaque select.
        // (Eager rhs evaluation is conservative for SMT purposes — correctness is fine.)
        mir_val lhs_val = lower_expr(e->lhs, ctx);
        // Emit a null comparison so SMT can track the null check
        std::string null_cmp = ctx.new_tmp();
        mir_instr cmp_i; cmp_i.kind = mik::binop_; cmp_i.dest = null_cmp;
        cmp_i.bop = binary_op::eq; cmp_i.src = e; cmp_i.line = e->line;
        cmp_i.ops.push_back(lhs_val);
        cmp_i.ops.push_back(mir_val::null_());
        ctx.emit(std::move(cmp_i));
        // Lower rhs (may have side effects — accept conservative over-approximation)
        mir_val rhs_val = lower_expr(e->rhs, ctx);
        // Result: opaque select — SMT sees both operands, conservatively returns maybe-null
        std::string result = ctx.new_tmp();
        mir_instr sel; sel.kind = mik::opaque_; sel.dest = result; sel.src = e; sel.line = e->line;
        sel.ops.push_back(lhs_val);
        sel.ops.push_back(rhs_val);
        ctx.emit(std::move(sel));
        return mir_val::tmp(result);
    }

    default: {
        std::string r = ctx.new_tmp();
        mir_instr i; i.kind = mik::opaque_; i.dest = r; i.line = e->line; i.src = e;
        ctx.emit(std::move(i));
        return mir_val::tmp(r);
    }
    }
}

// ============================================================ Stmt lowering =

static void lower_stmt(ast_node* n, mir_ctx& ctx) {
    if (!n || ctx.terminated) return;

    if (auto* b = dynamic_cast<block_stmt*>(n)) {
        ctx.push_scope();
        for (auto* s : b->stmts) { lower_stmt(s, ctx); if (ctx.terminated) break; }
        ctx.pop_scope();
        return;
    }
    if (auto* vd = dynamic_cast<var_decl*>(n)) {
        std::string slot = "s" + std::to_string(ctx.tmp_n++) + "_" + vd->name;
        mir_instr ai; ai.kind = mik::alloca_; ai.dest = slot; ai.type = vd->type;
        ai.line = vd->line;
        ctx.emit(std::move(ai));
        ctx.func->slot_types[slot] = vd->type;
        ctx.decl_var(vd->name, slot);
        if (vd->init.has_value())
            emit_store_local(slot, lower_expr(*vd->init, ctx), vd->line, ctx);
        return;
    }
    if (auto* es = dynamic_cast<expr_stmt*>(n)) {
        lower_expr(es->expr, ctx);
        return;
    }
    if (auto* rs = dynamic_cast<return_stmt*>(n)) {
        if (rs->value.has_value())
            ctx.set_term({mtk::ret_, {}, {}, {}, lower_expr(*rs->value, ctx)});
        else
            ctx.set_term(mir_term{mtk::ret_void_, {}, {}, {}, {}});
        return;
    }
    if (auto* is = dynamic_cast<if_stmt*>(n)) {
        mir_val cv = lower_expr(is->cond, ctx);
        std::string t_lbl = ctx.new_lbl("ift"), m_lbl = ctx.new_lbl("ifm");
        std::string f_lbl = is->else_body ? ctx.new_lbl("iff") : m_lbl;
        ctx.set_term({mtk::condbr_, cv, t_lbl, f_lbl, {}});

        ctx.start_bb(t_lbl);
        ctx.push_scope();
        lower_stmt(is->then_body, ctx);
        ctx.pop_scope();
        bool t_done = ctx.terminated;
        if (!ctx.terminated) ctx.br(m_lbl);

        bool f_done = false;
        if (is->else_body) {
            ctx.start_bb(f_lbl);
            ctx.push_scope();
            lower_stmt(is->else_body, ctx);
            ctx.pop_scope();
            f_done = ctx.terminated;
            if (!ctx.terminated) ctx.br(m_lbl);
        }

        if (!t_done || !f_done || !is->else_body)
            ctx.start_bb(m_lbl);
        return;
    }
    if (auto* ws = dynamic_cast<while_stmt*>(n)) {
        std::string hdr = ctx.new_lbl("whh"), bod = ctx.new_lbl("whb"), ex = ctx.new_lbl("whe");
        ctx.br(hdr);
        ctx.start_bb(hdr);
        mir_val cv = lower_expr(ws->cond, ctx);
        ctx.set_term({mtk::condbr_, cv, bod, ex, {}});
        ctx.start_bb(bod);
        ctx.loop_stack.push_back({ex, hdr});
        ctx.push_scope();
        lower_stmt(ws->body, ctx);
        ctx.pop_scope();
        ctx.loop_stack.pop_back();
        if (!ctx.terminated) ctx.br(hdr);
        ctx.start_bb(ex);
        return;
    }
    if (auto* fs = dynamic_cast<for_stmt*>(n)) {
        std::string hdr = ctx.new_lbl("foh"), bod = ctx.new_lbl("fob");
        std::string stp = ctx.new_lbl("fos"), ex  = ctx.new_lbl("foe");
        ctx.push_scope();
        if (fs->init) lower_stmt(fs->init, ctx);
        ctx.br(hdr);
        ctx.start_bb(hdr);
        if (fs->cond) {
            mir_val cv = lower_expr(fs->cond, ctx);
            ctx.set_term({mtk::condbr_, cv, bod, ex, {}});
        } else { ctx.br(bod); }
        ctx.start_bb(bod);
        ctx.loop_stack.push_back({ex, stp});
        ctx.push_scope();
        lower_stmt(fs->body, ctx);
        ctx.pop_scope();
        ctx.loop_stack.pop_back();
        if (!ctx.terminated) ctx.br(stp);
        ctx.start_bb(stp);
        if (fs->step) lower_expr(fs->step, ctx);
        ctx.br(hdr);
        ctx.pop_scope();
        ctx.start_bb(ex);
        return;
    }
    if (dynamic_cast<break_stmt*>(n)) {
        if (!ctx.loop_stack.empty()) ctx.br(ctx.loop_stack.back().brk);
        return;
    }
    if (dynamic_cast<continue_stmt*>(n)) {
        if (!ctx.loop_stack.empty()) ctx.br(ctx.loop_stack.back().cont);
        return;
    }
    if (auto* ss = dynamic_cast<switch_stmt*>(n)) {
        // Lower switch: evaluate subject and each case body so SMT sees instructions inside them
        if (ss->subject) lower_expr(ss->subject, ctx);
        for (auto& [cond_expr, body] : ss->cases) {
            if (cond_expr.has_value() && *cond_expr) lower_expr(*cond_expr, ctx);
            if (body) lower_stmt(body, ctx);
        }
        return;
    }
    if (auto* frs = dynamic_cast<for_range_stmt*>(n)) {
        // Lower for-range: evaluate range and body so SMT sees instructions inside them
        if (frs->range) lower_expr(frs->range, ctx);
        if (frs->body) lower_stmt(frs->body, ctx);
        return;
    }
    // defer / errdefer: lower bodies so SMT can see safety violations inside them
    if (auto* ds = dynamic_cast<defer_stmt*>(n)) {
        if (ds->blk)  lower_stmt(ds->blk, ctx);
        if (ds->expr) lower_expr(ds->expr, ctx);
        return;
    }
    if (auto* eds = dynamic_cast<errdefer_stmt*>(n)) {
        if (eds->blk)  lower_stmt(eds->blk, ctx);
        if (eds->expr) lower_expr(eds->expr, ctx);
        return;
    }
    // All other statements (asm, etc.) — opaque
    mir_instr i; i.kind = mik::opaque_; i.line = 0; ctx.emit(std::move(i));
}

// ============================================================ Function lower =

static void lower_func(func_decl* fd, mir_module& mod) {
    if (!fd->body) return; // prototype / extern

    mir_func mf;
    mf.name           = fd->mangled_name.empty() ? fd->name : fd->mangled_name;
    mf.ret_type       = fd->ret_type;
    mf.is_error_union = fd->is_error_union;
    for (auto& p : fd->params) mf.params.push_back({p.name, p.type});
    mod.funcs.push_back(std::move(mf));
    mir_func& func = mod.funcs.back();

    mir_ctx ctx; ctx.mod = &mod; ctx.func = &func;
    ctx.globals_ref = &mod.global_names;
    ctx.start_bb("entry");
    ctx.push_scope();

    // Create alloca slots for each parameter, then store the param value in
    for (auto& [pname, ptype] : func.params) {
        std::string slot = "sp_" + pname;
        mir_instr ai; ai.kind = mik::alloca_; ai.dest = slot; ai.type = ptype;
        ctx.emit(std::move(ai));
        func.slot_types[slot] = ptype;
        mir_instr si; si.kind = mik::store_local;
        si.ops.push_back(mir_val::param_(pname, ptype));
        si.ops.push_back(mir_val::local_(slot));
        ctx.emit(std::move(si));
        ctx.decl_var(pname, slot);
    }

    lower_stmt(fd->body, ctx);
    ctx.pop_scope();

    // Ensure the last block is terminated
    if (!ctx.terminated && !func.blocks.empty())
        func.blocks.back().term = mir_term{mtk::ret_void_, {}, {}, {}, {}};

    // Build predecessor lists
    for (auto& blk : func.blocks) {
        auto add_pred = [&](const std::string& succ_lbl) {
            if (auto* s = func.find_block(succ_lbl)) {
                for (auto& p : s->preds) if (p == blk.label) return;
                s->preds.push_back(blk.label);
            }
        };
        if (blk.term.kind == mtk::br_)     add_pred(blk.term.true_lbl);
        if (blk.term.kind == mtk::condbr_) { add_pred(blk.term.true_lbl); add_pred(blk.term.false_lbl); }
    }
}

// ============================================================ Module entry ==

inline mir_module lower_to_mir(program_node* prog) {
    mir_module mod;
    for (auto* d : prog->decls) {
        if (auto* gv = dynamic_cast<var_decl*>(d)) {
            mod.globals.push_back({gv->name, gv->type});
            mod.global_names.insert(gv->name);
        }
    }
    for (auto* d : prog->decls) {
        if (auto* fd = dynamic_cast<func_decl*>(d))
            lower_func(fd, mod);
    }
    return mod;
}
