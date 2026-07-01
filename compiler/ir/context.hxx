#pragma once
#include "include.h"

// Forward declarations for generic templates (full defs in parser/main.hxx).
struct func_decl;
struct class_decl;
struct enum_decl;
struct type_node;

// ---- Per-scope variable table ----
struct ir_scope_frame {
    std::unordered_map<std::string, LLVMValueRef> alloca_ptrs;  // name -> alloca
    std::unordered_map<std::string, LLVMTypeRef>  alloca_types; // name -> element type (i32 for i32[N], ptr for i32*)
    std::unordered_map<std::string, LLVMTypeRef>  deref_types;  // name -> pointed-to type (i32 when name is i32*)
};

// ---- Control-flow target pair (for break/continue) ----
struct ir_loop_info {
    LLVMBasicBlockRef break_block;
    LLVMBasicBlockRef continue_block;
};

// ---- Central state carried through every visitor ----
struct ir_context {
    LLVMContextRef llvm_ctx     = nullptr;
    LLVMModuleRef  llvm_mod     = nullptr;
    LLVMBuilderRef llvm_builder = nullptr;

    // Current function being emitted
    LLVMValueRef current_func     = nullptr;
    LLVMTypeRef  current_func_type = nullptr; // the LLVMFunctionType
    LLVMTypeRef  current_ret_type  = nullptr;

    // Local variable scopes (pushed/popped around blocks and function bodies)
    std::vector<ir_scope_frame> scopes;

    // Loop/switch control-flow stack (innermost last)
    std::vector<ir_loop_info> loop_stack;

    // Global declarations registered during pass 1
    std::unordered_map<std::string, LLVMValueRef> global_funcs;
    std::unordered_map<std::string, LLVMTypeRef>  global_func_types; // fn type (not ptr)
    std::unordered_map<std::string, LLVMValueRef> global_vars;
    std::unordered_map<std::string, LLVMTypeRef>  struct_types;           // name -> LLVMStructType
    std::unordered_map<std::string, std::vector<std::string>> struct_field_names; // for GEP index
    std::unordered_map<std::string, std::vector<LLVMTypeRef>> struct_field_types; // for member load
    std::unordered_set<std::string> union_names; // union types (single-body LLVM struct)
    // Non-struct typedef aliases: alias name -> underlying AST type (e.g. Real -> f64,
    // IntPtr -> i32*). Struct typedefs are handled via struct_types directly.
    std::unordered_map<std::string, type_node*> typedef_aliases;

    // Class-specific IR state
    struct class_ir_info {
        LLVMTypeRef   class_type    = nullptr;  // LLVM struct for the class
        LLVMTypeRef   vtable_type   = nullptr;  // LLVM struct for the vtable (may be null)
        LLVMValueRef  vtable_global = nullptr;  // @ClassName_vtable global (may be null)
        std::vector<std::string>  vtable_slots; // virtual method names in vtable order
        std::string   base_name;                // base class name (empty if none)
        bool          has_virtual   = false;
        // Field layout: includes base fields (if any) then own fields
        std::vector<std::string>  all_field_names;
        std::vector<LLVMTypeRef>  all_field_types;
        // vtable pointer is at index 0 if has_virtual
    };
    std::unordered_map<std::string, class_ir_info> class_infos;

    // Defer stack: each scope level has a list of deferred items (exprs/blocks)
    // stored as pairs of (expr_node*, block_stmt*) — one of which is non-null
    using defer_item = std::pair<void*, bool>; // ptr, false=expr_node, true=block_stmt
    std::vector<std::vector<std::pair<void*, bool>>> defer_stack; // per-scope deferred items

    // Current class being emitted (for self parameter lookup)
    std::string current_class_name;

    // ---- Generics (monomorphization) ----
    // Active type-parameter substitution while emitting a generic instantiation:
    //   type-param-name -> concrete LLVM type.
    std::unordered_map<std::string, LLVMTypeRef> type_subst;
    // Generic templates collected during pass 1 (keyed by base name).
    std::unordered_map<std::string, func_decl*>  generic_funcs;
    std::unordered_map<std::string, class_decl*> generic_classes;

