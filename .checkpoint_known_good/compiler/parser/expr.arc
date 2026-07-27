// Expression and type AST node definitions for the Artemis self-hosting compiler.

namespace parser {

// ---- Primitive type enumeration ----
enum prim_type_t {
    char_t       = 0,
    arb_int      = 1,
    arb_uint     = 2,
    arb_float    = 3,
    arb_bool     = 4,
    void_t       = 5,
    arb_rational = 6,   // qN  — rational number { iN num; iN den; }
    arb_complex  = 7,   // cN  — complex number  { fN re;  fN im; }
    arb_char_w   = 8,   // chN — N-bit character (unsigned)
    arb_str_w    = 9,   // strN — string of N-bit chars
    arb_nat      = 10,  // nN  — natural number ≥0 (distinct unsigned int)
    arb_zint     = 11,  // zN  — integer ring ℤ (distinct signed int)
    arb_real     = 12,  // rN  — real number ℝ (distinct float)
    arb_alg      = 13,  // aN  — algebraic number (always f64 at runtime) (ptr to chN)
    arb_usize    = 14,  // usize — pointer-sized unsigned integer (u64 on x64)
    arb_isize    = 15,  // isize — pointer-sized signed integer (i64 on x64)
    arb_iofs     = 16,  // iofs  — signed offset type (i65 on x64 = arch_bits + 1)
}

// ---- Type node ----
struct type_node {
    let is_primitive: bool;
    let is_const: bool;
    let is_volatile: bool;
    let is_signed: bool;
    let is_extern: bool;
    let is_inline: bool;
    let is_extern_c: bool;
    let has_prim: bool;
    let prim: i32;          // prim_type_t value
    let name: *i8;          // user-defined type name (null for primitives)
    let pointer_depth: i32;
    // array_size: if non-null, this is an array type
    // We use a forward-declared pointer - defined later
    let array_size_ptr: *i8;   // actually expr_node* but using i8* for forward ref
    // type_args for generics
    let type_args: **i8;         // actually type_node**
    let type_args_len: i32;
    // function pointer
    let is_func_ptr: bool;
    let fp_ret: *i8;            // actually type_node*
    let fp_params: **i8;         // actually type_node**
    let fp_params_len: i32;
    let fp_param_names: **i8;    // i8** (string array)
    let fp_param_names_len: i32;
    let fp_variadic: bool;
    // misc flags
    let is_self_ref: bool;
    let is_self_ref_const: bool;
    let is_self_type: bool;
    let ptr_data_const: bool;
    let is_memstr_ref: bool;
    let is_auto: bool;
    let is_nullable: bool;
    let is_null_literal: bool;
    let is_sta: bool;
    let is_static_kw: bool;  // `static` qualifier in type position: `let x: static T`
    let is_interface: bool;  // `interface NAME` parameter type — fat pointer dispatch
    let bit_width: u32;
    let is_anytype: bool;  // `anytype` — accept any type (generic parameter)
    let is_typeof: bool;   // `@typeof(expr)` used as a type — inferred from expr type
    let typeof_expr: *i8;  // expr_node* for @typeof in type position
    let is_error_union: bool;  // `!T` error union type prefix
}

fn alloc_type_node() *type_node {
    let mut t: *type_node= (type_node*)arc_malloc(sizeof(parser__NS_type_node));
    memset((i8*)t, 0, sizeof(parser__NS_type_node));
    t.is_signed = true;
    return t;
}

// ---- Expression kind enumeration ----
enum expr_kind {
    ek_int_lit      = 0,
    ek_float_lit    = 1,
    ek_string_lit   = 2,
    ek_char_lit     = 3,
    ek_bool_lit     = 4,
    ek_identifier   = 5,
    ek_unary        = 6,
    ek_binary       = 7,
    ek_call         = 8,
    ek_subscript    = 9,
    ek_member       = 10,
    ek_cast         = 11,
    ek_sizeof_e     = 12,
    ek_typeinfo_e   = 13,
    ek_assign       = 14,
    ek_ternary      = 15,
    ek_annotation   = 16,
    ek_class_init   = 17,
    ek_error_lit    = 18,
    ek_try_expr     = 19,
    ek_except_expr  = 20,
    ek_null_lit     = 21,
    ek_null_coal    = 22,
    // 23 was ek_import_expr and 24 ek_sta_type_expr — both from an earlier design
    // where @import and `type` variables were expressions. Neither is produced by the
    // parser: @import splices at declaration level and type variables are resolved in
    // type position. The values stay unused so later discriminants keep their numbers.
    ek_ref_expr     = 25,  // ref T — context-aware address-of
    ek_shcopy       = 26,  // @shcopy(x) — explicit shallow copy
    ek_decopy       = 27,  // @decopy(x) — deep copy
    ek_move_expr    = 28,  // @move(x)   — move (transfer ownership)
    ek_quote        = 29,  // quote{} — tokenstream literal for proc macros
    ek_lambda       = 30,  // [captures](params) RetType { body }
    ek_cast_as      = 31,  // expr as Type — safe explicit type conversion
    ek_match_expr   = 32,  // match(v) { ... } used as an expression
    ek_range        = 33,  // lo..hi or lo..=hi — integer range literal
    ek_cstype       = 34,  // @cstype(T) — first-class type value
    ek_self_builtin = 35,  // @self()    — ptr to enclosing container
    ek_ifield       = 36,  // @ifield()  — metadata of enclosing container
    ek_typeof_e     = 37,  // @typeof(x) — comptime type of expression
    ek_anon_struct  = 38,  // .{ .f=v }  — anonymous struct literal
}

// ---- Unary operator enumeration ----
enum unary_op {
    uop_neg      = 0,
    uop_pos      = 1,
    uop_bit_not  = 2,
    uop_log_not  = 3,
    uop_pre_inc  = 4,
    uop_pre_dec  = 5,
    uop_post_inc = 6,
    uop_post_dec = 7,
    uop_deref    = 8,
    uop_addr_of  = 9,
}

// ---- Binary operator enumeration ----
enum binary_op {
    bop_add        = 0,
    bop_sub        = 1,
    bop_mul        = 2,
    bop_div        = 3,
    bop_mod        = 4,
    bop_eq         = 5,
    bop_ne         = 6,
    bop_lt         = 7,
    bop_gt         = 8,
    bop_lte        = 9,
    bop_gte        = 10,
    bop_log_and    = 11,
    bop_log_or     = 12,
    bop_bit_and    = 13,
    bop_bit_or     = 14,
    bop_bit_xor    = 15,
    bop_shl        = 16,
    bop_shr        = 17,
    bop_assign     = 18,
    bop_add_assign = 19,
    bop_sub_assign = 20,
    bop_mul_assign = 21,
    bop_div_assign = 22,
    bop_mod_assign = 23,
    bop_and_assign = 24,
    bop_or_assign  = 25,
    bop_xor_assign = 26,
    bop_shl_assign = 27,
    bop_shr_assign = 28,
}

// ---- Expression node ----
struct expr_node {
    let kind: i32;          // expr_kind value
    let line: u64;

