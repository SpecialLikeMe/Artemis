// smt/main.arc — Abstract interpretation engine for pointer safety.
// Three-outcome model:
//   SAFE    → pointer provably valid, no check inserted
//   UNSAFE  → pointer provably invalid, compile error
//   UNKNOWN → cannot decide (target ≤ 2 %), runtime null/bounds check injected
//
// Covers: use-after-free, double-free, null dereference (alias tracking),
//         array bounds checking (constant → GOOD/BAD; dynamic → runtime check),
//         iterator invalidation (mutation of container during range-for → BAD).
// Data races require a full thread model; UNKNOWN is acceptable per spec.

namespace smt {

// ---- Pointer states ----
enum ptr_state {
    PTR_UNKNOWN = 0,   // not known — will require runtime check
    PTR_VALID   = 1,   // freshly allocated / just assigned non-null
    PTR_FREED   = 2,   // passed to arc_free() — any use is UNSAFE
    PTR_NULL    = 3,   // assigned null literal
    PTR_MOVED   = 4,   // ownership transferred — any use is UNSAFE
}

// ---- Outcome of an SMT check ----
enum smt_outcome {
    SMT_SAFE    = 0,
    SMT_UNSAFE  = 1,
    SMT_UNKNOWN = 2,
}

// ---- Pointer state + alias map ----
// alias_of[i]: if non-null, this slot's state is determined by the canonical slot
// that alias_of[i] names.  Freeing a canonical name propagates to all aliases.
struct smt_pmap {
    i8* names[256];
    i32 states[256];
    i8* alias_of[256];   // alias_of[i] == canonical name, or null if no alias
    i32 len;
}

void smt_pmap_init(smt_pmap* m) { m.len = 0; }

// Copy pmap state (for save/restore around if-branches).
void smt_pmap_copy(smt_pmap* dst, smt_pmap* src) {
    dst.len = src.len;
    i32 i = 0;
    while (i < src.len) {
        dst.names[i]    = src.names[i];
        dst.states[i]   = src.states[i];
        dst.alias_of[i] = src.alias_of[i];
        i = i + 1;
    }
}

// Merge two post-branch states into one:
// - If both branches freed a pointer → FREED (definitely freed on both paths)
// - If only one freed it → UNKNOWN (may or may not be freed)
// - Otherwise keep the original state from before the branch
void smt_pmap_merge(smt_pmap* pre, smt_pmap* after_then, smt_pmap* after_else, smt_pmap* result) {
    smt_pmap_copy(result, pre);
    i32 i = 0;
    while (i < pre.len) {
        i8* nm = pre.names[i];
        if (nm != (i8*)0) {
            i32 s_then = smt_pmap_get(after_then, nm);
            i32 s_else = smt_pmap_get(after_else, nm);
            i32 s_pre  = pre.states[i];
            if (s_then == PTR_FREED && s_else == PTR_FREED) {
                result.states[i] = PTR_FREED;
            } else if ((s_then == PTR_FREED || s_else == PTR_FREED) && s_pre != PTR_FREED) {
                result.states[i] = PTR_UNKNOWN;
            } else {
                result.states[i] = s_pre;
            }
        }
        i = i + 1;
    }
}

// Resolve to the canonical slot index, following one alias level.
i32 smt_pmap_canon_idx(smt_pmap* m, i8* name) {
    i32 i = 0;
    while (i < m.len) {
        if (m.names[i] != (i8*)0 && strcmp(m.names[i], name) == 0) {
            if (m.alias_of[i] != (i8*)0) {
                // Follow one level — find the canonical slot
                i32 j = 0;
                while (j < m.len) {
                    if (m.names[j] != (i8*)0 && strcmp(m.names[j], m.alias_of[i]) == 0) {
                        return j;
                    }
                    j = j + 1;
                }
            }
            return i;
        }
        i = i + 1;
    }
    return -1;
}

i32 smt_pmap_get(smt_pmap* m, i8* name) {
    if (name == (i8*)0) { return PTR_UNKNOWN; }
    i32 ci = smt_pmap_canon_idx(m, name);
    if (ci >= 0) { return m.states[ci]; }
    return PTR_UNKNOWN;
}

void smt_pmap_set(smt_pmap* m, i8* name, i32 state) {
    if (name == (i8*)0) { return; }
    i32 i = 0;
    // Find existing entry and update it (clear alias on explicit set)
    while (i < m.len) {
        if (m.names[i] != (i8*)0 && strcmp(m.names[i], name) == 0) {
            m.states[i]   = state;
            m.alias_of[i] = (i8*)0;  // explicit set breaks alias
            // Propagate FREED/MOVED to all slots aliased to this name
            if (state == PTR_FREED || state == PTR_MOVED) {
                i32 j = 0;
                while (j < m.len) {
                    if (m.alias_of[j] != (i8*)0 && strcmp(m.alias_of[j], name) == 0) {
                        m.states[j]   = state;
                        m.alias_of[j] = (i8*)0;
                    }
                    j = j + 1;
                }
            }
            return;
        }
        i = i + 1;
    }
    if (m.len < 256) {
        m.names[m.len]    = name;
        m.states[m.len]   = state;
        m.alias_of[m.len] = (i8*)0;
        m.len = m.len + 1;
    }
}

// Record that `alias` points to the same allocation as `canon`.
// Used when p2 = p1 — any subsequent arc_free(p1) also invalidates p2.
void smt_pmap_alias(smt_pmap* m, i8* alias_name, i8* canon_name) {
    if (alias_name == (i8*)0 || canon_name == (i8*)0) { return; }
    // Resolve the canonical name through existing aliases
    i32 ci = smt_pmap_canon_idx(m, canon_name);
    i8* resolved_canon = (ci >= 0) ? m.names[ci] : canon_name;

    i32 i = 0;
    while (i < m.len) {
        if (m.names[i] != (i8*)0 && strcmp(m.names[i], alias_name) == 0) {
            m.alias_of[i] = resolved_canon;
            m.states[i]   = smt_pmap_get(m, resolved_canon);
            return;
        }
        i = i + 1;
    }
    if (m.len < 256) {
        m.names[m.len]    = alias_name;
        m.states[m.len]   = smt_pmap_get(m, resolved_canon);
        m.alias_of[m.len] = resolved_canon;
        m.len = m.len + 1;
    }
}

// ---- Array size map — maps local array name → declared size ----
struct smt_asz {
    i8*  names[64];
    i32  sizes[64];
    i32  len;
}

void smt_asz_init(smt_asz* m) { m.len = 0; }

i32 smt_asz_get(smt_asz* m, i8* name) {
    if (name == (i8*)0) { return 0; }
    i32 i = 0;
    while (i < m.len) {
        if (m.names[i] != (i8*)0 && strcmp(m.names[i], name) == 0) { return m.sizes[i]; }
        i = i + 1;
    }
    return 0;
}

void smt_asz_set(smt_asz* m, i8* name, i32 sz) {
    if (name == (i8*)0 || m.len >= 64) { return; }
    i32 i = 0;
    while (i < m.len) {
        if (m.names[i] != (i8*)0 && strcmp(m.names[i], name) == 0) { m.sizes[i] = sz; return; }
        i = i + 1;
    }
    m.names[m.len] = name;
    m.sizes[m.len] = sz;
    m.len = m.len + 1;
}

void smt_asz_copy(smt_asz* dst, smt_asz* src) {
    dst.len = src.len;
    i32 i = 0;
    while (i < src.len) { dst.names[i] = src.names[i]; dst.sizes[i] = src.sizes[i]; i = i + 1; }
}

// ---- Iterator invalidation set — containers currently under range-for ----
struct smt_iter {
    i8*  names[32];
    i32  len;
}

void smt_iter_init(smt_iter* s) { s.len = 0; }

bool smt_iter_check(smt_iter* s, i8* name) {
    if (name == (i8*)0) { return false; }
    i32 i = 0;
    while (i < s.len) {
        if (s.names[i] != (i8*)0 && strcmp(s.names[i], name) == 0) { return true; }
        i = i + 1;
    }
    return false;
}

void smt_iter_add(smt_iter* s, i8* name) {
    if (name == (i8*)0 || s.len >= 32 || smt_iter_check(s, name)) { return; }
    s.names[s.len] = name;
    s.len = s.len + 1;
}

void smt_iter_remove(smt_iter* s, i8* name) {
    if (name == (i8*)0) { return; }
    i32 i = 0;
    while (i < s.len) {
        if (s.names[i] != (i8*)0 && strcmp(s.names[i], name) == 0) {
            i32 j = i;
            while (j < s.len - 1) { s.names[j] = s.names[j + 1]; j = j + 1; }
            s.len = s.len - 1;
            return;
        }
        i = i + 1;
    }
}

// ---- SMT analysis context ----
struct smt_ctx {
    smt_pmap vars;
    smt_asz  arrs;   // array size map (for bounds checking)
    smt_iter iters;  // containers currently being iterated (invalidation detection)
    bool had_error;
    i8*  func_name;
    i32  warn_count;
    i32  rtcheck_count;  // locations that need runtime check injection
}

void smt_ctx_init(smt_ctx* ctx, i8* fn) {
    smt_pmap_init(&ctx.vars);
    smt_asz_init(&ctx.arrs);
    smt_iter_init(&ctx.iters);
    ctx.had_error    = false;
    ctx.func_name    = fn;
    ctx.warn_count   = 0;
    ctx.rtcheck_count = 0;
}

// Emit a proved-UNSAFE compile error.
void smt_error(smt_ctx* ctx, i32 line, i8* msg, i8* var) {
    i8* fn = ctx.func_name != (i8*)0 ? ctx.func_name : "<unknown>";
    if (var != (i8*)0) {
        printf("SMT error: %s (line %d, func '%s', var '%s')\n", msg, line, fn, var);
    } else {
        printf("SMT error: %s (line %d, func '%s')\n", msg, line, fn);
    }
    ctx.warn_count = ctx.warn_count + 1;
    ctx.had_error  = true;
}

// Emit an UNKNOWN note — location will need a runtime check.
void smt_need_rtcheck(smt_ctx* ctx, i32 line, i8* msg, i8* var) {
    i8* fn = ctx.func_name != (i8*)0 ? ctx.func_name : "<unknown>";
    if (var != (i8*)0) {
        printf("SMT note: runtime check needed: %s (line %d, func '%s', var '%s')\n",
               msg, line, fn, var);
    } else {
        printf("SMT note: runtime check needed: %s (line %d, func '%s')\n",
               msg, line, fn);
    }
    ctx.rtcheck_count = ctx.rtcheck_count + 1;
}

// ---- Helpers ----

i8* smt_base_name(parser.expr_node* e) {
    if (e == (parser.expr_node*)0) { return (i8*)0; }
    if (e.kind == ek_identifier) { return e.str_val; }
    return (i8*)0;
}

bool smt_is_null_lit(parser.expr_node* e) {
    if (e == (parser.expr_node*)0) { return false; }
    if (e.kind == ek_int_lit && e.int_val == 0) { return true; }
    if (e.kind == ek_null_lit) { return true; }
    if (e.kind == ek_cast) { return smt_is_null_lit(e.operand); }
    return false;
}

bool smt_is_free_call(i8* name) {
    if (name == (i8*)0) { return false; }
    return strcmp(name, "free") == 0;
}

bool smt_is_alloc_call(i8* name) {
    if (name == (i8*)0) { return false; }
    if (strcmp(name, "malloc") == 0)  { return true; }
    if (strcmp(name, "calloc") == 0)  { return true; }
    if (strcmp(name, "realloc") == 0) { return true; }
    return false;
}

// ---- Forward declarations ----
void smt_expr(parser.expr_node* e, smt_ctx* ctx);
void smt_stmt(parser.ast_node* s, smt_ctx* ctx);

// ---- Pointer safety check ----
// Returns: SMT_SAFE, SMT_UNSAFE, or SMT_UNKNOWN

i32 smt_check_outcome(smt_ctx* ctx, i8* vname) {
    if (vname == (i8*)0) { return SMT_UNKNOWN; }
    i32 st = smt_pmap_get(&ctx.vars, vname);
    if (st == PTR_FREED || st == PTR_MOVED) { return SMT_UNSAFE; }
    if (st == PTR_NULL)                     { return SMT_UNSAFE; }
    if (st == PTR_VALID)                    { return SMT_SAFE; }
    return SMT_UNKNOWN;
}

void smt_check_ptr(parser.expr_node* e, smt_ctx* ctx, i8* context) {
    i8* vname = smt_base_name(e);
    if (vname == (i8*)0) {
        // Can't name it — mark the expression itself as needing a runtime check
        if (e != (parser.expr_node*)0) { e.needs_rtcheck = true; }
        return;
    }
    i32 outcome = smt_check_outcome(ctx, vname);
    if (outcome == SMT_UNSAFE) {
        i32 st = smt_pmap_get(&ctx.vars, vname);
        if (st == PTR_FREED || st == PTR_MOVED) {
            i8 msg[256];
            snprintf(msg, (u64)256, "use-after-free in %s", context);
            smt_error(ctx, (i32)e.line, msg, vname);
        } else {
            i8 msg[256];
            snprintf(msg, (u64)256, "null dereference in %s", context);
            smt_error(ctx, (i32)e.line, msg, vname);
        }
    } else if (outcome == SMT_UNKNOWN) {
        // Tag the expression — the IR stage will emit a null-guard branch
        if (e != (parser.expr_node*)0) { e.needs_rtcheck = true; }
    }
}

i8* smt_call_name(parser.expr_node* e) {
    if (e == (parser.expr_node*)0) { return (i8*)0; }
    if (e.func_resolved_name != (i8*)0) { return e.func_resolved_name; }
    if (e.callee != (parser.expr_node*)0 && e.callee.kind == ek_identifier) {
        return e.callee.str_val;
    }
    return (i8*)0;
}

// ---- Expression analysis ----

void smt_expr(parser.expr_node* e, smt_ctx* ctx) {
    if (e == (parser.expr_node*)0) { return; }
    i32 k = e.kind;

    if (k == ek_unary) {
        if (e.uop == uop_deref && e.operand != (parser.expr_node*)0) {
            smt_check_ptr(e.operand, ctx, "pointer dereference");
        }
        smt_expr(e.operand, ctx);
        return;
    }

    if (k == ek_member) {
        if (e.object != (parser.expr_node*)0) {
            smt_check_ptr(e.object, ctx, "member access");
            smt_expr(e.object, ctx);
        }
        return;
    }

    if (k == ek_subscript) {
        if (e.object != (parser.expr_node*)0) {
            smt_check_ptr(e.object, ctx, "subscript");
            // Array bounds checking: if this is a named array with known size, validate index.
            i8* arr_name = smt_base_name(e.object);
            i32 arr_size = smt_asz_get(&ctx.arrs, arr_name);
            if (arr_size > 0 && e.index != (parser.expr_node*)0) {
                if (e.index.kind == ek_int_lit) {
                    // Constant index: prove GOOD or BAD statically.
                    i64 iv = e.index.int_val;
                    if (iv < 0 || iv >= (i64)arr_size) {
                        i8 msg[128];
                        snprintf(msg, (u64)128, "array index out of bounds (index=%lld, size=%d)", (i64)iv, arr_size);
                        smt_error(ctx, (i32)e.line, msg, arr_name);
                    }
                    // else GOOD: constant in bounds — no check needed.
                } else {
                    // UNKNOWN: dynamic index — inject runtime bounds check.
                    e.needs_rtcheck = true;
                    e.int_val = (i64)arr_size;
                    smt_need_rtcheck(ctx, (i32)e.line, "dynamic array index — bounds check injected", arr_name);
                    ctx.rtcheck_count = ctx.rtcheck_count + 1;
                }
            }
            smt_expr(e.object, ctx);
        }
        smt_expr(e.index, ctx);
        return;
    }

    if (k == ek_call) {
        i32 ai = 0;
        while (ai < e.args_len) {
            smt_expr(e.args[ai], ctx);
            ai = ai + 1;
        }
        i8* cn = smt_call_name(e);
        if (smt_is_free_call(cn) && e.args_len > 0) {
            i8* arg_name = smt_base_name(e.args[0]);
            if (arg_name != (i8*)0) {
                i32 cur = smt_pmap_get(&ctx.vars, arg_name);
                if (cur == PTR_FREED || cur == PTR_MOVED) {
                    smt_error(ctx, (i32)e.line, "double-free", arg_name);
                }
                // Mark the canonical name FREED — alias propagation handles aliases
                smt_pmap_set(&ctx.vars, arg_name, PTR_FREED);
            }
        }
        // Iterator invalidation: detect mutation methods called on a container under range-for.
        if (e.callee != (parser.expr_node*)0 && e.callee.kind == ek_member &&
                e.callee.member_name != (i8*)0 && e.callee.object != (parser.expr_node*)0) {
            i8* obj_name = smt_base_name(e.callee.object);
            if (obj_name != (i8*)0 && smt_iter_check(&ctx.iters, obj_name)) {
                i8* mn = e.callee.member_name;
                bool is_mut = (strcmp(mn, "push")   == 0) || (strcmp(mn, "pop")    == 0) ||
                              (strcmp(mn, "insert") == 0) || (strcmp(mn, "erase")  == 0) ||
                              (strcmp(mn, "clear")  == 0) || (strcmp(mn, "resize") == 0) ||
                              (strcmp(mn, "deinit") == 0);
                if (is_mut) {
                    smt_error(ctx, (i32)e.line,
                              "iterator invalidation: container mutated during range-for loop", obj_name);
                }
            }
        }
        return;
    }

    if (k == ek_assign) {
        smt_expr(e.rhs, ctx);
        i8* lname = smt_base_name(e.lhs);
        if (lname != (i8*)0) {
            if (smt_is_null_lit(e.rhs)) {
                smt_pmap_set(&ctx.vars, lname, PTR_NULL);
            } else if (e.rhs != (parser.expr_node*)0 && e.rhs.kind == ek_call) {
                i8* cn = smt_call_name(e.rhs);
                if (smt_is_alloc_call(cn)) {
                    smt_pmap_set(&ctx.vars, lname, PTR_VALID);
                } else {
                    smt_pmap_set(&ctx.vars, lname, PTR_UNKNOWN);
                }
            } else {
                i8* rname = smt_base_name(e.rhs);
                if (rname != (i8*)0) {
                    // p2 = p1 — create alias so arc_free(p1) also invalidates p2
                    smt_pmap_alias(&ctx.vars, lname, rname);
                } else {
                    smt_pmap_set(&ctx.vars, lname, PTR_UNKNOWN);
                }
            }
        }
        return;
    }

    if (k == ek_binary)  { smt_expr(e.lhs, ctx); smt_expr(e.rhs, ctx); return; }
    if (k == ek_cast)    { smt_expr(e.operand, ctx); return; }
    if (k == ek_ternary) {
        smt_expr(e.cond, ctx); smt_expr(e.then_e, ctx); smt_expr(e.else_e, ctx); return;
    }
}

// ---- Statement analysis ----

void smt_stmt(parser.ast_node* s, smt_ctx* ctx) {
    if (s == (parser.ast_node*)0) { return; }
    i32 k = s.kind;

    if (k == nd_block) {
        parser.block_stmt* blk = (parser.block_stmt*)s;
        i32 si = 0;
        while (si < blk.stmts_len) {
            smt_stmt(blk.stmts[si], ctx);
            si = si + 1;
        }
        return;
    }

    if (k == nd_expr_stmt) {
        parser.expr_stmt* es = (parser.expr_stmt*)s;
        smt_expr(es.expr, ctx);
        return;
    }

    if (k == nd_var_decl) {
        parser.var_decl* vd = (parser.var_decl*)s;
        // Record array size for bounds checking.
        if (vd.name != (i8*)0 && vd.type != (parser.type_node*)0 &&
                vd.type.array_size_ptr != (i8*)0) {
            parser.expr_node* asz_e = (parser.expr_node*)vd.type.array_size_ptr;
            if (asz_e.kind == ek_int_lit && asz_e.int_val > 0) {
                smt_asz_set(&ctx.arrs, vd.name, (i32)asz_e.int_val);
            }
        }
        if (vd.has_init && vd.init != (parser.expr_node*)0) {
            smt_expr(vd.init, ctx);
            if (vd.name != (i8*)0) {
                if (smt_is_null_lit(vd.init)) {
                    smt_pmap_set(&ctx.vars, vd.name, PTR_NULL);
                } else if (vd.init.kind == ek_call) {
                    i8* cn = smt_call_name(vd.init);
                    if (smt_is_alloc_call(cn)) {
                        smt_pmap_set(&ctx.vars, vd.name, PTR_VALID);
                    } else {
                        smt_pmap_set(&ctx.vars, vd.name, PTR_UNKNOWN);
                    }
                } else {
                    i8* rname = smt_base_name(vd.init);
                    if (rname != (i8*)0) {
                        smt_pmap_alias(&ctx.vars, vd.name, rname);
                    } else {
                        smt_pmap_set(&ctx.vars, vd.name, PTR_UNKNOWN);
                    }
                }
            }
        } else if (vd.name != (i8*)0) {
            smt_pmap_set(&ctx.vars, vd.name, PTR_UNKNOWN);
        }
        return;
    }

    if (k == nd_return_stmt) {
        parser.return_stmt* rs = (parser.return_stmt*)s;
        if (rs.has_val && rs.val != (parser.expr_node*)0) { smt_expr(rs.val, ctx); }
        return;
    }

    if (k == nd_if_stmt) {
        parser.if_stmt* is = (parser.if_stmt*)s;
        smt_expr(is.cond, ctx);
        // Save pre-branch state and process branches independently.
        // Then merge: pointer FREED only if freed on BOTH paths.
        smt_pmap pre_state;
        smt_pmap_copy(&pre_state, &ctx.vars);
        smt_stmt(is.then_body, ctx);
        smt_pmap after_then;
        smt_pmap_copy(&after_then, &ctx.vars);
        smt_pmap_copy(&ctx.vars, &pre_state);
        smt_stmt(is.else_body, ctx);
        smt_pmap after_else;
        smt_pmap_copy(&after_else, &ctx.vars);
        smt_pmap_merge(&pre_state, &after_then, &after_else, &ctx.vars);
        return;
    }

    if (k == nd_while_stmt) {
        parser.while_stmt* ws = (parser.while_stmt*)s;
        smt_expr(ws.cond, ctx);
        smt_stmt(ws.body, ctx);
        return;
    }

    if (k == nd_for_stmt) {
        parser.for_stmt* fs = (parser.for_stmt*)s;
        smt_stmt(fs.init, ctx);
        smt_expr(fs.cond, ctx);
        smt_expr(fs.step, ctx);
        smt_stmt(fs.body, ctx);
        return;
    }

    if (k == nd_for_range_stmt) {
        parser.for_range_stmt* frs = (parser.for_range_stmt*)s;
        smt_expr(frs.range, ctx);
        // Track the range container for iterator invalidation detection.
        i8* container = smt_base_name(frs.range);
        smt_iter_add(&ctx.iters, container);
        smt_stmt(frs.body, ctx);
        smt_iter_remove(&ctx.iters, container);
        return;
    }
}

// ---- Function and program analysis ----

void smt_analyze_func(parser.func_decl* fd, smt_ctx* ctx) {
    if (fd == (parser.func_decl*)0 || !fd.has_body) { return; }
    // Reset per-function state but preserve ctx.arrs (it holds global array sizes
    // pre-populated by smt_analyze so they remain visible inside each function body).
    smt_pmap_init(&ctx.vars);
    smt_iter_init(&ctx.iters);
    ctx.had_error     = false;
    ctx.func_name     = fd.name;
    ctx.warn_count    = 0;
    ctx.rtcheck_count = 0;
    i32 pi = 0;
    while (pi < fd.params_len) {
        parser.param_decl p = fd.params[pi];
        if (p.name != (i8*)0) { smt_pmap_set(&ctx.vars, p.name, PTR_UNKNOWN); }
        pi = pi + 1;
    }
    if (fd.body != (i8*)0) {
        parser.block_stmt* blk = (parser.block_stmt*)fd.body;
        smt_stmt((parser.ast_node*)blk, ctx);
    }
}

i32 smt_analyze(parser.program_node* prog) {
    if (prog == (parser.program_node*)0) { return 0; }
    smt_ctx ctx;
    smt_ctx_init(&ctx, (i8*)0);

    // First pass: collect global array sizes so bounds checks work in all functions.
    i32 gi = 0;
    while (gi < prog.decls_len) {
        parser.ast_node* d = prog.decls[gi];
        if (d != (parser.ast_node*)0 && d.kind == nd_var_decl) {
            parser.var_decl* gvd = (parser.var_decl*)d;
            if (gvd.name != (i8*)0 && gvd.type != (parser.type_node*)0 &&
                    gvd.type.array_size_ptr != (i8*)0) {
                parser.expr_node* asz_e = (parser.expr_node*)gvd.type.array_size_ptr;
                if (asz_e.kind == ek_int_lit && asz_e.int_val > 0) {
                    smt_asz_set(&ctx.arrs, gvd.name, (i32)asz_e.int_val);
                }
            }
        }
        gi = gi + 1;
    }

    // Save global array sizes to restore before each function (functions add local arrs).
    smt_asz global_arrs;
    smt_asz_copy(&global_arrs, &ctx.arrs);

    // Second pass: analyze each function.
    i32 total_errors = 0;
    i32 i = 0;
    while (i < prog.decls_len) {
        parser.ast_node* d = prog.decls[i];
        if (d != (parser.ast_node*)0 && d.kind == nd_func_decl) {
            parser.func_decl* fd = (parser.func_decl*)d;
            // Restore global array sizes before each function so local arrays
            // from a previous function don't bleed into this one.
            smt_asz_copy(&ctx.arrs, &global_arrs);
            smt_analyze_func(fd, &ctx);
            if (ctx.had_error) { total_errors = total_errors + 1; }
        }
        i = i + 1;
    }
    return total_errors;
}

} // namespace smt
