// LLVM C API bindings for the Artemis self-hosting compiler.
// All LLVM handle types are represented as i8* (opaque pointers).
//
// @unsafe: every declaration here is defined by libLLVM, outside this program, so
// the compiler can verify nothing about its behaviour or its handling of the opaque
// pointers we hand it.


// ---- Context / Module / Builder ----
@unsafe extern fn LLVMContextCreate() *i8;
@unsafe extern fn LLVMContextDispose(ctx: *i8) void;
@unsafe extern fn LLVMModuleCreateWithNameInContext(name: *i8, ctx: *i8) *i8;
@unsafe extern fn LLVMDisposeModule(mod: *i8) void;
@unsafe extern fn LLVMCreateBuilderInContext(ctx: *i8) *i8;
@unsafe extern fn LLVMDisposeBuilder(b: *i8) void;
@unsafe extern fn LLVMSetTarget(mod: *i8, triple: *i8) void;
@unsafe extern fn LLVMSetDataLayout(mod: *i8, dl: *i8) void;

// ---- Integer types ----
@unsafe extern fn LLVMVoidTypeInContext(ctx: *i8) *i8;
@unsafe extern fn LLVMInt1TypeInContext(ctx: *i8) *i8;
@unsafe extern fn LLVMInt8TypeInContext(ctx: *i8) *i8;
@unsafe extern fn LLVMInt16TypeInContext(ctx: *i8) *i8;
@unsafe extern fn LLVMInt32TypeInContext(ctx: *i8) *i8;
@unsafe extern fn LLVMInt64TypeInContext(ctx: *i8) *i8;
@unsafe extern fn LLVMInt128TypeInContext(ctx: *i8) *i8;
@unsafe extern fn LLVMIntTypeInContext(ctx: *i8, bits: u32) *i8;

// ---- Float types ----
@unsafe extern fn LLVMHalfTypeInContext(ctx: *i8) *i8;
@unsafe extern fn LLVMFloatTypeInContext(ctx: *i8) *i8;
@unsafe extern fn LLVMDoubleTypeInContext(ctx: *i8) *i8;
@unsafe extern fn LLVMX86FP80TypeInContext(ctx: *i8) *i8;
@unsafe extern fn LLVMFP128TypeInContext(ctx: *i8) *i8;

// ---- Derived types ----
@unsafe extern fn LLVMPointerType(elem: *i8, addrspace: u32) *i8;
@unsafe extern fn LLVMPointerTypeInContext(ctx: *i8, addrspace: u32) *i8;
@unsafe extern fn LLVMArrayType(elem: *i8, count: u32) *i8;  // deprecated in LLVM 17, removed in LLVM 19
@unsafe extern fn LLVMArrayType2(elem: *i8, count: u64) *i8;  // use this for LLVM 17+
@unsafe extern fn LLVMFunctionType(ret: *i8, params: **i8, nparams: u32, variadic: i32) *i8;

// ---- Struct types ----
@unsafe extern fn LLVMStructCreateNamed(ctx: *i8, name: *i8) *i8;
@unsafe extern fn LLVMStructSetBody(stype: *i8, fields: **i8, nfields: u32, packed: i32) void;
@unsafe extern fn LLVMStructTypeInContext(ctx: *i8, fields: **i8, nfields: u32, packed: i32) *i8;

// ---- Type inspection ----
@unsafe extern fn LLVMGetTypeKind(ty: *i8) i32;
@unsafe extern fn LLVMGetElementType(ty: *i8) *i8;
@unsafe extern fn LLVMGetArrayLength(ty: *i8) u32;
@unsafe extern fn LLVMCountStructElementTypes(ty: *i8) u32;
@unsafe extern fn LLVMGetStructName(ty: *i8) *i8;
@unsafe extern fn LLVMGetTypeByName2(ctx: *i8, name: *i8) *i8;
@unsafe extern fn LLVMGetIntTypeWidth(ty: *i8) u32;
@unsafe extern fn LLVMCountParamTypes(fnty: *i8) u32;
@unsafe extern fn LLVMGetParamTypes(fnty: *i8, dest: **i8) void;

