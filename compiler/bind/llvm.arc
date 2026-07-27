// LLVM C API and C stdlib bindings for the Artemis self-hosting compiler.
//
// Each foreign symbol appears twice: `raw_<name>` bound to the real C symbol via
// @link_name, and a safe wrapper `<name>` that performs the call inside `@unsafe { }`.
// Call sites use the plain name and need no annotation.
//
// The wrapper carries its own @link_name ("arc_<name>"). Without it the wrapper and
// the raw binding would emit the same symbol: the wrapper would resolve to itself
// (infinite recursion) and shadow the real library definition.
//
// These wrappers are a trust assertion, not a proof — forwarding a raw pointer does
// not make the callee safe. They assert that the compiler's own use of these symbols
// (opaque LLVM handles it created, buffers it sized) is sound.
//
// The LLVMInitializeAll*/Native* families are header macros with no linkable symbol;
// boot/llvm_init.c provides *_shim functions and the driver calls those.

// ---- Raw foreign symbols ----

@unsafe @link_name("LLVMContextCreate") extern fn raw_LLVMContextCreate() *i8;
@unsafe @link_name("LLVMContextDispose") extern fn raw_LLVMContextDispose(ctx: *i8) void;
@unsafe @link_name("LLVMModuleCreateWithNameInContext") extern fn raw_LLVMModuleCreateWithNameInContext(name: *i8, ctx: *i8) *i8;
@unsafe @link_name("LLVMDisposeModule") extern fn raw_LLVMDisposeModule(mod: *i8) void;
@unsafe @link_name("LLVMCreateBuilderInContext") extern fn raw_LLVMCreateBuilderInContext(ctx: *i8) *i8;
@unsafe @link_name("LLVMDisposeBuilder") extern fn raw_LLVMDisposeBuilder(b: *i8) void;
@unsafe @link_name("LLVMSetTarget") extern fn raw_LLVMSetTarget(mod: *i8, triple: *i8) void;
@unsafe @link_name("LLVMSetDataLayout") extern fn raw_LLVMSetDataLayout(mod: *i8, dl: *i8) void;
@unsafe @link_name("LLVMVoidTypeInContext") extern fn raw_LLVMVoidTypeInContext(ctx: *i8) *i8;
@unsafe @link_name("LLVMInt1TypeInContext") extern fn raw_LLVMInt1TypeInContext(ctx: *i8) *i8;
@unsafe @link_name("LLVMInt8TypeInContext") extern fn raw_LLVMInt8TypeInContext(ctx: *i8) *i8;
@unsafe @link_name("LLVMInt16TypeInContext") extern fn raw_LLVMInt16TypeInContext(ctx: *i8) *i8;
@unsafe @link_name("LLVMInt32TypeInContext") extern fn raw_LLVMInt32TypeInContext(ctx: *i8) *i8;
@unsafe @link_name("LLVMInt64TypeInContext") extern fn raw_LLVMInt64TypeInContext(ctx: *i8) *i8;
@unsafe @link_name("LLVMInt128TypeInContext") extern fn raw_LLVMInt128TypeInContext(ctx: *i8) *i8;
@unsafe @link_name("LLVMIntTypeInContext") extern fn raw_LLVMIntTypeInContext(ctx: *i8, bits: u32) *i8;
@unsafe @link_name("LLVMHalfTypeInContext") extern fn raw_LLVMHalfTypeInContext(ctx: *i8) *i8;
@unsafe @link_name("LLVMFloatTypeInContext") extern fn raw_LLVMFloatTypeInContext(ctx: *i8) *i8;
@unsafe @link_name("LLVMDoubleTypeInContext") extern fn raw_LLVMDoubleTypeInContext(ctx: *i8) *i8;
@unsafe @link_name("LLVMX86FP80TypeInContext") extern fn raw_LLVMX86FP80TypeInContext(ctx: *i8) *i8;
@unsafe @link_name("LLVMFP128TypeInContext") extern fn raw_LLVMFP128TypeInContext(ctx: *i8) *i8;
@unsafe @link_name("LLVMPointerType") extern fn raw_LLVMPointerType(elem: *i8, addrspace: u32) *i8;
@unsafe @link_name("LLVMPointerTypeInContext") extern fn raw_LLVMPointerTypeInContext(ctx: *i8, addrspace: u32) *i8;
@unsafe @link_name("LLVMArrayType") extern fn raw_LLVMArrayType(elem: *i8, count: u32) *i8; // deprecated in LLVM 17, removed in LLVM 19
@unsafe @link_name("LLVMArrayType2") extern fn raw_LLVMArrayType2(elem: *i8, count: u64) *i8; // use this for LLVM 17+
@unsafe @link_name("LLVMFunctionType") extern fn raw_LLVMFunctionType(ret: *i8, params: **i8, nparams: u32, variadic: i32) *i8;
@unsafe @link_name("LLVMStructCreateNamed") extern fn raw_LLVMStructCreateNamed(ctx: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMStructSetBody") extern fn raw_LLVMStructSetBody(stype: *i8, fields: **i8, nfields: u32, packed: i32) void;
@unsafe @link_name("LLVMStructTypeInContext") extern fn raw_LLVMStructTypeInContext(ctx: *i8, fields: **i8, nfields: u32, packed: i32) *i8;
@unsafe @link_name("LLVMGetTypeKind") extern fn raw_LLVMGetTypeKind(ty: *i8) i32;
@unsafe @link_name("LLVMGetElementType") extern fn raw_LLVMGetElementType(ty: *i8) *i8;
@unsafe @link_name("LLVMGetArrayLength") extern fn raw_LLVMGetArrayLength(ty: *i8) u32;
@unsafe @link_name("LLVMCountStructElementTypes") extern fn raw_LLVMCountStructElementTypes(ty: *i8) u32;
@unsafe @link_name("LLVMGetStructName") extern fn raw_LLVMGetStructName(ty: *i8) *i8;
@unsafe @link_name("LLVMGetTypeByName2") extern fn raw_LLVMGetTypeByName2(ctx: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMGetIntTypeWidth") extern fn raw_LLVMGetIntTypeWidth(ty: *i8) u32;
@unsafe @link_name("LLVMCountParamTypes") extern fn raw_LLVMCountParamTypes(fnty: *i8) u32;
@unsafe @link_name("LLVMGetParamTypes") extern fn raw_LLVMGetParamTypes(fnty: *i8, dest: **i8) void;
@unsafe @link_name("LLVMConstInt") extern fn raw_LLVMConstInt(ty: *i8, val: u64, sign_extend: i32) *i8;
@unsafe @link_name("LLVMConstReal") extern fn raw_LLVMConstReal(ty: *i8, val: f64) *i8;
@unsafe @link_name("LLVMConstNull") extern fn raw_LLVMConstNull(ty: *i8) *i8;
@unsafe @link_name("LLVMConstPointerNull") extern fn raw_LLVMConstPointerNull(ty: *i8) *i8;
@unsafe @link_name("LLVMGetUndef") extern fn raw_LLVMGetUndef(ty: *i8) *i8;
@unsafe @link_name("LLVMConstString") extern fn raw_LLVMConstString(str: *i8, length: u32, dont_null_terminate: i32) *i8;
@unsafe @link_name("LLVMConstStringInContext") extern fn raw_LLVMConstStringInContext(ctx: *i8, str: *i8, length: u32, dont_null_terminate: i32) *i8;
@unsafe @link_name("LLVMConstArray") extern fn raw_LLVMConstArray(elem_ty: *i8, vals: **i8, nvals: u32) *i8;
@unsafe @link_name("LLVMConstStructInContext") extern fn raw_LLVMConstStructInContext(ctx: *i8, vals: **i8, nvals: u32, packed: i32) *i8;
@unsafe @link_name("LLVMConstNamedStruct") extern fn raw_LLVMConstNamedStruct(sty: *i8, vals: **i8, nvals: u32) *i8;
@unsafe @link_name("LLVMConstBitCast") extern fn raw_LLVMConstBitCast(val: *i8, ty: *i8) *i8;
@unsafe @link_name("LLVMConstTrunc") extern fn raw_LLVMConstTrunc(val: *i8, to_type: *i8) *i8;
@unsafe @link_name("LLVMConstAdd") extern fn raw_LLVMConstAdd(lhs: *i8, rhs: *i8) *i8;
@unsafe @link_name("LLVMConstIntOfString") extern fn raw_LLVMConstIntOfString(ty: *i8, text: *i8, radix: u8) *i8;
@unsafe @link_name("LLVMTypeOf") extern fn raw_LLVMTypeOf(val: *i8) *i8;
@unsafe @link_name("LLVMIsConstant") extern fn raw_LLVMIsConstant(val: *i8) i32;
@unsafe @link_name("LLVMIsNull") extern fn raw_LLVMIsNull(val: *i8) i32;
@unsafe @link_name("LLVMIsUndef") extern fn raw_LLVMIsUndef(val: *i8) i32;
@unsafe @link_name("LLVMSetValueName2") extern fn raw_LLVMSetValueName2(val: *i8, name: *i8, len: u64) void;
@unsafe @link_name("LLVMGetValueName2") extern fn raw_LLVMGetValueName2(val: *i8, len: *u64) *i8;
@unsafe @link_name("LLVMSetLinkage") extern fn raw_LLVMSetLinkage(val: *i8, linkage: i32) void;
@unsafe @link_name("LLVMSetGlobalConstant") extern fn raw_LLVMSetGlobalConstant(gv: *i8, is_constant: i32) void;
@unsafe @link_name("LLVMSetInitializer") extern fn raw_LLVMSetInitializer(gv: *i8, init: *i8) void;
@unsafe @link_name("LLVMAddGlobal") extern fn raw_LLVMAddGlobal(mod: *i8, ty: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMGetNamedGlobal") extern fn raw_LLVMGetNamedGlobal(mod: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMGlobalGetValueType") extern fn raw_LLVMGlobalGetValueType(gv: *i8) *i8;
@unsafe @link_name("LLVMGetInitializer") extern fn raw_LLVMGetInitializer(gv: *i8) *i8;
@unsafe @link_name("LLVMAddFunction") extern fn raw_LLVMAddFunction(mod: *i8, name: *i8, fn_ty: *i8) *i8;
@unsafe @link_name("LLVMGetNamedFunction") extern fn raw_LLVMGetNamedFunction(mod: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMGetParam") extern fn raw_LLVMGetParam(fn_ref: *i8, idx: u32) *i8;
@unsafe @link_name("LLVMCountParams") extern fn raw_LLVMCountParams(fn_ref: *i8) u32;
@unsafe @link_name("LLVMGetFirstParam") extern fn raw_LLVMGetFirstParam(fn_ref: *i8) *i8;
@unsafe @link_name("LLVMGetNextParam") extern fn raw_LLVMGetNextParam(param: *i8) *i8;
@unsafe @link_name("LLVMSetFunctionCallConv") extern fn raw_LLVMSetFunctionCallConv(fn_ref: *i8, cc: u32) void;
@unsafe @link_name("LLVMAppendBasicBlockInContext") extern fn raw_LLVMAppendBasicBlockInContext(ctx: *i8, fn_ref: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMAppendBasicBlock") extern fn raw_LLVMAppendBasicBlock(fn_ref: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMPositionBuilderAtEnd") extern fn raw_LLVMPositionBuilderAtEnd(b: *i8, bb: *i8) void;
@unsafe @link_name("LLVMPositionBuilderBefore") extern fn raw_LLVMPositionBuilderBefore(b: *i8, inst: *i8) void;
@unsafe @link_name("LLVMGetInsertBlock") extern fn raw_LLVMGetInsertBlock(b: *i8) *i8;
@unsafe @link_name("LLVMGetBasicBlockTerminator") extern fn raw_LLVMGetBasicBlockTerminator(bb: *i8) *i8;
@unsafe @link_name("LLVMGetFirstBasicBlock") extern fn raw_LLVMGetFirstBasicBlock(fn_ref: *i8) *i8;
@unsafe @link_name("LLVMGetLastInstruction") extern fn raw_LLVMGetLastInstruction(bb: *i8) *i8;
@unsafe @link_name("LLVMGetBasicBlockParent") extern fn raw_LLVMGetBasicBlockParent(bb: *i8) *i8;
@unsafe @link_name("LLVMGetInstructionOpcode") extern fn raw_LLVMGetInstructionOpcode(inst: *i8) i32; // 27=load 1=ret 2=br 7=unreachable
@unsafe @link_name("LLVMGetOperand") extern fn raw_LLVMGetOperand(val: *i8, index: u32) *i8;
@unsafe @link_name("LLVMMoveBasicBlockAfter") extern fn raw_LLVMMoveBasicBlockAfter(bb: *i8, move_after: *i8) void;
@unsafe @link_name("LLVMBuildAdd") extern fn raw_LLVMBuildAdd(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildSub") extern fn raw_LLVMBuildSub(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildMul") extern fn raw_LLVMBuildMul(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildUDiv") extern fn raw_LLVMBuildUDiv(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildSDiv") extern fn raw_LLVMBuildSDiv(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildURem") extern fn raw_LLVMBuildURem(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildSRem") extern fn raw_LLVMBuildSRem(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildFAdd") extern fn raw_LLVMBuildFAdd(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildFSub") extern fn raw_LLVMBuildFSub(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildFMul") extern fn raw_LLVMBuildFMul(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildFDiv") extern fn raw_LLVMBuildFDiv(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildFRem") extern fn raw_LLVMBuildFRem(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildNeg") extern fn raw_LLVMBuildNeg(b: *i8, val: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildFNeg") extern fn raw_LLVMBuildFNeg(b: *i8, val: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildNot") extern fn raw_LLVMBuildNot(b: *i8, val: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildAnd") extern fn raw_LLVMBuildAnd(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildOr") extern fn raw_LLVMBuildOr(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildXor") extern fn raw_LLVMBuildXor(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildShl") extern fn raw_LLVMBuildShl(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildLShr") extern fn raw_LLVMBuildLShr(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildAShr") extern fn raw_LLVMBuildAShr(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildICmp") extern fn raw_LLVMBuildICmp(b: *i8, pred: i32, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildFCmp") extern fn raw_LLVMBuildFCmp(b: *i8, pred: i32, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildAlloca") extern fn raw_LLVMBuildAlloca(b: *i8, ty: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildLoad2") extern fn raw_LLVMBuildLoad2(b: *i8, ty: *i8, ptr: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildStore") extern fn raw_LLVMBuildStore(b: *i8, val: *i8, ptr: *i8) *i8;
@unsafe @link_name("LLVMBuildGEP2") extern fn raw_LLVMBuildGEP2(b: *i8, ty: *i8, ptr: *i8, indices: **i8, nidx: u32, name: *i8) *i8;
@unsafe @link_name("LLVMBuildInBoundsGEP2") extern fn raw_LLVMBuildInBoundsGEP2(b: *i8, ty: *i8, ptr: *i8, indices: **i8, nidx: u32, name: *i8) *i8;
@unsafe @link_name("LLVMBuildStructGEP2") extern fn raw_LLVMBuildStructGEP2(b: *i8, ty: *i8, ptr: *i8, idx: u32, name: *i8) *i8;
@unsafe @link_name("LLVMBuildMemSet") extern fn raw_LLVMBuildMemSet(b: *i8, ptr: *i8, val: *i8, len: *i8, align: u32) *i8;
@unsafe @link_name("LLVMBuildMemCpy") extern fn raw_LLVMBuildMemCpy(b: *i8, dst: *i8, dst_align: u32, src: *i8, src_align: u32, size: *i8) *i8;
@unsafe @link_name("LLVMBuildBr") extern fn raw_LLVMBuildBr(b: *i8, dest: *i8) *i8;
@unsafe @link_name("LLVMBuildCondBr") extern fn raw_LLVMBuildCondBr(b: *i8, cond: *i8, then_bb: *i8, else_bb: *i8) *i8;
@unsafe @link_name("LLVMBuildRet") extern fn raw_LLVMBuildRet(b: *i8, val: *i8) *i8;
@unsafe @link_name("LLVMBuildRetVoid") extern fn raw_LLVMBuildRetVoid(b: *i8) *i8;
@unsafe @link_name("LLVMBuildUnreachable") extern fn raw_LLVMBuildUnreachable(b: *i8) *i8;
@unsafe @link_name("LLVMBuildCall2") extern fn raw_LLVMBuildCall2(b: *i8, fn_ty: *i8, fn_ref: *i8, args: **i8, nargs: u32, name: *i8) *i8;
@unsafe @link_name("LLVMGetInlineAsm") extern fn raw_LLVMGetInlineAsm(ty: *i8, asm_string: *i8, asm_len: u64, constraints: *i8, con_len: u64, has_side_effects: i32, is_align_stack: i32, dialect: i32, can_throw: i32) *i8;
@unsafe @link_name("LLVMBuildTrunc") extern fn raw_LLVMBuildTrunc(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildZExt") extern fn raw_LLVMBuildZExt(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildSExt") extern fn raw_LLVMBuildSExt(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildFPToUI") extern fn raw_LLVMBuildFPToUI(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildFPToSI") extern fn raw_LLVMBuildFPToSI(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildUIToFP") extern fn raw_LLVMBuildUIToFP(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildSIToFP") extern fn raw_LLVMBuildSIToFP(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildFPTrunc") extern fn raw_LLVMBuildFPTrunc(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildFPExt") extern fn raw_LLVMBuildFPExt(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildFPCast") extern fn raw_LLVMBuildFPCast(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildBitCast") extern fn raw_LLVMBuildBitCast(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildIntToPtr") extern fn raw_LLVMBuildIntToPtr(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildPtrToInt") extern fn raw_LLVMBuildPtrToInt(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildPointerCast") extern fn raw_LLVMBuildPointerCast(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildExtractValue") extern fn raw_LLVMBuildExtractValue(b: *i8, agg: *i8, idx: u32, name: *i8) *i8;
@unsafe @link_name("LLVMBuildInsertValue") extern fn raw_LLVMBuildInsertValue(b: *i8, agg: *i8, val: *i8, idx: u32, name: *i8) *i8;
@unsafe @link_name("LLVMBuildFence") extern fn raw_LLVMBuildFence(b: *i8, ordering: i32, single_thread: i32, name: *i8) *i8;
@unsafe @link_name("LLVMBuildAtomicRMW") extern fn raw_LLVMBuildAtomicRMW(b: *i8, op: i32, ptr: *i8, val: *i8, ordering: i32, single_thread: i32) *i8;
@unsafe @link_name("LLVMBuildAtomicCmpXchg") extern fn raw_LLVMBuildAtomicCmpXchg(b: *i8, ptr: *i8, cmp: *i8, new_val: *i8, success_ord: i32, failure_ord: i32, single_thread: i32) *i8;
@unsafe @link_name("LLVMBuildPhi") extern fn raw_LLVMBuildPhi(b: *i8, ty: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMAddIncoming") extern fn raw_LLVMAddIncoming(phi: *i8, vals: **i8, bbs: **i8, count: u32) void;
@unsafe @link_name("LLVMBuildSelect") extern fn raw_LLVMBuildSelect(b: *i8, cond: *i8, then_val: *i8, else_val: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildSwitch") extern fn raw_LLVMBuildSwitch(b: *i8, val: *i8, default_bb: *i8, num_cases: u32) *i8;
@unsafe @link_name("LLVMAddCase") extern fn raw_LLVMAddCase(sw: *i8, on_val: *i8, dest: *i8) void;
@unsafe @link_name("LLVMGetTargetFromTriple") extern fn raw_LLVMGetTargetFromTriple(triple: *i8, target_out: **i8, err_out: **i8) i32;
@unsafe @link_name("LLVMCreateTargetMachine") extern fn raw_LLVMCreateTargetMachine(target: *i8, triple: *i8, cpu: *i8, features: *i8, opt_level: i32, reloc: i32, code_model: i32) *i8;
@unsafe @link_name("LLVMDisposeTargetMachine") extern fn raw_LLVMDisposeTargetMachine(tm: *i8) void;
@unsafe @link_name("LLVMGetDefaultTargetTriple") extern fn raw_LLVMGetDefaultTargetTriple() *i8;
@unsafe @link_name("LLVMGetHostCPUName") extern fn raw_LLVMGetHostCPUName() *i8;
@unsafe @link_name("LLVMGetHostCPUFeatures") extern fn raw_LLVMGetHostCPUFeatures() *i8;
@unsafe @link_name("LLVMDisposeMessage") extern fn raw_LLVMDisposeMessage(msg: *i8) void;
@unsafe @link_name("LLVMCreateTargetDataLayout") extern fn raw_LLVMCreateTargetDataLayout(tm: *i8) *i8;
@unsafe @link_name("LLVMCopyStringRepOfTargetData") extern fn raw_LLVMCopyStringRepOfTargetData(td: *i8) *i8;
@unsafe @link_name("LLVMDisposeTargetData") extern fn raw_LLVMDisposeTargetData(td: *i8) void;
@unsafe @link_name("LLVMVerifyModule") extern fn raw_LLVMVerifyModule(mod: *i8, action: i32, msg_out: **i8) i32;
@unsafe @link_name("LLVMTargetMachineEmitToFile") extern fn raw_LLVMTargetMachineEmitToFile(tm: *i8, mod: *i8, filename: *i8, filetype: i32, err_out: **i8) i32;
@unsafe @link_name("LLVMPrintModuleToFile") extern fn raw_LLVMPrintModuleToFile(mod: *i8, filename: *i8, err_out: **i8) i32;
@unsafe @link_name("LLVMPrintModuleToString") extern fn raw_LLVMPrintModuleToString(mod: *i8) *i8;
@unsafe @link_name("LLVMCreatePassBuilderOptions") extern fn raw_LLVMCreatePassBuilderOptions() *i8;
@unsafe @link_name("LLVMDisposePassBuilderOptions") extern fn raw_LLVMDisposePassBuilderOptions(opts: *i8) void;
@unsafe @link_name("LLVMRunPasses") extern fn raw_LLVMRunPasses(mod: *i8, passes: *i8, tm: *i8, opts: *i8) *i8;
@unsafe @link_name("LLVMConsumeError") extern fn raw_LLVMConsumeError(err: *i8) void;
@unsafe @link_name("LLVMGetErrorMessage") extern fn raw_LLVMGetErrorMessage(err: *i8) *i8;
@unsafe @link_name("LLVMDisposeErrorMessage") extern fn raw_LLVMDisposeErrorMessage(msg: *i8) void;
@unsafe @link_name("LLVMBuildGlobalStringPtr") extern fn raw_LLVMBuildGlobalStringPtr(b: *i8, str: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMBuildGlobalString") extern fn raw_LLVMBuildGlobalString(b: *i8, str: *i8, name: *i8) *i8;
@unsafe @link_name("LLVMSizeOf") extern fn raw_LLVMSizeOf(ty: *i8) *i8;
@unsafe @link_name("LLVMAlignOf") extern fn raw_LLVMAlignOf(ty: *i8) *i8;
@unsafe @link_name("LLVMStructGetTypeAtIndex") extern fn raw_LLVMStructGetTypeAtIndex(sty: *i8, idx: u32) *i8;
@unsafe @link_name("LLVMIsAConstant") extern fn raw_LLVMIsAConstant(val: *i8) *i8;
@unsafe @link_name("LLVMIsAConstantInt") extern fn raw_LLVMIsAConstantInt(val: *i8) *i8;
@unsafe @link_name("LLVMConstIntGetSExtValue") extern fn raw_LLVMConstIntGetSExtValue(val: *i8) i64;
@unsafe @link_name("LLVMConstIntGetZExtValue") extern fn raw_LLVMConstIntGetZExtValue(val: *i8) u64;
@unsafe @link_name("LLVMGetStructElementTypes_get") extern fn raw_LLVMGetStructElementTypes_get(sty: *i8, idx: u32) *i8;
@unsafe @link_name("LLVMFunctionType_get_params") extern fn raw_LLVMFunctionType_get_params(fnty: *i8, dest: **i8, n: u32) void;
@unsafe @link_name("LLVMGetReturnType") extern fn raw_LLVMGetReturnType(fnty: *i8) *i8;
@unsafe @link_name("LLVMGetFunctionCallConv") extern fn raw_LLVMGetFunctionCallConv(fn_ref: *i8) i32;
@unsafe @link_name("LLVMSetAlignment") extern fn raw_LLVMSetAlignment(val: *i8, bytes: u32) void;
@unsafe @link_name("LLVMSetVolatile") extern fn raw_LLVMSetVolatile(memory_access_inst: *i8, is_volatile: i32) void;
@unsafe @link_name("LLVMGetCalledFunctionType") extern fn raw_LLVMGetCalledFunctionType(call: *i8) *i8;
@unsafe @link_name("LLVMGetBasicBlocks_first") extern fn raw_LLVMGetBasicBlocks_first(fn_ref: *i8) *i8;
@unsafe @link_name("LLVMGetNextBasicBlock") extern fn raw_LLVMGetNextBasicBlock(bb: *i8) *i8;
@unsafe @link_name("LLVMCountBasicBlocks") extern fn raw_LLVMCountBasicBlocks(fn_ref: *i8) i32;
@unsafe @link_name("LLVMInitializeAllTargetInfos_shim") extern fn raw_LLVMInitializeAllTargetInfos_shim() void;
@unsafe @link_name("LLVMInitializeAllTargets_shim") extern fn raw_LLVMInitializeAllTargets_shim() void;
@unsafe @link_name("LLVMInitializeAllTargetMCs_shim") extern fn raw_LLVMInitializeAllTargetMCs_shim() void;
@unsafe @link_name("LLVMInitializeAllAsmPrinters_shim") extern fn raw_LLVMInitializeAllAsmPrinters_shim() void;
@unsafe @link_name("LLVMInitializeAllAsmParsers_shim") extern fn raw_LLVMInitializeAllAsmParsers_shim() void;
@unsafe @link_name("malloc") extern fn raw_malloc(size: u64) *i8;
@unsafe @link_name("realloc") extern fn raw_realloc(ptr: *i8, size: u64) *i8;
@unsafe @link_name("free") extern fn raw_free(ptr: *i8) void;
@unsafe @link_name("memset") extern fn raw_memset(dst: *i8, val: i32, n: u64) *i8;
@unsafe @link_name("memcpy") extern fn raw_memcpy(dst: *i8, src: *i8, n: u64) *i8;
@unsafe @link_name("memmove") extern fn raw_memmove(dst: *i8, src: *i8, n: u64) *i8;
@unsafe @link_name("memcmp") extern fn raw_memcmp(a: *i8, b: *i8, n: u64) i32;
@unsafe @link_name("strcmp") extern fn raw_strcmp(a: *i8, b: *i8) i32;
@unsafe @link_name("strncmp") extern fn raw_strncmp(a: *i8, b: *i8, n: u64) i32;
@unsafe @link_name("strlen") extern fn raw_strlen(s: *i8) u64;
@unsafe @link_name("strcpy") extern fn raw_strcpy(dst: *i8, src: *i8) *i8;
@unsafe @link_name("strcat") extern fn raw_strcat(dst: *i8, src: *i8) *i8;
@unsafe @link_name("strstr") extern fn raw_strstr(haystack: *i8, needle: *i8) *i8;
@unsafe @link_name("strchr") extern fn raw_strchr(s: *i8, c: i32) *i8;
@unsafe @link_name("puts") extern fn raw_puts(s: *i8) i32;
@unsafe @link_name("putchar") extern fn raw_putchar(c: i32) i32;
@unsafe @link_name("atoi") extern fn raw_atoi(s: *i8) i32;
@unsafe @link_name("atoll") extern fn raw_atoll(s: *i8) i64;
@unsafe @link_name("atof") extern fn raw_atof(s: *i8) f64;
@unsafe @link_name("strtoll") extern fn raw_strtoll(s: *i8, end: **i8, base: i32) i64;
@unsafe @link_name("strtoull") extern fn raw_strtoull(s: *i8, end: **i8, base: i32) u64;
@unsafe @link_name("strtod") extern fn raw_strtod(s: *i8, end: **i8) f64;
@unsafe @link_name("exit") extern fn raw_exit(code: i32) void;
@unsafe @link_name("system") extern fn raw_system(cmd: *i8) i32;
@unsafe @link_name("remove") extern fn raw_remove(path: *i8) i32;
@unsafe @link_name("fopen") extern fn raw_fopen(path: *i8, mode: *i8) *void;
@unsafe @link_name("fclose") extern fn raw_fclose(fp: *void) i32;
@unsafe @link_name("fread") extern fn raw_fread(buf: *void, sz: u64, n: u64, fp: *void) u64;
@unsafe @link_name("fwrite") extern fn raw_fwrite(buf: *void, sz: u64, n: u64, fp: *void) u64;
@unsafe @link_name("fseek") extern fn raw_fseek(fp: *void, off: i64, whence: i32) i32;
@unsafe @link_name("ftell") extern fn raw_ftell(fp: *void) i64;
@unsafe @link_name("feof") extern fn raw_feof(fp: *void) i32;
@unsafe @link_name("fflush") extern fn raw_fflush(fp: *void) i32;
@unsafe @link_name("getenv") extern fn raw_getenv(name: *i8) *i8;
@unsafe @link_name("getchar") extern fn raw_getchar() i32;
@unsafe @link_name("fgets") extern fn raw_fgets(buf: *i8, n: i32, fp: *void) *i8;
@unsafe @link_name("popen") extern fn raw_popen(cmd: *i8, mode: *i8) *void;
@unsafe @link_name("pclose") extern fn raw_pclose(fp: *void) i32;
@unsafe @link_name("stdout_file") extern fn raw_stdout_file() *void;
@unsafe @link_name("isalpha") extern fn raw_isalpha(c: i32) i32;
@unsafe @link_name("isdigit") extern fn raw_isdigit(c: i32) i32;
@unsafe @link_name("isalnum") extern fn raw_isalnum(c: i32) i32;
@unsafe @link_name("isspace") extern fn raw_isspace(c: i32) i32;
@unsafe @link_name("isxdigit") extern fn raw_isxdigit(c: i32) i32;
@unsafe @link_name("tolower") extern fn raw_tolower(c: i32) i32;
@unsafe @link_name("toupper") extern fn raw_toupper(c: i32) i32;
@unsafe @link_name("GetModuleFileNameA") extern fn raw_GetModuleFileNameA(hmod: *void, filename: *i8, size: u32) i32;

// ---- Variadic foreign symbols (no va_list, so not wrappable) ----

@unsafe extern fn sprintf(buf: *i8, fmt: *i8, ...) i32;
@unsafe extern fn snprintf(buf: *i8, n: u64, fmt: *i8, ...) i32;
@unsafe extern fn printf(fmt: *i8, ...) i32;
@unsafe extern fn fprintf(stream: *void, fmt: *i8, ...) i32;

// ---- Safe wrappers ----

@link_name("arc_LLVMContextCreate") fn LLVMContextCreate() *i8 { let mut r: *i8; @unsafe { r = raw_LLVMContextCreate(); } return r; }
@link_name("arc_LLVMContextDispose") fn LLVMContextDispose(ctx: *i8) void { @unsafe { raw_LLVMContextDispose(ctx); } }
@link_name("arc_LLVMModuleCreateWithNameInContext") fn LLVMModuleCreateWithNameInContext(name: *i8, ctx: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMModuleCreateWithNameInContext(name, ctx); } return r; }
@link_name("arc_LLVMDisposeModule") fn LLVMDisposeModule(mod: *i8) void { @unsafe { raw_LLVMDisposeModule(mod); } }
@link_name("arc_LLVMCreateBuilderInContext") fn LLVMCreateBuilderInContext(ctx: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMCreateBuilderInContext(ctx); } return r; }
@link_name("arc_LLVMDisposeBuilder") fn LLVMDisposeBuilder(b: *i8) void { @unsafe { raw_LLVMDisposeBuilder(b); } }
@link_name("arc_LLVMSetTarget") fn LLVMSetTarget(mod: *i8, triple: *i8) void { @unsafe { raw_LLVMSetTarget(mod, triple); } }
@link_name("arc_LLVMSetDataLayout") fn LLVMSetDataLayout(mod: *i8, dl: *i8) void { @unsafe { raw_LLVMSetDataLayout(mod, dl); } }
@link_name("arc_LLVMVoidTypeInContext") fn LLVMVoidTypeInContext(ctx: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMVoidTypeInContext(ctx); } return r; }
@link_name("arc_LLVMInt1TypeInContext") fn LLVMInt1TypeInContext(ctx: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMInt1TypeInContext(ctx); } return r; }
@link_name("arc_LLVMInt8TypeInContext") fn LLVMInt8TypeInContext(ctx: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMInt8TypeInContext(ctx); } return r; }
@link_name("arc_LLVMInt16TypeInContext") fn LLVMInt16TypeInContext(ctx: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMInt16TypeInContext(ctx); } return r; }
@link_name("arc_LLVMInt32TypeInContext") fn LLVMInt32TypeInContext(ctx: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMInt32TypeInContext(ctx); } return r; }
@link_name("arc_LLVMInt64TypeInContext") fn LLVMInt64TypeInContext(ctx: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMInt64TypeInContext(ctx); } return r; }
@link_name("arc_LLVMInt128TypeInContext") fn LLVMInt128TypeInContext(ctx: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMInt128TypeInContext(ctx); } return r; }
@link_name("arc_LLVMIntTypeInContext") fn LLVMIntTypeInContext(ctx: *i8, bits: u32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMIntTypeInContext(ctx, bits); } return r; }
@link_name("arc_LLVMHalfTypeInContext") fn LLVMHalfTypeInContext(ctx: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMHalfTypeInContext(ctx); } return r; }
@link_name("arc_LLVMFloatTypeInContext") fn LLVMFloatTypeInContext(ctx: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMFloatTypeInContext(ctx); } return r; }
@link_name("arc_LLVMDoubleTypeInContext") fn LLVMDoubleTypeInContext(ctx: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMDoubleTypeInContext(ctx); } return r; }
@link_name("arc_LLVMX86FP80TypeInContext") fn LLVMX86FP80TypeInContext(ctx: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMX86FP80TypeInContext(ctx); } return r; }
@link_name("arc_LLVMFP128TypeInContext") fn LLVMFP128TypeInContext(ctx: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMFP128TypeInContext(ctx); } return r; }
@link_name("arc_LLVMPointerType") fn LLVMPointerType(elem: *i8, addrspace: u32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMPointerType(elem, addrspace); } return r; }
@link_name("arc_LLVMPointerTypeInContext") fn LLVMPointerTypeInContext(ctx: *i8, addrspace: u32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMPointerTypeInContext(ctx, addrspace); } return r; }
@link_name("arc_LLVMArrayType") fn LLVMArrayType(elem: *i8, count: u32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMArrayType(elem, count); } return r; }
@link_name("arc_LLVMArrayType2") fn LLVMArrayType2(elem: *i8, count: u64) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMArrayType2(elem, count); } return r; }
@link_name("arc_LLVMFunctionType") fn LLVMFunctionType(ret: *i8, params: **i8, nparams: u32, variadic: i32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMFunctionType(ret, params, nparams, variadic); } return r; }
@link_name("arc_LLVMStructCreateNamed") fn LLVMStructCreateNamed(ctx: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMStructCreateNamed(ctx, name); } return r; }
@link_name("arc_LLVMStructSetBody") fn LLVMStructSetBody(stype: *i8, fields: **i8, nfields: u32, packed: i32) void { @unsafe { raw_LLVMStructSetBody(stype, fields, nfields, packed); } }
@link_name("arc_LLVMStructTypeInContext") fn LLVMStructTypeInContext(ctx: *i8, fields: **i8, nfields: u32, packed: i32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMStructTypeInContext(ctx, fields, nfields, packed); } return r; }
@link_name("arc_LLVMGetTypeKind") fn LLVMGetTypeKind(ty: *i8) i32 { let mut r: i32; @unsafe { r = raw_LLVMGetTypeKind(ty); } return r; }
@link_name("arc_LLVMGetElementType") fn LLVMGetElementType(ty: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetElementType(ty); } return r; }
@link_name("arc_LLVMGetArrayLength") fn LLVMGetArrayLength(ty: *i8) u32 { let mut r: u32; @unsafe { r = raw_LLVMGetArrayLength(ty); } return r; }
@link_name("arc_LLVMCountStructElementTypes") fn LLVMCountStructElementTypes(ty: *i8) u32 { let mut r: u32; @unsafe { r = raw_LLVMCountStructElementTypes(ty); } return r; }
@link_name("arc_LLVMGetStructName") fn LLVMGetStructName(ty: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetStructName(ty); } return r; }
@link_name("arc_LLVMGetTypeByName2") fn LLVMGetTypeByName2(ctx: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetTypeByName2(ctx, name); } return r; }
@link_name("arc_LLVMGetIntTypeWidth") fn LLVMGetIntTypeWidth(ty: *i8) u32 { let mut r: u32; @unsafe { r = raw_LLVMGetIntTypeWidth(ty); } return r; }
@link_name("arc_LLVMCountParamTypes") fn LLVMCountParamTypes(fnty: *i8) u32 { let mut r: u32; @unsafe { r = raw_LLVMCountParamTypes(fnty); } return r; }
@link_name("arc_LLVMGetParamTypes") fn LLVMGetParamTypes(fnty: *i8, dest: **i8) void { @unsafe { raw_LLVMGetParamTypes(fnty, dest); } }
@link_name("arc_LLVMConstInt") fn LLVMConstInt(ty: *i8, val: u64, sign_extend: i32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMConstInt(ty, val, sign_extend); } return r; }
@link_name("arc_LLVMConstReal") fn LLVMConstReal(ty: *i8, val: f64) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMConstReal(ty, val); } return r; }
@link_name("arc_LLVMConstNull") fn LLVMConstNull(ty: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMConstNull(ty); } return r; }
@link_name("arc_LLVMConstPointerNull") fn LLVMConstPointerNull(ty: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMConstPointerNull(ty); } return r; }
@link_name("arc_LLVMGetUndef") fn LLVMGetUndef(ty: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetUndef(ty); } return r; }
@link_name("arc_LLVMConstString") fn LLVMConstString(str: *i8, length: u32, dont_null_terminate: i32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMConstString(str, length, dont_null_terminate); } return r; }
@link_name("arc_LLVMConstStringInContext") fn LLVMConstStringInContext(ctx: *i8, str: *i8, length: u32, dont_null_terminate: i32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMConstStringInContext(ctx, str, length, dont_null_terminate); } return r; }
@link_name("arc_LLVMConstArray") fn LLVMConstArray(elem_ty: *i8, vals: **i8, nvals: u32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMConstArray(elem_ty, vals, nvals); } return r; }
@link_name("arc_LLVMConstStructInContext") fn LLVMConstStructInContext(ctx: *i8, vals: **i8, nvals: u32, packed: i32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMConstStructInContext(ctx, vals, nvals, packed); } return r; }
@link_name("arc_LLVMConstNamedStruct") fn LLVMConstNamedStruct(sty: *i8, vals: **i8, nvals: u32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMConstNamedStruct(sty, vals, nvals); } return r; }
@link_name("arc_LLVMConstBitCast") fn LLVMConstBitCast(val: *i8, ty: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMConstBitCast(val, ty); } return r; }
@link_name("arc_LLVMConstTrunc") fn LLVMConstTrunc(val: *i8, to_type: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMConstTrunc(val, to_type); } return r; }
@link_name("arc_LLVMConstAdd") fn LLVMConstAdd(lhs: *i8, rhs: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMConstAdd(lhs, rhs); } return r; }
@link_name("arc_LLVMConstIntOfString") fn LLVMConstIntOfString(ty: *i8, text: *i8, radix: u8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMConstIntOfString(ty, text, radix); } return r; }
@link_name("arc_LLVMTypeOf") fn LLVMTypeOf(val: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMTypeOf(val); } return r; }
@link_name("arc_LLVMIsConstant") fn LLVMIsConstant(val: *i8) i32 { let mut r: i32; @unsafe { r = raw_LLVMIsConstant(val); } return r; }
@link_name("arc_LLVMIsNull") fn LLVMIsNull(val: *i8) i32 { let mut r: i32; @unsafe { r = raw_LLVMIsNull(val); } return r; }
@link_name("arc_LLVMIsUndef") fn LLVMIsUndef(val: *i8) i32 { let mut r: i32; @unsafe { r = raw_LLVMIsUndef(val); } return r; }
@link_name("arc_LLVMSetValueName2") fn LLVMSetValueName2(val: *i8, name: *i8, len: u64) void { @unsafe { raw_LLVMSetValueName2(val, name, len); } }
@link_name("arc_LLVMGetValueName2") fn LLVMGetValueName2(val: *i8, len: *u64) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetValueName2(val, len); } return r; }
@link_name("arc_LLVMSetLinkage") fn LLVMSetLinkage(val: *i8, linkage: i32) void { @unsafe { raw_LLVMSetLinkage(val, linkage); } }
@link_name("arc_LLVMSetGlobalConstant") fn LLVMSetGlobalConstant(gv: *i8, is_constant: i32) void { @unsafe { raw_LLVMSetGlobalConstant(gv, is_constant); } }
@link_name("arc_LLVMSetInitializer") fn LLVMSetInitializer(gv: *i8, init: *i8) void { @unsafe { raw_LLVMSetInitializer(gv, init); } }
@link_name("arc_LLVMAddGlobal") fn LLVMAddGlobal(mod: *i8, ty: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMAddGlobal(mod, ty, name); } return r; }
@link_name("arc_LLVMGetNamedGlobal") fn LLVMGetNamedGlobal(mod: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetNamedGlobal(mod, name); } return r; }
@link_name("arc_LLVMGlobalGetValueType") fn LLVMGlobalGetValueType(gv: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGlobalGetValueType(gv); } return r; }
@link_name("arc_LLVMGetInitializer") fn LLVMGetInitializer(gv: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetInitializer(gv); } return r; }
@link_name("arc_LLVMAddFunction") fn LLVMAddFunction(mod: *i8, name: *i8, fn_ty: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMAddFunction(mod, name, fn_ty); } return r; }
@link_name("arc_LLVMGetNamedFunction") fn LLVMGetNamedFunction(mod: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetNamedFunction(mod, name); } return r; }
@link_name("arc_LLVMGetParam") fn LLVMGetParam(fn_ref: *i8, idx: u32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetParam(fn_ref, idx); } return r; }
@link_name("arc_LLVMCountParams") fn LLVMCountParams(fn_ref: *i8) u32 { let mut r: u32; @unsafe { r = raw_LLVMCountParams(fn_ref); } return r; }
@link_name("arc_LLVMGetFirstParam") fn LLVMGetFirstParam(fn_ref: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetFirstParam(fn_ref); } return r; }
@link_name("arc_LLVMGetNextParam") fn LLVMGetNextParam(param: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetNextParam(param); } return r; }
@link_name("arc_LLVMSetFunctionCallConv") fn LLVMSetFunctionCallConv(fn_ref: *i8, cc: u32) void { @unsafe { raw_LLVMSetFunctionCallConv(fn_ref, cc); } }
@link_name("arc_LLVMAppendBasicBlockInContext") fn LLVMAppendBasicBlockInContext(ctx: *i8, fn_ref: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMAppendBasicBlockInContext(ctx, fn_ref, name); } return r; }
@link_name("arc_LLVMAppendBasicBlock") fn LLVMAppendBasicBlock(fn_ref: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMAppendBasicBlock(fn_ref, name); } return r; }
@link_name("arc_LLVMPositionBuilderAtEnd") fn LLVMPositionBuilderAtEnd(b: *i8, bb: *i8) void { @unsafe { raw_LLVMPositionBuilderAtEnd(b, bb); } }
@link_name("arc_LLVMPositionBuilderBefore") fn LLVMPositionBuilderBefore(b: *i8, inst: *i8) void { @unsafe { raw_LLVMPositionBuilderBefore(b, inst); } }
@link_name("arc_LLVMGetInsertBlock") fn LLVMGetInsertBlock(b: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetInsertBlock(b); } return r; }
@link_name("arc_LLVMGetBasicBlockTerminator") fn LLVMGetBasicBlockTerminator(bb: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetBasicBlockTerminator(bb); } return r; }
@link_name("arc_LLVMGetFirstBasicBlock") fn LLVMGetFirstBasicBlock(fn_ref: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetFirstBasicBlock(fn_ref); } return r; }
@link_name("arc_LLVMGetLastInstruction") fn LLVMGetLastInstruction(bb: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetLastInstruction(bb); } return r; }
@link_name("arc_LLVMGetBasicBlockParent") fn LLVMGetBasicBlockParent(bb: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetBasicBlockParent(bb); } return r; }
@link_name("arc_LLVMGetInstructionOpcode") fn LLVMGetInstructionOpcode(inst: *i8) i32 { let mut r: i32; @unsafe { r = raw_LLVMGetInstructionOpcode(inst); } return r; }
@link_name("arc_LLVMGetOperand") fn LLVMGetOperand(val: *i8, index: u32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetOperand(val, index); } return r; }
@link_name("arc_LLVMMoveBasicBlockAfter") fn LLVMMoveBasicBlockAfter(bb: *i8, move_after: *i8) void { @unsafe { raw_LLVMMoveBasicBlockAfter(bb, move_after); } }
@link_name("arc_LLVMBuildAdd") fn LLVMBuildAdd(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildAdd(b, lhs, rhs, name); } return r; }
@link_name("arc_LLVMBuildSub") fn LLVMBuildSub(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildSub(b, lhs, rhs, name); } return r; }
@link_name("arc_LLVMBuildMul") fn LLVMBuildMul(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildMul(b, lhs, rhs, name); } return r; }
@link_name("arc_LLVMBuildUDiv") fn LLVMBuildUDiv(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildUDiv(b, lhs, rhs, name); } return r; }
@link_name("arc_LLVMBuildSDiv") fn LLVMBuildSDiv(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildSDiv(b, lhs, rhs, name); } return r; }
@link_name("arc_LLVMBuildURem") fn LLVMBuildURem(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildURem(b, lhs, rhs, name); } return r; }
@link_name("arc_LLVMBuildSRem") fn LLVMBuildSRem(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildSRem(b, lhs, rhs, name); } return r; }
@link_name("arc_LLVMBuildFAdd") fn LLVMBuildFAdd(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildFAdd(b, lhs, rhs, name); } return r; }
@link_name("arc_LLVMBuildFSub") fn LLVMBuildFSub(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildFSub(b, lhs, rhs, name); } return r; }
@link_name("arc_LLVMBuildFMul") fn LLVMBuildFMul(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildFMul(b, lhs, rhs, name); } return r; }
@link_name("arc_LLVMBuildFDiv") fn LLVMBuildFDiv(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildFDiv(b, lhs, rhs, name); } return r; }
@link_name("arc_LLVMBuildFRem") fn LLVMBuildFRem(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildFRem(b, lhs, rhs, name); } return r; }
@link_name("arc_LLVMBuildNeg") fn LLVMBuildNeg(b: *i8, val: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildNeg(b, val, name); } return r; }
@link_name("arc_LLVMBuildFNeg") fn LLVMBuildFNeg(b: *i8, val: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildFNeg(b, val, name); } return r; }
@link_name("arc_LLVMBuildNot") fn LLVMBuildNot(b: *i8, val: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildNot(b, val, name); } return r; }
@link_name("arc_LLVMBuildAnd") fn LLVMBuildAnd(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildAnd(b, lhs, rhs, name); } return r; }
@link_name("arc_LLVMBuildOr") fn LLVMBuildOr(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildOr(b, lhs, rhs, name); } return r; }
@link_name("arc_LLVMBuildXor") fn LLVMBuildXor(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildXor(b, lhs, rhs, name); } return r; }
@link_name("arc_LLVMBuildShl") fn LLVMBuildShl(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildShl(b, lhs, rhs, name); } return r; }
@link_name("arc_LLVMBuildLShr") fn LLVMBuildLShr(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildLShr(b, lhs, rhs, name); } return r; }
@link_name("arc_LLVMBuildAShr") fn LLVMBuildAShr(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildAShr(b, lhs, rhs, name); } return r; }
@link_name("arc_LLVMBuildICmp") fn LLVMBuildICmp(b: *i8, pred: i32, lhs: *i8, rhs: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildICmp(b, pred, lhs, rhs, name); } return r; }
@link_name("arc_LLVMBuildFCmp") fn LLVMBuildFCmp(b: *i8, pred: i32, lhs: *i8, rhs: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildFCmp(b, pred, lhs, rhs, name); } return r; }
@link_name("arc_LLVMBuildAlloca") fn LLVMBuildAlloca(b: *i8, ty: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildAlloca(b, ty, name); } return r; }
@link_name("arc_LLVMBuildLoad2") fn LLVMBuildLoad2(b: *i8, ty: *i8, ptr: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildLoad2(b, ty, ptr, name); } return r; }
@link_name("arc_LLVMBuildStore") fn LLVMBuildStore(b: *i8, val: *i8, ptr: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildStore(b, val, ptr); } return r; }
@link_name("arc_LLVMBuildGEP2") fn LLVMBuildGEP2(b: *i8, ty: *i8, ptr: *i8, indices: **i8, nidx: u32, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildGEP2(b, ty, ptr, indices, nidx, name); } return r; }
@link_name("arc_LLVMBuildInBoundsGEP2") fn LLVMBuildInBoundsGEP2(b: *i8, ty: *i8, ptr: *i8, indices: **i8, nidx: u32, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildInBoundsGEP2(b, ty, ptr, indices, nidx, name); } return r; }
@link_name("arc_LLVMBuildStructGEP2") fn LLVMBuildStructGEP2(b: *i8, ty: *i8, ptr: *i8, idx: u32, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildStructGEP2(b, ty, ptr, idx, name); } return r; }
@link_name("arc_LLVMBuildMemSet") fn LLVMBuildMemSet(b: *i8, ptr: *i8, val: *i8, len: *i8, align: u32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildMemSet(b, ptr, val, len, align); } return r; }
@link_name("arc_LLVMBuildMemCpy") fn LLVMBuildMemCpy(b: *i8, dst: *i8, dst_align: u32, src: *i8, src_align: u32, size: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildMemCpy(b, dst, dst_align, src, src_align, size); } return r; }
@link_name("arc_LLVMBuildBr") fn LLVMBuildBr(b: *i8, dest: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildBr(b, dest); } return r; }
@link_name("arc_LLVMBuildCondBr") fn LLVMBuildCondBr(b: *i8, cond: *i8, then_bb: *i8, else_bb: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildCondBr(b, cond, then_bb, else_bb); } return r; }
@link_name("arc_LLVMBuildRet") fn LLVMBuildRet(b: *i8, val: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildRet(b, val); } return r; }
@link_name("arc_LLVMBuildRetVoid") fn LLVMBuildRetVoid(b: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildRetVoid(b); } return r; }
@link_name("arc_LLVMBuildUnreachable") fn LLVMBuildUnreachable(b: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildUnreachable(b); } return r; }
@link_name("arc_LLVMBuildCall2") fn LLVMBuildCall2(b: *i8, fn_ty: *i8, fn_ref: *i8, args: **i8, nargs: u32, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildCall2(b, fn_ty, fn_ref, args, nargs, name); } return r; }
@link_name("arc_LLVMGetInlineAsm") fn LLVMGetInlineAsm(ty: *i8, asm_string: *i8, asm_len: u64, constraints: *i8, con_len: u64, has_side_effects: i32, is_align_stack: i32, dialect: i32, can_throw: i32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetInlineAsm(ty, asm_string, asm_len, constraints, con_len, has_side_effects, is_align_stack, dialect, can_throw); } return r; }
@link_name("arc_LLVMBuildTrunc") fn LLVMBuildTrunc(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildTrunc(b, val, dest_ty, name); } return r; }
@link_name("arc_LLVMBuildZExt") fn LLVMBuildZExt(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildZExt(b, val, dest_ty, name); } return r; }
@link_name("arc_LLVMBuildSExt") fn LLVMBuildSExt(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildSExt(b, val, dest_ty, name); } return r; }
@link_name("arc_LLVMBuildFPToUI") fn LLVMBuildFPToUI(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildFPToUI(b, val, dest_ty, name); } return r; }
@link_name("arc_LLVMBuildFPToSI") fn LLVMBuildFPToSI(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildFPToSI(b, val, dest_ty, name); } return r; }
@link_name("arc_LLVMBuildUIToFP") fn LLVMBuildUIToFP(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildUIToFP(b, val, dest_ty, name); } return r; }
@link_name("arc_LLVMBuildSIToFP") fn LLVMBuildSIToFP(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildSIToFP(b, val, dest_ty, name); } return r; }
@link_name("arc_LLVMBuildFPTrunc") fn LLVMBuildFPTrunc(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildFPTrunc(b, val, dest_ty, name); } return r; }
@link_name("arc_LLVMBuildFPExt") fn LLVMBuildFPExt(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildFPExt(b, val, dest_ty, name); } return r; }
@link_name("arc_LLVMBuildFPCast") fn LLVMBuildFPCast(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildFPCast(b, val, dest_ty, name); } return r; }
@link_name("arc_LLVMBuildBitCast") fn LLVMBuildBitCast(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildBitCast(b, val, dest_ty, name); } return r; }
@link_name("arc_LLVMBuildIntToPtr") fn LLVMBuildIntToPtr(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildIntToPtr(b, val, dest_ty, name); } return r; }
@link_name("arc_LLVMBuildPtrToInt") fn LLVMBuildPtrToInt(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildPtrToInt(b, val, dest_ty, name); } return r; }
@link_name("arc_LLVMBuildPointerCast") fn LLVMBuildPointerCast(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildPointerCast(b, val, dest_ty, name); } return r; }
@link_name("arc_LLVMBuildExtractValue") fn LLVMBuildExtractValue(b: *i8, agg: *i8, idx: u32, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildExtractValue(b, agg, idx, name); } return r; }
@link_name("arc_LLVMBuildInsertValue") fn LLVMBuildInsertValue(b: *i8, agg: *i8, val: *i8, idx: u32, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildInsertValue(b, agg, val, idx, name); } return r; }
@link_name("arc_LLVMBuildFence") fn LLVMBuildFence(b: *i8, ordering: i32, single_thread: i32, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildFence(b, ordering, single_thread, name); } return r; }
@link_name("arc_LLVMBuildAtomicRMW") fn LLVMBuildAtomicRMW(b: *i8, op: i32, ptr: *i8, val: *i8, ordering: i32, single_thread: i32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildAtomicRMW(b, op, ptr, val, ordering, single_thread); } return r; }
@link_name("arc_LLVMBuildAtomicCmpXchg") fn LLVMBuildAtomicCmpXchg(b: *i8, ptr: *i8, cmp: *i8, new_val: *i8, success_ord: i32, failure_ord: i32, single_thread: i32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildAtomicCmpXchg(b, ptr, cmp, new_val, success_ord, failure_ord, single_thread); } return r; }
@link_name("arc_LLVMBuildPhi") fn LLVMBuildPhi(b: *i8, ty: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildPhi(b, ty, name); } return r; }
@link_name("arc_LLVMAddIncoming") fn LLVMAddIncoming(phi: *i8, vals: **i8, bbs: **i8, count: u32) void { @unsafe { raw_LLVMAddIncoming(phi, vals, bbs, count); } }
@link_name("arc_LLVMBuildSelect") fn LLVMBuildSelect(b: *i8, cond: *i8, then_val: *i8, else_val: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildSelect(b, cond, then_val, else_val, name); } return r; }
@link_name("arc_LLVMBuildSwitch") fn LLVMBuildSwitch(b: *i8, val: *i8, default_bb: *i8, num_cases: u32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildSwitch(b, val, default_bb, num_cases); } return r; }
@link_name("arc_LLVMAddCase") fn LLVMAddCase(sw: *i8, on_val: *i8, dest: *i8) void { @unsafe { raw_LLVMAddCase(sw, on_val, dest); } }
@link_name("arc_LLVMGetTargetFromTriple") fn LLVMGetTargetFromTriple(triple: *i8, target_out: **i8, err_out: **i8) i32 { let mut r: i32; @unsafe { r = raw_LLVMGetTargetFromTriple(triple, target_out, err_out); } return r; }
@link_name("arc_LLVMCreateTargetMachine") fn LLVMCreateTargetMachine(target: *i8, triple: *i8, cpu: *i8, features: *i8, opt_level: i32, reloc: i32, code_model: i32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMCreateTargetMachine(target, triple, cpu, features, opt_level, reloc, code_model); } return r; }
@link_name("arc_LLVMDisposeTargetMachine") fn LLVMDisposeTargetMachine(tm: *i8) void { @unsafe { raw_LLVMDisposeTargetMachine(tm); } }
@link_name("arc_LLVMGetDefaultTargetTriple") fn LLVMGetDefaultTargetTriple() *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetDefaultTargetTriple(); } return r; }
@link_name("arc_LLVMGetHostCPUName") fn LLVMGetHostCPUName() *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetHostCPUName(); } return r; }
@link_name("arc_LLVMGetHostCPUFeatures") fn LLVMGetHostCPUFeatures() *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetHostCPUFeatures(); } return r; }
@link_name("arc_LLVMDisposeMessage") fn LLVMDisposeMessage(msg: *i8) void { @unsafe { raw_LLVMDisposeMessage(msg); } }
@link_name("arc_LLVMCreateTargetDataLayout") fn LLVMCreateTargetDataLayout(tm: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMCreateTargetDataLayout(tm); } return r; }
@link_name("arc_LLVMCopyStringRepOfTargetData") fn LLVMCopyStringRepOfTargetData(td: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMCopyStringRepOfTargetData(td); } return r; }
@link_name("arc_LLVMDisposeTargetData") fn LLVMDisposeTargetData(td: *i8) void { @unsafe { raw_LLVMDisposeTargetData(td); } }
@link_name("arc_LLVMVerifyModule") fn LLVMVerifyModule(mod: *i8, action: i32, msg_out: **i8) i32 { let mut r: i32; @unsafe { r = raw_LLVMVerifyModule(mod, action, msg_out); } return r; }
@link_name("arc_LLVMTargetMachineEmitToFile") fn LLVMTargetMachineEmitToFile(tm: *i8, mod: *i8, filename: *i8, filetype: i32, err_out: **i8) i32 { let mut r: i32; @unsafe { r = raw_LLVMTargetMachineEmitToFile(tm, mod, filename, filetype, err_out); } return r; }
@link_name("arc_LLVMPrintModuleToFile") fn LLVMPrintModuleToFile(mod: *i8, filename: *i8, err_out: **i8) i32 { let mut r: i32; @unsafe { r = raw_LLVMPrintModuleToFile(mod, filename, err_out); } return r; }
@link_name("arc_LLVMPrintModuleToString") fn LLVMPrintModuleToString(mod: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMPrintModuleToString(mod); } return r; }
@link_name("arc_LLVMCreatePassBuilderOptions") fn LLVMCreatePassBuilderOptions() *i8 { let mut r: *i8; @unsafe { r = raw_LLVMCreatePassBuilderOptions(); } return r; }
@link_name("arc_LLVMDisposePassBuilderOptions") fn LLVMDisposePassBuilderOptions(opts: *i8) void { @unsafe { raw_LLVMDisposePassBuilderOptions(opts); } }
@link_name("arc_LLVMRunPasses") fn LLVMRunPasses(mod: *i8, passes: *i8, tm: *i8, opts: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMRunPasses(mod, passes, tm, opts); } return r; }
@link_name("arc_LLVMConsumeError") fn LLVMConsumeError(err: *i8) void { @unsafe { raw_LLVMConsumeError(err); } }
@link_name("arc_LLVMGetErrorMessage") fn LLVMGetErrorMessage(err: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetErrorMessage(err); } return r; }
@link_name("arc_LLVMDisposeErrorMessage") fn LLVMDisposeErrorMessage(msg: *i8) void { @unsafe { raw_LLVMDisposeErrorMessage(msg); } }
@link_name("arc_LLVMBuildGlobalStringPtr") fn LLVMBuildGlobalStringPtr(b: *i8, str: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildGlobalStringPtr(b, str, name); } return r; }
@link_name("arc_LLVMBuildGlobalString") fn LLVMBuildGlobalString(b: *i8, str: *i8, name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMBuildGlobalString(b, str, name); } return r; }
@link_name("arc_LLVMSizeOf") fn LLVMSizeOf(ty: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMSizeOf(ty); } return r; }
@link_name("arc_LLVMAlignOf") fn LLVMAlignOf(ty: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMAlignOf(ty); } return r; }
@link_name("arc_LLVMStructGetTypeAtIndex") fn LLVMStructGetTypeAtIndex(sty: *i8, idx: u32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMStructGetTypeAtIndex(sty, idx); } return r; }
@link_name("arc_LLVMIsAConstant") fn LLVMIsAConstant(val: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMIsAConstant(val); } return r; }
@link_name("arc_LLVMIsAConstantInt") fn LLVMIsAConstantInt(val: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMIsAConstantInt(val); } return r; }
@link_name("arc_LLVMConstIntGetSExtValue") fn LLVMConstIntGetSExtValue(val: *i8) i64 { let mut r: i64; @unsafe { r = raw_LLVMConstIntGetSExtValue(val); } return r; }
@link_name("arc_LLVMConstIntGetZExtValue") fn LLVMConstIntGetZExtValue(val: *i8) u64 { let mut r: u64; @unsafe { r = raw_LLVMConstIntGetZExtValue(val); } return r; }
@link_name("arc_LLVMGetStructElementTypes_get") fn LLVMGetStructElementTypes_get(sty: *i8, idx: u32) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetStructElementTypes_get(sty, idx); } return r; }
@link_name("arc_LLVMFunctionType_get_params") fn LLVMFunctionType_get_params(fnty: *i8, dest: **i8, n: u32) void { @unsafe { raw_LLVMFunctionType_get_params(fnty, dest, n); } }
@link_name("arc_LLVMGetReturnType") fn LLVMGetReturnType(fnty: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetReturnType(fnty); } return r; }
@link_name("arc_LLVMGetFunctionCallConv") fn LLVMGetFunctionCallConv(fn_ref: *i8) i32 { let mut r: i32; @unsafe { r = raw_LLVMGetFunctionCallConv(fn_ref); } return r; }
@link_name("arc_LLVMSetAlignment") fn LLVMSetAlignment(val: *i8, bytes: u32) void { @unsafe { raw_LLVMSetAlignment(val, bytes); } }
@link_name("arc_LLVMSetVolatile") fn LLVMSetVolatile(memory_access_inst: *i8, is_volatile: i32) void { @unsafe { raw_LLVMSetVolatile(memory_access_inst, is_volatile); } }
@link_name("arc_LLVMGetCalledFunctionType") fn LLVMGetCalledFunctionType(call: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetCalledFunctionType(call); } return r; }
@link_name("arc_LLVMGetBasicBlocks_first") fn LLVMGetBasicBlocks_first(fn_ref: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetBasicBlocks_first(fn_ref); } return r; }
@link_name("arc_LLVMGetNextBasicBlock") fn LLVMGetNextBasicBlock(bb: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_LLVMGetNextBasicBlock(bb); } return r; }
@link_name("arc_LLVMCountBasicBlocks") fn LLVMCountBasicBlocks(fn_ref: *i8) i32 { let mut r: i32; @unsafe { r = raw_LLVMCountBasicBlocks(fn_ref); } return r; }
@link_name("arc_LLVMInitializeAllTargetInfos_shim") fn LLVMInitializeAllTargetInfos_shim() void { @unsafe { raw_LLVMInitializeAllTargetInfos_shim(); } }
@link_name("arc_LLVMInitializeAllTargets_shim") fn LLVMInitializeAllTargets_shim() void { @unsafe { raw_LLVMInitializeAllTargets_shim(); } }
@link_name("arc_LLVMInitializeAllTargetMCs_shim") fn LLVMInitializeAllTargetMCs_shim() void { @unsafe { raw_LLVMInitializeAllTargetMCs_shim(); } }
@link_name("arc_LLVMInitializeAllAsmPrinters_shim") fn LLVMInitializeAllAsmPrinters_shim() void { @unsafe { raw_LLVMInitializeAllAsmPrinters_shim(); } }
@link_name("arc_LLVMInitializeAllAsmParsers_shim") fn LLVMInitializeAllAsmParsers_shim() void { @unsafe { raw_LLVMInitializeAllAsmParsers_shim(); } }
@link_name("arc_malloc") fn malloc(size: u64) *i8 { let mut r: *i8; @unsafe { r = raw_malloc(size); } return r; }
@link_name("arc_realloc") fn realloc(ptr: *i8, size: u64) *i8 { let mut r: *i8; @unsafe { r = raw_realloc(ptr, size); } return r; }
@link_name("arc_free") fn free(ptr: *i8) void { @unsafe { raw_free(ptr); } }
@link_name("arc_memset") fn memset(dst: *i8, val: i32, n: u64) *i8 { let mut r: *i8; @unsafe { r = raw_memset(dst, val, n); } return r; }
@link_name("arc_memcpy") fn memcpy(dst: *i8, src: *i8, n: u64) *i8 { let mut r: *i8; @unsafe { r = raw_memcpy(dst, src, n); } return r; }
@link_name("arc_memmove") fn memmove(dst: *i8, src: *i8, n: u64) *i8 { let mut r: *i8; @unsafe { r = raw_memmove(dst, src, n); } return r; }
@link_name("arc_memcmp") fn memcmp(a: *i8, b: *i8, n: u64) i32 { let mut r: i32; @unsafe { r = raw_memcmp(a, b, n); } return r; }
@link_name("arc_strcmp") fn strcmp(a: *i8, b: *i8) i32 { let mut r: i32; @unsafe { r = raw_strcmp(a, b); } return r; }
@link_name("arc_strncmp") fn strncmp(a: *i8, b: *i8, n: u64) i32 { let mut r: i32; @unsafe { r = raw_strncmp(a, b, n); } return r; }
@link_name("arc_strlen") fn strlen(s: *i8) u64 { let mut r: u64; @unsafe { r = raw_strlen(s); } return r; }
@link_name("arc_strcpy") fn strcpy(dst: *i8, src: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_strcpy(dst, src); } return r; }
@link_name("arc_strcat") fn strcat(dst: *i8, src: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_strcat(dst, src); } return r; }
@link_name("arc_strstr") fn strstr(haystack: *i8, needle: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_strstr(haystack, needle); } return r; }
@link_name("arc_strchr") fn strchr(s: *i8, c: i32) *i8 { let mut r: *i8; @unsafe { r = raw_strchr(s, c); } return r; }
@link_name("arc_puts") fn puts(s: *i8) i32 { let mut r: i32; @unsafe { r = raw_puts(s); } return r; }
@link_name("arc_putchar") fn putchar(c: i32) i32 { let mut r: i32; @unsafe { r = raw_putchar(c); } return r; }
@link_name("arc_atoi") fn atoi(s: *i8) i32 { let mut r: i32; @unsafe { r = raw_atoi(s); } return r; }
@link_name("arc_atoll") fn atoll(s: *i8) i64 { let mut r: i64; @unsafe { r = raw_atoll(s); } return r; }
@link_name("arc_atof") fn atof(s: *i8) f64 { let mut r: f64; @unsafe { r = raw_atof(s); } return r; }
@link_name("arc_strtoll") fn strtoll(s: *i8, end: **i8, base: i32) i64 { let mut r: i64; @unsafe { r = raw_strtoll(s, end, base); } return r; }
@link_name("arc_strtoull") fn strtoull(s: *i8, end: **i8, base: i32) u64 { let mut r: u64; @unsafe { r = raw_strtoull(s, end, base); } return r; }
@link_name("arc_strtod") fn strtod(s: *i8, end: **i8) f64 { let mut r: f64; @unsafe { r = raw_strtod(s, end); } return r; }
@link_name("arc_exit") fn exit(code: i32) void { @unsafe { raw_exit(code); } }
@link_name("arc_system") fn system(cmd: *i8) i32 { let mut r: i32; @unsafe { r = raw_system(cmd); } return r; }
@link_name("arc_remove") fn remove(path: *i8) i32 { let mut r: i32; @unsafe { r = raw_remove(path); } return r; }
@link_name("arc_fopen") fn fopen(path: *i8, mode: *i8) *void { let mut r: *void; @unsafe { r = raw_fopen(path, mode); } return r; }
@link_name("arc_fclose") fn fclose(fp: *void) i32 { let mut r: i32; @unsafe { r = raw_fclose(fp); } return r; }
@link_name("arc_fread") fn fread(buf: *void, sz: u64, n: u64, fp: *void) u64 { let mut r: u64; @unsafe { r = raw_fread(buf, sz, n, fp); } return r; }
@link_name("arc_fwrite") fn fwrite(buf: *void, sz: u64, n: u64, fp: *void) u64 { let mut r: u64; @unsafe { r = raw_fwrite(buf, sz, n, fp); } return r; }
@link_name("arc_fseek") fn fseek(fp: *void, off: i64, whence: i32) i32 { let mut r: i32; @unsafe { r = raw_fseek(fp, off, whence); } return r; }
@link_name("arc_ftell") fn ftell(fp: *void) i64 { let mut r: i64; @unsafe { r = raw_ftell(fp); } return r; }
@link_name("arc_feof") fn feof(fp: *void) i32 { let mut r: i32; @unsafe { r = raw_feof(fp); } return r; }
@link_name("arc_fflush") fn fflush(fp: *void) i32 { let mut r: i32; @unsafe { r = raw_fflush(fp); } return r; }
@link_name("arc_getenv") fn getenv(name: *i8) *i8 { let mut r: *i8; @unsafe { r = raw_getenv(name); } return r; }
@link_name("arc_getchar") fn getchar() i32 { let mut r: i32; @unsafe { r = raw_getchar(); } return r; }
@link_name("arc_fgets") fn fgets(buf: *i8, n: i32, fp: *void) *i8 { let mut r: *i8; @unsafe { r = raw_fgets(buf, n, fp); } return r; }
@link_name("arc_popen") fn popen(cmd: *i8, mode: *i8) *void { let mut r: *void; @unsafe { r = raw_popen(cmd, mode); } return r; }
@link_name("arc_pclose") fn pclose(fp: *void) i32 { let mut r: i32; @unsafe { r = raw_pclose(fp); } return r; }
@link_name("arc_stdout_file") fn stdout_file() *void { let mut r: *void; @unsafe { r = raw_stdout_file(); } return r; }
@link_name("arc_isalpha") fn isalpha(c: i32) i32 { let mut r: i32; @unsafe { r = raw_isalpha(c); } return r; }
@link_name("arc_isdigit") fn isdigit(c: i32) i32 { let mut r: i32; @unsafe { r = raw_isdigit(c); } return r; }
@link_name("arc_isalnum") fn isalnum(c: i32) i32 { let mut r: i32; @unsafe { r = raw_isalnum(c); } return r; }
@link_name("arc_isspace") fn isspace(c: i32) i32 { let mut r: i32; @unsafe { r = raw_isspace(c); } return r; }
@link_name("arc_isxdigit") fn isxdigit(c: i32) i32 { let mut r: i32; @unsafe { r = raw_isxdigit(c); } return r; }
@link_name("arc_tolower") fn tolower(c: i32) i32 { let mut r: i32; @unsafe { r = raw_tolower(c); } return r; }
@link_name("arc_toupper") fn toupper(c: i32) i32 { let mut r: i32; @unsafe { r = raw_toupper(c); } return r; }
@link_name("arc_GetModuleFileNameA") fn GetModuleFileNameA(hmod: *void, filename: *i8, size: u32) i32 { let mut r: i32; @unsafe { r = raw_GetModuleFileNameA(hmod, filename, size); } return r; }

