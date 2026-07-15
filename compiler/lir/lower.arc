// compiler/lir/lower.arc — MIR → LIR lowering pass
//
// Lowers a MIR module to scalar LIR: aggregates become pointer+scalar-load
// sequences, and SMT pseudo-instructions (LI_RTCHECK_*) are inserted at sites
// where the bounds-check analysis signals UNKNOWN.
//
// Status: scaffolding. The pass is gated behind --use-mir.

namespace lir {

// Lower a MIR module to LIR.
lir_module* lower_mir(mir.mir_module* mir_mod) {
    lir_module* lm = (lir_module*)arc_malloc(sizeof(lir__NS_lir_module));
    lm.funcs      = (lir__NS_lir_func**)0;
    lm.funcs_len  = 0;
    lm.funcs_cap  = 0;
    // TODO: walk mir_mod.funcs and emit scalar lir_func entries.
    return lm;
}

void lir_module_free(lir_module* lm) {
    if (lm == (lir_module*)0) { return; }
    arc_free((i8*)lm);
}

} // namespace lir
