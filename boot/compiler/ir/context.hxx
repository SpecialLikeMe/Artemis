#pragma once
#include "include.h"

// Forward declarations for generic templates (full defs in parser/main.hxx).
struct func_decl;
struct expr_node;

// Runtime check kind: populated by SMT inject pass, consumed by IR emitter.
enum class check_kind : uint8_t {
    bounds,    // array index out-of-bounds
    null_deref,// pointer null dereference
    div_zero,  // division or remainder by zero
};
struct class_decl;
struct enum_decl;
struct type_node;

// ---- Per-scope variable table ----
struct ir_scope_frame {
    std::unordered_map<std::string, LLVMValueRef> alloca_ptrs;     // name -> alloca
    std::unordered_map<std::string, LLVMTypeRef>  alloca_types;    // name -> element type (i32 for i32[N], ptr for i32*)
    std::unordered_map<std::string, LLVMTypeRef>  deref_types;     // name -> pointed-to type (i32 when name is i32*)
    std::unordered_map<std::string, bool>          alloca_unsigned; // name -> true if declared unsigned (u8/u16/u32/u64/...)
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
    // Error union: true when emitting a !T function; eu_type is the {i32,T} struct (or i32 for !void)
    bool        current_func_is_error_union = false;
    LLVMTypeRef current_error_union_type    = nullptr;

    // Local variable scopes (pushed/popped around blocks and function bodies)
    std::vector<ir_scope_frame> scopes;

    // Loop/switch control-flow stack (innermost last)
    std::vector<ir_loop_info> loop_stack;

    // Global declarations registered during pass 1
    std::unordered_map<std::string, LLVMValueRef> global_funcs;
    std::unordered_map<std::string, LLVMTypeRef>  global_func_types; // fn type (not ptr)
    std::unordered_map<std::string, bool>          global_func_ret_unsigned; // fn name -> unsigned return
    std::unordered_map<std::string, LLVMValueRef> global_vars;
    std::unordered_set<std::string>                global_var_unsigned; // unsigned global variable names
    std::unordered_map<std::string, LLVMTypeRef>  struct_types;           // name -> LLVMStructType
    std::unordered_map<std::string, std::vector<std::string>> struct_field_names;    // for GEP index
    std::unordered_map<std::string, std::vector<LLVMTypeRef>> struct_field_types;   // for member load
    std::unordered_map<std::string, std::vector<bool>>        struct_field_unsigned; // per-field unsigned flag
    std::unordered_set<std::string> union_names; // union types (single-body LLVM struct)
    // Non-struct typedef aliases: alias name -> underlying AST type (e.g. Real -> f64,
    // IntPtr -> i32*). Struct typedefs are handled via struct_types directly.
    std::unordered_map<std::string, type_node*> typedef_aliases;

    // Class-specific IR state
    struct class_method_ir_info {
        std::string  name;
        int          param_count = 0;
        type_node*   ret_type    = nullptr; // AST type node — used for ifo_t reflection only
    };
    struct class_ir_info {
        LLVMTypeRef   class_type    = nullptr;
        std::string   base_name;                // base class name (for base-chain method lookup)
        std::vector<std::string>          all_field_names;
        std::vector<LLVMTypeRef>          all_field_types;
        std::vector<class_method_ir_info> methods;  // for ifo_t reflection
    };
    std::unordered_map<std::string, class_ir_info> class_infos;

    // &memstr fat-pointer dispatch support
    LLVMTypeRef memstr_fat_type    = nullptr;   // {ptr, ptr} = {data_ptr, vtable_ptr}
    LLVMTypeRef memstr_vtable_type = nullptr;   // {ptr, ptr, ptr} for {mmap, rmap, deinit}
    std::unordered_map<std::string, LLVMValueRef> memstr_vtables;  // class_name -> vtable global

    // Pointee types for struct pointer fields (for correct subscript element type)
    std::unordered_map<std::string, std::vector<LLVMTypeRef>> struct_field_pointee_types;

