// Shim: wraps LLVM target-initialization macros as real linkable symbols.
// Does NOT include LLVM headers to avoid static-inline redefinition conflicts.

extern void LLVMInitializeX86TargetInfo(void);
extern void LLVMInitializeX86Target(void);
extern void LLVMInitializeX86TargetMC(void);
extern void LLVMInitializeX86AsmPrinter(void);
extern void LLVMInitializeX86AsmParser(void);

void LLVMInitializeAllTargetInfos_shim(void)  { LLVMInitializeX86TargetInfo(); }
void LLVMInitializeAllTargets_shim(void)      { LLVMInitializeX86Target(); }
void LLVMInitializeAllTargetMCs_shim(void)    { LLVMInitializeX86TargetMC(); }
void LLVMInitializeAllAsmPrinters_shim(void)  { LLVMInitializeX86AsmPrinter(); }
void LLVMInitializeAllAsmParsers_shim(void)   { LLVMInitializeX86AsmParser(); }
