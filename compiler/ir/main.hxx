#pragma once
#include "decls.hxx"

// Entry point: lower a fully analysed program_node to LLVM IR.
// unsafe_ops: optional map from SMT inject pass (UNKNOWN check sites → runtime check kind).
//   Null means no safety checks were injected (all sites were GOOD or pipeline not run).
// Returns the populated module; caller is responsible for disposing it via the ir_context.
inline LLVMModuleRef ir_main(program_node* prog, const char* module_name = "artemis_module",
                              std::unordered_map<expr_node*, check_kind>* unsafe_ops = nullptr) {
    ir_context* ctx = make_ir_context(module_name);
    if (unsafe_ops) ctx->unsafe_ops = std::move(*unsafe_ops);
    visit_program(prog, ctx);
    LLVMModuleRef mod = ctx->llvm_mod;
    // Transfer ownership: null out both mod and ctx so destroy_ir_context does not
    // dispose them.  The caller owns the module; the LLVM context is intentionally
    // left alive (leaked) — it will be freed by LLVMDisposeModule or process exit.
    ctx->llvm_mod = nullptr;
    ctx->llvm_ctx = nullptr;
    destroy_ir_context(ctx);
    return mod;
}
