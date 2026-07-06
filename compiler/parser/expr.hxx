#pragma once
#include <string>
#include <vector>
#include <cstdint>
#include <optional>

// Forward declarations
struct expr_node;
struct type_node;
struct func_decl; // needed for resolved_overload in expr_node
struct block_stmt; // needed for except_expr handler block

// ---------- Type representation ----------

enum class prim_type_t {
    char_t,     // char — i8 alias (string / character type)
    arb_int,    // iN  — signed integer of N bits
    arb_uint,   // uN  — unsigned integer of N bits
    arb_float,  // fN  — floating-point of N bits
    arb_bool,   // bN  — boolean integer of N bits
    void_t,
};

struct type_node {
    bool is_primitive = false;
    bool is_const     = false;
    bool is_signed    = true;  // only meaningful for integer prims
    bool is_extern    = false;
    bool is_inline    = false;
    bool is_register  = false;
    bool is_extern_c  = false; // extern "C" linkage (no name mangling)
    std::optional<prim_type_t>  prim;
    std::optional<std::string>  name; // custom / struct / enum / union
    int  pointer_depth = 0;           // number of * decorators
    std::optional<expr_node*>   array_size; // non-null => array type
    std::vector<type_node*>     type_args;  // generic instantiation args: q<int>


    // Function pointer: returntype(params)* varname
    bool                          is_func_ptr  = false;
    type_node*                    fp_ret       = nullptr; // return type
    std::vector<type_node*>       fp_params;              // parameter types
    std::vector<std::string>      fp_param_names;         // parameter names (optional)
    bool                          fp_variadic  = false;

    // Self reference (&self / &const self) — legacy, kept for IR compat during migration
    bool is_self_ref       = false;
    bool is_self_ref_const = false;

    // 'self' or 'this' used as a type keyword inside a method param list (alias for class type)
    bool is_self_type = false;

    // *const after stars: data pointed to is immutable (new Artemis semantics)
    bool ptr_data_const = false;

    // Memstr reference (&memstr name) in function parameters
    bool is_memstr_ref = false;

    // auto placeholder (trailing-type form: the real type is filled in later)
    bool is_auto = false;

    // Nullable wrapper: ?T — the value may be null
    bool is_nullable = false;

    // Marker set on the synthesized type returned by the null literal expression.
    // Allows assignable() to accept null→pointer and null→?T while rejecting null→plain-prim.
    bool is_null_literal = false;

    // sta: this type is the comptime type-value type (Zig's `type`).
    // Variables of sta type hold types or namespaces at comptime; no runtime representation.
    bool is_sta = false;

    // For arb_int / arb_uint / arb_float / arb_bool: the N in iN/uN/fN/bN.
    uint32_t bit_width = 0;
};

// ---------- Expressions ----------

enum class expr_kind {
    int_lit,
    float_lit,
    string_lit,
    char_lit,
    bool_lit,
    identifier,
    unary,
    binary,
    call,
    subscript,  // a[i]
    member,     // a.b
    cast,       // (type)expr
    sizeof_e,   // sizeof(type) or sizeof(expr)
    get_ifo_t_e,// get_ifo_t(Type) — compile-time type info
    assign,
    ternary,    // cond ? then : else
    annotation, // @identifier
    class_init, // TypeName { .field = val, ... } or .{ .field = val }
    error_lit,  // error.Name — error tag literal (i32)
    try_expr,   // try expr — propagate error; operand is the inner expression
    except_expr,// expr except |name| block — catch error; object=expr, str_val=name, rhs=nil, then_e=handler_block_as_expr
    null_lit,   // null keyword — null pointer constant; assignable to any pointer or ?T
    null_coal,  // lhs ?? rhs — yield lhs if non-null/non-zero, else evaluate rhs or handler_block
    import_expr,// @import("path") — module import; str_val=path, resolved to namespace at comptime
    sta_type_expr, // sta used as a value (e.g. return i32 from a sta-returning function)
};

enum class unary_op  { neg, pos, bit_not, log_not, pre_inc, pre_dec, post_inc, post_dec, deref, addr_of };
enum class binary_op { add, sub, mul, div, mod, eq, ne, lt, gt, lte, gte,
                       log_and, log_or, bit_and, bit_or, bit_xor,
                       shl, shr,
                       assign, add_assign, sub_assign, mul_assign,
                       div_assign, mod_assign,
                       and_assign, or_assign, xor_assign, shl_assign, shr_assign };

struct expr_node {
    expr_kind kind;
    uint64_t  line = 0;

    // literals
    std::string                 str_val;   // string / char lit or identifier name
    int64_t                     int_val  = 0;
    double                      flt_val  = 0.0;
    bool                        bool_val = false;

    // unary
    unary_op                    uop{};
    expr_node*                  operand  = nullptr;

    // binary / assign
    binary_op                   bop{};
    expr_node*                  lhs      = nullptr;
    expr_node*                  rhs      = nullptr;

    // call
    expr_node*                  callee   = nullptr;
    std::vector<expr_node*>     args;
    func_decl*                  resolved_overload = nullptr; // set by analyzer for overload resolution

    // subscript / member
    expr_node*                  object   = nullptr;
    expr_node*                  index    = nullptr;
    std::string                 member_name;

    // cast / sizeof
    type_node*                  cast_type = nullptr;

    // ternary
    expr_node*                  cond     = nullptr;
    expr_node*                  then_e   = nullptr;
    expr_node*                  else_e   = nullptr;

    // class_init: TypeName { .field = val, ... }
    type_node*                                          init_type        = nullptr; // null => infer from context (.{...})
    std::vector<std::pair<std::string, expr_node*>>     field_inits;               // named field initializers
    bool                                                is_implicit_init = false;  // true if used in copy-init (= expr) context

    // call: explicit generic type arguments  f<T>(...)
    std::vector<type_node*>     type_args;
    // constexpr marker (for constexpr-evaluated expressions, informational)
    bool                        is_constexpr = false;

    // except_expr: the catch handler block (block_stmt*)
    block_stmt*                 handler_block = nullptr;
};