// LLVM C API bindings for the Artemis self-hosting compiler.
// All LLVM handle types are represented as i8* (opaque pointers).
//
// @unsafe: every declaration here is defined by libLLVM, outside this program, so
// the compiler can verify nothing about its behaviour or its handling of the opaque
// pointers we hand it.


// ---- Context / Module / Builder ----

// ---- Integer types ----

// ---- Float types ----

// ---- Derived types ----

// ---- Struct types ----

// ---- Type inspection ----

// ---- Constants ----

// ---- Value inspection ----

// ---- Global variables ----

// ---- Functions ----

// ---- Basic blocks ----

// ---- Arithmetic builders ----

// ---- Bitwise builders ----

// ---- Comparison builders ----

// ---- Memory builders ----

// ---- Control flow builders ----

// ---- Call builders ----

// ---- Inline assembly ----

// ---- Cast builders ----

// ---- Aggregate ops ----

// ---- Atomics ----

// ---- Phi / Select ----

// ---- Switch ----

// ---- Target machine ----

// ---- Verification and emission ----

// ---- PassBuilder (LLVM 14+) ----

// ---- String / global helpers ----

// Target init shims (defined in boot/llvm_init.c)


// ---- C stdlib ----
// @unsafe: defined by libc, outside this program.

// ---- LLVM TypeKind constants ----
enum LLVMTypeKindEnum {
    LLVMVoidTypeKind       = 0,
    LLVMHalfTypeKind       = 1,
    LLVMFloatTypeKind      = 2,
    LLVMDoubleTypeKind     = 3,
    LLVMX86_FP80TypeKind   = 4,
    LLVMFP128TypeKind      = 5,
    LLVMPPC_FP128TypeKind  = 6,
    LLVMLabelTypeKind      = 7,
    LLVMIntegerTypeKind    = 8,
    LLVMFunctionTypeKind   = 9,
    LLVMStructTypeKind     = 10,
    LLVMArrayTypeKind      = 11,
    LLVMPointerTypeKind    = 12,
    LLVMVectorTypeKind     = 13,
    LLVMMetadataTypeKind   = 14,
    LLVMBFloatTypeKind     = 19,
}