// ---- Constants ----
@unsafe extern fn LLVMConstInt(ty: *i8, val: u64, sign_extend: i32) *i8;
@unsafe extern fn LLVMConstReal(ty: *i8, val: f64) *i8;
@unsafe extern fn LLVMConstNull(ty: *i8) *i8;
@unsafe extern fn LLVMConstPointerNull(ty: *i8) *i8;
@unsafe extern fn LLVMGetUndef(ty: *i8) *i8;
@unsafe extern fn LLVMConstString(str: *i8, length: u32, dont_null_terminate: i32) *i8;
@unsafe extern fn LLVMConstStringInContext(ctx: *i8, str: *i8, length: u32, dont_null_terminate: i32) *i8;
@unsafe extern fn LLVMConstArray(elem_ty: *i8, vals: **i8, nvals: u32) *i8;
@unsafe extern fn LLVMConstStructInContext(ctx: *i8, vals: **i8, nvals: u32, packed: i32) *i8;
@unsafe extern fn LLVMConstNamedStruct(sty: *i8, vals: **i8, nvals: u32) *i8;
@unsafe extern fn LLVMConstBitCast(val: *i8, ty: *i8) *i8;
@unsafe extern fn LLVMConstTrunc(val: *i8, to_type: *i8) *i8;
@unsafe extern fn LLVMConstAdd(lhs: *i8, rhs: *i8) *i8;
@unsafe extern fn LLVMConstIntOfString(ty: *i8, text: *i8, radix: u8) *i8;

// ---- Value inspection ----
@unsafe extern fn LLVMTypeOf(val: *i8) *i8;
@unsafe extern fn LLVMIsConstant(val: *i8) i32;
@unsafe extern fn LLVMIsNull(val: *i8) i32;
@unsafe extern fn LLVMIsUndef(val: *i8) i32;
@unsafe extern fn LLVMSetValueName2(val: *i8, name: *i8, len: u64) void;
@unsafe extern fn LLVMGetValueName2(val: *i8, len: *u64) *i8;
@unsafe extern fn LLVMSetLinkage(val: *i8, linkage: i32) void;
@unsafe extern fn LLVMSetGlobalConstant(gv: *i8, is_constant: i32) void;
@unsafe extern fn LLVMSetInitializer(gv: *i8, init: *i8) void;

// ---- Global variables ----
@unsafe extern fn LLVMAddGlobal(mod: *i8, ty: *i8, name: *i8) *i8;
@unsafe extern fn LLVMGetNamedGlobal(mod: *i8, name: *i8) *i8;
@unsafe extern fn LLVMGlobalGetValueType(gv: *i8) *i8;
@unsafe extern fn LLVMGetInitializer(gv: *i8) *i8;

// ---- Functions ----
@unsafe extern fn LLVMAddFunction(mod: *i8, name: *i8, fn_ty: *i8) *i8;
@unsafe extern fn LLVMGetNamedFunction(mod: *i8, name: *i8) *i8;
@unsafe extern fn LLVMGetParam(fn_ref: *i8, idx: u32) *i8;
@unsafe extern fn LLVMCountParams(fn_ref: *i8) u32;
@unsafe extern fn LLVMGetFirstParam(fn_ref: *i8) *i8;
@unsafe extern fn LLVMGetNextParam(param: *i8) *i8;
@unsafe extern fn LLVMSetFunctionCallConv(fn_ref: *i8, cc: u32) void;

// ---- Basic blocks ----
@unsafe extern fn LLVMAppendBasicBlockInContext(ctx: *i8, fn_ref: *i8, name: *i8) *i8;
@unsafe extern fn LLVMAppendBasicBlock(fn_ref: *i8, name: *i8) *i8;
@unsafe extern fn LLVMPositionBuilderAtEnd(b: *i8, bb: *i8) void;
@unsafe extern fn LLVMPositionBuilderBefore(b: *i8, inst: *i8) void;
@unsafe extern fn LLVMGetInsertBlock(b: *i8) *i8;
@unsafe extern fn LLVMGetBasicBlockTerminator(bb: *i8) *i8;
@unsafe extern fn LLVMGetFirstBasicBlock(fn_ref: *i8) *i8;
@unsafe extern fn LLVMGetLastInstruction(bb: *i8) *i8;
@unsafe extern fn LLVMGetBasicBlockParent(bb: *i8) *i8;
@unsafe extern fn LLVMGetInstructionOpcode(inst: *i8) i32;  // 27=load 1=ret 2=br 7=unreachable
@unsafe extern fn LLVMGetOperand(val: *i8, index: u32) *i8;
@unsafe extern fn LLVMMoveBasicBlockAfter(bb: *i8, move_after: *i8) void;

