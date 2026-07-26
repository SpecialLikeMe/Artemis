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
    let names: [256]*i8;
    let states: [256]i32;
    let alias_of: [256]*i8;   // alias_of[i] == canonical name, or null if no alias
    let len: i32;
}

// Loop bodies are re-analysed until the pointer state stops changing. The lattice
// (VALID/FREED/MOVED → UNKNOWN) only ever widens, so this converges in a couple of
// rounds; the bound is a safety net against a state that oscillates.
comptime i32 SMT_LOOP_FIXPOINT_MAX = 8;

fn smt_pmap_init(m: *smt_pmap) void { m.len = 0; }

// True when two states are identical — the fixpoint test for loop bodies.
fn smt_pmap_equal(a: *smt_pmap, b: *smt_pmap) bool {
    if (a.len != b.len) { return false; }
    let mut i: i32= 0;
    while (i < a.len) {
        if (a.states[i] != b.states[i]) { return false; }
        let mut an: *i8= a.names[i];
        let mut bn: *i8= b.names[i];
        if ((an == (i8*)0) != (bn == (i8*)0)) { return false; }
        if (an != (i8*)0 && strcmp(an, bn) != 0) { return false; }
        let mut aa: *i8= a.alias_of[i];
        let mut ba: *i8= b.alias_of[i];
        if ((aa == (i8*)0) != (ba == (i8*)0)) { return false; }
        if (aa != (i8*)0 && strcmp(aa, ba) != 0) { return false; }
        i = i + 1;
    }
    return true;
}