// ---- LLVM AtomicOrdering constants ----
enum LLVMAtomicOrderingEnum {
    LLVMAtomicOrderingNotAtomic              = 0,
    LLVMAtomicOrderingUnordered              = 1,
    LLVMAtomicOrderingMonotonic              = 2,
    LLVMAtomicOrderingAcquire                = 4,
    LLVMAtomicOrderingRelease                = 5,
    LLVMAtomicOrderingAcquireRelease         = 6,
    LLVMAtomicOrderingSequentiallyConsistent = 7,
}

// ---- LLVM AtomicRMWBinOp constants ----
enum LLVMAtomicRMWBinOpEnum {
    LLVMAtomicRMWBinOpXchg = 0,
    LLVMAtomicRMWBinOpAdd  = 1,
    LLVMAtomicRMWBinOpSub  = 2,
    LLVMAtomicRMWBinOpAnd  = 3,
    LLVMAtomicRMWBinOpNand = 4,
    LLVMAtomicRMWBinOpOr   = 5,
    LLVMAtomicRMWBinOpXor  = 6,
    LLVMAtomicRMWBinOpMax  = 7,
    LLVMAtomicRMWBinOpMin  = 8,
    LLVMAtomicRMWBinOpUMax = 9,
    LLVMAtomicRMWBinOpUMin = 10,
}