// ---- Arithmetic builders ----
@unsafe extern fn LLVMBuildAdd(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildSub(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildMul(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildUDiv(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildSDiv(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildURem(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildSRem(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildFAdd(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildFSub(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildFMul(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildFDiv(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildFRem(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildNeg(b: *i8, val: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildFNeg(b: *i8, val: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildNot(b: *i8, val: *i8, name: *i8) *i8;

// ---- Bitwise builders ----
@unsafe extern fn LLVMBuildAnd(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildOr(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildXor(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildShl(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildLShr(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildAShr(b: *i8, lhs: *i8, rhs: *i8, name: *i8) *i8;

// ---- Comparison builders ----
@unsafe extern fn LLVMBuildICmp(b: *i8, pred: i32, lhs: *i8, rhs: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildFCmp(b: *i8, pred: i32, lhs: *i8, rhs: *i8, name: *i8) *i8;

// ---- Memory builders ----
@unsafe extern fn LLVMBuildAlloca(b: *i8, ty: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildLoad2(b: *i8, ty: *i8, ptr: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildStore(b: *i8, val: *i8, ptr: *i8) *i8;
@unsafe extern fn LLVMBuildGEP2(b: *i8, ty: *i8, ptr: *i8, indices: **i8, nidx: u32, name: *i8) *i8;
@unsafe extern fn LLVMBuildInBoundsGEP2(b: *i8, ty: *i8, ptr: *i8, indices: **i8, nidx: u32, name: *i8) *i8;
@unsafe extern fn LLVMBuildStructGEP2(b: *i8, ty: *i8, ptr: *i8, idx: u32, name: *i8) *i8;
@unsafe extern fn LLVMBuildMemSet(b: *i8, ptr: *i8, val: *i8, len: *i8, align: u32) *i8;
@unsafe extern fn LLVMBuildMemCpy(b: *i8, dst: *i8, dst_align: u32, src: *i8, src_align: u32, size: *i8) *i8;

// ---- Control flow builders ----
@unsafe extern fn LLVMBuildBr(b: *i8, dest: *i8) *i8;
@unsafe extern fn LLVMBuildCondBr(b: *i8, cond: *i8, then_bb: *i8, else_bb: *i8) *i8;
@unsafe extern fn LLVMBuildRet(b: *i8, val: *i8) *i8;
@unsafe extern fn LLVMBuildRetVoid(b: *i8) *i8;
@unsafe extern fn LLVMBuildUnreachable(b: *i8) *i8;

// ---- Call builders ----
@unsafe extern fn LLVMBuildCall2(b: *i8, fn_ty: *i8, fn_ref: *i8, args: **i8, nargs: u32, name: *i8) *i8;

// ---- Inline assembly ----
@unsafe extern fn LLVMGetInlineAsm(ty: *i8, asm_string: *i8, asm_len: u64, constraints: *i8, con_len: u64, has_side_effects: i32, is_align_stack: i32, dialect: i32, can_throw: i32) *i8;

// ---- Cast builders ----
@unsafe extern fn LLVMBuildTrunc(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildZExt(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildSExt(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildFPToUI(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildFPToSI(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildUIToFP(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildSIToFP(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildFPTrunc(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildFPExt(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildFPCast(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildBitCast(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildIntToPtr(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildPtrToInt(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildPointerCast(b: *i8, val: *i8, dest_ty: *i8, name: *i8) *i8;

// ---- Aggregate ops ----
@unsafe extern fn LLVMBuildExtractValue(b: *i8, agg: *i8, idx: u32, name: *i8) *i8;
@unsafe extern fn LLVMBuildInsertValue(b: *i8, agg: *i8, val: *i8, idx: u32, name: *i8) *i8;

// ---- Atomics ----
@unsafe extern fn LLVMBuildFence(b: *i8, ordering: i32, single_thread: i32, name: *i8) *i8;
@unsafe extern fn LLVMBuildAtomicRMW(b: *i8, op: i32, ptr: *i8, val: *i8, ordering: i32, single_thread: i32) *i8;
@unsafe extern fn LLVMBuildAtomicCmpXchg(b: *i8, ptr: *i8, cmp: *i8, new_val: *i8, success_ord: i32, failure_ord: i32, single_thread: i32) *i8;

// ---- Phi / Select ----
@unsafe extern fn LLVMBuildPhi(b: *i8, ty: *i8, name: *i8) *i8;
@unsafe extern fn LLVMAddIncoming(phi: *i8, vals: **i8, bbs: **i8, count: u32) void;
@unsafe extern fn LLVMBuildSelect(b: *i8, cond: *i8, then_val: *i8, else_val: *i8, name: *i8) *i8;

// ---- Switch ----
@unsafe extern fn LLVMBuildSwitch(b: *i8, val: *i8, default_bb: *i8, num_cases: u32) *i8;
@unsafe extern fn LLVMAddCase(sw: *i8, on_val: *i8, dest: *i8) void;

// ---- Target machine ----
@unsafe extern fn LLVMInitializeAllTargetInfos() void;
@unsafe extern fn LLVMInitializeAllTargets() void;
@unsafe extern fn LLVMInitializeAllTargetMCs() void;
@unsafe extern fn LLVMInitializeAllAsmPrinters() void;
@unsafe extern fn LLVMInitializeAllAsmParsers() void;
@unsafe extern fn LLVMInitializeNativeTarget() void;
@unsafe extern fn LLVMInitializeNativeAsmPrinter() void;
@unsafe extern fn LLVMInitializeNativeAsmParser() void;
@unsafe extern fn LLVMGetTargetFromTriple(triple: *i8, target_out: **i8, err_out: **i8) i32;
@unsafe extern fn LLVMCreateTargetMachine(target: *i8, triple: *i8, cpu: *i8, features: *i8, opt_level: i32, reloc: i32, code_model: i32) *i8;
@unsafe extern fn LLVMDisposeTargetMachine(tm: *i8) void;
@unsafe extern fn LLVMGetDefaultTargetTriple() *i8;
@unsafe extern fn LLVMGetHostCPUName() *i8;
@unsafe extern fn LLVMGetHostCPUFeatures() *i8;
@unsafe extern fn LLVMDisposeMessage(msg: *i8) void;
@unsafe extern fn LLVMCreateTargetDataLayout(tm: *i8) *i8;
@unsafe extern fn LLVMCopyStringRepOfTargetData(td: *i8) *i8;
@unsafe extern fn LLVMDisposeTargetData(td: *i8) void;

// ---- Verification and emission ----
@unsafe extern fn LLVMVerifyModule(mod: *i8, action: i32, msg_out: **i8) i32;
@unsafe extern fn LLVMTargetMachineEmitToFile(tm: *i8, mod: *i8, filename: *i8, filetype: i32, err_out: **i8) i32;
@unsafe extern fn LLVMPrintModuleToFile(mod: *i8, filename: *i8, err_out: **i8) i32;
@unsafe extern fn LLVMPrintModuleToString(mod: *i8) *i8;

// ---- PassBuilder (LLVM 14+) ----
@unsafe extern fn LLVMCreatePassBuilderOptions() *i8;
@unsafe extern fn LLVMDisposePassBuilderOptions(opts: *i8) void;
@unsafe extern fn LLVMRunPasses(mod: *i8, passes: *i8, tm: *i8, opts: *i8) *i8;
@unsafe extern fn LLVMConsumeError(err: *i8) void;
@unsafe extern fn LLVMGetErrorMessage(err: *i8) *i8;
@unsafe extern fn LLVMDisposeErrorMessage(msg: *i8) void;

// ---- String / global helpers ----
@unsafe extern fn LLVMBuildGlobalStringPtr(b: *i8, str: *i8, name: *i8) *i8;
@unsafe extern fn LLVMBuildGlobalString(b: *i8, str: *i8, name: *i8) *i8;
@unsafe extern fn LLVMSizeOf(ty: *i8) *i8;
@unsafe extern fn LLVMAlignOf(ty: *i8) *i8;
@unsafe extern fn LLVMStructGetTypeAtIndex(sty: *i8, idx: u32) *i8;
@unsafe extern fn LLVMIsAConstant(val: *i8) *i8;
@unsafe extern fn LLVMIsAConstantInt(val: *i8) *i8;
@unsafe extern fn LLVMConstIntGetSExtValue(val: *i8) i64;
@unsafe extern fn LLVMConstIntGetZExtValue(val: *i8) u64;
@unsafe extern fn LLVMGetStructElementTypes_get(sty: *i8, idx: u32) *i8;
@unsafe extern fn LLVMFunctionType_get_params(fnty: *i8, dest: **i8, n: u32) void;
@unsafe extern fn LLVMGetReturnType(fnty: *i8) *i8;
@unsafe extern fn LLVMGetFunctionCallConv(fn_ref: *i8) i32;
@unsafe extern fn LLVMSetAlignment(val: *i8, bytes: u32) void;
@unsafe extern fn LLVMSetVolatile(memory_access_inst: *i8, is_volatile: i32) void;
@unsafe extern fn LLVMGetCalledFunctionType(call: *i8) *i8;
@unsafe extern fn LLVMGetBasicBlocks_first(fn_ref: *i8) *i8;
@unsafe extern fn LLVMGetNextBasicBlock(bb: *i8) *i8;
@unsafe extern fn LLVMCountBasicBlocks(fn_ref: *i8) i32;

// Target init shims (defined in boot/llvm_init.c)
@unsafe extern fn LLVMInitializeAllTargetInfos_shim() void;
@unsafe extern fn LLVMInitializeAllTargets_shim() void;
@unsafe extern fn LLVMInitializeAllTargetMCs_shim() void;
@unsafe extern fn LLVMInitializeAllAsmPrinters_shim() void;
@unsafe extern fn LLVMInitializeAllAsmParsers_shim() void;


// ---- C stdlib ----
// @unsafe: defined by libc, outside this program.
@unsafe extern fn malloc(size: u64) *i8;
@unsafe extern fn realloc(ptr: *i8, size: u64) *i8;
@unsafe extern fn free(ptr: *i8) void;
@unsafe extern fn memset(dst: *i8, val: i32, n: u64) *i8;
@unsafe extern fn memcpy(dst: *i8, src: *i8, n: u64) *i8;
@unsafe extern fn memmove(dst: *i8, src: *i8, n: u64) *i8;
@unsafe extern fn memcmp(a: *i8, b: *i8, n: u64) i32;
@unsafe extern fn strcmp(a: *i8, b: *i8) i32;
@unsafe extern fn strncmp(a: *i8, b: *i8, n: u64) i32;
@unsafe extern fn strlen(s: *i8) u64;
@unsafe extern fn strcpy(dst: *i8, src: *i8) *i8;
@unsafe extern fn strcat(dst: *i8, src: *i8) *i8;
@unsafe extern fn strstr(haystack: *i8, needle: *i8) *i8;
@unsafe extern fn strchr(s: *i8, c: i32) *i8;
@unsafe extern fn sprintf(buf: *i8, fmt: *i8, ...) i32;
@unsafe extern fn snprintf(buf: *i8, n: u64, fmt: *i8, ...) i32;
@unsafe extern fn printf(fmt: *i8, ...) i32;
@unsafe extern fn fprintf(stream: *void, fmt: *i8, ...) i32;
@unsafe extern fn puts(s: *i8) i32;
@unsafe extern fn putchar(c: i32) i32;
@unsafe extern fn atoi(s: *i8) i32;
@unsafe extern fn atoll(s: *i8) i64;
@unsafe extern fn atof(s: *i8) f64;
@unsafe extern fn strtoll(s: *i8, end: **i8, base: i32) i64;
@unsafe extern fn strtoull(s: *i8, end: **i8, base: i32) u64;
@unsafe extern fn strtod(s: *i8, end: **i8) f64;
@unsafe extern fn exit(code: i32) void;
@unsafe extern fn system(cmd: *i8) i32;
@unsafe extern fn remove(path: *i8) i32;
@unsafe extern fn fopen(path: *i8, mode: *i8) *void;
@unsafe extern fn fclose(fp: *void) i32;
@unsafe extern fn fread(buf: *void, sz: u64, n: u64, fp: *void) u64;
@unsafe extern fn fwrite(buf: *void, sz: u64, n: u64, fp: *void) u64;
@unsafe extern fn fseek(fp: *void, off: i64, whence: i32) i32;
@unsafe extern fn ftell(fp: *void) i64;
@unsafe extern fn feof(fp: *void) i32;
@unsafe extern fn fflush(fp: *void) i32;
@unsafe extern fn getenv(name: *i8) *i8;
@unsafe extern fn getchar() i32;
@unsafe extern fn fgets(buf: *i8, n: i32, fp: *void) *i8;
@unsafe extern fn popen(cmd: *i8, mode: *i8) *void;
@unsafe extern fn pclose(fp: *void) i32;
@unsafe extern fn stdout_file() *void;
@unsafe extern fn isalpha(c: i32) i32;
@unsafe extern fn isdigit(c: i32) i32;
@unsafe extern fn isalnum(c: i32) i32;
@unsafe extern fn isspace(c: i32) i32;
@unsafe extern fn isxdigit(c: i32) i32;
@unsafe extern fn tolower(c: i32) i32;
@unsafe extern fn toupper(c: i32) i32;
@unsafe extern fn GetModuleFileNameA(hmod: *void, filename: *i8, size: u32) i32;

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
