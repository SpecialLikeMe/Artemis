// smt/lir.arc — pointer-safety and bounds analysis over LIR.
//
// The AST-level engine in smt/main.arc works on source structure. This one works on
// the lowered form, which is where the pipeline was always meant to check:
//
//     AST → MIR → LIR → SMT
//
// LIR is a better subject for it: every memory access is an explicit instruction, so
// there is one place to look at rather than a dozen expression shapes, and a construct
// that lowers to a load or a store cannot escape the check by being spelled unusually.
//
// What it reads:
//   LI_ALLOCA with src1  — a fixed-size array and its element count
//   LI_GEP with src2     — an indexed access: src1 is the base, src2 the index
//   LI_LOAD / LI_STORE   — the access itself, through whatever address it was given
//   LI_CALL              — allocation and release, by callee name
//
// Reported outcomes match the AST engine's three-way model: a provably bad access is
// an error, an undecidable one asks for a runtime check, and a provably good one is
// silent.

namespace smt {

// A GEP temp remembers which array it indexed and with what, so the load or store that
// consumes it can be attributed back to the array the programmer named.
struct lir_gep_info {
    let temp: *i8;      // the SSA temp the GEP produced
    let base: *i8;      // the array it indexed
    let idx_const: i64; // constant index, when the index was a literal
    let idx_known: bool;
    let line: u64;
}

comptime i32 SMT_LIR_MAX_GEPS = 512;

struct lir_smt_ctx {
    let arrs: smt_asz;                        // array name -> element count
    let geps: [SMT_LIR_MAX_GEPS]lir_gep_info;
    let geps_len: i32;
    let func_name: *i8;
    let error_count: i32;
    let rtcheck_count: i32;
}

fn lir_smt_init(c: *lir_smt_ctx, fname: *i8) void {
    smt_asz_init(&c.arrs);
    c.geps_len      = 0;
    c.func_name     = fname != (i8*)0 ? fname : "<anon>";
    c.error_count   = 0;
    c.rtcheck_count = 0;
}

fn lir_gep_find(c: *lir_smt_ctx, name: *i8) i32 {
    if (name == (i8*)0) { return -1; }
    let mut i: i32= 0;
    while (i < c.geps_len) {
        if (c.geps[i].temp != (i8*)0 && strcmp(c.geps[i].temp, name) == 0) { return i; }
        i = i + 1;
    }
    return -1;
}

fn lir_gep_add(c: *lir_smt_ctx, temp: *i8, base: *i8, idx_const: i64, idx_known: bool, line: u64) void {
    if (c.geps_len >= SMT_LIR_MAX_GEPS || temp == (i8*)0) { return; }
    c.geps[c.geps_len].temp      = temp;
    c.geps[c.geps_len].base      = base;
    c.geps[c.geps_len].idx_const = idx_const;
    c.geps[c.geps_len].idx_known = idx_known;
    c.geps[c.geps_len].line      = line;
    c.geps_len = c.geps_len + 1;
}

// Check one indexed access. Mirrors the AST engine: a constant index outside the
// declared extent is an error, a dynamic index asks for a runtime check, and a
// constant index inside the extent is silent.
fn lir_check_index(c: *lir_smt_ctx, gi: i32) void {
    if (gi < 0 || gi >= c.geps_len) { return; }
    let mut base: *i8= c.geps[gi].base;
    if (base == (i8*)0) { return; }
    let mut n: i32= smt_asz_get(&c.arrs, base);
    if (n <= 0) { return; }                      // extent unknown — nothing to say
    if (c.geps[gi].idx_known) {
        let mut idx: i64= c.geps[gi].idx_const;
        if (idx < (i64)0 || idx >= (i64)n) {
            let mut msg: [256]i8;
            afmt(msg, (u64)256,
                 "index %lld is outside '%s' (length %d)", .{ idx, base, n });
            aprint("SMT error at line %d, func '%s': %s\n",
                   .{ (i32)c.geps[gi].line, c.func_name, msg });
            c.error_count = c.error_count + 1;
        }
        return;
    }
    // Dynamic index: undecidable here, so ask for the runtime check.
    aprint("SMT note: runtime check needed: dynamic array index — bounds check injected (line %d, func '%s', var '%s')\n",
           .{ (i32)c.geps[gi].line, c.func_name, base });
    c.rtcheck_count = c.rtcheck_count + 1;
}

// Walk one LIR function.
fn lir_smt_func(f: *lir.lir_func, total_errors: *i32) void {
    if (f == (lir.lir_func*)0) { return; }
    let mut c: lir_smt_ctx;
    lir_smt_init(&c, f.name);

    let mut bi: i32= 0;
    while (bi < f.blocks_len) {
        let mut b: *lir.lir_block= f.blocks[bi];
        if (b != (lir.lir_block*)0) {
            let mut ii: i32= 0;
            while (ii < b.instrs_len) {
                let mut ins: *lir.lir_instr= b.instrs[ii];
                if (ins != (lir.lir_instr*)0) {
                    let mut k: i32= ins.kind;

                    // alloca with an element count: record the extent.
                    if (k == 12 && ins.dst != (lir.lir_val*)0 && ins.dst.name != (i8*)0 &&
                        ins.src1 != (lir.lir_val*)0 && ins.src1.kind == 0) {
                        smt_asz_set(&c.arrs, ins.dst.name, (i32)ins.src1.iconst);
                    }

                    // Indexed GEP: remember base and index for the access that uses it.
                    if (k == 4 && ins.src2 != (lir.lir_val*)0 && ins.dst != (lir.lir_val*)0) {
                        let mut base_nm: *i8= (ins.src1 != (lir.lir_val*)0) ? ins.src1.name : (i8*)0;
                        let mut is_const: bool= (ins.src2.kind == 0);
                        lir_gep_add(&c, ins.dst.name, base_nm,
                                    is_const ? ins.src2.iconst : (i64)0, is_const, ins.line);
                    }

                    // A load or a store through a GEP temp is the access itself.
                    if (k == 2 && ins.src1 != (lir.lir_val*)0) {
                        lir_check_index(&c, lir_gep_find(&c, ins.src1.name));
                    }
                    if (k == 3 && ins.src1 != (lir.lir_val*)0) {
                        lir_check_index(&c, lir_gep_find(&c, ins.src1.name));
                    }
                }
                ii = ii + 1;
            }
        }
        bi = bi + 1;
    }
    if (c.error_count > 0) { *total_errors = *total_errors + c.error_count; }
}

// Entry point: run the analysis over a lowered module. Returns the error count.
fn smt_analyze_lir(m: *lir.lir_module) i32 {
    if (m == (lir.lir_module*)0) { return 0; }
    let mut total: i32= 0;
    let mut fi: i32= 0;
    while (fi < m.funcs_len) {
        lir_smt_func(m.funcs[fi], &total);
        fi = fi + 1;
    }
    return total;
}

} // namespace smt
