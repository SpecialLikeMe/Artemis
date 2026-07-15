// compiler/mir/lower.arc — AST → MIR lowering pass
//
// Walks the AST and emits three-address MIR instructions.
// All loops are flattened to label/branch form; compound expressions
// are split into temporaries.
//
// Status: scaffolding. The pass is gated behind --use-mir; when not
// supplied the main pipeline skips this and goes directly to LLVM IR.

namespace mir {

// Lower a full program AST to a MIR module.
// Returns a valid mir_module even in stub mode (it will be empty).
mir_module* lower_program(i8* prog_node) {
    mir_module* m = (mir_module*)arc_malloc(sizeof(mir__NS_mir_module));
    m.funcs      = (mir__NS_mir_func**)0;
    m.funcs_len  = 0;
    m.funcs_cap  = 0;
    // TODO: walk prog_node (parser.program_node*) and emit mir_func entries.
    return m;
}

void mir_module_free(mir_module* m) {
    if (m == (mir_module*)0) { return; }
    arc_free((i8*)m);
}

} // namespace mir
