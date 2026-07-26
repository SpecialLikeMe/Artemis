// compiler/lir/lower.arc — MIR → LIR lowering pass.
//
// Translates a MIR module to scalar LIR. The opcode mapping is 1:1 for most
// instructions; MIR value kinds are remapped to LIR value kinds. SMT
// pseudo-instructions (LI_RTCHECK_*) are reserved for the bounds-check pass
// and are not emitted here.

namespace lir {

// ---- Helpers: allocate LIR values ----

fn lval_from_mir(mv: *mir.mir_val) *lir_val {
    if (mv == (mir.mir_val*)0) { return (lir_val*)0; }
    let mut lv: *lir_val= (lir_val*)arc_malloc(sizeof(lir__NS_lir_val));
    // Map MIR val kind to LIR val kind:
    //   MV_CONST=0 → LV_ICONST=0 (float stored separately)
    //   MV_LOCAL=1 → LV_LOCAL=2
    //   MV_GLOBAL=2 → LV_GLOBAL=3
    //   MV_PARAM=3 → LV_PARAM=4
    let mut mk: i32= mv.kind;
    if (mk == 0) {
        if (mv.fconst != 0.0) { lv.kind = 1; } // LV_FCONST
        else { lv.kind = 0; }                   // LV_ICONST
    } else if (mk == 1) { lv.kind = 2; }
    else if (mk == 2)   { lv.kind = 3; }
    else if (mk == 3)   { lv.kind = 4; }
    else                { lv.kind = 2; }
    lv.type_id = mv.type_id;
    lv.name    = mv.name;
    lv.iconst  = mv.iconst;
    lv.fconst  = mv.fconst;
    return lv;
}

// ---- Helpers: allocate LIR instructions ----

fn lalloc_args(mir_args: **mir.mir_val, n: i32) **lir_val {
    if (n == 0 || mir_args == (mir.mir_val**)0) { return (lir_val**)0; }
    let mut arr: **lir_val= (lir_val**)arc_malloc(sizeof(i8*) * (u64)n);
    let mut i: i32= 0;
    while (i < n) { arr[i] = lval_from_mir(mir_args[i]); i = i + 1; }
    return arr;
}

fn linstr_from_mir(mi: *mir.mir_instr) *lir_instr {
    if (mi == (mir.mir_instr*)0) { return (lir_instr*)0; }
    let mut li: *lir_instr= (lir_instr*)arc_malloc(sizeof(lir__NS_lir_instr));
    // Opcodes are identical in the MIR and LIR enums (0-13)
    li.kind     = mi.kind;
    li.dst      = lval_from_mir(mi.dst);
    li.src1     = lval_from_mir(mi.src1);
    li.src2     = lval_from_mir(mi.src2);
    li.label    = mi.label;
    li.fn_name  = mi.fn_name;
    li.args     = lalloc_args(mi.args, mi.args_len);
    li.args_len = mi.args_len;
    li.line     = mi.line;
    li.check_msg = (i8*)0;
    return li;
}

// ---- Block helpers ----

fn lnew_block(name: *i8) *lir_block {
    let mut b: *lir_block= (lir_block*)arc_malloc(sizeof(lir__NS_lir_block));
    b.name       = name;
    b.instrs_cap = 16;
    b.instrs_len = 0;
    b.instrs     = (lir_instr**)arc_malloc(sizeof(i8*) * (u64)16);
    return b;
}

fn lblock_push(b: *lir_block, ins: *lir_instr) void {
    if (b.instrs_len >= b.instrs_cap) {
        b.instrs_cap = b.instrs_cap * 2;
        b.instrs = (lir_instr**)arc_realloc((i8*)b.instrs, sizeof(i8*) * (u64)b.instrs_cap);
    }
    b.instrs[b.instrs_len] = ins;
    b.instrs_len = b.instrs_len + 1;
}

fn lfunc_push_block(f: *lir_func, b: *lir_block) void {
    if (f.blocks_len >= f.blocks_cap) {
        f.blocks_cap = f.blocks_cap * 2;
        f.blocks = (lir_block**)arc_realloc((i8*)f.blocks, sizeof(i8*) * (u64)f.blocks_cap);
    }
    f.blocks[f.blocks_len] = b;
    f.blocks_len = f.blocks_len + 1;
}

fn lmodule_push_func(m: *lir_module, f: *lir_func) void {
    if (m.funcs_len >= m.funcs_cap) {
        m.funcs_cap = m.funcs_cap * 2;
        m.funcs = (lir_func**)arc_realloc((i8*)m.funcs, sizeof(i8*) * (u64)m.funcs_cap);
    }
    m.funcs[m.funcs_len] = f;
    m.funcs_len = m.funcs_len + 1;
}

// ---- Core lowering: block ----

fn lower_mir_block(mb: *mir.mir_block) *lir_block {
    if (mb == (mir.mir_block*)0) { return (lir_block*)0; }
    let mut lb: *lir_block= lnew_block(mb.name);
    let mut i: i32= 0;
    while (i < mb.instrs_len) {
        let mut li: *lir_instr= linstr_from_mir(mb.instrs[i]);
        if (li != (lir_instr*)0) { lblock_push(lb, li); }
        i = i + 1;
    }
    return lb;
}

// ---- Core lowering: function ----

fn lower_mir_func(mf: *mir.mir_func) *lir_func {
    if (mf == (mir.mir_func*)0) { return (lir_func*)0; }
    let mut lf: *lir_func= (lir_func*)arc_malloc(sizeof(lir__NS_lir_func));
    lf.name       = mf.name;
    lf.blocks_cap = mf.blocks_len > 0 ? mf.blocks_len : 8;
    lf.blocks_len = 0;
    lf.blocks     = (lir_block**)arc_malloc(sizeof(i8*) * (u64)lf.blocks_cap);
    let mut i: i32= 0;
    while (i < mf.blocks_len) {
        let mut lb: *lir_block= lower_mir_block(mf.blocks[i]);
        if (lb != (lir_block*)0) { lfunc_push_block(lf, lb); }
        i = i + 1;
    }
    return lf;
}

// ---- Top-level entry ----

fn lower_mir(mir_mod: *mir.mir_module) *lir_module {
    let mut lm: *lir_module= (lir_module*)arc_malloc(sizeof(lir__NS_lir_module));
    lm.funcs_cap = 64;
    lm.funcs_len = 0;
    lm.funcs     = (lir_func**)arc_malloc(sizeof(i8*) * (u64)64);

    if (mir_mod == (mir.mir_module*)0) { return lm; }

    let mut i: i32= 0;
    while (i < mir_mod.funcs_len) {
        let mut lf: *lir_func= lower_mir_func(mir_mod.funcs[i]);
        if (lf != (lir_func*)0) { lmodule_push_func(lm, lf); }
        i = i + 1;
    }
    return lm;
}

// ---- Textual dump (for --emit-lir) ----

fn lir_val_str(v: *lir_val, buf: *i8, cap: u64) void {
    if (v == (lir_val*)0) { snprintf(buf, cap, "_"); return; }
    if (v.kind == 0) { snprintf(buf, cap, "%lld", v.iconst); return; }
    if (v.kind == 1) { snprintf(buf, cap, "%f", v.fconst); return; }
    snprintf(buf, cap, "%s", v.name != (i8*)0 ? v.name : "_");
}

fn lir_print_instr(ins: *lir_instr, fp: *void) void {
    if (ins == (lir_instr*)0) { return; }
    let mut d: [64]i8;  lir_val_str(ins.dst,  d, 64u);
    let mut a: [64]i8;  lir_val_str(ins.src1, a, 64u);
    let mut b: [64]i8;  lir_val_str(ins.src2, b, 64u);
    let mut k: i32= ins.kind;
    if      (k == 1)  { fprintf(fp, "    %s = %s
", d, a); }
    else if (k == 2)  { fprintf(fp, "    %s = load %s
", d, a); }
    else if (k == 3)  { fprintf(fp, "    store %s, %s
", a, b); }
    else if (k == 4)  { fprintf(fp, "    %s = gep %s
", d, a); }
    else if (k == 5)  { fprintf(fp, "    %s = binop.%s %s, %s
", d, ins.fn_name != (i8*)0 ? ins.fn_name : "?", a, b); }
    else if (k == 6)  { fprintf(fp, "    %s = unop.%s %s
", d, ins.fn_name != (i8*)0 ? ins.fn_name : "?", a); }
    else if (k == 7)  { fprintf(fp, "    %s = call %s/%d
", d, ins.fn_name != (i8*)0 ? ins.fn_name : "?", ins.args_len); }
    else if (k == 8)  { fprintf(fp, "    br %s
", ins.label != (i8*)0 ? ins.label : "?"); }
    else if (k == 9)  { fprintf(fp, "    cbr %s, %s, %s
", a,
                                ins.label != (i8*)0 ? ins.label : "?",
                                ins.fn_name != (i8*)0 ? ins.fn_name : "?"); }
    else if (k == 10) { if (ins.src1 != (lir_val*)0) { fprintf(fp, "    ret %s
", a); } else { fprintf(fp, "    ret
"); } }
    else if (k == 12) { fprintf(fp, "    %s = alloca
", d); }
    else if (k == 13) { fprintf(fp, "    %s = cast %s
", d, a); }
    else if (k == 20) { fprintf(fp, "    rtcheck.null %s
", a); }
    else if (k == 21) { fprintf(fp, "    rtcheck.bounds %s, %s
", a, b); }
    else              { fprintf(fp, "    nop
"); }
}

fn lir_print_module(m: *lir_module, fp: *void) void {
    if (m == (lir_module*)0 || fp == (void*)0) { return; }
    fprintf(fp, "; Artemis LIR
");
    let mut fi: i32= 0;
    while (fi < m.funcs_len) {
        let mut f: *lir_func= m.funcs[fi];
        fprintf(fp, "
func %s {
", f.name != (i8*)0 ? f.name : "<anon>");
        let mut bi: i32= 0;
        while (bi < f.blocks_len) {
            let mut b: *lir_block= f.blocks[bi];
            fprintf(fp, "  %s:
", b.name != (i8*)0 ? b.name : "?");
            let mut ii: i32= 0;
            while (ii < b.instrs_len) { lir_print_instr(b.instrs[ii], fp); ii = ii + 1; }
            bi = bi + 1;
        }
        fprintf(fp, "}
");
        fi = fi + 1;
    }
}

fn lir_module_free(lm: *lir_module) void {
    if (lm == (lir_module*)0) { return; }
    arc_free((i8*)lm);
}

} // namespace lir