// Copy pmap state (for save/restore around if-branches).
fn smt_pmap_copy(dst: *smt_pmap, src: *smt_pmap) void {
    dst.len = src.len;
    let mut i: i32= 0;
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
fn smt_pmap_merge(pre: *smt_pmap, after_then: *smt_pmap, after_else: *smt_pmap, result: *smt_pmap) void {
    smt_pmap_copy(result, pre);
    let mut i: i32= 0;
    while (i < pre.len) {
        let mut nm: *i8= pre.names[i];
        if (nm != (i8*)0) {
            let mut s_then: i32= smt_pmap_get(after_then, nm);
            let mut s_else: i32= smt_pmap_get(after_else, nm);
            let mut s_pre: i32= pre.states[i];
            if (s_then == PTR_FREED && s_else == PTR_FREED) {
                result.states[i] = PTR_FREED;
            } else if ((s_then == PTR_FREED || s_else == PTR_FREED) && s_pre != PTR_FREED) {
                result.states[i] = PTR_UNKNOWN;
            } else if (s_then != s_pre || s_else != s_pre) {
                // State changed on at least one branch — post-if state is uncertain
                result.states[i] = PTR_UNKNOWN;
            } else {
                result.states[i] = s_pre;
            }
        }
        i = i + 1;
    }
}

// Resolve to the canonical slot index, following one alias level.
fn smt_pmap_canon_idx(m: *smt_pmap, name: *i8) i32 {
    let mut i: i32= 0;
    while (i < m.len) {
        if (m.names[i] != (i8*)0 && strcmp(m.names[i], name) == 0) {
            if (m.alias_of[i] != (i8*)0) {
                // Follow alias chain to canonical entry (iterate to handle multi-hop chains)
                let mut hops: i32= 0;
                let mut cur: *i8= m.alias_of[i];
                while (cur != (i8*)0 && hops < 256) {
                    let mut j: i32= 0;
                    let mut found_j: i32= -1;
                    while (j < m.len) {
                        if (m.names[j] != (i8*)0 && strcmp(m.names[j], cur) == 0) {
                            found_j = j; break;
                        }
                        j = j + 1;
                    }
                    if (found_j < 0) { break; }
                    if (m.alias_of[found_j] == (i8*)0) { return found_j; }
                    cur = m.alias_of[found_j];
                    hops = hops + 1;
                }
            }
            return i;
        }
        i = i + 1;
    }
    return -1;
}

fn smt_pmap_get(m: *smt_pmap, name: *i8) i32 {
    if (name == (i8*)0) { return PTR_UNKNOWN; }
    let mut ci: i32= smt_pmap_canon_idx(m, name);
    if (ci >= 0) { return m.states[ci]; }
    return PTR_UNKNOWN;
}

fn smt_pmap_set(m: *smt_pmap, name: *i8, state: i32) void {
    if (name == (i8*)0) { return; }
    let mut i: i32= 0;
    // Find existing entry and update it (clear alias on explicit set)
    while (i < m.len) {
        if (m.names[i] != (i8*)0 && strcmp(m.names[i], name) == 0) {
            m.states[i]   = state;
            m.alias_of[i] = (i8*)0;  // explicit set breaks alias
            // Propagate FREED/MOVED to all slots aliased to this name
            if (state == PTR_FREED || state == PTR_MOVED) {
                let mut j: i32= 0;
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
    } else {
        printf("SMT warning: pointer map full (256 entries); '%s' will not be tracked\n", name);
    }
}

// Record that `alias` points to the same allocation as `canon`.
// Used when p2 = p1 — any subsequent arc_free(p1) also invalidates p2.
fn smt_pmap_alias(m: *smt_pmap, alias_name: *i8, canon_name: *i8) void {
    if (alias_name == (i8*)0 || canon_name == (i8*)0) { return; }
    // Resolve the canonical name through existing aliases
    let mut ci: i32= smt_pmap_canon_idx(m, canon_name);
    let mut resolved_canon: *i8= (ci >= 0) ? m.names[ci] : canon_name;

    let mut i: i32= 0;
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
    let names: [64]*i8;
    let sizes: [64]i32;
    let len: i32;
}

fn smt_asz_init(m: *smt_asz) void { m.len = 0; }

fn smt_asz_get(m: *smt_asz, name: *i8) i32 {
    if (name == (i8*)0) { return 0; }
    let mut i: i32= 0;
    while (i < m.len) {
        if (m.names[i] != (i8*)0 && strcmp(m.names[i], name) == 0) { return m.sizes[i]; }
        i = i + 1;
    }
    return 0;
}

fn smt_asz_set(m: *smt_asz, name: *i8, sz: i32) void {
    if (name == (i8*)0) { return; }
    let mut i: i32= 0;
    while (i < m.len) {
        if (m.names[i] != (i8*)0 && strcmp(m.names[i], name) == 0) { m.sizes[i] = sz; return; }
        i = i + 1;
    }
    if (m.len >= 64) {
        // Dropping silently would leave the array untracked and its subscripts
        // unchecked, which looks identical to "proven safe". Say so instead.
        printf("SMT warning: array-size table full (64 entries); bounds of '%s' will not be checked\n", name);
        return;
    }
    m.names[m.len] = name;
    m.sizes[m.len] = sz;
    m.len = m.len + 1;
}

fn smt_asz_copy(dst: *smt_asz, src: *smt_asz) void {
    dst.len = src.len;
    let mut i: i32= 0;
    while (i < src.len) { dst.names[i] = src.names[i]; dst.sizes[i] = src.sizes[i]; i = i + 1; }
}

// ---- Iterator invalidation set — containers currently under range-for ----
struct smt_iter {
    let names: [32]*i8;
    let len: i32;
}

fn smt_iter_init(s: *smt_iter) void { s.len = 0; }

fn smt_iter_check(s: *smt_iter, name: *i8) bool {
    if (name == (i8*)0) { return false; }
    let mut i: i32= 0;
    while (i < s.len) {
        if (s.names[i] != (i8*)0 && strcmp(s.names[i], name) == 0) { return true; }
        i = i + 1;
    }
    return false;
}

fn smt_iter_add(s: *smt_iter, name: *i8) void {
    if (name == (i8*)0 || smt_iter_check(s, name)) { return; }
    if (s.len >= 32) {
        printf("SMT warning: iterator table full (32 entries); '%s' will not be checked for invalidation\n", name);
        return;
    }
    s.names[s.len] = name;
    s.len = s.len + 1;
}

fn smt_iter_remove(s: *smt_iter, name: *i8) void {
    if (name == (i8*)0) { return; }
    let mut i: i32= 0;
    while (i < s.len) {
        if (s.names[i] != (i8*)0 && strcmp(s.names[i], name) == 0) {
            let mut j: i32= i;
            while (j < s.len - 1) { s.names[j] = s.names[j + 1]; j = j + 1; }
            s.len = s.len - 1;
            return;
        }
        i = i + 1;
    }
}

// ---- SMT analysis context ----
struct smt_ctx {
    let vars: smt_pmap;
    let arrs: smt_asz;   // array size map (for bounds checking)
    let iters: smt_iter;  // containers currently being iterated (invalidation detection)
    let had_error: bool;
    let func_name: *i8;
    let warn_count: i32;
    let error_count: i32;   // proven-UNSAFE errors (distinct from uncertain warnings)
    let rtcheck_count: i32;  // locations that need runtime check injection
}

fn smt_ctx_init(ctx: *smt_ctx, fn_ref: *i8) void {
    smt_pmap_init(&ctx.vars);
    smt_asz_init(&ctx.arrs);
    smt_iter_init(&ctx.iters);
    ctx.had_error    = false;
    ctx.func_name    = fn_ref;
    ctx.warn_count   = 0;
    ctx.error_count  = 0;
    ctx.rtcheck_count = 0;
}

// Emit a proved-UNSAFE compile error.
fn smt_error(ctx: *smt_ctx, line: i32, msg: *i8, var: *i8) void {
    let mut fn_ref: *i8= ctx.func_name != (i8*)0 ? ctx.func_name : "<unknown>";
    if (var != (i8*)0) {
        printf("SMT error: %s (line %d, func '%s', var '%s')\n", msg, line, fn_ref, var);
    } else {
        printf("SMT error: %s (line %d, func '%s')\n", msg, line, fn_ref);
    }
    ctx.error_count = ctx.error_count + 1;
    ctx.had_error  = true;
}

// Emit an UNKNOWN note — location will need a runtime check.
fn smt_need_rtcheck(ctx: *smt_ctx, line: i32, msg: *i8, var: *i8) void {
    let mut fn_ref: *i8= ctx.func_name != (i8*)0 ? ctx.func_name : "<unknown>";
    if (var != (i8*)0) {
        printf("SMT note: runtime check needed: %s (line %d, func '%s', var '%s')\n",
               msg, line, fn_ref, var);
    } else {
        printf("SMT note: runtime check needed: %s (line %d, func '%s')\n",
               msg, line, fn_ref);
    }
    ctx.rtcheck_count = ctx.rtcheck_count + 1;
}

// ---- Helpers ----

fn smt_base_name(e: *parser.expr_node) *i8 {
    if (e == (parser.expr_node*)0) { return (i8*)0; }
    if (e.kind == ek_identifier) { return e.str_val; }
    return (i8*)0;
}

fn smt_is_null_lit(e: *parser.expr_node) bool {
    if (e == (parser.expr_node*)0) { return false; }
    if (e.kind == ek_int_lit && e.int_val == 0) { return true; }
    if (e.kind == ek_null_lit) { return true; }
    if (e.kind == ek_cast || e.kind == ek_cast_as) { return smt_is_null_lit(e.operand); }
    return false;
}

fn smt_is_free_call(name: *i8) bool {
    if (name == (i8*)0) { return false; }
    return strcmp(name, "free") == 0;
}

fn smt_is_alloc_call(name: *i8) bool {
    if (name == (i8*)0) { return false; }
    if (strcmp(name, "malloc") == 0)  { return true; }
    if (strcmp(name, "calloc") == 0)  { return true; }
    if (strcmp(name, "realloc") == 0) { return true; }
    return false;
}

// ---- Forward declarations ----
fn smt_expr(e: *parser.expr_node, ctx: *smt_ctx) void;
fn smt_stmt(s: *parser.ast_node, ctx: *smt_ctx) void;

// Walk a condition expression and, for each 'ptr != null' sub-check, promote ptr from PTR_NULL
// to PTR_UNKNOWN so the then-branch doesn't report a false-positive null dereference.
fn smt_narrow_nonnull(cond: *parser.expr_node, ctx: *smt_ctx) void {
    if (cond == (parser.expr_node*)0) { return; }
    // Handle && chains
    if (cond.kind == ek_binary && cond.bop == 11) { // bop_log_and = 11
        smt_narrow_nonnull(cond.lhs, ctx);
        smt_narrow_nonnull(cond.rhs, ctx);
        return;
    }
    // Handle ptr != null or null != ptr (bop_ne = 6)
    if (cond.kind == ek_binary && cond.bop == 6) {
        let mut lhs: *parser.expr_node= cond.lhs;
        let mut rhs: *parser.expr_node= cond.rhs;
        let mut vname: *i8= (i8*)0;
        if (smt_is_null_lit(rhs) && lhs != (parser.expr_node*)0 && lhs.kind == ek_identifier) {
            vname = lhs.str_val;
        } else if (smt_is_null_lit(lhs) && rhs != (parser.expr_node*)0 && rhs.kind == ek_identifier) {
            vname = rhs.str_val;
        }
        if (vname != (i8*)0) {
            let mut st: i32= smt_pmap_get(&ctx.vars, vname);
            if (st == PTR_NULL) { smt_pmap_set(&ctx.vars, vname, PTR_UNKNOWN); }
        }
    }
}

// ---- Pointer safety check ----
// Returns: SMT_SAFE, SMT_UNSAFE, or SMT_UNKNOWN

fn smt_check_outcome(ctx: *smt_ctx, vname: *i8) i32 {
    if (vname == (i8*)0) { return SMT_UNKNOWN; }
    let mut st: i32= smt_pmap_get(&ctx.vars, vname);
    if (st == PTR_FREED || st == PTR_MOVED) { return SMT_UNSAFE; }
    if (st == PTR_NULL)                     { return SMT_UNSAFE; }
    if (st == PTR_VALID)                    { return SMT_SAFE; }
    return SMT_UNKNOWN;
}

fn smt_check_ptr(e: *parser.expr_node, ctx: *smt_ctx, context: *i8) void {
    let mut vname: *i8= smt_base_name(e);
    if (vname == (i8*)0) {
        // Can't name it — mark the expression itself as needing a runtime check
        if (e != (parser.expr_node*)0) { e.needs_rtcheck = true; }
        return;
    }
    let mut outcome: i32= smt_check_outcome(ctx, vname);
    if (outcome == SMT_UNSAFE) {
        let mut st: i32= smt_pmap_get(&ctx.vars, vname);
        if (st == PTR_FREED || st == PTR_MOVED) {
            let mut msg: [256]i8;
            snprintf(msg, (u64)256, "use-after-free in %s", context);
            smt_error(ctx, (i32)e.line, msg, vname);
        } else {
            let mut msg: [256]i8;
            snprintf(msg, (u64)256, "null dereference in %s", context);
            smt_error(ctx, (i32)e.line, msg, vname);
        }
    } else if (outcome == SMT_UNKNOWN) {
        // Tag the expression — the IR stage will emit a null-guard branch
        if (e != (parser.expr_node*)0) { e.needs_rtcheck = true; }
    }
}

fn smt_call_name(e: *parser.expr_node) *i8 {
    if (e == (parser.expr_node*)0) { return (i8*)0; }
    if (e.func_resolved_name != (i8*)0) { return e.func_resolved_name; }
    if (e.callee != (parser.expr_node*)0 && e.callee.kind == ek_identifier) {
        return e.callee.str_val;
    }
    return (i8*)0;
}

// ---- Expression analysis ----

fn smt_expr(e: *parser.expr_node, ctx: *smt_ctx) void {
    if (e == (parser.expr_node*)0) { return; }
    let mut k: i32= e.kind;

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
            let mut arr_name: *i8= smt_base_name(e.object);
            let mut arr_size: i32= smt_asz_get(&ctx.arrs, arr_name);
            if (arr_size > 0 && e.index != (parser.expr_node*)0) {
                if (e.index.kind == ek_int_lit) {
                    // Constant index: prove GOOD or BAD statically.
                    let mut iv: i64= e.index.int_val;
                    if (iv < 0 || iv >= (i64)arr_size) {
                        let mut msg: [128]i8;
                        snprintf(msg, (u64)128, "array index out of bounds (index=%lld, size=%d)", (i64)iv, arr_size);
                        smt_error(ctx, (i32)e.line, msg, arr_name);
                    }
                    // else GOOD: constant in bounds — no check needed.
                } else {
                    // UNKNOWN: dynamic index — inject runtime bounds check.
                    e.needs_rtcheck = true;
                    e.int_val = (i64)arr_size;
                    smt_need_rtcheck(ctx, (i32)e.line, "dynamic array index — bounds check injected", arr_name);
                }
            }
            smt_expr(e.object, ctx);
        }
        smt_expr(e.index, ctx);
        return;
    }

    if (k == ek_call) {
        let mut ai: i32= 0;
        while (ai < e.args_len) {
            smt_expr(e.args[ai], ctx);
            // &var passed to function — function may write through the pointer, so invalidate state
            let mut _a: *parser.expr_node= e.args[ai];
            if (_a != (parser.expr_node*)0 && _a.kind == ek_unary && _a.uop == 9) { // addr_of
                let mut pname: *i8= smt_base_name(_a.operand);
                if (pname != (i8*)0) { smt_pmap_set(&ctx.vars, pname, PTR_UNKNOWN); }
            }
            ai = ai + 1;
        }
        let mut cn: *i8= smt_call_name(e);
        if (smt_is_free_call(cn) && e.args_len > 0) {
            let mut arg_name: *i8= smt_base_name(e.args[0]);
            if (arg_name != (i8*)0) {
                let mut cur: i32= smt_pmap_get(&ctx.vars, arg_name);
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
            let mut obj_name: *i8= smt_base_name(e.callee.object);
            if (obj_name != (i8*)0 && smt_iter_check(&ctx.iters, obj_name)) {
                let mut mn: *i8= e.callee.member_name;
                let mut is_mut: bool= (strcmp(mn, "push")   == 0) || (strcmp(mn, "pop")    == 0) ||
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
        let mut lname: *i8= smt_base_name(e.lhs);
        if (lname != (i8*)0) {
            if (smt_is_null_lit(e.rhs)) {
                smt_pmap_set(&ctx.vars, lname, PTR_NULL);
            } else if (e.rhs != (parser.expr_node*)0 && e.rhs.kind == ek_call) {
                let mut cn: *i8= smt_call_name(e.rhs);
                if (smt_is_alloc_call(cn)) {
                    smt_pmap_set(&ctx.vars, lname, PTR_VALID);
                } else {
                    smt_pmap_set(&ctx.vars, lname, PTR_UNKNOWN);
                }
            } else {
                let mut rname: *i8= smt_base_name(e.rhs);
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
    if (k == ek_cast || k == ek_cast_as) { smt_expr(e.operand, ctx); return; }
    if (k == ek_match_expr) { return; }
    if (k == ek_ternary) {
        smt_expr(e.cond, ctx); smt_expr(e.then_e, ctx); smt_expr(e.else_e, ctx); return;
    }
}

// ---- Statement analysis ----

fn smt_stmt(s: *parser.ast_node, ctx: *smt_ctx) void {
    if (s == (parser.ast_node*)0) { return; }
    let mut k: i32= s.kind;

    if (k == nd_block) {
        let mut blk: *parser.block_stmt= (parser.block_stmt*)s;
        let mut si: i32= 0;
        while (si < blk.stmts_len) {
            smt_stmt(blk.stmts[si], ctx);
            si = si + 1;
        }
        return;
    }

    if (k == nd_expr_stmt) {
        let mut es: *parser.expr_stmt= (parser.expr_stmt*)s;
        smt_expr(es.expr, ctx);
        return;
    }

    if (k == nd_var_decl) {
        let mut vd: *parser.var_decl= (parser.var_decl*)s;
        // Record array size for bounds checking.
        if (vd.name != (i8*)0 && vd.type != (parser.type_node*)0 &&
                vd.type.array_size_ptr != (i8*)0) {
            let mut asz_e: *parser.expr_node= (parser.expr_node*)vd.type.array_size_ptr;
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
                    let mut cn: *i8= smt_call_name(vd.init);
                    if (smt_is_alloc_call(cn)) {
                        smt_pmap_set(&ctx.vars, vd.name, PTR_VALID);
                    } else {
                        smt_pmap_set(&ctx.vars, vd.name, PTR_UNKNOWN);
                    }
                } else {
                    let mut rname: *i8= smt_base_name(vd.init);
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
        let mut rs: *parser.return_stmt= (parser.return_stmt*)s;
        if (rs.has_val && rs.val != (parser.expr_node*)0) { smt_expr(rs.val, ctx); }
        return;
    }

    if (k == nd_if_stmt) {
        let mut is: *parser.if_stmt= (parser.if_stmt*)s;
        smt_expr(is.cond, ctx);
        // Save pre-branch state and process branches independently.
        // Then merge: pointer FREED only if freed on BOTH paths.
        let mut pre_state: smt_pmap;
        smt_pmap_copy(&pre_state, &ctx.vars);
        // Narrow null-state for ptr != null checks in the condition
        smt_narrow_nonnull(is.cond, ctx);
        smt_stmt(is.then_body, ctx);
        let mut after_then: smt_pmap;
        smt_pmap_copy(&after_then, &ctx.vars);
        smt_pmap_copy(&ctx.vars, &pre_state);
        smt_stmt(is.else_body, ctx);
        let mut after_else: smt_pmap;
        smt_pmap_copy(&after_else, &ctx.vars);
        smt_pmap_merge(&pre_state, &after_then, &after_else, &ctx.vars);
        return;
    }

    if (k == nd_while_stmt) {
        let mut ws: *parser.while_stmt= (parser.while_stmt*)s;
        // Iterate the body to a fixpoint so a pointer freed on iteration N is seen
        // as freed when iteration N+1 uses it. One pass would miss that entirely.
        let mut wi: i32= 0;
        while (wi < SMT_LOOP_FIXPOINT_MAX) {
            let mut before: smt_pmap;
            smt_pmap_copy(&before, &ctx.vars);
            smt_expr(ws.cond, ctx);
            smt_stmt(ws.body, ctx);
            if (smt_pmap_equal(&before, &ctx.vars)) { return; }
            wi = wi + 1;
        }
        return;
    }

    if (k == nd_for_stmt) {
        let mut fs: *parser.for_stmt= (parser.for_stmt*)s;
        smt_stmt(fs.init, ctx);
        let mut fi: i32= 0;
        while (fi < SMT_LOOP_FIXPOINT_MAX) {
            let mut before: smt_pmap;
            smt_pmap_copy(&before, &ctx.vars);
            smt_expr(fs.cond, ctx);
            smt_stmt(fs.body, ctx);
            smt_expr(fs.step, ctx);
            if (smt_pmap_equal(&before, &ctx.vars)) { return; }
            fi = fi + 1;
        }
        return;
    }

    if (k == nd_for_range_stmt) {
        let mut frs: *parser.for_range_stmt= (parser.for_range_stmt*)s;
        smt_expr(frs.range, ctx);
        // Track the range container for iterator invalidation detection.
        let mut container: *i8= smt_base_name(frs.range);
        smt_iter_add(&ctx.iters, container);
        let mut ri: i32= 0;
        while (ri < SMT_LOOP_FIXPOINT_MAX) {
            let mut before: smt_pmap;
            smt_pmap_copy(&before, &ctx.vars);
            smt_stmt(frs.body, ctx);
            if (smt_pmap_equal(&before, &ctx.vars)) { ri = SMT_LOOP_FIXPOINT_MAX; }
            else { ri = ri + 1; }
        }
        smt_iter_remove(&ctx.iters, container);
        return;
    }

    // match: each arm is an independent path. Analyse every arm from the same
    // pre-state, then merge — without this the assignments inside arms are
    // invisible and a variable keeps its pre-match state (e.g. a null
    // initializer), producing false null-dereference reports after the match.
    if (k == nd_match_stmt) {
        let mut ms: *parser.match_stmt= (parser.match_stmt*)s;
        smt_expr((parser.expr_node*)ms.subject, ctx);
        let mut pre_m: smt_pmap;
        smt_pmap_copy(&pre_m, &ctx.vars);
        let mut acc: smt_pmap;
        smt_pmap_copy(&acc, &ctx.vars);
        let mut ai: i32= 0;
        while (ai < ms.arms_len) {
            let mut arm: *parser.match_arm= ms.arms[ai];
            if (arm != (parser.match_arm*)0) {
                smt_pmap_copy(&ctx.vars, &pre_m);
                if (arm.guard != (i8*)0) { smt_expr((parser.expr_node*)arm.guard, ctx); }
                smt_stmt(arm.body, ctx);
                let mut after_arm: smt_pmap;
                smt_pmap_copy(&after_arm, &ctx.vars);
                let mut merged: smt_pmap;
                smt_pmap_merge(&pre_m, &acc, &after_arm, &merged);
                smt_pmap_copy(&acc, &merged);
            }
            ai = ai + 1;
        }
        smt_pmap_copy(&ctx.vars, &acc);
        return;
    }

    // switch: same treatment as match — every case body is a distinct path.
    if (k == nd_switch_stmt) {
        let mut sw: *parser.switch_stmt= (parser.switch_stmt*)s;
        smt_expr(sw.val, ctx);
        let mut pre_s: smt_pmap;
        smt_pmap_copy(&pre_s, &ctx.vars);
        let mut acc_s: smt_pmap;
        smt_pmap_copy(&acc_s, &ctx.vars);
        let mut ci: i32= 0;
        while (ci < sw.cases_len) {
            smt_pmap_copy(&ctx.vars, &pre_s);
            smt_stmt((parser.ast_node*)sw.case_bodies[ci], ctx);
            let mut after_case: smt_pmap;
            smt_pmap_copy(&after_case, &ctx.vars);
            let mut merged_s: smt_pmap;
            smt_pmap_merge(&pre_s, &acc_s, &after_case, &merged_s);
            smt_pmap_copy(&acc_s, &merged_s);
            ci = ci + 1;
        }
        smt_pmap_copy(&ctx.vars, &acc_s);
        return;
    }

    // defer/errdefer bodies run on scope exit — analyse them so a free() inside a
    // defer is not invisible to the use-after-free checks.
    if (k == nd_defer_stmt || k == nd_errdefer_stmt) {
        let mut ds: *parser.defer_stmt= (parser.defer_stmt*)s;
        if (ds.is_block && ds.blk != (i8*)0) { smt_stmt((parser.ast_node*)ds.blk, ctx); }
        else if (ds.expr != (parser.expr_node*)0) { smt_expr(ds.expr, ctx); }
        return;
    }
}

// ---- Function and program analysis ----

fn smt_analyze_func(fd: *parser.func_decl, ctx: *smt_ctx) void {
    if (fd == (parser.func_decl*)0 || !fd.has_body) { return; }
    // Reset per-function state but preserve ctx.arrs (it holds global array sizes
    // pre-populated by smt_analyze so they remain visible inside each function body).
    smt_pmap_init(&ctx.vars);
    smt_iter_init(&ctx.iters);
    ctx.had_error     = false;
    ctx.func_name     = fd.name;
    ctx.warn_count    = 0;
    ctx.error_count   = 0;
    ctx.rtcheck_count = 0;
    let mut pi: i32= 0;
    while (pi < fd.params_len) {
        let mut p: parser.param_decl= fd.params[pi];
        if (p.name != (i8*)0) { smt_pmap_set(&ctx.vars, p.name, PTR_UNKNOWN); }
        pi = pi + 1;
    }
    if (fd.body != (i8*)0) {
        let mut blk: *parser.block_stmt= (parser.block_stmt*)fd.body;
        smt_stmt((parser.ast_node*)blk, ctx);
    }
}

// Recursively analyze all func_decls in a declaration list (including nested namespace/istruc).
fn smt_analyze_decl_list(decls: **parser.ast_node, decls_len: i32, ctx: *smt_ctx, global_arrs: *smt_asz, total_errors: *i32) void {
    let mut i: i32= 0;
    while (i < decls_len) {
        let mut d: *parser.ast_node= decls[i];
        if (d != (parser.ast_node*)0) {
            if (d.kind == nd_func_decl) {
                let mut fd: *parser.func_decl= (parser.func_decl*)d;
                smt_asz_copy(&ctx.arrs, global_arrs);
                smt_analyze_func(fd, ctx);
                if (ctx.had_error) { *total_errors = *total_errors + 1; }
            } else if (d.kind == nd_namespace_decl) {
                // Recurse into namespace/istruc children
                let mut nd: *parser.namespace_decl= (parser.namespace_decl*)d;
                smt_analyze_decl_list(nd.decls, nd.decls_len, ctx, global_arrs, total_errors);
            }
        }
        i = i + 1;
    }
}

fn smt_analyze(prog: *parser.program_node) i32 {
    if (prog == (parser.program_node*)0) { return 0; }
    let mut ctx: smt_ctx;
    smt_ctx_init(&ctx, (i8*)0);

    // First pass: collect global array sizes so bounds checks work in all functions.
    let mut gi: i32= 0;
    while (gi < prog.decls_len) {
        let mut d: *parser.ast_node= prog.decls[gi];
        if (d != (parser.ast_node*)0 && d.kind == nd_var_decl) {
            let mut gvd: *parser.var_decl= (parser.var_decl*)d;
            if (gvd.name != (i8*)0 && gvd.type != (parser.type_node*)0 &&
                    gvd.type.array_size_ptr != (i8*)0) {
                let mut asz_e: *parser.expr_node= (parser.expr_node*)gvd.type.array_size_ptr;
                if (asz_e.kind == ek_int_lit && asz_e.int_val > 0) {
                    smt_asz_set(&ctx.arrs, gvd.name, (i32)asz_e.int_val);
                }
            }
        }
        gi = gi + 1;
    }

    // Save global array sizes to restore before each function (functions add local arrs).
    let mut global_arrs: smt_asz;
    smt_asz_copy(&global_arrs, &ctx.arrs);

    // Second pass: analyze all functions (including methods in namespaces and istrucs).
    let mut total_errors: i32= 0;
    smt_analyze_decl_list(prog.decls, prog.decls_len, &ctx, &global_arrs, &total_errors);
    return total_errors;
}

} // namespace smt