    // ADT enum registry: enum name -> enum_decl* (for payload-access codegen)
    std::unordered_map<std::string, enum_decl*> adt_enums;

    void push_defer_scope() { defer_stack.emplace_back(); }
    void add_defer(void* item, bool is_block) {
        if (!defer_stack.empty()) defer_stack.back().push_back({item, is_block});
    }
    std::vector<std::pair<void*, bool>> pop_defer_scope() {
        if (defer_stack.empty()) return {};
        auto items = std::move(defer_stack.back());
        defer_stack.pop_back();
        return items; // caller must emit these in reverse order
    }

    // ---- scope helpers ----
    void push_scope() { scopes.emplace_back(); }
    void pop_scope()  { if (!scopes.empty()) scopes.pop_back(); }

    void declare_local(const std::string& name, LLVMValueRef ptr, LLVMTypeRef elem_type,
                       LLVMTypeRef deref_type = nullptr) {
        if (scopes.empty()) push_scope();
        scopes.back().alloca_ptrs[name]  = ptr;
        scopes.back().alloca_types[name] = elem_type;
        if (deref_type) scopes.back().deref_types[name] = deref_type;
    }

    LLVMValueRef lookup_local(const std::string& name) const {
        for (auto it = scopes.rbegin(); it != scopes.rend(); ++it) {
            auto f = it->alloca_ptrs.find(name);
            if (f != it->alloca_ptrs.end()) return f->second;
        }
        return nullptr;
    }

    LLVMTypeRef lookup_local_type(const std::string& name) const {
        for (auto it = scopes.rbegin(); it != scopes.rend(); ++it) {
            auto f = it->alloca_types.find(name);
            if (f != it->alloca_types.end()) return f->second;
        }
        return nullptr;
    }

    LLVMTypeRef lookup_deref_type(const std::string& name) const {
        for (auto it = scopes.rbegin(); it != scopes.rend(); ++it) {
            auto f = it->deref_types.find(name);
            if (f != it->deref_types.end()) return f->second;
        }
        return nullptr;
    }

    // ---- loop/switch helpers ----
    void push_loop(LLVMBasicBlockRef break_bb, LLVMBasicBlockRef continue_bb) {
        loop_stack.push_back({break_bb, continue_bb});
    }
    void pop_loop() { if (!loop_stack.empty()) loop_stack.pop_back(); }

    LLVMBasicBlockRef current_break_target() const {
        return loop_stack.empty() ? nullptr : loop_stack.back().break_block;
    }
    LLVMBasicBlockRef current_continue_target() const {
        return loop_stack.empty() ? nullptr : loop_stack.back().continue_block;
    }

    // ---- utility ----
    // True if the basic block the builder is currently positioned in already has a terminator.
    bool is_terminated() const {
        LLVMBasicBlockRef bb = LLVMGetInsertBlock(llvm_builder);
        return bb && LLVMGetBasicBlockTerminator(bb) != nullptr;
    }
};

// Allocate and initialise an ir_context. The caller owns the returned pointer.
inline ir_context* make_ir_context(const char* module_name) {
    auto* ctx          = new ir_context();
    ctx->llvm_ctx      = LLVMContextCreate();
    ctx->llvm_mod      = LLVMModuleCreateWithNameInContext(module_name, ctx->llvm_ctx);
    ctx->llvm_builder  = LLVMCreateBuilderInContext(ctx->llvm_ctx);
    return ctx;
}

inline void destroy_ir_context(ir_context* ctx) {
    if (!ctx) return;
    LLVMDisposeBuilder(ctx->llvm_builder);
    LLVMDisposeModule(ctx->llvm_mod);
    LLVMContextDispose(ctx->llvm_ctx);
    delete ctx;
}
