// IR context for the Artemis self-hosting compiler.
// Uses linear-search tables instead of hash maps for simplicity.

namespace ir {

// ---- String -> Value linear map ----
struct sv_entry {
    i8*  key;
    i8*  val;   // LLVMValueRef as i8*
}

struct sv_map {
    sv_entry* data;
    i32       len;
    i32       cap;
}

void sv_map_init(sv_map* m) {
    m.data = (sv_entry*)0;
    m.len  = 0;
    m.cap  = 0;
}

void sv_map_set(sv_map* m, i8* key, i8* val) {
    // Update existing key
    i32 i = 0;
    while (i < m.len) {
        if (strcmp(m.data[i].key, key) == 0) {
            m.data[i].val = val;
            return;
        }
        i = i + 1;
    }
    // Insert new
    if (m.len >= m.cap) {
        i32 nc = m.cap == 0 ? 32 : m.cap * 2;
        m.data = (sv_entry*)realloc((i8*)m.data, sizeof(ir__NS_sv_entry) * (u64)nc);
        m.cap  = nc;
    }
    m.data[m.len].key = key;
    m.data[m.len].val = val;
    m.len = m.len + 1;
}

i8* sv_map_get(sv_map* m, i8* key) {
    i32 i = m.len - 1;
    while (i >= 0) {
        if (strcmp(m.data[i].key, key) == 0) {
            return m.data[i].val;
        }
        i = i - 1;
    }
    return (i8*)0;
}

bool sv_map_has(sv_map* m, i8* key) {
    return sv_map_get(m, key) != (i8*)0;
}

// ---- String -> Type linear map ----
struct st_entry {
    i8* key;
    i8* type;  // LLVMTypeRef as i8*
}

struct st_map {
    st_entry* data;
    i32       len;
    i32       cap;
}

void st_map_init(st_map* m) {
    m.data = (st_entry*)0;
    m.len  = 0;
    m.cap  = 0;
}

void st_map_set(st_map* m, i8* key, i8* type) {
    i32 i = 0;
    while (i < m.len) {
        if (strcmp(m.data[i].key, key) == 0) {
            m.data[i].type = type;
            return;
        }
        i = i + 1;
    }
    if (m.len >= m.cap) {
        i32 nc = m.cap == 0 ? 32 : m.cap * 2;
        m.data = (st_entry*)realloc((i8*)m.data, sizeof(ir__NS_st_entry) * (u64)nc);
        m.cap  = nc;
    }
    m.data[m.len].key  = key;
    m.data[m.len].type = type;
    m.len = m.len + 1;
}

i8* st_map_get(st_map* m, i8* key) {
    i32 i = m.len - 1;
    while (i >= 0) {
        if (strcmp(m.data[i].key, key) == 0) {
            return m.data[i].type;
        }
        i = i - 1;
    }
    return (i8*)0;
}

bool st_map_has(st_map* m, i8* key) {
    return st_map_get(m, key) != (i8*)0;
}

// ---- String -> bool map ----
struct sb_entry {
    i8*  key;
    bool val;
}

struct sb_map {
    sb_entry* data;
    i32       len;
    i32       cap;
}

void sb_map_init(sb_map* m) {
    m.data = (sb_entry*)0;
    m.len  = 0;
    m.cap  = 0;
}

void sb_map_set(sb_map* m, i8* key, bool val) {
    i32 i = 0;
    while (i < m.len) {
        if (strcmp(m.data[i].key, key) == 0) {
            m.data[i].val = val;
            return;
        }
        i = i + 1;
    }
    if (m.len >= m.cap) {
        i32 nc = m.cap == 0 ? 16 : m.cap * 2;
        m.data = (sb_entry*)realloc((i8*)m.data, sizeof(ir__NS_sb_entry) * (u64)nc);
        m.cap  = nc;
    }
    m.data[m.len].key = key;
    m.data[m.len].val = val;
    m.len = m.len + 1;
}

bool sb_map_get(sb_map* m, i8* key) {
    i32 i = m.len - 1;
    while (i >= 0) {
        if (strcmp(m.data[i].key, key) == 0) {
            return m.data[i].val;
        }
        i = i - 1;
    }
    return false;
}

// ---- String names (parallel arrays for struct fields) ----
struct name_list {
    i8** data;
    i32  len;
    i32  cap;
}

void name_list_init(name_list* v) {
    v.data = (i8**)0;
    v.len  = 0;
    v.cap  = 0;
}

void name_list_push(name_list* v, i8* s) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 8 : v.cap * 2;
        v.data = (i8**)realloc((i8*)v.data, sizeof(i8*) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = s;
    v.len = v.len + 1;
}

// ---- Type lists for struct fields ----
struct type_list {
    i8** data;   // LLVMTypeRef*
    i32  len;
    i32  cap;
}

void type_list_init(type_list* v) {
    v.data = (i8**)0;
    v.len  = 0;
    v.cap  = 0;
}

void type_list_push(type_list* v, i8* t) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 8 : v.cap * 2;
        v.data = (i8**)realloc((i8*)v.data, sizeof(i8*) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = t;
    v.len = v.len + 1;
}

// ---- Bool lists for unsigned tracking ----
struct bool_list {
    bool* data;
    i32   len;
    i32   cap;
}

void bool_list_init(bool_list* v) {
    v.data = (bool*)0;
    v.len  = 0;
    v.cap  = 0;
}

void bool_list_push(bool_list* v, bool b) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 8 : v.cap * 2;
        v.data = (bool*)realloc((i8*)v.data, sizeof(bool) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = b;
    v.len = v.len + 1;
}

// ---- Struct field metadata (parallel arrays per struct) ----
struct struct_meta {
    i8*        name;        // struct name
    name_list  field_names;
    type_list  field_types;   // LLVMTypeRef*
    bool_list  field_unsigned;
    type_list  field_pointee; // pointee types for pointer fields (null for non-pointers)
    bool       is_union;    // true if declared as 'union' rather than 'struct'
}

struct struct_meta_vec {
    struct_meta* data;
    i32          len;
    i32          cap;
}

void struct_meta_vec_init(struct_meta_vec* v) {
    v.data = (struct_meta*)0;
    v.len  = 0;
    v.cap  = 0;
}

void struct_meta_vec_push(struct_meta_vec* v, struct_meta m) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 16 : v.cap * 2;
        v.data = (struct_meta*)realloc((i8*)v.data, sizeof(ir__NS_struct_meta) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = m;
    v.len = v.len + 1;
}

struct_meta* struct_meta_find(struct_meta_vec* v, i8* name) {
    i32 i = 0;
    while (i < v.len) {
        if (strcmp(v.data[i].name, name) == 0) {
            return &v.data[i];
        }
        i = i + 1;
    }
    return (struct_meta*)0;
}

bool ctx_is_union(ir_context* ctx, i8* struct_name) {
    struct_meta* sm = struct_meta_find(&ctx.struct_meta_tbl, struct_name);
    if (sm == (struct_meta*)0) { return false; }
    return sm.is_union;
}

// ---- typedef alias entry ----
struct typedef_entry {
    i8*  name;
    i8*  type_node_ptr;   // parser::type_node* as i8*
}

struct typedef_map {
    typedef_entry* data;
    i32            len;
    i32            cap;
}

void typedef_map_init(typedef_map* m) {
    m.data = (typedef_entry*)0;
    m.len  = 0;
    m.cap  = 0;
}

void typedef_map_set(typedef_map* m, i8* name, i8* tn_ptr) {
    i32 i = 0;
    while (i < m.len) {
        if (strcmp(m.data[i].name, name) == 0) {
            m.data[i].type_node_ptr = tn_ptr;
            return;
        }
        i = i + 1;
    }
    if (m.len >= m.cap) {
        i32 nc = m.cap == 0 ? 16 : m.cap * 2;
        m.data = (typedef_entry*)realloc((i8*)m.data, sizeof(ir__NS_typedef_entry) * (u64)nc);
        m.cap  = nc;
    }
    m.data[m.len].name         = name;
    m.data[m.len].type_node_ptr = tn_ptr;
    m.len = m.len + 1;
}

i8* typedef_map_get(typedef_map* m, i8* name) {
    i32 i = 0;
    while (i < m.len) {
        if (strcmp(m.data[i].name, name) == 0) {
            return m.data[i].type_node_ptr;
        }
        i = i + 1;
    }
    return (i8*)0;
}

// ---- IR scope frame ----
struct ir_scope_frame {
    sv_map alloca_ptrs;     // name -> LLVMValueRef (alloca)
    st_map alloca_types;    // name -> LLVMTypeRef (element type)
    st_map deref_types;     // name -> LLVMTypeRef (pointed-to type)
    sb_map alloca_unsigned; // name -> bool
    st_map local_func_types;// name -> LLVMTypeRef (function type for func-ptr locals)
}

struct scope_frame_vec {
    ir_scope_frame* data;
    i32             len;
    i32             cap;
}

void scope_frame_vec_init(scope_frame_vec* v) {
    v.data = (ir_scope_frame*)0;
    v.len  = 0;
    v.cap  = 0;
}

void scope_frame_vec_push(scope_frame_vec* v, ir_scope_frame f) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 8 : v.cap * 2;
        v.data = (ir_scope_frame*)realloc((i8*)v.data, sizeof(ir__NS_ir_scope_frame) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = f;
    v.len = v.len + 1;
}

// ---- Loop control-flow info ----
struct ir_loop_info {
    i8* break_block;    // LLVMBasicBlockRef
    i8* continue_block; // LLVMBasicBlockRef
}

struct loop_stack {
    ir_loop_info* data;
    i32           len;
    i32           cap;
}

void loop_stack_init(loop_stack* v) {
    v.data = (ir_loop_info*)0;
    v.len  = 0;
    v.cap  = 0;
}

void loop_stack_push(loop_stack* v, ir_loop_info info) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 8 : v.cap * 2;
        v.data = (ir_loop_info*)realloc((i8*)v.data, sizeof(ir__NS_ir_loop_info) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = info;
    v.len = v.len + 1;
}

// ---- Defer item ----
struct defer_item {
    i8*  ptr;      // expr_node* or block_stmt*
    bool is_block; // true = block_stmt, false = expr_node
}

struct defer_scope {
    defer_item* data;
    i32         len;
    i32         cap;
}

void defer_scope_init(defer_scope* v) {
    v.data = (defer_item*)0;
    v.len  = 0;
    v.cap  = 0;
}

void defer_scope_push(defer_scope* v, defer_item d) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 8 : v.cap * 2;
        v.data = (defer_item*)realloc((i8*)v.data, sizeof(ir__NS_defer_item) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = d;
    v.len = v.len + 1;
}

struct defer_stack {
    defer_scope* data;
    i32          len;
    i32          cap;
}

void defer_stack_init(defer_stack* v) {
    v.data = (defer_scope*)0;
    v.len  = 0;
    v.cap  = 0;
}

void defer_stack_push_scope(defer_stack* v) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 8 : v.cap * 2;
        v.data = (defer_scope*)realloc((i8*)v.data, sizeof(ir__NS_defer_scope) * (u64)nc);
        v.cap  = nc;
    }
    defer_scope_init(&v.data[v.len]);
    v.len = v.len + 1;
}