// ---- LLVM IntPredicate constants ----
enum LLVMIntPredicateEnum {
    LLVMIntEQ  = 32,
    LLVMIntNE  = 33,
    LLVMIntUGT = 34,
    LLVMIntUGE = 35,
    LLVMIntULT = 36,
    LLVMIntULE = 37,
    LLVMIntSGT = 38,
    LLVMIntSGE = 39,
    LLVMIntSLT = 40,
    LLVMIntSLE = 41,
}

// ---- LLVM RealPredicate constants ----
enum LLVMRealPredicateEnum {
    LLVMRealPredicateFalse = 0,
    LLVMRealOEQ            = 1,
    LLVMRealOGT            = 2,
    LLVMRealOGE            = 3,
    LLVMRealOLT            = 4,
    LLVMRealOLE            = 5,
    LLVMRealONE            = 6,
    LLVMRealORD            = 7,
    LLVMRealUNO            = 8,
    LLVMRealUEQ            = 9,
    LLVMRealUGT            = 10,
    LLVMRealUGE            = 11,
    LLVMRealULT            = 12,
    LLVMRealULE            = 13,
    LLVMRealUNE            = 14,
    LLVMRealPredicateTrue  = 15,
}

// ---- LLVM Linkage constants ----
enum LLVMLinkageEnum {
    LLVMExternalLinkage    = 0,
    LLVMAppendingLinkage   = 7,
    LLVMInternalLinkage    = 8,
    LLVMPrivateLinkage     = 9,
}