    // literals
    let str_val: *i8;
    let int_val: i64;
    let flt_val: f64;
    let bool_val: bool;

    // unary
    let uop: i32;
    let operand: *expr_node;

    // binary / assign
    let bop: i32;
    let lhs: *expr_node;
    let rhs: *expr_node;

    // call
    let callee: *expr_node;
    let args: **expr_node;
    let args_len: i32;
    let func_resolved_name: *i8;

    // subscript / member
    let object: *expr_node;
    let index: *expr_node;
    let member_name: *i8;

    // cast / sizeof
    let cast_type: *type_node;

    // ternary
    let cond: *expr_node;
    let then_e: *expr_node;
    let else_e: *expr_node;

    // class_init
    let init_type: *type_node;
    let field_names: **i8;
    let field_vals: **expr_node;
    let field_count: i32;
    let is_implicit_init: bool;

    // generic type args for calls
    let type_args: **type_node;
    let type_args_len: i32;

    let is_constexpr: bool;

    // except handler block
    let handler_block: *i8;  // actually block_stmt*

    // SMT: set to true when the SMT cannot prove safety — IR emits a runtime null-guard
    let needs_rtcheck: bool;

    // lambda: ek_lambda
    let lambda_cap_names: **i8;   // captured variable names
    let lambda_cap_byref: *i32;   // 1 = captured by reference, 0 = by value
    let lambda_cap_len: i32;
    let lambda_param_types: **type_node;
    let lambda_param_names: **i8;
    let lambda_param_len: i32;
    let lambda_ret_type: *type_node;    // null = infer
    let lambda_body: *i8;        // actually block_stmt*
    let lambda_synth_name: *i8;  // generated function name in IR

    // ek_match_expr: match(...){} used as expression
    let match_stmt_ptr: *i8;    // actually match_stmt*
}

fn alloc_expr_node() *expr_node {
    let mut e: *expr_node= (expr_node*)arc_malloc(sizeof(parser__NS_expr_node));
    memset((i8*)e, 0, sizeof(parser__NS_expr_node));
    return e;
}

// Dynamic array of expr_node pointers
struct expr_ptr_vec {
    let data: **expr_node;
    let len: i32;
    let cap: i32;
}

fn expr_ptr_vec_init(v: *expr_ptr_vec) void {
    v.data = (expr_node**)0;
    v.len  = 0;
    v.cap  = 0;
}

fn expr_ptr_vec_push(v: *expr_ptr_vec, e: *expr_node) void {
    if (v.len >= v.cap) {
        let mut nc: i32= v.cap == 0 ? 8 : v.cap * 2;
        v.data = (expr_node**)arc_realloc((i8*)v.data, (u64)(nc * (i32)sizeof(i8*)));
        v.cap  = nc;
    }
    v.data[v.len] = e;
    v.len = v.len + 1;
}

// Dynamic array of type_node pointers
struct type_ptr_vec {
    let data: **type_node;
    let len: i32;
    let cap: i32;
}

fn type_ptr_vec_init(v: *type_ptr_vec) void {
    v.data = (type_node**)0;
    v.len  = 0;
    v.cap  = 0;
}

fn type_ptr_vec_push(v: *type_ptr_vec, t: *type_node) void {
    if (v.len >= v.cap) {
        let mut nc: i32= v.cap == 0 ? 8 : v.cap * 2;
        v.data = (type_node**)arc_realloc((i8*)v.data, (u64)(nc * (i32)sizeof(i8*)));
        v.cap  = nc;
    }
    v.data[v.len] = t;
    v.len = v.len + 1;
}

// Dynamic array of strings
struct str_vec {
    let data: **i8;
    let len: i32;
    let cap: i32;
}

fn str_vec_init(v: *str_vec) void {
    v.data = (i8**)0;
    v.len  = 0;
    v.cap  = 0;
}

fn str_vec_push(v: *str_vec, s: *i8) void {
    if (v.len >= v.cap) {
        let mut nc: i32= v.cap == 0 ? 8 : v.cap * 2;
        v.data = (i8**)arc_realloc((i8*)v.data, (u64)(nc * (i32)sizeof(i8*)));
        v.cap  = nc;
    }
    v.data[v.len] = s;
    v.len = v.len + 1;
}

} // namespace parser