// ---- IR context ----

struct ir_context {
    i8* llvm_ctx;      // LLVMContextRef
    i8* llvm_mod;      // LLVMModuleRef
    i8* llvm_builder;  // LLVMBuilderRef

    i8* current_func;      // LLVMValueRef
    i8* current_func_type; // LLVMTypeRef
    i8* current_ret_type;  // LLVMTypeRef
    bool current_func_is_error_union;
    i8*  current_error_union_type;  // LLVMTypeRef

    scope_frame_vec scopes;
    loop_stack      loops;

    // Global function/variable tables
    sv_map global_funcs;
    st_map global_func_types;
    sb_map global_func_ret_unsigned;
    sv_map global_vars;
    sb_map global_var_unsigned;

    // Struct type registry: name -> LLVMTypeRef
    st_map struct_types;

    // Struct field metadata
    struct_meta_vec struct_meta_tbl;

    // Set of union names (stored as name -> true in a sb_map)
    sb_map union_names;

    // Non-struct typedef aliases
    typedef_map typedef_aliases;

    // Current class and namespace context
    i8* current_class_name;
    i8* current_namespace;

    // Defer stacks
    defer_stack defers;
    defer_stack errdefers;

    // constexpr integer values: name -> i64
    sv_map constexpr_int_vals_map;

