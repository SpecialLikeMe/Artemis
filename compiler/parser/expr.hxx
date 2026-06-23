#pragma once
#include <string>
#include <vector>
#include <cstdint>
#include <optional>

// Forward declarations
struct expr_node;
struct type_node;

// ---------- Type representation ----------

enum class prim_type_t {
    i8, i16, i32, i64, i128, i256, i512,
    u8, u16, u32, u64, u128, u256, u512,
    f8, f16, f32, f64, f128, f256, f512,
    boolean,
    b1, b8, b16, b32, b64, b128, b256, b512,
    void_t,
};

struct type_node {
    bool is_primitive = false;
    bool is_const     = false;
    bool is_signed    = true;  // only meaningful for integer prims
    bool is_extern    = false;
    bool is_inline    = false;
    bool is_register  = false;
    std::optional<prim_type_t>  prim;
    std::optional<std::string>  name; // custom / struct / enum / union
    int  pointer_depth = 0;           // number of * decorators
    std::optional<expr_node*>   array_size; // non-null => array type
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
    assign,
    ternary,    // cond ? then : else
    annotation, // @identifier
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
};
