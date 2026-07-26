// IR context for the Artemis self-hosting compiler.
// Uses linear-search tables instead of hash maps for simplicity.

namespace ir {

// ---- String -> Value linear map ----
struct sv_entry {
    let key: *i8;
    let val: *i8;   // LLVMValueRef as i8*
}

struct sv_map {
    let data: *sv_entry;
    let len: i32;
    let cap: i32;
}

fn sv_map_init(m: *sv_map) void {
    m.data = (sv_entry*)0;
    m.len  = 0;
    m.cap  = 0;
}

fn sv_map_set(m: *sv_map, key: *i8, val: *i8) void {
    // Update existing key
    let mut i: i32= 0;
    while (i < m.len) {
        if (strcmp(m.data[i].key, key) == 0) {
            m.data[i].val = val;
            return;
        }
        i = i + 1;
    }
    // Insert new
    if (m.len >= m.cap) {
        let mut nc: i32= m.cap == 0 ? 32 : m.cap * 2;
        m.data = (sv_entry*)arc_realloc((i8*)m.data, sizeof(ir__NS_sv_entry) * (u64)nc);
        m.cap  = nc;
    }
    m.data[m.len].key = key;
    m.data[m.len].val = val;
    m.len = m.len + 1;
}

fn sv_map_get(m: *sv_map, key: *i8) *i8 {
    let mut i: i32= m.len - 1;
    while (i >= 0) {
        if (strcmp(m.data[i].key, key) == 0) {
            return m.data[i].val;
        }
        i = i - 1;
    }
    return (i8*)0;
}

fn sv_map_has(m: *sv_map, key: *i8) bool {
    return sv_map_get(m, key) != (i8*)0;
}

// ---- String -> Type linear map ----
struct st_entry {
    let key: *i8;
    let type: *i8;  // LLVMTypeRef as i8*
}

struct st_map {
    let data: *st_entry;
    let len: i32;
    let cap: i32;
}

fn st_map_init(m: *st_map) void {
    m.data = (st_entry*)0;
    m.len  = 0;
    m.cap  = 0;
}

fn st_map_set(m: *st_map, key: *i8, llvm_type: *i8) void {
    let mut i: i32= 0;
    while (i < m.len) {
        if (strcmp(m.data[i].key, key) == 0) {
            m.data[i].type = llvm_type;
            return;
        }
        i = i + 1;
    }
    if (m.len >= m.cap) {
        let mut nc: i32= m.cap == 0 ? 32 : m.cap * 2;
        m.data = (st_entry*)arc_realloc((i8*)m.data, sizeof(ir__NS_st_entry) * (u64)nc);
        m.cap  = nc;
    }
    m.data[m.len].key  = key;
    m.data[m.len].type = llvm_type;
    m.len = m.len + 1;
}

fn st_map_get(m: *st_map, key: *i8) *i8 {
    let mut i: i32= m.len - 1;
    while (i >= 0) {
        if (strcmp(m.data[i].key, key) == 0) {
            return m.data[i].type;
        }
        i = i - 1;
    }
    return (i8*)0;
}

fn st_map_has(m: *st_map, key: *i8) bool {
    return st_map_get(m, key) != (i8*)0;
}

// ---- String -> bool map ----
struct sb_entry {
    let key: *i8;
    let val: bool;
}

struct sb_map {
    let data: *sb_entry;
    let len: i32;
    let cap: i32;
}

fn sb_map_init(m: *sb_map) void {
    m.data = (sb_entry*)0;
    m.len  = 0;
    m.cap  = 0;
}

fn sb_map_set(m: *sb_map, key: *i8, val: bool) void {
    let mut i: i32= 0;
    while (i < m.len) {
        if (strcmp(m.data[i].key, key) == 0) {
            m.data[i].val = val;
            return;
        }
        i = i + 1;
    }
    if (m.len >= m.cap) {
        let mut nc: i32= m.cap == 0 ? 16 : m.cap * 2;
        m.data = (sb_entry*)arc_realloc((i8*)m.data, sizeof(ir__NS_sb_entry) * (u64)nc);
        m.cap  = nc;
    }
    m.data[m.len].key = key;
    m.data[m.len].val = val;
    m.len = m.len + 1;
}

fn sb_map_get(m: *sb_map, key: *i8) bool {
    let mut i: i32= m.len - 1;
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
    let data: **i8;
    let len: i32;
    let cap: i32;
}

fn name_list_init(v: *name_list) void {
    v.data = (i8**)0;
    v.len  = 0;
    v.cap  = 0;
}

fn name_list_push(v: *name_list, s: *i8) void {
    if (v.len >= v.cap) {
        let mut nc: i32= v.cap == 0 ? 8 : v.cap * 2;
        v.data = (i8**)arc_realloc((i8*)v.data, sizeof(i8*) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = s;
    v.len = v.len + 1;
}

// ---- Type lists for struct fields ----
struct type_list {
    let data: **i8;   // LLVMTypeRef*
    let len: i32;
    let cap: i32;
}

fn type_list_init(v: *type_list) void {
    v.data = (i8**)0;
    v.len  = 0;
    v.cap  = 0;
}

fn type_list_push(v: *type_list, t: *i8) void {
    if (v.len >= v.cap) {
        let mut nc: i32= v.cap == 0 ? 8 : v.cap * 2;
        v.data = (i8**)arc_realloc((i8*)v.data, sizeof(i8*) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = t;
    v.len = v.len + 1;
}

// ---- Bool lists for unsigned tracking ----
struct bool_list {
    let data: *bool;
    let len: i32;
    let cap: i32;
}

fn bool_list_init(v: *bool_list) void {
    v.data = (bool*)0;
    v.len  = 0;
    v.cap  = 0;
}

fn bool_list_push(v: *bool_list, b: bool) void {
    if (v.len >= v.cap) {
        let mut nc: i32= v.cap == 0 ? 8 : v.cap * 2;
        v.data = (bool*)arc_realloc((i8*)v.data, sizeof(bool) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = b;
    v.len = v.len + 1;
}

// ---- Struct field metadata (parallel arrays per struct) ----
struct struct_meta {
    let name: *i8;        // struct name
    let field_names: name_list;
    let field_types: type_list;   // LLVMTypeRef*
    let field_unsigned: bool_list;
    let field_pointee: type_list; // pointee types for pointer fields (null for non-pointers)
    let field_pointee_names: name_list; // base struct name for pointer fields (for forward-ref resolution)
    let is_union: bool;    // true if declared as 'union' rather than 'struct'
    let is_istruc: bool;   // true if declared as 'istruc' (class-like, has methods)
    let is_interface: bool; // true if declared as 'interface' with vtable dispatch
    let iface_method_names: name_list; // method names in vtable slot order (interfaces only)
}

struct struct_meta_vec {
    let data: *struct_meta;
    let len: i32;
    let cap: i32;
}

fn struct_meta_vec_init(v: *struct_meta_vec) void {
    v.data = (struct_meta*)0;
    v.len  = 0;
    v.cap  = 0;
}

fn struct_meta_vec_push(v: *struct_meta_vec, m: struct_meta) void {
    if (v.len >= v.cap) {
        let mut nc: i32= v.cap == 0 ? 16 : v.cap * 2;
        v.data = (struct_meta*)arc_realloc((i8*)v.data, sizeof(ir__NS_struct_meta) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = m;
    v.len = v.len + 1;
}

fn struct_meta_find(v: *struct_meta_vec, name: *i8) *struct_meta {
    let mut i: i32= 0;
    while (i < v.len) {
        if (strcmp(v.data[i].name, name) == 0) {
            return &v.data[i];
        }
        i = i + 1;
    }
    return (struct_meta*)0;
}

fn ctx_is_union(ctx: *ir_context, struct_name: *i8) bool {
    let mut sm: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, struct_name);
    if (sm == (struct_meta*)0) { return false; }
    return sm.is_union;
}

// ---- typedef alias entry ----
struct typedef_entry {
    let name: *i8;
    let type_node_ptr: *i8;   // parser::type_node* as i8*
}

struct typedef_map {
    let data: *typedef_entry;
    let len: i32;
    let cap: i32;
}

fn typedef_map_init(m: *typedef_map) void {
    m.data = (typedef_entry*)0;
    m.len  = 0;
    m.cap  = 0;
}

fn typedef_map_set(m: *typedef_map, name: *i8, tn_ptr: *i8) void {
    let mut i: i32= 0;
    while (i < m.len) {
        if (strcmp(m.data[i].name, name) == 0) {
            m.data[i].type_node_ptr = tn_ptr;
            return;
        }
        i = i + 1;
    }
    if (m.len >= m.cap) {
        let mut nc: i32= m.cap == 0 ? 16 : m.cap * 2;
        m.data = (typedef_entry*)arc_realloc((i8*)m.data, sizeof(ir__NS_typedef_entry) * (u64)nc);
        m.cap  = nc;
    }
    m.data[m.len].name         = name;
    m.data[m.len].type_node_ptr = tn_ptr;
    m.len = m.len + 1;
}

fn typedef_map_get(m: *typedef_map, name: *i8) *i8 {
    let mut i: i32= 0;
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
    let alloca_ptrs: sv_map;     // name -> LLVMValueRef (alloca)
    let alloca_types: st_map;    // name -> LLVMTypeRef (element type)
    let deref_types: st_map;     // name -> LLVMTypeRef (pointed-to type)
    let alloca_unsigned: sb_map; // name -> bool
    let alloca_volatile: sb_map; // name -> bool (volatile qualifier)
    let local_func_types: st_map;  // name -> LLVMTypeRef (function type for func-ptr locals)
    let local_func_depths: sv_map; // name -> pointer_depth as decimal string
    let alloca_ptr_data_const: sb_map; // name -> bool (*const T pointer — writes are forbidden)
    let alloca_var_depths: sv_map; // name -> semantic pointer depth as decimal string (for ref deref)
    let alloca_base_types: st_map; // name -> base LLVMTypeRef at ptr depth 0 (for ref deref)
}

struct scope_frame_vec {
    let data: *ir_scope_frame;
    let len: i32;
    let cap: i32;
}

fn scope_frame_vec_init(v: *scope_frame_vec) void {
    v.data = (ir_scope_frame*)0;
    v.len  = 0;
    v.cap  = 0;
}

fn scope_frame_vec_push(v: *scope_frame_vec, f: ir_scope_frame) void {
    if (v.len >= v.cap) {
        let mut nc: i32= v.cap == 0 ? 8 : v.cap * 2;
        v.data = (ir_scope_frame*)arc_realloc((i8*)v.data, sizeof(ir__NS_ir_scope_frame) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = f;
    v.len = v.len + 1;
}

// ---- Loop control-flow info ----
struct ir_loop_info {
    let break_block: *i8;    // LLVMBasicBlockRef
    let continue_block: *i8; // LLVMBasicBlockRef
}

struct loop_stack {
    let data: *ir_loop_info;
    let len: i32;
    let cap: i32;
}

fn loop_stack_init(v: *loop_stack) void {
    v.data = (ir_loop_info*)0;
    v.len  = 0;
    v.cap  = 0;
}

fn loop_stack_push(v: *loop_stack, info: ir_loop_info) void {
    if (v.len >= v.cap) {
        let mut nc: i32= v.cap == 0 ? 8 : v.cap * 2;
        v.data = (ir_loop_info*)arc_realloc((i8*)v.data, sizeof(ir__NS_ir_loop_info) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = info;
    v.len = v.len + 1;
}

// ---- Defer item ----
struct defer_item {
    let ptr: *i8;      // expr_node* or block_stmt*
    let is_block: bool; // true = block_stmt, false = expr_node
}

struct defer_scope {
    let data: *defer_item;
    let len: i32;
    let cap: i32;
}

fn defer_scope_init(v: *defer_scope) void {
    v.data = (defer_item*)0;
    v.len  = 0;
    v.cap  = 0;
}

fn defer_scope_push(v: *defer_scope, d: defer_item) void {
    if (v.len >= v.cap) {
        let mut nc: i32= v.cap == 0 ? 8 : v.cap * 2;
        v.data = (defer_item*)arc_realloc((i8*)v.data, sizeof(ir__NS_defer_item) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = d;
    v.len = v.len + 1;
}

struct defer_stack {
    let data: *defer_scope;
    let len: i32;
    let cap: i32;
}

fn defer_stack_init(v: *defer_stack) void {
    v.data = (defer_scope*)0;
    v.len  = 0;
    v.cap  = 0;
}

fn defer_stack_push_scope(v: *defer_stack) void {
    if (v.len >= v.cap) {
        let mut nc: i32= v.cap == 0 ? 8 : v.cap * 2;
        v.data = (defer_scope*)arc_realloc((i8*)v.data, sizeof(ir__NS_defer_scope) * (u64)nc);
        v.cap  = nc;
    }
    defer_scope_init(&v.data[v.len]);
    v.len = v.len + 1;
}

// ---- IR context ----

struct ir_context {
    let llvm_ctx: *i8;      // LLVMContextRef
    let llvm_mod: *i8;      // LLVMModuleRef
    let llvm_builder: *i8;  // LLVMBuilderRef

    let current_func: *i8;      // LLVMValueRef
    let current_func_type: *i8; // LLVMTypeRef
    let current_ret_type: *i8;  // LLVMTypeRef
    let current_func_is_error_union: bool;
    let current_error_union_type: *i8;  // LLVMTypeRef
    // !T (non-void) error union tracking
    let current_func_eu_is_value: bool; // true when current fn returns !T (non-void)
    let current_eu_value_type: *i8;     // LLVMTypeRef of T in !T

    let scopes: scope_frame_vec;
    let loops: loop_stack;

    // Global function/variable tables
    let global_funcs: sv_map;
    let global_func_types: st_map;
    let global_func_ret_unsigned: sb_map;
    let global_func_decls: sv_map;      // mangled name -> parser.func_decl* (for interface coercion)
    let global_vars: sv_map;
    let global_var_unsigned: sb_map;

    // Struct type registry: name -> LLVMTypeRef
    let struct_types: st_map;

    // Struct field metadata
    let struct_meta_tbl: struct_meta_vec;

    // Set of union names (stored as name -> true in a sb_map)
    let union_names: sb_map;

    // Non-struct typedef aliases
    let typedef_aliases: typedef_map;

    // Current class and namespace context
    let current_class_name: *i8;
    let current_namespace: *i8;
    let current_ns_is_istruc: bool;     // true when inside an istruc namespace block
    let current_ns_is_interface: bool;  // true when inside an interface namespace block

    // Defer stacks
    let defers: defer_stack;
    let errdefers: defer_stack;

    // constexpr integer values: name -> i64
    let constexpr_int_vals_map: sv_map;

    // memstr fat-pointer dispatch support
    let memstr_fat_type: *i8;       // %__memstr_fat__ = { ptr data, ptr vtable }
    let memstr_vtable_type: *i8;    // { ptr mmap_fn, ptr rmap_fn, ptr deinit_fn }
    let memstr_vtables: sv_map;     // class_name -> vtable global (LLVMValueRef as i8*)

    // Interface fat-pointer dispatch support
    let iface_vtable_types: st_map;      // iface_name -> %IfaceName__vtable LLVM struct type
    let iface_concrete_vtables: sv_map;  // "ConcreteName__IFACE__IfaceName" -> vtable global

    // Generic function support
    let generic_funcs: sv_map;       // name -> func_decl* (i8*)
    let type_param_bindings: st_map; // type param name -> LLVMTypeRef

    // anytype function monomorphization: name -> func_decl*, and per-param type bindings
    let anytype_funcs: sv_map;           // func_name -> func_decl* (i8*)
    let anytype_param_bindings: st_map;  // param_name -> LLVMTypeRef for current monomorphization
    let mut in_anytype_mono: bool;       // true while compiling an anytype specialization

    // Generic class support
    let generic_classes: sv_map;     // qualified name -> namespace_decl* (i8*)

    // All istruc declarations: istruc name -> namespace_decl* (i8*)
    // Used to look up field defaults when constructing an istruc.
    let istruc_decls: sv_map;

    // ADT enum support: enum name -> enum_decl* (i8*)
    let adt_enum_decls: sv_map;

    let had_error: bool;  // set to true on any compile error; main checks before emitting

    // Pointer depth of the current LHS variable declaration when visiting an
    // initializer expression. Used by the ref_expr handler to build the correct
    // number of indirection levels (depth 1 = &x, depth 2 = &&x, ...).
    let ref_target_depth: i32;

    // When non-null, ek_class_init uses this pre-allocated target alloca instead of
    // creating its own, preserving istruc field defaults already stored there.
    let class_init_alloca: *i8;

    // Namespace imports: `using ns_name;` adds the mangled prefix to this map.
    // key = mangled prefix (e.g. "std__NS_math__NS_"), val = "" (sentinel).
    let using_ns_map: sv_map;
    let using_ns_len: i32;  // length of using_ns_map (for fast empty check)

    // Counter for generating unique names for static local globals
    let static_local_count: i32;

    // Match-as-expression result slot (non-null when inside a match expression)
    let match_result_slot: *i8;
    let match_result_type: *i8;
}

// Allocate and initialize an ir_context.
fn make_ir_context(module_name: *i8) *ir_context {
    let mut ctx: *ir_context= (ir_context*)arc_malloc(sizeof(ir__NS_ir_context));
    memset((i8*)ctx, 0, sizeof(ir__NS_ir_context));

    ctx.llvm_ctx     = LLVMContextCreate();
    ctx.llvm_mod     = LLVMModuleCreateWithNameInContext(module_name, ctx.llvm_ctx);
    ctx.llvm_builder = LLVMCreateBuilderInContext(ctx.llvm_ctx);

    sv_map_init(&ctx.global_funcs);
    st_map_init(&ctx.global_func_types);
    sb_map_init(&ctx.global_func_ret_unsigned);
    sv_map_init(&ctx.global_func_decls);
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
    sv_map_init(&ctx.anytype_funcs);
    st_map_init(&ctx.anytype_param_bindings);
    ctx.in_anytype_mono = false;
    sv_map_init(&ctx.generic_classes);
    sv_map_init(&ctx.istruc_decls);
    sv_map_init(&ctx.adt_enum_decls);
    sv_map_init(&ctx.memstr_vtables);
    st_map_init(&ctx.iface_vtable_types);
    sv_map_init(&ctx.iface_concrete_vtables);

    ctx.current_class_name  = (i8*)0;
    ctx.current_namespace   = (i8*)0;
    ctx.memstr_fat_type     = (i8*)0;
    ctx.memstr_vtable_type  = (i8*)0;
    sv_map_init(&ctx.using_ns_map);
    ctx.using_ns_len        = 0;
    ctx.had_error           = false;
    ctx.static_local_count  = 0;

    return ctx;
}

fn destroy_ir_context(ctx: *ir_context) void {
    if (ctx == (ir_context*)0) { return; }
    if (ctx.llvm_builder != (i8*)0) { LLVMDisposeBuilder(ctx.llvm_builder); }
    if (ctx.llvm_mod     != (i8*)0) { LLVMDisposeModule(ctx.llvm_mod); }
    if (ctx.llvm_ctx     != (i8*)0) { LLVMContextDispose(ctx.llvm_ctx); }
    arc_free((i8*)ctx);
}

// ---- Scope helpers ----

fn ctx_push_scope(ctx: *ir_context) void {
    let mut f: ir_scope_frame;
    sv_map_init(&f.alloca_ptrs);
    st_map_init(&f.alloca_types);
    st_map_init(&f.deref_types);
    sb_map_init(&f.alloca_unsigned);
    sb_map_init(&f.alloca_volatile);
    st_map_init(&f.local_func_types);
    sv_map_init(&f.local_func_depths);
    sb_map_init(&f.alloca_ptr_data_const);
    sv_map_init(&f.alloca_var_depths);
    st_map_init(&f.alloca_base_types);
    scope_frame_vec_push(&ctx.scopes, f);
}

fn ctx_pop_scope(ctx: *ir_context) void {
    if (ctx.scopes.len > 0) {
        ctx.scopes.len = ctx.scopes.len - 1;
    }
}

fn ctx_declare_local(ctx: *ir_context, name: *i8, alloca_ptr: *i8, elem_type: *i8, deref_type: *i8, is_unsigned: bool) void {
    if (ctx.scopes.len == 0) { ctx_push_scope(ctx); }
    let mut idx: i32= ctx.scopes.len - 1;
    sv_map_set(&ctx.scopes.data[idx].alloca_ptrs,     name, alloca_ptr);
    st_map_set(&ctx.scopes.data[idx].alloca_types,    name, elem_type);
    if (deref_type != (i8*)0) {
        st_map_set(&ctx.scopes.data[idx].deref_types, name, deref_type);
    }
    if (is_unsigned) {
        sb_map_set(&ctx.scopes.data[idx].alloca_unsigned, name, true);
    }
}

fn ctx_declare_local_volatile(ctx: *ir_context, name: *i8, alloca_ptr: *i8, elem_type: *i8, deref_type: *i8, is_unsigned: bool) void {
    ctx_declare_local(ctx, name, alloca_ptr, elem_type, deref_type, is_unsigned);
    let mut idx: i32= ctx.scopes.len - 1;
    sb_map_set(&ctx.scopes.data[idx].alloca_volatile, name, true);
}

fn ctx_is_local_volatile(ctx: *ir_context, name: *i8) bool {
    let mut i: i32= ctx.scopes.len - 1;
    while (i >= 0) {
        if (sb_map_get(&ctx.scopes.data[i].alloca_volatile, name)) { return true; }
        i = i - 1;
    }
    return false;
}

fn ctx_mark_local_const_ptr(ctx: *ir_context, name: *i8) void {
    if (ctx.scopes.len == 0) { return; }
    let mut idx: i32= ctx.scopes.len - 1;
    sb_map_set(&ctx.scopes.data[idx].alloca_ptr_data_const, name, true);
}

fn ctx_is_local_const_ptr(ctx: *ir_context, name: *i8) bool {
    let mut i: i32= ctx.scopes.len - 1;
    while (i >= 0) {
        if (sb_map_get(&ctx.scopes.data[i].alloca_ptr_data_const, name)) { return true; }
        i = i - 1;
    }
    return false;
}

fn ctx_lookup_local(ctx: *ir_context, name: *i8) *i8 {
    let mut i: i32= ctx.scopes.len - 1;
    while (i >= 0) {
        let mut v: *i8= sv_map_get(&ctx.scopes.data[i].alloca_ptrs, name);
        if (v != (i8*)0) { return v; }
        i = i - 1;
    }
    return (i8*)0;
}

fn ctx_lookup_local_type(ctx: *ir_context, name: *i8) *i8 {
    let mut i: i32= ctx.scopes.len - 1;
    while (i >= 0) {
        let mut v: *i8= st_map_get(&ctx.scopes.data[i].alloca_types, name);
        if (v != (i8*)0) { return v; }
        i = i - 1;
    }
    return (i8*)0;
}

fn ctx_lookup_deref_type(ctx: *ir_context, name: *i8) *i8 {
    let mut i: i32= ctx.scopes.len - 1;
    while (i >= 0) {
        let mut v: *i8= st_map_get(&ctx.scopes.data[i].deref_types, name);
        if (v != (i8*)0) { return v; }
        i = i - 1;
    }
    return (i8*)0;
}

fn ctx_declare_local_func_type(ctx: *ir_context, name: *i8, fn_type: *i8) void {
    if (ctx.scopes.len == 0) { ctx_push_scope(ctx); }
    let mut idx: i32= ctx.scopes.len - 1;
    st_map_set(&ctx.scopes.data[idx].local_func_types, name, fn_type);
}

fn ctx_lookup_local_func_type(ctx: *ir_context, name: *i8) *i8 {
    let mut i: i32= ctx.scopes.len - 1;
    while (i >= 0) {
        let mut v: *i8= st_map_get(&ctx.scopes.data[i].local_func_types, name);
        if (v != (i8*)0) { return v; }
        i = i - 1;
    }
    return (i8*)0;
}

fn ctx_declare_local_func_depth(ctx: *ir_context, name: *i8, depth: i32) void {
    if (ctx.scopes.len == 0) { ctx_push_scope(ctx); }
    let mut idx: i32= ctx.scopes.len - 1;
    let mut buf: [16]i8;
    snprintf(buf, (u64)16, "%d", depth);
    sv_map_set(&ctx.scopes.data[idx].local_func_depths, name, lexer.str_dup(buf));
}

fn ctx_lookup_local_func_depth(ctx: *ir_context, name: *i8) i32 {
    let mut i: i32= ctx.scopes.len - 1;
    while (i >= 0) {
        let mut v: *i8= sv_map_get(&ctx.scopes.data[i].local_func_depths, name);
        if (v != (i8*)0) { return atoi(v); }
        i = i - 1;
    }
    return 1;
}

fn ctx_lookup_local_unsigned(ctx: *ir_context, name: *i8) bool {
    let mut i: i32= ctx.scopes.len - 1;
    while (i >= 0) {
        let mut v: bool= sb_map_get(&ctx.scopes.data[i].alloca_unsigned, name);
        if (v) { return true; }
        i = i - 1;
    }
    return false;
}

fn ctx_declare_local_var_depth(ctx: *ir_context, name: *i8, depth: i32) void {
    if (ctx.scopes.len == 0) { ctx_push_scope(ctx); }
    let mut idx: i32= ctx.scopes.len - 1;
    let mut buf: [16]i8;
    snprintf(buf, (u64)16, "%d", depth);
    sv_map_set(&ctx.scopes.data[idx].alloca_var_depths, name, lexer.str_dup(buf));
}

fn ctx_lookup_local_var_depth(ctx: *ir_context, name: *i8) i32 {
    let mut i: i32= ctx.scopes.len - 1;
    while (i >= 0) {
        let mut v: *i8= sv_map_get(&ctx.scopes.data[i].alloca_var_depths, name);
        if (v != (i8*)0) { return atoi(v); }
        i = i - 1;
    }
    return -1;
}

fn ctx_declare_local_base_type(ctx: *ir_context, name: *i8, base_ty: *i8) void {
    if (ctx.scopes.len == 0) { ctx_push_scope(ctx); }
    let mut idx: i32= ctx.scopes.len - 1;
    st_map_set(&ctx.scopes.data[idx].alloca_base_types, name, base_ty);
}

fn ctx_lookup_local_base_type(ctx: *ir_context, name: *i8) *i8 {
    let mut i: i32= ctx.scopes.len - 1;
    while (i >= 0) {
        let mut v: *i8= st_map_get(&ctx.scopes.data[i].alloca_base_types, name);
        if (v != (i8*)0) { return v; }
        i = i - 1;
    }
    return (i8*)0;
}

// ---- Loop helpers ----

fn ctx_push_loop(ctx: *ir_context, break_bb: *i8, continue_bb: *i8) void {
    let mut info: ir_loop_info;
    info.break_block    = break_bb;
    info.continue_block = continue_bb;
    loop_stack_push(&ctx.loops, info);
}

fn ctx_pop_loop(ctx: *ir_context) void {
    if (ctx.loops.len > 0) {
        ctx.loops.len = ctx.loops.len - 1;
    }
}

fn ctx_current_break(ctx: *ir_context) *i8 {
    if (ctx.loops.len == 0) { return (i8*)0; }
    return ctx.loops.data[ctx.loops.len - 1].break_block;
}

fn ctx_current_continue(ctx: *ir_context) *i8 {
    if (ctx.loops.len == 0) { return (i8*)0; }
    return ctx.loops.data[ctx.loops.len - 1].continue_block;
}

// ---- Using-namespace helpers ----

// Convert dotted namespace name "a.b.c" to mangled prefix "a__NS_b__NS_c__NS_".
fn ns_name_to_prefix(ns_name: *i8) *i8 {
    if (ns_name == (i8*)0) { return (i8*)0; }
    let mut tmp: [512]i8; tmp[0] = 0; let mut ti: i32= 0;
    let mut i: i32= 0;
    while (ns_name[i] != 0 && ti < 500) {
        if (ns_name[i] == '.') {
            if (ti + 5 < 511) {
                tmp[ti] = '_'; ti = ti + 1;
                tmp[ti] = '_'; ti = ti + 1;
                tmp[ti] = 'N'; ti = ti + 1;
                tmp[ti] = 'S'; ti = ti + 1;
                tmp[ti] = '_'; ti = ti + 1;
            }
        } else {
            tmp[ti] = ns_name[i]; ti = ti + 1;
        }
        i = i + 1;
    }
    if (ti + 5 < 511) {
        tmp[ti] = '_'; ti = ti + 1;
        tmp[ti] = '_'; ti = ti + 1;
        tmp[ti] = 'N'; ti = ti + 1;
        tmp[ti] = 'S'; ti = ti + 1;
        tmp[ti] = '_'; ti = ti + 1;
    }
    tmp[ti] = 0;
    return lexer.str_dup(tmp);
}

// Store prefix in using_ns_map (key=prefix, val="").
fn ctx_add_using_ns(ctx: *ir_context, ns_name: *i8) void {
    if (ns_name == (i8*)0) { return; }
    let mut prefix: *i8= ns_name_to_prefix(ns_name);
    if (prefix == (i8*)0) { return; }
    sv_map_set(&ctx.using_ns_map, prefix, "");
    ctx.using_ns_len = ctx.using_ns_len + 1;
}

// Resolve name in global_funcs, falling back to each using-ns prefix.
fn ctx_resolve_func(ctx: *ir_context, name: *i8) *i8 {
    let mut v: *i8= sv_map_get(&ctx.global_funcs, name);
    if (v != (i8*)0) { return v; }
    if (ctx.using_ns_len == 0) { return (i8*)0; }
    let mut ubuf: [512]i8;
    let mut ui: i32= 0;
    while (ui < ctx.using_ns_map.len) {
        snprintf(ubuf, (u64)512, "%s%s", ctx.using_ns_map.data[ui].key, name);
        v = sv_map_get(&ctx.global_funcs, ubuf);
        if (v != (i8*)0) { return v; }
        ui = ui + 1;
    }
    return (i8*)0;
}

// Resolve name in global_vars, falling back to each using-ns prefix.
fn ctx_resolve_var(ctx: *ir_context, name: *i8) *i8 {
    let mut v: *i8= sv_map_get(&ctx.global_vars, name);
    if (v != (i8*)0) { return v; }
    if (ctx.using_ns_len == 0) { return (i8*)0; }
    let mut ubuf: [512]i8;
    let mut ui: i32= 0;
    while (ui < ctx.using_ns_map.len) {
        snprintf(ubuf, (u64)512, "%s%s", ctx.using_ns_map.data[ui].key, name);
        v = sv_map_get(&ctx.global_vars, ubuf);
        if (v != (i8*)0) { return v; }
        ui = ui + 1;
    }
    return (i8*)0;
}

// ---- Terminator check ----

fn ctx_is_terminated(ctx: *ir_context) bool {
    let mut bb: *i8= LLVMGetInsertBlock(ctx.llvm_builder);
    if (bb == (i8*)0) { return false; }
    return LLVMGetBasicBlockTerminator(bb) != (i8*)0;
}

// ---- Defer helpers ----

fn ctx_push_defer_scope(ctx: *ir_context) void {
    defer_stack_push_scope(&ctx.defers);
}

fn ctx_push_errdefer_scope(ctx: *ir_context) void {
    defer_stack_push_scope(&ctx.errdefers);
}

fn ctx_add_defer(ctx: *ir_context, ptr: *i8, is_block: bool) void {
    if (ctx.defers.len == 0) { return; }
    let mut di: defer_item;
    di.ptr      = ptr;
    di.is_block = is_block;
    defer_scope_push(&ctx.defers.data[ctx.defers.len - 1], di);
}

fn ctx_add_errdefer(ctx: *ir_context, ptr: *i8, is_block: bool) void {
    if (ctx.errdefers.len == 0) { return; }
    let mut di: defer_item;
    di.ptr      = ptr;
    di.is_block = is_block;
    defer_scope_push(&ctx.errdefers.data[ctx.errdefers.len - 1], di);
}

fn ctx_pop_errdefer_scope(ctx: *ir_context) void {
    if (ctx.errdefers.len > 0) {
        ctx.errdefers.len = ctx.errdefers.len - 1;
    }
}

fn ctx_pop_errdefer_scope_get(ctx: *ir_context) defer_scope {
    let mut empty: defer_scope;
    defer_scope_init(&empty);
    if (ctx.errdefers.len == 0) { return empty; }
    let mut s: defer_scope= ctx.errdefers.data[ctx.errdefers.len - 1];
    ctx.errdefers.len = ctx.errdefers.len - 1;
    return s;
}

// Pop and return the defer scope (caller emits in reverse order).
fn ctx_pop_defer_scope(ctx: *ir_context) defer_scope {
    let mut empty: defer_scope;
    defer_scope_init(&empty);
    if (ctx.defers.len == 0) { return empty; }
    let mut s: defer_scope= ctx.defers.data[ctx.defers.len - 1];
    ctx.defers.len = ctx.defers.len - 1;
    return s;
}

// ---- Field index lookup ----

fn ctx_field_index(ctx: *ir_context, struct_name: *i8, field_name: *i8) i32 {
    let mut m: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, struct_name);
    if (m == (struct_meta*)0) { return -1; }
    let mut i: i32= 0;
    while (i < m.field_names.len) {
        if (strcmp(m.field_names.data[i], field_name) == 0) {
            return i;
        }
        i = i + 1;
    }
    return -1;
}

fn ctx_field_type(ctx: *ir_context, struct_name: *i8, idx: i32) *i8 {
    let mut m: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, struct_name);
    if (m == (struct_meta*)0) { return (i8*)0; }
    if (idx < 0 || idx >= m.field_types.len) { return (i8*)0; }
    return m.field_types.data[idx];
}

fn ctx_field_unsigned(ctx: *ir_context, struct_name: *i8, field_name: *i8) bool {
    let mut m: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, struct_name);
    if (m == (struct_meta*)0) { return false; }
    let mut i: i32= 0;
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