    // Error union type (memstr fat type, etc.)
    i8* memstr_fat_type;

    // Generic function support
    sv_map generic_funcs;       // name -> func_decl* (i8*)
    st_map type_param_bindings; // type param name -> LLVMTypeRef

    // ADT enum support: enum name -> enum_decl* (i8*)
    sv_map adt_enum_decls;
}

// Allocate and initialize an ir_context.
ir_context* make_ir_context(i8* module_name) {
    ir_context* ctx = (ir_context*)malloc(sizeof(ir__NS_ir_context));
    memset((i8*)ctx, 0, sizeof(ir__NS_ir_context));

    ctx.llvm_ctx     = LLVMContextCreate();
    ctx.llvm_mod     = LLVMModuleCreateWithNameInContext(module_name, ctx.llvm_ctx);
    ctx.llvm_builder = LLVMCreateBuilderInContext(ctx.llvm_ctx);

    sv_map_init(&ctx.global_funcs);
    st_map_init(&ctx.global_func_types);
    sb_map_init(&ctx.global_func_ret_unsigned);
    sv_map_init(&ctx.global_vars);
    sb_map_init(&ctx.global_var_unsigned);
    st_map_init(&ctx.struct_types);
    struct_meta_vec_init(&ctx.struct_meta_tbl);
    sb_map_init(&ctx.union_names);
    typedef_map_init(&ctx.typedef_aliases);
    scope_frame_vec_init(&ctx.scopes);
    loop_stack_init(&ctx.loops);
    defer_stack_init(&ctx.defers);
    defer_stack_init(&ctx.errdefers);
    sv_map_init(&ctx.constexpr_int_vals_map);
    sv_map_init(&ctx.generic_funcs);
    st_map_init(&ctx.type_param_bindings);
    sv_map_init(&ctx.adt_enum_decls);

    ctx.current_class_name = (i8*)0;
    ctx.current_namespace  = (i8*)0;
    ctx.memstr_fat_type    = (i8*)0;

    return ctx;
}

