// Shim: wraps LLVM target-initialization macros as real linkable symbols.
// Does NOT include LLVM headers to avoid static-inline redefinition conflicts.
#include <stdio.h>
#include <stdint.h>

extern void LLVMInitializeX86TargetInfo(void);
extern void LLVMInitializeX86Target(void);
extern void LLVMInitializeX86TargetMC(void);
extern void LLVMInitializeX86AsmPrinter(void);
extern void LLVMInitializeX86AsmParser(void);

// LLVM helper declarations (opaque types treated as void*)
typedef void* LLVMTypeRef;
typedef void* LLVMValueRef;
typedef void* LLVMBasicBlockRef;

extern LLVMTypeRef  LLVMStructGetTypeAtIndex(LLVMTypeRef StructTy, unsigned i);
extern void         LLVMGetParamTypes(LLVMTypeRef FunctionTy, LLVMTypeRef *Dest);
extern LLVMBasicBlockRef LLVMGetFirstBasicBlock(LLVMValueRef Fn);

void LLVMInitializeAllTargetInfos_shim(void)  { LLVMInitializeX86TargetInfo(); }
void LLVMInitializeAllTargets_shim(void)      { LLVMInitializeX86Target(); }
void LLVMInitializeAllTargetMCs_shim(void)    { LLVMInitializeX86TargetMC(); }
void LLVMInitializeAllAsmPrinters_shim(void)  { LLVMInitializeX86AsmPrinter(); }
void LLVMInitializeAllAsmParsers_shim(void)   { LLVMInitializeX86AsmParser(); }

void* stdout_file(void) { return (void*)stdout; }

// Custom LLVM shims used by the Artemis self-hosted compiler bootstrap
LLVMTypeRef LLVMGetStructElementTypes_get(LLVMTypeRef sty, unsigned idx) {
    return LLVMStructGetTypeAtIndex(sty, idx);
}

void LLVMFunctionType_get_params(LLVMTypeRef fnty, LLVMTypeRef *dest, unsigned n) {
    (void)n;
    LLVMGetParamTypes(fnty, dest);
}

LLVMBasicBlockRef LLVMGetBasicBlocks_first(LLVMValueRef fn_ref) {
    return LLVMGetFirstBasicBlock(fn_ref);
}
