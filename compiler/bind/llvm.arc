// LLVM C API bindings for the Artemis self-hosting compiler.
// All LLVM handle types are represented as i8* (opaque pointers).

extern "C" {

// ---- Context / Module / Builder ----
fn LLVMContextCreate() *i8;
fn LLVMContextDispose(ctx: *i8) void;
fn LLVMModuleCreateWithNameInContext(name: *i8, ctx: *i8) *i8;
fn LLVMDisposeModule(mod: *i8) void;
fn LLVMCreateBuilderInContext(ctx: *i8) *i8;
fn LLVMDisposeBuilder(b: *i8) void;
fn LLVMSetTarget(mod: *i8, triple: *i8) void;
fn LLVMSetDataLayout(mod: *i8, dl: *i8) void;

// ---- Integer types ----
fn LLVMVoidTypeInContext(ctx: *i8) *i8;
fn LLVMInt1TypeInContext(ctx: *i8) *i8;
fn LLVMInt8TypeInContext(ctx: *i8) *i8;
fn LLVMInt16TypeInContext(ctx: *i8) *i8;
fn LLVMInt32TypeInContext(ctx: *i8) *i8;
fn LLVMInt64TypeInContext(ctx: *i8) *i8;
fn LLVMInt128TypeInContext(ctx: *i8) *i8;
fn LLVMIntTypeInContext(ctx: *i8, bits: u32) *i8;

// ---- Float types ----
fn LLVMHalfTypeInContext(ctx: *i8) *i8;
fn LLVMFloatTypeInContext(ctx: *i8) *i8;
fn LLVMDoubleTypeInContext(ctx: *i8) *i8;
fn LLVMX86FP80TypeInContext(ctx: *i8) *i8;
fn LLVMFP128TypeInContext(ctx: *i8) *i8;

// ---- Derived types ----
fn LLVMPointerType(elem: *i8, addrspace: u32) *i8;
fn LLVMPointerTypeInContext(ctx: *i8, addrspace: u32) *i8;
fn LLVMArrayType(elem: *i8, count: u32) *i8;  // deprecated in LLVM 17, removed in LLVM 19
fn LLVMArrayType2(elem: *i8, count: u64) *i8;  // use this for LLVM 17+
fn LLVMFunctionType(ret: *i8, params: **i8, nparams: u32, variadic: i32) *i8;

// ---- Struct types ----
fn LLVMStructCreateNamed(ctx: *i8, name: *i8) *i8;
fn LLVMStructSetBody(stype: *i8, fields: **i8, nfields: u32, packed: i32) void;
fn LLVMStructTypeInContext(ctx: *i8, fields: **i8, nfields: u32, packed: i32) *i8;

// ---- Type inspection ----
fn LLVMGetTypeKind(ty: *i8) i32;
fn LLVMGetElementType(ty: *i8) *i8;
fn LLVMGetArrayLength(ty: *i8) u32;
fn LLVMCountStructElementTypes(ty: *i8) u32;
fn LLVMGetStructName(ty: *i8) *i8;
fn LLVMGetTypeByName2(ctx: *i8, name: *i8) *i8;
fn LLVMGetIntTypeWidth(ty: *i8) u32;
fn LLVMCountParamTypes(fnty: *i8) u32;
fn LLVMGetParamTypes(fnty: *i8, dest: **i8) void;

// ---- Constants ----
fn LLVMConstInt(ty: *i8, val: u64, sign_extend: i32) *i8;
fn LLVMConstReal(ty: *i8, val: f64) *i8;
fn LLVMConstNull(ty: *i8) *i8;
fn LLVMConstPointerNull(ty: *i8) *i8;
fn LLVMGetUndef(ty: *i8) *i8;
fn LLVMConstString(str: *i8, length: u32, dont_null_terminate: i32) *i8;
fn LLVMConstStringInContext(ctx: *i8, str: *i8, length: u32, dont_null_terminate: i32) *i8;
fn LLVMConstArray(elem_ty: *i8, vals: **i8, nvals: u32) *i8;
fn LLVMConstStructInContext(ctx: *i8, vals: **i8, nvals: u32, packed: i32) *i8;
fn LLVMConstNamedStruct(sty: *i8, vals: **i8, nvals: u32) *i8;
fn LLVMConstBitCast(val: *i8, ty: *i8) *i8;
fn LLVMConstTrunc(val: *i8, to_type: *i8) *i8;
fn LLVMConstAdd(lhs: *i8, rhs: *i8) *i8;
fn LLVMConstIntOfString(ty: *i8, text: *i8, radix: u8) *i8;

// ---- Value inspection ----
fn LLVMTypeOf(val: *i8) *i8;
fn LLVMIsConstant(val: *i8) i32;
fn LLVMIsNull(val: *i8) i32;
fn LLVMIsUndef(val: *i8) i32;
fn LLVMSetValueName2(val: *i8, name: *i8, len: u64) void;
fn LLVMGetValueName2(val: *i8, len: *u64) *i8;
fn LLVMSetLinkage(val: *i8, linkage: i32) void;
fn LLVMSetGlobalConstant(gv: *i8, is_constant: i32) void;
fn LLVMSetInitializer(gv: *i8, init: *i8) void;

// ---- Global variables ----
fn LLVMAddGlobal(mod: *i8, ty: *i8, name: *i8) *i8;
fn LLVMGetNamedGlobal(mod: *i8, name: *i8) *i8;
fn LLVMGlobalGetValueType(gv: *i8) *i8;
fn LLVMGetInitializer(gv: *i8) *i8;

// ---- Functions ----
fn LLVMAddFunction(mod: *i8, name: *i8, fn_ty: *i8) *i8;
fn LLVMGetNamedFunction(mod: *i8, name: *i8) *i8;
fn LLVMGetParam(fn_ref: *i8, idx: u32) *i8;
fn LLVMCountParams(fn_ref: *i8) u32;
fn LLVMGetFirstParam(fn_ref: *i8) *i8;
fn LLVMGetNextParam(param: *i8) *i8;
fn LLVMSetFunctionCallConv(fn_ref: *i8, cc: u32) void;

// ---- Basic blocks ----
fn LLVMAppendBasicBlockInContext(ctx: *i8, fn_ref: *i8, name: *i8) *i8;
fn LLVMAppendBasicBlock(fn_ref: *i8, name: *i8) *i8;
fn LLVMPositionBuilderAtEnd(b: *i8, bb: *i8) void;
fn LLVMPositionBuilderBefore(b: *i8, inst: *i8) void;
fn LLVMGetInsertBlock(b: *i8) *i8;
fn LLVMGetBasicBlockTerminator(bb: *i8) *i8;
fn LLVMGetFirstBasicBlock(fn_ref: *i8) *i8;
fn LLVMGetLastInstruction(bb: *i8) *i8;
fn LLVMGetBasicBlockParent(bb: *i8) *i8;
fn LLVMGetInstructionOpcode(inst: *i8) i32;  // 27=load 1=ret 2=br 7=unreachable
fn LLVMGetOperand(val: *i8, index: u32) *i8;
fn LLVMMoveBasicBlockAfter(bb: *i8, move_after: *i8) void;

// ---- Arithmetic builders ----
fn LLVMBuildAdd(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
fn LLVMBuildSub(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
fn LLVMBuildMul(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
fn LLVMBuildUDiv(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
fn LLVMBuildSDiv(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
fn LLVMBuildURem(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
fn LLVMBuildSRem(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
fn LLVMBuildFAdd(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
fn LLVMBuildFSub(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
fn LLVMBuildFMul(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
fn LLVMBuildFDiv(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
fn LLVMBuildFRem(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
fn LLVMBuildNeg(b: *i8, val: *i8, name: *i8) *i8;
fn LLVMBuildFNeg(b: *i8, val: *i8, name: *i8) *i8;
fn LLVMBuildNot(b: *i8, val: *i8, name: *i8) *i8;

// ---- Bitwise builders ----
fn LLVMBuildAnd(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
fn LLVMBuildOr(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
fn LLVMBuildXor(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
fn LLVMBuildShl(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
fn LLVMBuildLShr(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
fn LLVMBuildAShr(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;

// ---- Comparison builders ----
fn LLVMBuildICmp(b: *i8, pred: i32, lhs: *i8, rhs: *i8, name: *i8) *i8;
fn LLVMBuildFCmp(b: *i8, pred: i32, lhs: *i8, rhs: *i8, name: *i8) *i8;

// ---- Memory builders ----
fn LLVMBuildAlloca(b: *i8, ty: *i8, name: *i8) *i8;
fn LLVMBuildLoad2(b: *i8, ty: *i8, ptr: *i8, name: *i8) *i8;
fn LLVMBuildStore(b: *i8, val: *i8, ptr: *i8) *i8;
fn LLVMBuildGEP2(b: *i8, ty: *i8, ptr: *i8, indices: **i8, nidx: u32, name: *i8) *i8;
fn LLVMBuildInBoundsGEP2(b: *i8, ty: *i8, ptr: *i8, indices: **i8, nidx: u32, name: *i8) *i8;
fn LLVMBuildStructGEP2(b: *i8, ty: *i8, ptr: *i8, idx: u32, name: *i8) *i8;
fn LLVMBuildMemSet(b: *i8, ptr: *i8, val: *i8, len: *i8, align: u32) *i8;
fn LLVMBuildMemCpy(b: *i8, dst: *i8, dst_align: u32, src: *i8, src_align: u32, size: *i8) *i8;

// ---- Control flow builders ----
fn LLVMBuildBr(b: *i8, dest: *i8) *i8;
fn LLVMBuildCondBr(b: *i8, cond: *i8, then_bb: *i8, else_bb: *i8) *i8;
fn LLVMBuildRet(b: *i8, val: *i8) *i8;
fn LLVMBuildRetVoid(b: *i8) *i8;
fn LLVMBuildUnreachable(b: *i8) *i8;

// ---- Call builders ----
fn LLVMBuildCall2(b: *i8, fn_ty: *i8, fn_ref: *i8, args: **i8, nargs: u32, name: *i8) *i8;

// ---- Inline assembly ----
fn LLVMGetInlineAsm(ty: *i8, asm_string: *i8, asm_len: u64, constraints: *i8, con_len: u64, has_side_effects: i32, is_align_stack: i32, dialect: i32, can_throw: i32) *i8;

// ---- Cast builders ----
fn LLVMBuildTrunc(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
fn LLVMBuildZExt(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
fn LLVMBuildSExt(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
fn LLVMBuildFPToUI(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
fn LLVMBuildFPToSI(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
fn LLVMBuildUIToFP(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
fn LLVMBuildSIToFP(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
fn LLVMBuildFPTrunc(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
fn LLVMBuildFPExt(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
fn LLVMBuildFPCast(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
fn LLVMBuildBitCast(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
fn LLVMBuildIntToPtr(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
fn LLVMBuildPtrToInt(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
fn LLVMBuildPointerCast(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;

// ---- Aggregate ops ----
fn LLVMBuildExtractValue(b: *i8, agg: *i8, idx: u32, name: *i8) *i8;
fn LLVMBuildInsertValue(b: *i8, agg: *i8, val: *i8, idx: u32, name: *i8) *i8;

// ---- Atomics ----
fn LLVMBuildFence(b: *i8, ordering: i32, single_thread: i32, name: *i8) *i8;
fn LLVMBuildAtomicRMW(b: *i8, op: i32, ptr: *i8, val: *i8, ordering: i32, single_thread: i32) *i8;
fn LLVMBuildAtomicCmpXchg(b: *i8, ptr: *i8, cmp: *i8, new_val: *i8,
                          success_ord: i32, failure_ord: i32, single_thread: i32) *i8;

// ---- Phi / Select ----
fn LLVMBuildPhi(b: *i8, ty: *i8, name: *i8) *i8;
fn LLVMAddIncoming(phi: *i8, vals: **i8, bbs: **i8, count: u32) void;
fn LLVMBuildSelect(b: *i8, cond: *i8, then_val: *i8, else_val: *i8, name: *i8) *i8;

// ---- Switch ----
fn LLVMBuildSwitch(b: *i8, val: *i8, default_bb: *i8, num_cases: u32) *i8;
fn LLVMAddCase(sw: *i8, on_val: *i8, dest: *i8) void;

// ---- Target machine ----
fn LLVMInitializeAllTargetInfos() void;
fn LLVMInitializeAllTargets() void;
fn LLVMInitializeAllTargetMCs() void;
fn LLVMInitializeAllAsmPrinters() void;
fn LLVMInitializeAllAsmParsers() void;
fn LLVMInitializeNativeTarget() void;
fn LLVMInitializeNativeAsmPrinter() void;
fn LLVMInitializeNativeAsmParser() void;
fn LLVMGetTargetFromTriple(triple: *i8, target_out: **i8, err_out: **i8) i32;
fn LLVMCreateTargetMachine(target: *i8, triple: *i8, cpu: *i8, features: *i8, opt_level: i32, reloc: i32, code_model: i32) *i8;
fn LLVMDisposeTargetMachine(tm: *i8) void;
fn LLVMGetDefaultTargetTriple() *i8;
fn LLVMGetHostCPUName() *i8;
fn LLVMGetHostCPUFeatures() *i8;
fn LLVMDisposeMessage(msg: *i8) void;
fn LLVMCreateTargetDataLayout(tm: *i8) *i8;
fn LLVMCopyStringRepOfTargetData(td: *i8) *i8;
fn LLVMDisposeTargetData(td: *i8) void;

// ---- Verification and emission ----
fn LLVMVerifyModule(mod: *i8, action: i32, msg_out: **i8) i32;
fn LLVMTargetMachineEmitToFile(tm: *i8, mod: *i8, filename: *i8, filetype: i32, err_out: **i8) i32;
fn LLVMPrintModuleToFile(mod: *i8, filename: *i8, err_out: **i8) i32;
fn LLVMPrintModuleToString(mod: *i8) *i8;

// ---- PassBuilder (LLVM 14+) ----
fn LLVMCreatePassBuilderOptions() *i8;
fn LLVMDisposePassBuilderOptions(opts: *i8) void;
fn LLVMRunPasses(mod: *i8, passes: *i8, tm: *i8, opts: *i8) *i8;
fn LLVMConsumeError(err: *i8) void;
fn LLVMGetErrorMessage(err: *i8) *i8;
fn LLVMDisposeErrorMessage(msg: *i8) void;

// ---- String / global helpers ----
fn LLVMBuildGlobalStringPtr(b: *i8, str: *i8, name: *i8) *i8;
fn LLVMBuildGlobalString(b: *i8, str: *i8, name: *i8) *i8;
fn LLVMSizeOf(ty: *i8) *i8;
fn LLVMAlignOf(ty: *i8) *i8;
fn LLVMStructGetTypeAtIndex(sty: *i8, idx: u32) *i8;
fn LLVMIsAConstant(val: *i8) *i8;
fn LLVMIsAConstantInt(val: *i8) *i8;
fn LLVMConstIntGetSExtValue(val: *i8) i64;
fn LLVMConstIntGetZExtValue(val: *i8) u64;
fn LLVMGetStructElementTypes_get(sty: *i8, idx: u32) *i8;
fn LLVMFunctionType_get_params(fnty: *i8, dest: **i8, n: u32) void;
fn LLVMGetReturnType(fnty: *i8) *i8;
fn LLVMGetFunctionCallConv(fn_ref: *i8) i32;
fn LLVMSetAlignment(val: *i8, bytes: u32) void;
fn LLVMSetVolatile(memory_access_inst: *i8, is_volatile: i32) void;
fn LLVMGetCalledFunctionType(call: *i8) *i8;
fn LLVMGetBasicBlocks_first(fn_ref: *i8) *i8;
fn LLVMGetNextBasicBlock(bb: *i8) *i8;
fn LLVMCountBasicBlocks(fn_ref: *i8) i32;

// Target init shims (defined in boot/llvm_init.c)
fn LLVMInitializeAllTargetInfos_shim() void;
fn LLVMInitializeAllTargets_shim() void;
fn LLVMInitializeAllTargetMCs_shim() void;
fn LLVMInitializeAllAsmPrinters_shim() void;
fn LLVMInitializeAllAsmParsers_shim() void;

} // extern "C"

// ---- C stdlib ----
extern "C" {
fn malloc(size: u64) *i8;
fn realloc(ptr: *i8, size: u64) *i8;
fn free(ptr: *i8) void;
fn memset(dst: *i8, val: i32, n: u64) *i8;
fn memcpy(dst: *i8, src: *i8, n: u64) *i8;
fn memmove(dst: *i8, src: *i8, n: u64) *i8;
fn memcmp(a: *i8, b: *i8, n: u64) i32;
fn strcmp(a: *i8, b: *i8) i32;
fn strncmp(a: *i8, b: *i8, n: u64) i32;
fn strlen(s: *i8) u64;
fn strcpy(dst: *i8, src: *i8) *i8;
fn strcat(dst: *i8, src: *i8) *i8;
fn strstr(haystack: *i8, needle: *i8) *i8;
fn strchr(s: *i8, c: i32) *i8;
fn sprintf(buf: *i8, fmt: *i8, ...) i32;
fn snprintf(buf: *i8, n: u64, fmt: *i8, ...) i32;
fn printf(fmt: *i8, ...) i32;
fn fprintf(stream: *void, fmt: *i8, ...) i32;
fn puts(s: *i8) i32;
fn putchar(c: i32) i32;
fn atoi(s: *i8) i32;
fn atoll(s: *i8) i64;
fn atof(s: *i8) f64;
fn strtoll(s: *i8, end: **i8, base: i32) i64;
fn strtoull(s: *i8, end: **i8, base: i32) u64;
fn strtod(s: *i8, end: **i8) f64;
fn exit(code: i32) void;
fn system(cmd: *i8) i32;
fn remove(path: *i8) i32;
fn fopen(path: *i8, mode: *i8) *void;
fn fclose(fp: *void) i32;
fn fread(buf: *void, sz: u64, n: u64, fp: *void) u64;
fn fwrite(buf: *void, sz: u64, n: u64, fp: *void) u64;
fn fseek(fp: *void, off: i64, whence: i32) i32;
fn ftell(fp: *void) i64;
fn feof(fp: *void) i32;
fn fflush(fp: *void) i32;
fn getenv(name: *i8) *i8;
fn getchar() i32;
fn fgets(buf: *i8, n: i32, fp: *void) *i8;
fn popen(cmd: *i8, mode: *i8) *void;
fn pclose(fp: *void) i32;
fn stdout_file() *void;
fn isalpha(c: i32) i32;
fn isdigit(c: i32) i32;
fn isalnum(c: i32) i32;
fn isspace(c: i32) i32;
fn isxdigit(c: i32) i32;
fn tolower(c: i32) i32;
fn toupper(c: i32) i32;
fn GetModuleFileNameA(hmod: *void, filename: *i8, size: u32) i32;
}

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
