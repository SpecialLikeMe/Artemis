#pragma once

#include <llvm-c/Core.h>
#include <llvm-c/Analysis.h>
#include <llvm-c/Target.h>

#include <vector>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <stdexcept>

#include "../parser/main.hxx"

// ---- RAII wrappers for LLVM handles ----

struct llvm_context_owner {
    LLVMContextRef ctx;
    explicit llvm_context_owner(LLVMContextRef c = LLVMContextCreate()) : ctx(c) {}
    ~llvm_context_owner() { if (ctx) LLVMContextDispose(ctx); }
    llvm_context_owner(const llvm_context_owner&) = delete;
    llvm_context_owner& operator=(const llvm_context_owner&) = delete;
    llvm_context_owner(llvm_context_owner&& o) noexcept : ctx(o.ctx) { o.ctx = nullptr; }
};

struct llvm_module_owner {
    LLVMModuleRef mod;
    explicit llvm_module_owner(LLVMModuleRef m) : mod(m) {}
    ~llvm_module_owner() { if (mod) LLVMDisposeModule(mod); }
    llvm_module_owner(const llvm_module_owner&) = delete;
    llvm_module_owner& operator=(const llvm_module_owner&) = delete;
    // Transfer ownership out (caller takes the module).
    LLVMModuleRef release() { LLVMModuleRef m = mod; mod = nullptr; return m; }
};

struct llvm_builder_owner {
    LLVMBuilderRef builder;
    explicit llvm_builder_owner(LLVMBuilderRef b) : builder(b) {}
    ~llvm_builder_owner() { if (builder) LLVMDisposeBuilder(builder); }
    llvm_builder_owner(const llvm_builder_owner&) = delete;
    llvm_builder_owner& operator=(const llvm_builder_owner&) = delete;
};