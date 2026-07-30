// IR main entry point for the Artemis self-hosting compiler.

namespace ir {

// Entry point: lower a fully analysed program_node to LLVM IR.
// Returns the populated module (caller must dispose it).
fn ir_main(prog: *parser.program_node, module_name: *i8) *i8 {
    return ir_main_t(prog, module_name, (i8*)0, (i8*)0);
}

// As ir_main, but with the target triple and data layout established up front.
//
// Layout-dependent codegen (@typeinfo sizes/offsets, @alignof) has to run against the
// ABI the module is actually compiled for. Attaching the layout afterwards left those
// queries answering for LLVM's default layout instead.
fn ir_main_t(prog: *parser.program_node, module_name: *i8, triple: *i8, data_layout: *i8) *i8 {
    if (module_name == (i8*)0) { module_name = "artemis_module"; }
    let mut ctx: *ir_context= make_ir_context(module_name);
    ctx.had_error = false;
    if (triple != (i8*)0)      { LLVMSetTarget(ctx.llvm_mod, triple); }
    if (data_layout != (i8*)0) { LLVMSetDataLayout(ctx.llvm_mod, data_layout); }
    // Pre-register compiler builtin types — always available without @include.
    ensure_typeinfo_types(ctx);
    ensure_memstr_types(ctx);
    visit_program(prog, ctx);
    if (ctx.had_error) {
        LLVMDisposeBuilder(ctx.llvm_builder);
        LLVMDisposeModule(ctx.llvm_mod);
        ctx.llvm_builder = (i8*)0;
        ctx.llvm_mod = (i8*)0;
        ctx.llvm_ctx = (i8*)0;
        arc_free((i8*)ctx);
        return (i8*)0;
    }
    // Finalize __artemis_init_typeinfo: add ret void terminator if the function exists.
    let mut init_fn_v: *i8= LLVMGetNamedFunction(ctx.llvm_mod, "__artemis_init_typeinfo");
    if (init_fn_v != (i8*)0) {
        let mut entry_bb2: *i8= LLVMGetFirstBasicBlock(init_fn_v);
        if (entry_bb2 != (i8*)0) {
            let mut existing_term: *i8= LLVMGetBasicBlockTerminator(entry_bb2);
            if (existing_term == (i8*)0) {
                let mut b2: *i8= LLVMCreateBuilderInContext(ctx.llvm_ctx);
                LLVMPositionBuilderAtEnd(b2, entry_bb2);
                LLVMBuildRetVoid(b2);
                LLVMDisposeBuilder(b2);
            }
        }
        // Register __artemis_init_typeinfo with @llvm.global_ctors (priority 65535).
        let mut i32t2: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);
        let mut i8pt2: *i8= LLVMPointerType(LLVMInt8TypeInContext(ctx.llvm_ctx), 0);
        let mut ctor_flds: [3]*i8;
        ctor_flds[0] = i32t2;
        ctor_flds[1] = i8pt2;
        ctor_flds[2] = i8pt2;
        let mut ctor_struct_ty: *i8= LLVMStructTypeInContext(ctx.llvm_ctx, ctor_flds, 3, 0);
        let mut ctor_entry_flds: [3]*i8;
        ctor_entry_flds[0] = LLVMConstInt(i32t2, 65535, 0);
        ctor_entry_flds[1] = init_fn_v;
        ctor_entry_flds[2] = LLVMConstNull(i8pt2);
        let mut ctor_entry: *i8= LLVMConstStructInContext(ctx.llvm_ctx, ctor_entry_flds, 3, 0);
        let mut ctor_arr: *i8= LLVMConstArray(ctor_struct_ty, &ctor_entry, 1);
        let mut ctor_arr_ty: *i8= LLVMTypeOf(ctor_arr);
        let mut ctor_gv: *i8= LLVMAddGlobal(ctx.llvm_mod, ctor_arr_ty, "llvm.global_ctors");
        LLVMSetInitializer(ctor_gv, ctor_arr);
        LLVMSetLinkage(ctor_gv, LLVMAppendingLinkage);
    }
    let mut mod: *i8= ctx.llvm_mod;
    // Transfer ownership: dispose builder, transfer module to caller
    LLVMDisposeBuilder(ctx.llvm_builder);
    ctx.llvm_builder = (i8*)0;
    ctx.llvm_mod = (i8*)0;
    ctx.llvm_ctx = (i8*)0;
    arc_free((i8*)ctx);
    return mod;
}

} // namespace ir