    // Defer stack: each scope level has a list of deferred items (exprs/blocks)
    // stored as pairs of (expr_node*, block_stmt*) — one of which is non-null
    using defer_item = std::pair<void*, bool>; // ptr, false=expr_node, true=block_stmt
    std::vector<std::vector<std::pair<void*, bool>>> defer_stack;    // per-scope deferred items
    std::vector<std::vector<std::pair<void*, bool>>> errdefer_stack; // fired only on error exit

    // Current class being emitted (for self parameter lookup)
    std::string current_class_name;
    // Current namespace being emitted (for intra-namespace bare-name calls)
    std::string current_namespace;

    // ---- Generics (monomorphization) ----
    // Active type-parameter substitution while emitting a generic instantiation:
    //   type-param-name -> concrete LLVM type.
    std::unordered_map<std::string, LLVMTypeRef> type_subst;
    // Generic templates collected during pass 1 (keyed by base name).
    std::unordered_map<std::string, func_decl*>  generic_funcs;
    std::unordered_map<std::string, class_decl*> generic_classes;

    // ADT enum registry: enum name -> enum_decl* (for payload-access codegen)
    std::unordered_map<std::string, enum_decl*> adt_enums;

    // Compile-time integer values for constexpr declarations, populated before pass 1a
    // so that llvm_type_of can resolve identifier-based array sizes (e.g. field_ptrs[SOA_MAX_FIELDS]).
    std::unordered_map<std::string, int64_t> constexpr_int_vals;

    // Error name registry: populated by every error.Name literal in the module.
    // Used to emit __artemis_error_name() lookup at end of codegen.
    std::vector<std::pair<uint32_t, std::string>> error_registry;
    bool error_name_fn_emitted = false; // guard: emit once per module

    // Safety runtime checks: SMT inject pass populates this before IR emission.
    // expr_node* → what kind of runtime check to wrap around it.
    // GOOD sites are absent (no check needed). BAD sites cause compile errors
    // before IR emission. Only UNKNOWN sites appear here.
    std::unordered_map<expr_node*, check_kind> unsafe_ops;

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

    void push_errdefer_scope() { errdefer_stack.emplace_back(); }
    void add_errdefer(void* item, bool is_block) {
        if (!errdefer_stack.empty()) errdefer_stack.back().push_back({item, is_block});
    }
    void pop_errdefer_scope() {
        if (!errdefer_stack.empty()) errdefer_stack.pop_back();
    }

    // ---- scope helpers ----
    void push_scope() { scopes.emplace_back(); }
    void pop_scope()  { if (!scopes.empty()) scopes.pop_back(); }

    void declare_local(const std::string& name, LLVMValueRef ptr, LLVMTypeRef elem_type,
                       LLVMTypeRef deref_type = nullptr, bool is_unsigned = false) {
        if (scopes.empty()) push_scope();
        scopes.back().alloca_ptrs[name]      = ptr;
        scopes.back().alloca_types[name]     = elem_type;
        if (deref_type) scopes.back().deref_types[name] = deref_type;
        if (is_unsigned) scopes.back().alloca_unsigned[name] = true;
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

    bool lookup_local_unsigned(const std::string& name) const {
        for (auto it = scopes.rbegin(); it != scopes.rend(); ++it) {
            auto f = it->alloca_unsigned.find(name);
            if (f != it->alloca_unsigned.end()) return f->second;
        }
        return false;
    }

    bool lookup_field_unsigned(const std::string& struct_name, const std::string& field_name) const {
        auto nit = struct_field_names.find(struct_name);
        auto uit = struct_field_unsigned.find(struct_name);
        if (nit == struct_field_names.end() || uit == struct_field_unsigned.end()) return false;
        const auto& names   = nit->second;
        const auto& unsigns = uit->second;
        for (size_t i = 0; i < names.size() && i < unsigns.size(); i++)
            if (names[i] == field_name) return unsigns[i];
        return false;
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
