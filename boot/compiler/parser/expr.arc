// Expression and type AST node definitions for the Artemis self-hosting compiler.

namespace parser {

// ---- Primitive type enumeration ----
enum prim_type_t {
    char_t    = 0,
    arb_int   = 1,
    arb_uint  = 2,
    arb_float = 3,
    arb_bool  = 4,
    void_t    = 5,
}

// ---- Type node ----
struct type_node {
    bool is_primitive;
    bool is_const;
    bool is_signed;
    bool is_extern;
    bool is_inline;
    bool is_register;
    bool is_extern_c;
    bool has_prim;
    i32  prim;          // prim_type_t value
    i8*  name;          // user-defined type name (null for primitives)
    i32  pointer_depth;
    // array_size: if non-null, this is an array type
    // We use a forward-declared pointer - defined later
    i8*  array_size_ptr;   // actually expr_node* but using i8* for forward ref
    // type_args for generics
    i8** type_args;         // actually type_node**
    i32  type_args_len;
    // function pointer
    bool is_func_ptr;
    i8*  fp_ret;            // actually type_node*
    i8** fp_params;         // actually type_node**
    i32  fp_params_len;
    i8** fp_param_names;    // i8** (string array)
    i32  fp_param_names_len;
    bool fp_variadic;
    // misc flags
    bool is_self_ref;
    bool is_self_ref_const;
    bool is_self_type;
    bool ptr_data_const;
    bool is_memstr_ref;
    bool is_auto;
    bool is_nullable;
    bool is_null_literal;
    bool is_sta;
    u32  bit_width;
}

type_node* alloc_type_node() {
    type_node* t = (type_node*)malloc(sizeof(parser__NS_type_node));
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
    ek_get_ifo_t_e  = 13,
    ek_assign       = 14,
    ek_ternary      = 15,
    ek_annotation   = 16,
    ek_class_init   = 17,
    ek_error_lit    = 18,
    ek_try_expr     = 19,
    ek_except_expr  = 20,
    ek_null_lit     = 21,
    ek_null_coal    = 22,
    ek_import_expr  = 23,
    ek_sta_type_expr= 24,
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
    i32  kind;          // expr_kind value
    u64  line;

    // literals
    i8*  str_val;
    i64  int_val;
    f64  flt_val;
    bool bool_val;

    // unary
    i32        uop;
    expr_node* operand;

    // binary / assign
    i32        bop;
    expr_node* lhs;
    expr_node* rhs;

    // call
    expr_node*  callee;
    expr_node** args;
    i32         args_len;
    i8*         func_resolved_name;

    // subscript / member
    expr_node*  object;
    expr_node*  index;
    i8*         member_name;

    // cast / sizeof
    type_node*  cast_type;

    // ternary
    expr_node*  cond;
    expr_node*  then_e;
    expr_node*  else_e;

    // class_init
    type_node*  init_type;
    i8**        field_names;
    expr_node** field_vals;
    i32         field_count;
    bool        is_implicit_init;

    // generic type args for calls
    type_node** type_args;
    i32         type_args_len;

    bool is_constexpr;

    // except handler block
    i8*  handler_block;  // actually block_stmt*
}

expr_node* alloc_expr_node() {
    expr_node* e = (expr_node*)malloc(sizeof(parser__NS_expr_node));
    memset((i8*)e, 0, sizeof(parser__NS_expr_node));
    return e;
}

// Dynamic array of expr_node pointers
struct expr_ptr_vec {
    expr_node** data;
    i32         len;
    i32         cap;
}

void expr_ptr_vec_init(expr_ptr_vec* v) {
    v.data = (expr_node**)0;
    v.len  = 0;
    v.cap  = 0;
}

void expr_ptr_vec_push(expr_ptr_vec* v, expr_node* e) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 8 : v.cap * 2;
        v.data = (expr_node**)realloc((i8*)v.data, (u64)(nc * (i32)sizeof(i8*)));
        v.cap  = nc;
    }
    v.data[v.len] = e;
    v.len = v.len + 1;
}

// Dynamic array of type_node pointers
struct type_ptr_vec {
    type_node** data;
    i32         len;
    i32         cap;
}

void type_ptr_vec_init(type_ptr_vec* v) {
    v.data = (type_node**)0;
    v.len  = 0;
    v.cap  = 0;
}

void type_ptr_vec_push(type_ptr_vec* v, type_node* t) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 8 : v.cap * 2;
        v.data = (type_node**)realloc((i8*)v.data, (u64)(nc * (i32)sizeof(i8*)));
        v.cap  = nc;
    }
    v.data[v.len] = t;
    v.len = v.len + 1;
}

// Dynamic array of strings
struct str_vec {
    i8** data;
    i32  len;
    i32  cap;
}

void str_vec_init(str_vec* v) {
    v.data = (i8**)0;
    v.len  = 0;
    v.cap  = 0;
}

void str_vec_push(str_vec* v, i8* s) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 8 : v.cap * 2;
        v.data = (i8**)realloc((i8*)v.data, (u64)(nc * (i32)sizeof(i8*)));
        v.cap  = nc;
    }
    v.data[v.len] = s;
    v.len = v.len + 1;
}

} // namespace parser
