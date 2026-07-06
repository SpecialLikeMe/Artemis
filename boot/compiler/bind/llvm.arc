// LLVM C API bindings for the Artemis self-hosting compiler.
// All LLVM handle types are represented as i8* (opaque pointers).

extern "C" {

// ---- Context / Module / Builder ----
i8* LLVMContextCreate();
void LLVMContextDispose(i8* ctx);
i8* LLVMModuleCreateWithNameInContext(i8* name, i8* ctx);
void LLVMDisposeModule(i8* mod);
i8* LLVMCreateBuilderInContext(i8* ctx);
void LLVMDisposeBuilder(i8* b);
void LLVMSetTarget(i8* mod, i8* triple);
void LLVMSetDataLayout(i8* mod, i8* dl);

// ---- Integer types ----
i8* LLVMVoidTypeInContext(i8* ctx);
i8* LLVMInt1TypeInContext(i8* ctx);
i8* LLVMInt8TypeInContext(i8* ctx);
i8* LLVMInt16TypeInContext(i8* ctx);
i8* LLVMInt32TypeInContext(i8* ctx);
i8* LLVMInt64TypeInContext(i8* ctx);
i8* LLVMInt128TypeInContext(i8* ctx);
i8* LLVMIntTypeInContext(i8* ctx, u32 bits);

// ---- Float types ----
i8* LLVMHalfTypeInContext(i8* ctx);
i8* LLVMFloatTypeInContext(i8* ctx);
i8* LLVMDoubleTypeInContext(i8* ctx);
i8* LLVMX86FP80TypeInContext(i8* ctx);
i8* LLVMFP128TypeInContext(i8* ctx);

// ---- Derived types ----
i8* LLVMPointerType(i8* elem, u32 addrspace);
i8* LLVMPointerTypeInContext(i8* ctx, u32 addrspace);
i8* LLVMArrayType(i8* elem, u32 count);
i8* LLVMFunctionType(i8* ret, i8** params, u32 nparams, i32 variadic);

// ---- Struct types ----
i8* LLVMStructCreateNamed(i8* ctx, i8* name);
void LLVMStructSetBody(i8* stype, i8** fields, u32 nfields, i32 packed);
i8* LLVMStructTypeInContext(i8* ctx, i8** fields, u32 nfields, i32 packed);

// ---- Type inspection ----
i32 LLVMGetTypeKind(i8* ty);
i8* LLVMGetElementType(i8* ty);
u32 LLVMGetArrayLength(i8* ty);
u32 LLVMCountStructElementTypes(i8* ty);
i8* LLVMGetStructName(i8* ty);
u32 LLVMGetIntTypeWidth(i8* ty);
u32 LLVMCountParamTypes(i8* fnty);
void LLVMGetParamTypes(i8* fnty, i8** dest);

// ---- Constants ----
i8* LLVMConstInt(i8* ty, u64 val, i32 sign_extend);
i8* LLVMConstReal(i8* ty, f64 val);
i8* LLVMConstNull(i8* ty);
i8* LLVMConstPointerNull(i8* ty);
i8* LLVMGetUndef(i8* ty);
i8* LLVMConstString(i8* str, u32 length, i32 dont_null_terminate);
i8* LLVMConstStringInContext(i8* ctx, i8* str, u32 length, i32 dont_null_terminate);
i8* LLVMConstArray(i8* elem_ty, i8** vals, u32 nvals);
i8* LLVMConstStructInContext(i8* ctx, i8** vals, u32 nvals, i32 packed);
i8* LLVMConstNamedStruct(i8* sty, i8** vals, u32 nvals);
i8* LLVMConstBitCast(i8* val, i8* ty);
i8* LLVMConstTrunc(i8* val, i8* to_type);

// ---- Value inspection ----
i8* LLVMTypeOf(i8* val);
i32 LLVMIsConstant(i8* val);
i32 LLVMIsNull(i8* val);
i32 LLVMIsUndef(i8* val);
void LLVMSetValueName2(i8* val, i8* name, u64 len);
void LLVMSetLinkage(i8* val, i32 linkage);
void LLVMSetGlobalConstant(i8* gv, i32 is_constant);
void LLVMSetInitializer(i8* gv, i8* init);

// ---- Global variables ----
i8* LLVMAddGlobal(i8* mod, i8* ty, i8* name);
i8* LLVMGetNamedGlobal(i8* mod, i8* name);
i8* LLVMGlobalGetValueType(i8* gv);
i8* LLVMGetInitializer(i8* gv);

// ---- Functions ----
i8* LLVMAddFunction(i8* mod, i8* name, i8* fn_ty);
i8* LLVMGetNamedFunction(i8* mod, i8* name);
i8* LLVMGetParam(i8* fn, u32 idx);
u32 LLVMCountParams(i8* fn);
i8* LLVMGetFirstParam(i8* fn);
i8* LLVMGetNextParam(i8* param);
void LLVMSetFunctionCallConv(i8* fn, u32 cc);

// ---- Basic blocks ----
i8* LLVMAppendBasicBlockInContext(i8* ctx, i8* fn, i8* name);
i8* LLVMAppendBasicBlock(i8* fn, i8* name);
void LLVMPositionBuilderAtEnd(i8* b, i8* bb);
i8* LLVMGetInsertBlock(i8* b);
i8* LLVMGetBasicBlockTerminator(i8* bb);
i8* LLVMGetBasicBlockParent(i8* bb);
void LLVMMoveBasicBlockAfter(i8* bb, i8* move_after);

// ---- Arithmetic builders ----
i8* LLVMBuildAdd(i8* b, i8* lhs, i8* rhs, i8* name);
i8* LLVMBuildSub(i8* b, i8* lhs, i8* rhs, i8* name);
i8* LLVMBuildMul(i8* b, i8* lhs, i8* rhs, i8* name);
i8* LLVMBuildUDiv(i8* b, i8* lhs, i8* rhs, i8* name);
i8* LLVMBuildSDiv(i8* b, i8* lhs, i8* rhs, i8* name);
i8* LLVMBuildURem(i8* b, i8* lhs, i8* rhs, i8* name);
i8* LLVMBuildSRem(i8* b, i8* lhs, i8* rhs, i8* name);
i8* LLVMBuildFAdd(i8* b, i8* lhs, i8* rhs, i8* name);
i8* LLVMBuildFSub(i8* b, i8* lhs, i8* rhs, i8* name);
i8* LLVMBuildFMul(i8* b, i8* lhs, i8* rhs, i8* name);
i8* LLVMBuildFDiv(i8* b, i8* lhs, i8* rhs, i8* name);
i8* LLVMBuildFRem(i8* b, i8* lhs, i8* rhs, i8* name);
i8* LLVMBuildNeg(i8* b, i8* val, i8* name);
i8* LLVMBuildFNeg(i8* b, i8* val, i8* name);
i8* LLVMBuildNot(i8* b, i8* val, i8* name);

// ---- Bitwise builders ----
i8* LLVMBuildAnd(i8* b, i8* lhs, i8* rhs, i8* name);
i8* LLVMBuildOr(i8* b, i8* lhs, i8* rhs, i8* name);
i8* LLVMBuildXor(i8* b, i8* lhs, i8* rhs, i8* name);
i8* LLVMBuildShl(i8* b, i8* lhs, i8* rhs, i8* name);
i8* LLVMBuildLShr(i8* b, i8* lhs, i8* rhs, i8* name);
i8* LLVMBuildAShr(i8* b, i8* lhs, i8* rhs, i8* name);

// ---- Comparison builders ----
i8* LLVMBuildICmp(i8* b, i32 pred, i8* lhs, i8* rhs, i8* name);
i8* LLVMBuildFCmp(i8* b, i32 pred, i8* lhs, i8* rhs, i8* name);

// ---- Memory builders ----
i8* LLVMBuildAlloca(i8* b, i8* ty, i8* name);
i8* LLVMBuildLoad2(i8* b, i8* ty, i8* ptr, i8* name);
i8* LLVMBuildStore(i8* b, i8* val, i8* ptr);
i8* LLVMBuildGEP2(i8* b, i8* ty, i8* ptr, i8** indices, u32 nidx, i8* name);
i8* LLVMBuildInBoundsGEP2(i8* b, i8* ty, i8* ptr, i8** indices, u32 nidx, i8* name);
i8* LLVMBuildStructGEP2(i8* b, i8* ty, i8* ptr, u32 idx, i8* name);
i8* LLVMBuildMemSet(i8* b, i8* ptr, i8* val, i8* len, u32 align);
i8* LLVMBuildMemCpy(i8* b, i8* dst, u32 dst_align, i8* src, u32 src_align, i8* size);

// ---- Control flow builders ----
i8* LLVMBuildBr(i8* b, i8* dest);
i8* LLVMBuildCondBr(i8* b, i8* cond, i8* then_bb, i8* else_bb);
i8* LLVMBuildRet(i8* b, i8* val);
i8* LLVMBuildRetVoid(i8* b);
i8* LLVMBuildUnreachable(i8* b);

// ---- Call builders ----
i8* LLVMBuildCall2(i8* b, i8* fn_ty, i8* fn, i8** args, u32 nargs, i8* name);

// ---- Cast builders ----
i8* LLVMBuildTrunc(i8* b, i8* val, i8* dest_ty, i8* name);
i8* LLVMBuildZExt(i8* b, i8* val, i8* dest_ty, i8* name);
i8* LLVMBuildSExt(i8* b, i8* val, i8* dest_ty, i8* name);
i8* LLVMBuildFPToUI(i8* b, i8* val, i8* dest_ty, i8* name);
i8* LLVMBuildFPToSI(i8* b, i8* val, i8* dest_ty, i8* name);
i8* LLVMBuildUIToFP(i8* b, i8* val, i8* dest_ty, i8* name);
i8* LLVMBuildSIToFP(i8* b, i8* val, i8* dest_ty, i8* name);
i8* LLVMBuildFPTrunc(i8* b, i8* val, i8* dest_ty, i8* name);
i8* LLVMBuildFPExt(i8* b, i8* val, i8* dest_ty, i8* name);
i8* LLVMBuildFPCast(i8* b, i8* val, i8* dest_ty, i8* name);
i8* LLVMBuildBitCast(i8* b, i8* val, i8* dest_ty, i8* name);
i8* LLVMBuildIntToPtr(i8* b, i8* val, i8* dest_ty, i8* name);
i8* LLVMBuildPtrToInt(i8* b, i8* val, i8* dest_ty, i8* name);
i8* LLVMBuildPointerCast(i8* b, i8* val, i8* dest_ty, i8* name);

// ---- Aggregate ops ----
i8* LLVMBuildExtractValue(i8* b, i8* agg, u32 idx, i8* name);
i8* LLVMBuildInsertValue(i8* b, i8* agg, i8* val, u32 idx, i8* name);

// ---- Phi / Select ----
i8* LLVMBuildPhi(i8* b, i8* ty, i8* name);
void LLVMAddIncoming(i8* phi, i8** vals, i8** bbs, u32 count);
i8* LLVMBuildSelect(i8* b, i8* cond, i8* then_val, i8* else_val, i8* name);

// ---- Switch ----
i8* LLVMBuildSwitch(i8* b, i8* val, i8* default_bb, u32 num_cases);
void LLVMAddCase(i8* sw, i8* on_val, i8* dest);

// ---- Target machine ----
void LLVMInitializeAllTargetInfos();
void LLVMInitializeAllTargets();
void LLVMInitializeAllTargetMCs();
void LLVMInitializeAllAsmPrinters();
void LLVMInitializeAllAsmParsers();
void LLVMInitializeNativeTarget();
void LLVMInitializeNativeAsmPrinter();
void LLVMInitializeNativeAsmParser();
i32  LLVMGetTargetFromTriple(i8* triple, i8** target_out, i8** err_out);
i8*  LLVMCreateTargetMachine(i8* target, i8* triple, i8* cpu, i8* features,
                              i32 opt_level, i32 reloc, i32 code_model);
void LLVMDisposeTargetMachine(i8* tm);
i8*  LLVMGetDefaultTargetTriple();
void LLVMDisposeMessage(i8* msg);
i8*  LLVMCreateTargetDataLayout(i8* tm);
i8*  LLVMCopyStringRepOfTargetData(i8* td);
void LLVMDisposeTargetData(i8* td);

// ---- Verification and emission ----
i32  LLVMVerifyModule(i8* mod, i32 action, i8** msg_out);
i32  LLVMTargetMachineEmitToFile(i8* tm, i8* mod, i8* filename, i32 filetype, i8** err_out);
i32  LLVMPrintModuleToFile(i8* mod, i8* filename, i8** err_out);
i8*  LLVMPrintModuleToString(i8* mod);

// ---- PassBuilder (LLVM 14+) ----
i8*  LLVMCreatePassBuilderOptions();
void LLVMDisposePassBuilderOptions(i8* opts);
i8*  LLVMRunPasses(i8* mod, i8* passes, i8* tm, i8* opts);
void LLVMConsumeError(i8* err);
i8*  LLVMGetErrorMessage(i8* err);
void LLVMDisposeErrorMessage(i8* msg);

// ---- String / global helpers ----
i8*  LLVMBuildGlobalStringPtr(i8* b, i8* str, i8* name);
i8*  LLVMBuildGlobalString(i8* b, i8* str, i8* name);
i8*  LLVMSizeOf(i8* ty);
i8*  LLVMAlignOf(i8* ty);
i8*  LLVMStructGetTypeAtIndex(i8* sty, u32 idx);
i32  LLVMIsAConstant(i8* val);
i32  LLVMConstIntGetSExtValue(i8* val);
u64  LLVMConstIntGetZExtValue(i8* val);
i8*  LLVMGetStructElementTypes_get(i8* sty, u32 idx);
void LLVMFunctionType_get_params(i8* fnty, i8** dest, u32 n);
i8*  LLVMGetReturnType(i8* fnty);
i32  LLVMGetFunctionCallConv(i8* fn);
void LLVMSetAlignment(i8* val, u32 bytes);
i8*  LLVMGetCalledFunctionType(i8* call);
i8*  LLVMGetBasicBlocks_first(i8* fn);
i8*  LLVMGetNextBasicBlock(i8* bb);
i32  LLVMCountBasicBlocks(i8* fn);

// Target init shims (defined in boot/llvm_init.c)
void LLVMInitializeAllTargetInfos_shim();
void LLVMInitializeAllTargets_shim();
void LLVMInitializeAllTargetMCs_shim();
void LLVMInitializeAllAsmPrinters_shim();
void LLVMInitializeAllAsmParsers_shim();

} // extern "C"