void destroy_ir_context(ir_context* ctx) {
    if (ctx == (ir_context*)0) { return; }
    if (ctx.llvm_builder != (i8*)0) { LLVMDisposeBuilder(ctx.llvm_builder); }
    if (ctx.llvm_mod     != (i8*)0) { LLVMDisposeModule(ctx.llvm_mod); }
    if (ctx.llvm_ctx     != (i8*)0) { LLVMContextDispose(ctx.llvm_ctx); }
    free((i8*)ctx);
}

// ---- Scope helpers ----

void ctx_push_scope(ir_context* ctx) {
    ir_scope_frame f;
    sv_map_init(&f.alloca_ptrs);
    st_map_init(&f.alloca_types);
    st_map_init(&f.deref_types);
    sb_map_init(&f.alloca_unsigned);
    st_map_init(&f.local_func_types);
    scope_frame_vec_push(&ctx.scopes, f);
}

void ctx_pop_scope(ir_context* ctx) {
    if (ctx.scopes.len > 0) {
        ctx.scopes.len = ctx.scopes.len - 1;
    }
}

void ctx_declare_local(ir_context* ctx, i8* name, i8* alloca_ptr,
                       i8* elem_type, i8* deref_type, bool is_unsigned) {
    if (ctx.scopes.len == 0) { ctx_push_scope(ctx); }
    i32 idx = ctx.scopes.len - 1;
    sv_map_set(&ctx.scopes.data[idx].alloca_ptrs,     name, alloca_ptr);
    st_map_set(&ctx.scopes.data[idx].alloca_types,    name, elem_type);
    if (deref_type != (i8*)0) {
        st_map_set(&ctx.scopes.data[idx].deref_types, name, deref_type);
    }
    if (is_unsigned) {
        sb_map_set(&ctx.scopes.data[idx].alloca_unsigned, name, true);
    }
}

i8* ctx_lookup_local(ir_context* ctx, i8* name) {
    i32 i = ctx.scopes.len - 1;
    while (i >= 0) {
        i8* v = sv_map_get(&ctx.scopes.data[i].alloca_ptrs, name);
        if (v != (i8*)0) { return v; }
        i = i - 1;
    }
    return (i8*)0;
}

i8* ctx_lookup_local_type(ir_context* ctx, i8* name) {
    i32 i = ctx.scopes.len - 1;
    while (i >= 0) {
        i8* v = st_map_get(&ctx.scopes.data[i].alloca_types, name);
        if (v != (i8*)0) { return v; }
        i = i - 1;
    }
    return (i8*)0;
}

i8* ctx_lookup_deref_type(ir_context* ctx, i8* name) {
    i32 i = ctx.scopes.len - 1;
    while (i >= 0) {
        i8* v = st_map_get(&ctx.scopes.data[i].deref_types, name);
        if (v != (i8*)0) { return v; }
        i = i - 1;
    }
    return (i8*)0;
}

void ctx_declare_local_func_type(ir_context* ctx, i8* name, i8* fn_type) {
    if (ctx.scopes.len == 0) { ctx_push_scope(ctx); }
    i32 idx = ctx.scopes.len - 1;
    st_map_set(&ctx.scopes.data[idx].local_func_types, name, fn_type);
}

i8* ctx_lookup_local_func_type(ir_context* ctx, i8* name) {
    i32 i = ctx.scopes.len - 1;
    while (i >= 0) {
        i8* v = st_map_get(&ctx.scopes.data[i].local_func_types, name);
        if (v != (i8*)0) { return v; }
        i = i - 1;
    }
    return (i8*)0;
}

bool ctx_lookup_local_unsigned(ir_context* ctx, i8* name) {
    i32 i = ctx.scopes.len - 1;
    while (i >= 0) {
        bool v = sb_map_get(&ctx.scopes.data[i].alloca_unsigned, name);
        if (v) { return true; }
        i = i - 1;
    }
    return false;
}

