// compiler/mir/lower.arc — AST → MIR lowering pass.
//
// Walks the program AST and emits three-address MIR instructions.
// Compound expressions are split into temporaries; loops become label/branch form.
// Currently handles: arithmetic, comparisons, assignments, calls, return,
// if/else, while loops, for-range loops, and local variable declarations.

namespace mir {

// ---- Lowering context ----

// Loop targets are kept on a stack so `break`/`continue` inside nested loops branch
// to the right labels; without it both statements lower to nothing and the loop
// becomes unconditional in MIR.
comptime i32 MIR_MAX_LOOP_DEPTH = 64;

struct lower_ctx {
    let func: *mir_func;
    let cur_block: *mir_block;
    let temp_counter: i32;
    let label_counter: i32;
    let break_lbls: [MIR_MAX_LOOP_DEPTH]*i8;
    let cont_lbls: [MIR_MAX_LOOP_DEPTH]*i8;
    let loop_depth: i32;
}

fn lctx_init(ctx: *lower_ctx, func: *mir_func) void {
    ctx.func = func;
    ctx.cur_block = (mir_block*)0;
    ctx.temp_counter = 0;
    ctx.label_counter = 0;
    ctx.loop_depth = 0;
}

fn lctx_push_loop(ctx: *lower_ctx, brk: *i8, cont: *i8) void {
    if (ctx.loop_depth >= MIR_MAX_LOOP_DEPTH) { return; }
    ctx.break_lbls[ctx.loop_depth] = brk;
    ctx.cont_lbls[ctx.loop_depth]  = cont;
    ctx.loop_depth = ctx.loop_depth + 1;
}

fn lctx_pop_loop(ctx: *lower_ctx) void {
    if (ctx.loop_depth > 0) { ctx.loop_depth = ctx.loop_depth - 1; }
}

fn lctx_break_lbl(ctx: *lower_ctx) *i8 {
    if (ctx.loop_depth <= 0) { return (i8*)0; }
    return ctx.break_lbls[ctx.loop_depth - 1];
}

fn lctx_cont_lbl(ctx: *lower_ctx) *i8 {
    if (ctx.loop_depth <= 0) { return (i8*)0; }
    return ctx.cont_lbls[ctx.loop_depth - 1];
}

// Allocate a new temporary name.
fn fresh_temp(ctx: *lower_ctx) *i8 {
    let mut buf: [32]i8;
    afmt(buf, 32u, "%%t%d", .{ ctx.temp_counter });
    ctx.temp_counter = ctx.temp_counter + 1;
    return lexer.str_dup(buf);
}

// Allocate a new label name.
fn fresh_label(ctx: *lower_ctx, prefix: *i8) *i8 {
    let mut buf: [64]i8;
    afmt(buf, 64u, "%s%d", .{ prefix != (i8*)0 ? prefix : "lbl", ctx.label_counter });
    ctx.label_counter = ctx.label_counter + 1;
    return lexer.str_dup(buf);
}

// ---- Block helpers ----

fn new_block(name: *i8) *mir_block {
    let mut b: *mir_block= (mir_block*)arc_malloc(sizeof(mir__NS_mir_block));
    b.name = name;
    b.instrs_cap = 16;
    b.instrs_len = 0;
    b.instrs = (mir_instr**)arc_malloc(sizeof(i8*) * (u64)16);
    return b;
}

fn block_push(b: *mir_block, ins: *mir_instr) void {
    if (b.instrs_len >= b.instrs_cap) {
        b.instrs_cap = b.instrs_cap * 2;
        b.instrs = (mir_instr**)arc_realloc((i8*)b.instrs, sizeof(i8*) * (u64)b.instrs_cap);
    }
    b.instrs[b.instrs_len] = ins;
    b.instrs_len = b.instrs_len + 1;
}

fn func_push_block(f: *mir_func, b: *mir_block) void {
    if (f.blocks_len >= f.blocks_cap) {
        f.blocks_cap = f.blocks_cap * 2;
        f.blocks = (mir_block**)arc_realloc((i8*)f.blocks, sizeof(i8*) * (u64)f.blocks_cap);
    }
    f.blocks[f.blocks_len] = b;
    f.blocks_len = f.blocks_len + 1;
}

fn module_push_func(m: *mir_module, f: *mir_func) void {
    if (m.funcs_len >= m.funcs_cap) {
        m.funcs_cap = m.funcs_cap * 2;
        m.funcs = (mir_func**)arc_realloc((i8*)m.funcs, sizeof(i8*) * (u64)m.funcs_cap);
    }
    m.funcs[m.funcs_len] = f;
    m.funcs_len = m.funcs_len + 1;
}

// ---- Value constructors ----

fn make_val_const_i(v: i64) *mir_val {
    let mut mv: *mir_val= (mir_val*)arc_malloc(sizeof(mir__NS_mir_val));
    mv.kind = 0; // MV_CONST
    mv.iconst = v;
    mv.fconst = 0.0;
    mv.name = (i8*)0;
    mv.type_id = 1; // i64
    return mv;
}

fn make_val_name(name: *i8, kind: i32) *mir_val {
    let mut mv: *mir_val= (mir_val*)arc_malloc(sizeof(mir__NS_mir_val));
    mv.kind = kind;
    mv.name = name;
    mv.iconst = 0;
    mv.fconst = 0.0;
    mv.type_id = 0;
    return mv;
}

fn make_instr(kind: i32, dst: *mir_val, s1: *mir_val, s2: *mir_val, ln: u64) *mir_instr {
    let mut ins: *mir_instr= (mir_instr*)arc_malloc(sizeof(mir__NS_mir_instr));
    ins.kind = kind;
    ins.dst  = dst;
    ins.src1 = s1;
    ins.src2 = s2;
    ins.label = (i8*)0;
    ins.fn_name = (i8*)0;
    ins.args = (mir_val**)0;
    ins.args_len = 0;
    ins.line = ln;
    return ins;
}

// ---- Expression lowering ----
// Returns a mir_val* holding the value of the expression,
// emitting any needed temporaries into ctx.cur_block.

fn lower_expr(e: *parser.expr_node, ctx: *lower_ctx) *mir_val;
fn lower_addr(e: *parser.expr_node, ctx: *lower_ctx) *mir_val;

// Lower an expression in *address* position — the destination of a store, or the base
// of a load. Returns a value denoting a location rather than the contents of one.
//
// Assignment used to assume its left side was a bare identifier and substituted "_"
// for anything else, so `a[i] = v` and `p.f = v` both lowered to a store to nothing.
// Every location form the analysis cares about is produced here instead.
fn lower_addr(e: *parser.expr_node, ctx: *lower_ctx) *mir_val {
    if (e == (parser.expr_node*)0) { return make_val_name("_", 1); }
    let mut k: i32= e.kind;

    // Plain variable: the alloca slot itself is the address.
    if (k == 5) {
        return make_val_name(e.str_val != (i8*)0 ? e.str_val : "_", 1);
    }

    // a[i] — GEP from the base with the index as the second operand.
    if (k == 9) {
        let mut base: *mir_val= (e.object != (parser.expr_node*)0 && e.object.kind == 5)
            ? make_val_name(e.object.str_val != (i8*)0 ? e.object.str_val : "_", 1)
            : lower_expr(e.object, ctx);
        let mut idx: *mir_val= lower_expr(e.index, ctx);
        let mut dst: *mir_val= make_val_name(fresh_temp(ctx), 1);
        let mut ins: *mir_instr= make_instr(4, dst, base, idx, e.line); // MI_GEP
        ins.label = (i8*)0;   // no field name: this is an index, held in src2
        block_push(ctx.cur_block, ins);
        return dst;
    }

    // s.field — GEP with the field name in the label slot.
    if (k == 10) {
        let mut base_m: *mir_val= (e.object != (parser.expr_node*)0 && e.object.kind == 5)
            ? make_val_name(e.object.str_val != (i8*)0 ? e.object.str_val : "_", 1)
            : lower_expr(e.object, ctx);
        let mut dst_m: *mir_val= make_val_name(fresh_temp(ctx), 1);
        let mut ins_m: *mir_instr= make_instr(4, dst_m, base_m, (mir_val*)0, e.line); // MI_GEP
        ins_m.label = e.str_val;
        block_push(ctx.cur_block, ins_m);
        return dst_m;
    }

    // *p — the pointer value is the address.
    if (k == 6 && e.uop == uop_deref) {
        return lower_expr(e.operand, ctx);
    }

    // Anything else: evaluate it and treat the result as the location.
    return lower_expr(e, ctx);
}

fn lower_expr(e: *parser.expr_node, ctx: *lower_ctx) *mir_val {
    if (e == (parser.expr_node*)0) { return make_val_const_i(0); }
    let mut k: i32= e.kind;

    // Integer literal
    if (k == 0) { return make_val_const_i(e.int_val); }

    // Bool literal
    if (k == 4) { return make_val_const_i(e.int_val); }

    // Identifier — load local or global
    if (k == 5) {
        let mut name: *i8= e.str_val != (i8*)0 ? e.str_val : "_";
        return make_val_name(name, 1); // MV_LOCAL
    }

    // Binary op
    if (k == 7) {
        let mut lv: *mir_val= lower_expr(e.lhs, ctx);
        let mut rv: *mir_val= lower_expr(e.rhs, ctx);
        let mut dst_name: *i8= fresh_temp(ctx);
        let mut dst: *mir_val= make_val_name(dst_name, 1);
        let mut ins: *mir_instr= make_instr(5, dst, lv, rv, e.line); // MI_BINOP
        ins.label = (i8*)0;
        // Store op kind in fn_name slot (repurposed for binop opcode)
        let mut opbuf: [8]i8;
        afmt(opbuf, 8u, "%d", .{ e.bop });
        ins.fn_name = lexer.str_dup(opbuf);
        block_push(ctx.cur_block, ins);
        return dst;
    }

    // Unary op
    if (k == 6) {
        let mut sv: *mir_val= lower_expr(e.operand, ctx);
        let mut dst_name: *i8= fresh_temp(ctx);
        let mut dst: *mir_val= make_val_name(dst_name, 1);
        let mut ins: *mir_instr= make_instr(6, dst, sv, (mir_val*)0, e.line); // MI_UNOP
        let mut opbuf: [8]i8;
        afmt(opbuf, 8u, "%d", .{ e.uop });
        ins.fn_name = lexer.str_dup(opbuf);
        block_push(ctx.cur_block, ins);
        return dst;
    }

    // Subscript: a[i] — address then load.
    // The GEP keeps the base and the index as operands so a consumer can see which
    // array is indexed by what. Dropping this is why `a[i]` used to lower to the
    // constant 0 and an out-of-range index was invisible downstream.
    if (k == 9) { // ek_subscript
        let mut addr: *mir_val= lower_addr(e, ctx);
        let mut dst_l: *mir_val= make_val_name(fresh_temp(ctx), 1);
        let mut ld: *mir_instr= make_instr(2, dst_l, addr, (mir_val*)0, e.line); // MI_LOAD
        block_push(ctx.cur_block, ld);
        return dst_l;
    }

    // Assignment
    if (k == 14) { // ek_assign
        let mut val: *mir_val= lower_expr(e.rhs, ctx);
        let mut ptr: *mir_val= lower_addr(e.lhs, ctx);
        let mut ins: *mir_instr= make_instr(3, (mir_val*)0, ptr, val, e.line); // MI_STORE
        block_push(ctx.cur_block, ins);
        return val;
    }
    // bop_assign embedded in binary
    if (k == 7 && e.bop == 18) {
        let mut val: *mir_val= lower_expr(e.rhs, ctx);
        let mut ptr: *mir_val= lower_addr(e.lhs, ctx);
        let mut ins: *mir_instr= make_instr(3, (mir_val*)0, ptr, val, e.line); // MI_STORE
        block_push(ctx.cur_block, ins);
        return val;
    }

    // Function call
    if (k == 8) {
        let mut dst_name: *i8= fresh_temp(ctx);
        let mut dst: *mir_val= make_val_name(dst_name, 1);
        let mut cap: i32= e.args_len > 0 ? e.args_len : 1;
        let mut call_args: **mir_val= (mir_val**)arc_malloc(sizeof(i8*) * (u64)cap);
        let mut ai: i32= 0;
        while (ai < e.args_len) {
            call_args[ai] = lower_expr(e.args[ai], ctx);
            ai = ai + 1;
        }
        let mut ins: *mir_instr= make_instr(7, dst, (mir_val*)0, (mir_val*)0, e.line); // MI_CALL
        // Callee name
        let mut callee_name: *i8= "<call>";
        if (e.callee != (parser.expr_node*)0 && e.callee.kind == 5) {
            callee_name = e.callee.str_val != (i8*)0 ? e.callee.str_val : "<call>";
        } else if (e.callee != (parser.expr_node*)0 && e.callee.kind == 10) {
            // member call: base.method — join as "base.method"
            let mut mbuf: [128]i8;
            let mut base_name: *i8= (e.callee.object != (parser.expr_node*)0 && e.callee.object.str_val != (i8*)0) ? e.callee.object.str_val : "";
            afmt(mbuf, 128u, "%s.%s", .{ base_name, e.callee.str_val != (i8*)0 ? e.callee.str_val : "" });
            callee_name = lexer.str_dup(mbuf);
        }
        ins.fn_name = callee_name;
        ins.args = call_args;
        ins.args_len = e.args_len;
        block_push(ctx.cur_block, ins);
        return dst;
    }

    // Cast
    if (k == 11 || k == 31) {
        let mut cv: *mir_val= lower_expr(e.operand, ctx);
        let mut dst_name: *i8= fresh_temp(ctx);
        let mut dst: *mir_val= make_val_name(dst_name, 1);
        let mut ins: *mir_instr= make_instr(13, dst, cv, (mir_val*)0, e.line); // MI_CAST
        block_push(ctx.cur_block, ins);
        return dst;
    }

    // Member access
    if (k == 10) {
        let mut base: *mir_val= lower_expr(e.object, ctx);
        let mut dst_name: *i8= fresh_temp(ctx);
        let mut dst: *mir_val= make_val_name(dst_name, 1);
        let mut ins: *mir_instr= make_instr(4, dst, base, (mir_val*)0, e.line); // MI_GEP
        ins.label = e.str_val; // field name in label slot
        block_push(ctx.cur_block, ins);
        return dst;
    }

    // Default: return constant 0 for unhandled expression kinds
    return make_val_const_i(0);
}

// ---- Statement lowering ----

fn lower_stmt(node: *parser.ast_node, ctx: *lower_ctx) void;

fn lower_block(blk: *parser.block_stmt, ctx: *lower_ctx) void {
    if (blk == (parser.block_stmt*)0) { return; }
    let mut i: i32= 0;
    while (i < blk.stmts_len) {
        lower_stmt(blk.stmts[i], ctx);
        i = i + 1;
    }
}

fn lower_stmt(node: *parser.ast_node, ctx: *lower_ctx) void {
    if (node == (parser.ast_node*)0) { return; }
    let mut k: i32= node.kind;

    // Block
    if (k == 0) {
        lower_block((parser.block_stmt*)node, ctx);
        return;
    }

    // var_decl (local)
    if (k == 13) {
        let mut vd: *parser.var_decl= (parser.var_decl*)node;
        let mut dst: *mir_val= make_val_name(vd.name != (i8*)0 ? vd.name : "_", 1);
        // Alloca. A fixed-size array records its element count as src1, so a bounds
        // check has a length to compare against — without it the declared extent is
        // lost at this point and can never be recovered from the MIR.
        let mut elem_count: i64= 0;
        if (vd.type != (parser.type_node*)0 && vd.type.array_size_ptr != (i8*)0) {
            let mut sz_e: *parser.expr_node= (parser.expr_node*)vd.type.array_size_ptr;
            if (sz_e != (parser.expr_node*)0 && sz_e.kind == 0) { elem_count = sz_e.int_val; }
        }
        let mut alloc_sz: *mir_val= (elem_count > 0) ? make_val_const_i(elem_count) : (mir_val*)0;
        let mut alloc_ins: *mir_instr= make_instr(12, dst, alloc_sz, (mir_val*)0, vd.line); // MI_ALLOCA
        block_push(ctx.cur_block, alloc_ins);
        // Init
        if (vd.has_init && vd.init != (parser.expr_node*)0) {
            let mut init_v: *mir_val= lower_expr(vd.init, ctx);
            let mut ptr: *mir_val= make_val_name(vd.name != (i8*)0 ? vd.name : "_", 1);
            let mut store: *mir_instr= make_instr(3, (mir_val*)0, ptr, init_v, vd.line); // MI_STORE
            block_push(ctx.cur_block, store);
        }
        return;
    }

    // nd_expr_stmt = 1: lower the contained expression
    if (k == 1) {
        let mut es: *parser.expr_stmt= (parser.expr_stmt*)node;
        if (es.expr != (parser.expr_node*)0) { lower_expr(es.expr, ctx); }
        return;
    }

    // nd_return_stmt = 2
    if (k == 2) {
        let mut rs: *parser.return_stmt= (parser.return_stmt*)node;
        let mut rv: *mir_val= (mir_val*)0;
        if (rs.has_val && rs.val != (parser.expr_node*)0) {
            rv = lower_expr(rs.val, ctx);
        }
        let mut ret_ins: *mir_instr= make_instr(10, (mir_val*)0, rv, (mir_val*)0, rs.line);
        block_push(ctx.cur_block, ret_ins);
        let mut dead_lbl: *i8= fresh_label(ctx, "dead");
        let mut dead_blk: *mir_block= new_block(dead_lbl);
        func_push_block(ctx.func, dead_blk);
        ctx.cur_block = dead_blk;
        return;
    }

    // nd_break_stmt = 3, nd_continue_stmt = 4 — branch to the enclosing loop's
    // exit/continue label. Code after the branch is unreachable, so open a fresh
    // block for it the way `return` does.
    if (k == 3 || k == 4) {
        let mut tgt: *i8= (k == 3) ? lctx_break_lbl(ctx) : lctx_cont_lbl(ctx);
        if (tgt == (i8*)0) { return; }   // outside any loop — nothing to branch to
        let mut jmp: *mir_instr= make_instr(8, (mir_val*)0, (mir_val*)0, (mir_val*)0, node.line);
        jmp.label = tgt;
        block_push(ctx.cur_block, jmp);
        let mut after_lbl: *i8= fresh_label(ctx, (k == 3) ? "after_break" : "after_cont");
        let mut after_blk: *mir_block= new_block(after_lbl);
        func_push_block(ctx.func, after_blk);
        ctx.cur_block = after_blk;
        return;
    }

    // nd_if_stmt = 5
    if (k == 5) {
        let mut isn: *parser.if_stmt= (parser.if_stmt*)node;
        let mut then_lbl: *i8= fresh_label(ctx, "if_then");
        let mut else_lbl: *i8= fresh_label(ctx, "if_else");
        let mut merge_lbl: *i8= fresh_label(ctx, "if_merge");
        let mut cond_v: *mir_val= lower_expr(isn.cond, ctx);
        let mut cbr: *mir_instr= make_instr(9, (mir_val*)0, cond_v, (mir_val*)0, isn.line);
        cbr.label = then_lbl; cbr.fn_name = else_lbl;
        block_push(ctx.cur_block, cbr);
        let mut then_blk: *mir_block= new_block(then_lbl);
        func_push_block(ctx.func, then_blk);
        ctx.cur_block = then_blk;
        if (isn.then_body != (parser.ast_node*)0) { lower_stmt(isn.then_body, ctx); }
        let mut br_t: *mir_instr= make_instr(8, (mir_val*)0, (mir_val*)0, (mir_val*)0, 0u);
        br_t.label = merge_lbl;
        block_push(ctx.cur_block, br_t);
        let mut else_blk: *mir_block= new_block(else_lbl);
        func_push_block(ctx.func, else_blk);
        ctx.cur_block = else_blk;
        if (isn.else_body != (parser.ast_node*)0) { lower_stmt(isn.else_body, ctx); }
        let mut br_e: *mir_instr= make_instr(8, (mir_val*)0, (mir_val*)0, (mir_val*)0, 0u);
        br_e.label = merge_lbl;
        block_push(ctx.cur_block, br_e);
        let mut merge_blk: *mir_block= new_block(merge_lbl);
        func_push_block(ctx.func, merge_blk);
        ctx.cur_block = merge_blk;
        return;
    }

    // nd_while_stmt = 6
    if (k == 6) {
        let mut ws: *parser.while_stmt= (parser.while_stmt*)node;
        let mut cond_lbl: *i8= fresh_label(ctx, "wh_cond");
        let mut body_lbl: *i8= fresh_label(ctx, "wh_body");
        let mut exit_lbl: *i8= fresh_label(ctx, "wh_exit");
        let mut br0: *mir_instr= make_instr(8, (mir_val*)0, (mir_val*)0, (mir_val*)0, ws.line);
        br0.label = cond_lbl;
        block_push(ctx.cur_block, br0);
        let mut cond_blk: *mir_block= new_block(cond_lbl);
        func_push_block(ctx.func, cond_blk);
        ctx.cur_block = cond_blk;
        let mut wcv: *mir_val= lower_expr(ws.cond, ctx);
        let mut wcbr: *mir_instr= make_instr(9, (mir_val*)0, wcv, (mir_val*)0, ws.line);
        wcbr.label = body_lbl; wcbr.fn_name = exit_lbl;
        block_push(ctx.cur_block, wcbr);
        let mut body_blk: *mir_block= new_block(body_lbl);
        func_push_block(ctx.func, body_blk);
        ctx.cur_block = body_blk;
        lctx_push_loop(ctx, exit_lbl, cond_lbl);
        if (ws.body != (parser.ast_node*)0) { lower_stmt(ws.body, ctx); }
        lctx_pop_loop(ctx);
        let mut br_back: *mir_instr= make_instr(8, (mir_val*)0, (mir_val*)0, (mir_val*)0, 0u);
        br_back.label = cond_lbl;
        block_push(ctx.cur_block, br_back);
        let mut exit_blk: *mir_block= new_block(exit_lbl);
        func_push_block(ctx.func, exit_blk);
        ctx.cur_block = exit_blk;
        return;
    }

    // nd_for_stmt = 7
    if (k == 7) {
        let mut fst: *parser.for_stmt= (parser.for_stmt*)node;
        if (fst.init != (parser.ast_node*)0) { lower_stmt(fst.init, ctx); }
        let mut fc_lbl: *i8= fresh_label(ctx, "for_cond");
        let mut fb_lbl: *i8= fresh_label(ctx, "for_body");
        let mut fs_lbl: *i8= fresh_label(ctx, "for_step");
        let mut fe_lbl: *i8= fresh_label(ctx, "for_exit");
        let mut fbr0: *mir_instr= make_instr(8, (mir_val*)0, (mir_val*)0, (mir_val*)0, fst.line);
        fbr0.label = fc_lbl;
        block_push(ctx.cur_block, fbr0);
        let mut fc_blk: *mir_block= new_block(fc_lbl);
        func_push_block(ctx.func, fc_blk);
        ctx.cur_block = fc_blk;
        if (fst.cond != (parser.expr_node*)0) {
            let mut fcv: *mir_val= lower_expr(fst.cond, ctx);
            let mut fcbr: *mir_instr= make_instr(9, (mir_val*)0, fcv, (mir_val*)0, fst.line);
            fcbr.label = fb_lbl; fcbr.fn_name = fe_lbl;
            block_push(ctx.cur_block, fcbr);
        } else {
            let mut fub: *mir_instr= make_instr(8, (mir_val*)0, (mir_val*)0, (mir_val*)0, 0u);
            fub.label = fb_lbl;
            block_push(ctx.cur_block, fub);
        }
        let mut fb_blk: *mir_block= new_block(fb_lbl);
        func_push_block(ctx.func, fb_blk);
        ctx.cur_block = fb_blk;
        lctx_push_loop(ctx, fe_lbl, fs_lbl);
        if (fst.body != (parser.ast_node*)0) { lower_stmt(fst.body, ctx); }
        lctx_pop_loop(ctx);
        let mut fbrs: *mir_instr= make_instr(8, (mir_val*)0, (mir_val*)0, (mir_val*)0, 0u);
        fbrs.label = fs_lbl;
        block_push(ctx.cur_block, fbrs);
        let mut fs_blk: *mir_block= new_block(fs_lbl);
        func_push_block(ctx.func, fs_blk);
        ctx.cur_block = fs_blk;
        if (fst.step != (parser.expr_node*)0) { lower_expr(fst.step, ctx); }
        let mut fbrb: *mir_instr= make_instr(8, (mir_val*)0, (mir_val*)0, (mir_val*)0, 0u);
        fbrb.label = fc_lbl;
        block_push(ctx.cur_block, fbrb);
        let mut fe_blk: *mir_block= new_block(fe_lbl);
        func_push_block(ctx.func, fe_blk);
        ctx.cur_block = fe_blk;
        return;
    }

    // nd_for_range_stmt = 8 — `for (x : range)`. The iteration protocol is resolved
    // during LLVM emission; in MIR it lowers to the same cond/body/exit skeleton so
    // the body's effects and any break/continue are represented.
    if (k == 8) {
        let mut frs: *parser.for_range_stmt= (parser.for_range_stmt*)node;
        let mut rc_lbl: *i8= fresh_label(ctx, "rng_cond");
        let mut rb_lbl: *i8= fresh_label(ctx, "rng_body");
        let mut re_lbl: *i8= fresh_label(ctx, "rng_exit");
        let mut rbr0: *mir_instr= make_instr(8, (mir_val*)0, (mir_val*)0, (mir_val*)0, frs.line);
        rbr0.label = rc_lbl;
        block_push(ctx.cur_block, rbr0);
        let mut rc_blk: *mir_block= new_block(rc_lbl);
        func_push_block(ctx.func, rc_blk);
        ctx.cur_block = rc_blk;
        let mut rcv: *mir_val= lower_expr(frs.range, ctx);
        let mut rcbr: *mir_instr= make_instr(9, (mir_val*)0, rcv, (mir_val*)0, frs.line);
        rcbr.label = rb_lbl; rcbr.fn_name = re_lbl;
        block_push(ctx.cur_block, rcbr);
        let mut rb_blk: *mir_block= new_block(rb_lbl);
        func_push_block(ctx.func, rb_blk);
        ctx.cur_block = rb_blk;
        lctx_push_loop(ctx, re_lbl, rc_lbl);
        if (frs.body != (parser.ast_node*)0) { lower_stmt(frs.body, ctx); }
        lctx_pop_loop(ctx);
        let mut rbrb: *mir_instr= make_instr(8, (mir_val*)0, (mir_val*)0, (mir_val*)0, 0u);
        rbrb.label = rc_lbl;
        block_push(ctx.cur_block, rbrb);
        let mut re_blk: *mir_block= new_block(re_lbl);
        func_push_block(ctx.func, re_blk);
        ctx.cur_block = re_blk;
        return;
    }

    // nd_switch_stmt = 9 — each case becomes a compare against the subject plus a
    // conditional branch; `break` inside a case exits to the merge label.
    if (k == 9) {
        let mut sw: *parser.switch_stmt= (parser.switch_stmt*)node;
        let mut subj: *mir_val= lower_expr(sw.val, ctx);
        let mut sw_end: *i8= fresh_label(ctx, "sw_end");
        lctx_push_loop(ctx, sw_end, sw_end);
        let mut ci: i32= 0;
        while (ci < sw.cases_len) {
            let mut case_lbl: *i8= fresh_label(ctx, "sw_case");
            let mut next_lbl: *i8= fresh_label(ctx, "sw_next");
            let mut is_default: bool= (sw.case_is_default != (bool*)0) ? sw.case_is_default[ci] : false;
            if (is_default) {
                let mut dbr: *mir_instr= make_instr(8, (mir_val*)0, (mir_val*)0, (mir_val*)0, sw.line);
                dbr.label = case_lbl;
                block_push(ctx.cur_block, dbr);
            } else {
                let mut cval: *mir_val= make_val_const_i(0);
                if (sw.case_vals != (parser.expr_node***)0 && sw.case_vals[ci] != (parser.expr_node**)0) {
                    // parse_switch stores the case value as the expr_node itself, cast
                    // to expr_node** (see n.case_vals[...] = (expr_node**)case_val).
                    // Indexing it as an array read the node's first field as a pointer,
                    // which crashed on any case value that was not an int literal.
                    cval = lower_expr((parser.expr_node*)sw.case_vals[ci], ctx);
                }
                let mut cmp_dst: *mir_val= make_val_name(fresh_temp(ctx), 1);
                let mut cmp_ins: *mir_instr= make_instr(5, cmp_dst, subj, cval, sw.line);
                cmp_ins.fn_name = lexer.str_dup("eq");
                block_push(ctx.cur_block, cmp_ins);
                let mut cbr_s: *mir_instr= make_instr(9, (mir_val*)0, cmp_dst, (mir_val*)0, sw.line);
                cbr_s.label = case_lbl; cbr_s.fn_name = next_lbl;
                block_push(ctx.cur_block, cbr_s);
            }
            let mut case_blk: *mir_block= new_block(case_lbl);
            func_push_block(ctx.func, case_blk);
            ctx.cur_block = case_blk;
            if (sw.case_bodies != (parser.block_stmt**)0 && sw.case_bodies[ci] != (parser.block_stmt*)0) {
                lower_block(sw.case_bodies[ci], ctx);
            }
            let mut fall: *mir_instr= make_instr(8, (mir_val*)0, (mir_val*)0, (mir_val*)0, 0u);
            fall.label = next_lbl;
            block_push(ctx.cur_block, fall);
            let mut next_blk: *mir_block= new_block(next_lbl);
            func_push_block(ctx.func, next_blk);
            ctx.cur_block = next_blk;
            ci = ci + 1;
        }
        lctx_pop_loop(ctx);
        let mut to_end: *mir_instr= make_instr(8, (mir_val*)0, (mir_val*)0, (mir_val*)0, 0u);
        to_end.label = sw_end;
        block_push(ctx.cur_block, to_end);
        let mut end_blk: *mir_block= new_block(sw_end);
        func_push_block(ctx.func, end_blk);
        ctx.cur_block = end_blk;
        return;
    }

    // nd_defer_stmt = 11 / nd_errdefer_stmt = 12 — the deferred body runs at scope
    // exit. Lower it in place so its effects appear in MIR; scheduling to the exact
    // exit point is the LLVM emitter's job.
    if (k == 11 || k == 12) {
        let mut ds: *parser.defer_stmt= (parser.defer_stmt*)node;
        if (ds.is_block && ds.blk != (i8*)0) { lower_stmt((parser.ast_node*)ds.blk, ctx); }
        else if (ds.expr != (parser.expr_node*)0) { lower_expr(ds.expr, ctx); }
        return;
    }

    // nd_asm_stmt = 10 has no MIR form (it is emitted verbatim by the backend).
    // nd_func_decl = 14: nested functions are lowered separately.
}

// ---- Function lowering ----

fn lower_func_decl(fd: *parser.func_decl, m: *mir_module) void {
    if (fd == (parser.func_decl*)0 || !fd.has_body) { return; }

    let mut f: *mir_func= (mir_func*)arc_malloc(sizeof(mir__NS_mir_func));
    f.name = fd.name != (i8*)0 ? fd.name : "<anon>";
    f.blocks_cap = 8;
    f.blocks_len = 0;
    f.blocks = (mir_block**)arc_malloc(sizeof(i8*) * (u64)8);

    let mut ctx: lower_ctx;
    lctx_init(&ctx, f);

    // Entry block
    let mut entry: *mir_block= new_block(lexer.str_dup("entry"));
    func_push_block(f, entry);
    ctx.cur_block = entry;

    // Parameter allocas
    let mut pi: i32= 0;
    while (pi < fd.params_len) {
        let mut pname: *i8= fd.params[pi].name != (i8*)0 ? fd.params[pi].name : "_";
        let mut pdst: *mir_val= make_val_name(pname, 3); // MV_PARAM
        let mut pa: *mir_instr= make_instr(12, pdst, (mir_val*)0, (mir_val*)0, fd.line);
        block_push(ctx.cur_block, pa);
        pi = pi + 1;
    }

    // Lower body
    let mut blk: *parser.block_stmt= (parser.block_stmt*)fd.body;
    lower_block(blk, &ctx);

    // Ensure last block ends with a return
    let mut _last_ins: *mir_instr= ctx.cur_block.instrs_len > 0 ? ctx.cur_block.instrs[ctx.cur_block.instrs_len - 1] : (mir_instr*)0;
    if (ctx.cur_block.instrs_len == 0 || _last_ins.kind != 10) {
        let mut ret_void: *mir_instr= make_instr(10, (mir_val*)0, (mir_val*)0, (mir_val*)0, 0u);
        block_push(ctx.cur_block, ret_void);
    }

    module_push_func(m, f);
}

// ---- Walk namespaces ----

fn lower_namespace(ns: *parser.namespace_decl, m: *mir_module) void {
    if (ns == (parser.namespace_decl*)0) { return; }
    let mut i: i32= 0;
    while (i < ns.decls_len) {
        let mut d: *parser.ast_node= ns.decls[i];
        if (d != (parser.ast_node*)0) {
            if (d.kind == 14) { // nd_func_decl
                lower_func_decl((parser.func_decl*)d, m);
            } else if (d.kind == 20) { // nd_namespace_decl
                lower_namespace((parser.namespace_decl*)d, m);
            }
        }
        i = i + 1;
    }
}

// ---- Top-level entry point ----

fn lower_program(prog_node: *i8) *mir_module {
    let mut m: *mir_module= (mir_module*)arc_malloc(sizeof(mir__NS_mir_module));
    m.funcs     = (mir_func**)arc_malloc(sizeof(i8*) * (u64)64);
    m.funcs_len = 0;
    m.funcs_cap = 64;

    if (prog_node == (i8*)0) { return m; }
    let mut prog: *parser.program_node= (parser.program_node*)prog_node;

    let mut i: i32= 0;
    while (i < prog.decls_len) {
        let mut d: *parser.ast_node= prog.decls[i];
        if (d != (parser.ast_node*)0) {
            if (d.kind == 14) {
                lower_func_decl((parser.func_decl*)d, m);
            } else if (d.kind == 20) {
                lower_namespace((parser.namespace_decl*)d, m);
            }
        }
        i = i + 1;
    }

    return m;
}

// ---- Textual dump (for --emit-mir) ----
// Mnemonics match the mir_instr_kind enum.

fn mir_val_str(v: *mir_val, buf: *i8, cap: u64) void {
    if (v == (mir_val*)0) { afmt(buf, cap, "_", .{}); return; }
    if (v.kind == 0) { afmt(buf, cap, "%lld", .{ v.iconst }); return; }
    afmt(buf, cap, "%s", .{ v.name != (i8*)0 ? v.name : "_" });
}

fn mir_print_instr(ins: *mir_instr, fp: *void) void {
    if (ins == (mir_instr*)0) { return; }
    let mut d: [64]i8;  mir_val_str(ins.dst,  d, 64u);
    let mut a: [64]i8;  mir_val_str(ins.src1, a, 64u);
    let mut b: [64]i8;  mir_val_str(ins.src2, b, 64u);
    let mut k: i32= ins.kind;
    let mut op: *i8= ins.fn_name != (i8*)0 ? ins.fn_name : "?";
    let mut lb: *i8= ins.label != (i8*)0 ? ins.label : "?";
    if      (k == 1)  { afprint(fp, "    %s = copy %s\n", .{ d, a }); }
    else if (k == 2)  { afprint(fp, "    %s = load %s\n", .{ d, a }); }
    else if (k == 3)  { afprint(fp, "    store %s, %s\n", .{ a, b }); }
    else if (k == 4)  { afprint(fp, "    %s = gep %s, .%s\n", .{ d, a, lb }); }
    else if (k == 5)  { afprint(fp, "    %s = binop.%s %s, %s\n", .{ d, op, a, b }); }
    else if (k == 6)  { afprint(fp, "    %s = unop.%s %s\n", .{ d, op, a }); }
    else if (k == 7)  { afprint(fp, "    %s = call %s/%d\n", .{ d, op, ins.args_len }); }
    else if (k == 8)  { afprint(fp, "    br %s\n", .{ lb }); }
    else if (k == 9)  { afprint(fp, "    cbr %s, %s, %s\n", .{ a, lb, op }); }
    else if (k == 10) { if (ins.src1 != (mir_val*)0) { afprint(fp, "    ret %s\n", .{ a }); } else { afprint(fp, "    ret\n", .{}); } }
    else if (k == 12) { afprint(fp, "    %s = alloca\n", .{ d }); }
    else if (k == 13) { afprint(fp, "    %s = cast %s\n", .{ d, a }); }
    else              { afprint(fp, "    nop\n", .{}); }
}

fn mir_print_module(m: *mir_module, fp: *void) void {
    if (m == (mir_module*)0 || fp == (void*)0) { return; }
    afprint(fp, "; Artemis MIR\n", .{});
    let mut fi: i32= 0;
    while (fi < m.funcs_len) {
        let mut f: *mir_func= m.funcs[fi];
        let mut fname: *i8= f.name != (i8*)0 ? f.name : "<anon>";
        afprint(fp, "\nfunc %s {\n", .{ fname });
        let mut bi: i32= 0;
        while (bi < f.blocks_len) {
            let mut b: *mir_block= f.blocks[bi];
            let mut bname: *i8= b.name != (i8*)0 ? b.name : "?";
            afprint(fp, "  %s:\n", .{ bname });
            let mut ii: i32= 0;
            while (ii < b.instrs_len) { mir_print_instr(b.instrs[ii], fp); ii = ii + 1; }
            bi = bi + 1;
        }
        afprint(fp, "}\n", .{});
        fi = fi + 1;
    }
}

fn mir_module_free(m: *mir_module) void {
    if (m == (mir_module*)0) { return; }
    arc_free((i8*)m);
}

} // namespace mir