// ---- LLVM CodeGenFileType constants ----
enum LLVMCodeGenFileTypeEnum {
    LLVMAssemblyFile = 0,
    LLVMObjectFile   = 1,
}

// ---- LLVM VerifierFailureAction constants ----
enum LLVMVerifierFailureActionEnum {
    LLVMAbortProcessAction = 0,
    LLVMPrintMessageAction = 1,
    LLVMReturnStatusAction = 2,
}

// ---- LLVM CodeGenOptLevel constants ----
enum LLVMCodeGenOptLevelEnum {
    LLVMCodeGenLevelNone       = 0,
    LLVMCodeGenLevelLess       = 1,
    LLVMCodeGenLevelDefault    = 2,
    LLVMCodeGenLevelAggressive = 3,
}

// ---- LLVM RelocMode constants ----
enum LLVMRelocModeEnum {
    LLVMRelocDefault = 0,
    LLVMRelocStatic  = 1,
    LLVMRelocPIC     = 2,
    LLVMRelocDynamicNoPic = 3,
}

// ---- LLVM CodeModel constants ----
enum LLVMCodeModelEnum {
    LLVMCodeModelDefault = 0,
    LLVMCodeModelJITDefault = 1,
    LLVMCodeModelSmall   = 2,
    LLVMCodeModelMedium  = 3,
    LLVMCodeModelLarge   = 4,
}