// ---- C stdlib ----
extern "C" {
i8*  malloc(u64 size);
i8*  realloc(i8* ptr, u64 size);
void free(i8* ptr);
i8*  memset(i8* dst, i32 val, u64 n);
i8*  memcpy(i8* dst, i8* src, u64 n);
i8*  memmove(i8* dst, i8* src, u64 n);
i32  memcmp(i8* a, i8* b, u64 n);
i32  strcmp(i8* a, i8* b);
i32  strncmp(i8* a, i8* b, u64 n);
u64  strlen(i8* s);
i8*  strcpy(i8* dst, i8* src);
i8*  strcat(i8* dst, i8* src);
i8*  strstr(i8* haystack, i8* needle);
i8*  strchr(i8* s, i32 c);
i32  sprintf(i8* buf, i8* fmt, ...);
i32  snprintf(i8* buf, u64 n, i8* fmt, ...);
i32  printf(i8* fmt, ...);
i32  fprintf(void* stream, i8* fmt, ...);
i32  puts(i8* s);
i32  putchar(i32 c);
i32  atoi(i8* s);
i64  atoll(i8* s);
f64  atof(i8* s);
i64  strtoll(i8* s, i8** end, i32 base);
u64  strtoull(i8* s, i8** end, i32 base);
f64  strtod(i8* s, i8** end);
void exit(i32 code);
i32  system(i8* cmd);
i32  remove(i8* path);
void* fopen(i8* path, i8* mode);
i32  fclose(void* fp);
u64  fread(void* buf, u64 sz, u64 n, void* fp);
u64  fwrite(void* buf, u64 sz, u64 n, void* fp);
i32  fseek(void* fp, i64 off, i32 whence);
i64  ftell(void* fp);
i32  feof(void* fp);
i32  fflush(void* fp);
i8*  getenv(i8* name);
i32  isalpha(i32 c);
i32  isdigit(i32 c);
i32  isalnum(i32 c);
i32  isspace(i32 c);
i32  isxdigit(i32 c);
i32  tolower(i32 c);
i32  toupper(i32 c);
i32  GetModuleFileNameA(void* hmod, i8* filename, u32 size);
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
