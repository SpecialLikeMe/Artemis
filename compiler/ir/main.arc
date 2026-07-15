// IR main entry point for the Artemis self-hosting compiler.

namespace ir {

// Entry point: lower a fully analysed program_node to LLVM IR.
// Returns the populated module (caller must dispose it).
i8* ir_main(parser.program_node* prog, i8* module_name) {
    if (module_name == (i8*)0) { module_name = "artemis_module"; }
    ir_context* ctx = make_ir_context(module_name);
    ctx.had_error = false;
    visit_program(prog, ctx);
    if (ctx.had_error) {
        LLVMDisposeModule(ctx.llvm_mod);
        ctx.llvm_mod = (i8*)0;
        ctx.llvm_ctx = (i8*)0;
        arc_free((i8*)ctx);
        return (i8*)0;
    }
    i8* mod = ctx.llvm_mod;
    // Transfer ownership: prevent destroy_ir_context from freeing the module
    ctx.llvm_mod = (i8*)0;
    ctx.llvm_ctx = (i8*)0;
    arc_free((i8*)ctx);
    return mod;
}

} // namespace ir