// ---- Loop helpers ----

void ctx_push_loop(ir_context* ctx, i8* break_bb, i8* continue_bb) {
    ir_loop_info info;
    info.break_block    = break_bb;
    info.continue_block = continue_bb;
    loop_stack_push(&ctx.loops, info);
}

void ctx_pop_loop(ir_context* ctx) {
    if (ctx.loops.len > 0) {
        ctx.loops.len = ctx.loops.len - 1;
    }
}

i8* ctx_current_break(ir_context* ctx) {
    if (ctx.loops.len == 0) { return (i8*)0; }
    return ctx.loops.data[ctx.loops.len - 1].break_block;
}

i8* ctx_current_continue(ir_context* ctx) {
    if (ctx.loops.len == 0) { return (i8*)0; }
    return ctx.loops.data[ctx.loops.len - 1].continue_block;
}

// ---- Terminator check ----

bool ctx_is_terminated(ir_context* ctx) {
    i8* bb = LLVMGetInsertBlock(ctx.llvm_builder);
    if (bb == (i8*)0) { return false; }
    return LLVMGetBasicBlockTerminator(bb) != (i8*)0;
}

// ---- Defer helpers ----

void ctx_push_defer_scope(ir_context* ctx) {
    defer_stack_push_scope(&ctx.defers);
}

void ctx_push_errdefer_scope(ir_context* ctx) {
    defer_stack_push_scope(&ctx.errdefers);
}

void ctx_add_defer(ir_context* ctx, i8* ptr, bool is_block) {
    if (ctx.defers.len == 0) { return; }
    defer_item di;
    di.ptr      = ptr;
    di.is_block = is_block;
    defer_scope_push(&ctx.defers.data[ctx.defers.len - 1], di);
}

void ctx_add_errdefer(ir_context* ctx, i8* ptr, bool is_block) {
    if (ctx.errdefers.len == 0) { return; }
    defer_item di;
    di.ptr      = ptr;
    di.is_block = is_block;
    defer_scope_push(&ctx.errdefers.data[ctx.errdefers.len - 1], di);
}

void ctx_pop_errdefer_scope(ir_context* ctx) {
    if (ctx.errdefers.len > 0) {
        ctx.errdefers.len = ctx.errdefers.len - 1;
    }
}

defer_scope ctx_pop_errdefer_scope_get(ir_context* ctx) {
    defer_scope empty;
    defer_scope_init(&empty);
    if (ctx.errdefers.len == 0) { return empty; }
    defer_scope s = ctx.errdefers.data[ctx.errdefers.len - 1];
    ctx.errdefers.len = ctx.errdefers.len - 1;
    return s;
}

// Pop and return the defer scope (caller emits in reverse order).
defer_scope ctx_pop_defer_scope(ir_context* ctx) {
    defer_scope empty;
    defer_scope_init(&empty);
    if (ctx.defers.len == 0) { return empty; }
    defer_scope s = ctx.defers.data[ctx.defers.len - 1];
    ctx.defers.len = ctx.defers.len - 1;
    return s;
}

// ---- Field index lookup ----

i32 ctx_field_index(ir_context* ctx, i8* struct_name, i8* field_name) {
    struct_meta* m = struct_meta_find(&ctx.struct_meta_tbl, struct_name);
    if (m == (struct_meta*)0) { return -1; }
    i32 i = 0;
    while (i < m.field_names.len) {
        if (strcmp(m.field_names.data[i], field_name) == 0) {
            return i;
        }
        i = i + 1;
    }
    return -1;
}

i8* ctx_field_type(ir_context* ctx, i8* struct_name, i32 idx) {
    struct_meta* m = struct_meta_find(&ctx.struct_meta_tbl, struct_name);
    if (m == (struct_meta*)0) { return (i8*)0; }
    if (idx < 0 || idx >= m.field_types.len) { return (i8*)0; }
    return m.field_types.data[idx];
}

bool ctx_field_unsigned(ir_context* ctx, i8* struct_name, i8* field_name) {
    struct_meta* m = struct_meta_find(&ctx.struct_meta_tbl, struct_name);
    if (m == (struct_meta*)0) { return false; }
    i32 i = 0;
    while (i < m.field_names.len) {
        if (strcmp(m.field_names.data[i], field_name) == 0) {
            if (i < m.field_unsigned.len) {
                return m.field_unsigned.data[i];
            }
            return false;
        }
        i = i + 1;
    }
    return false;
}

} // namespace ir
