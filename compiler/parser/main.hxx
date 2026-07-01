#pragma once
#include <vector>
#include <string>
#include <iostream>
#include <stdexcept>
#include <cstdint>
#include <optional>
#include <variant>
#include <memory>
#include "expr.hxx"
#include "../lexer/main.hxx"

// ============================================================
// AST statement/declaration nodes
// ============================================================

struct ast_node {
    virtual ~ast_node() = default;
    uint64_t line = 0;
};

// ---- statements ----

struct block_stmt : ast_node {
    std::vector<ast_node*> stmts;
};

struct expr_stmt : ast_node {
    expr_node* expr = nullptr;
};

struct return_stmt : ast_node {
    std::optional<expr_node*> value;
};

struct break_stmt    : ast_node {};
struct continue_stmt : ast_node {};

// One operand in an inline asm constraint section.
struct asm_constraint_entry {
    std::string modifier; // e.g. "r", "m", "i"  (leading "=" stripped for outputs)
    std::string varname;  // variable name in current scope
};

// Inline assembly statement: __asm__ { <instructions> : <inputs> : <outputs> : <clobbers> }
struct asm_stmt : ast_node {
    std::string raw_instructions;                      // instruction text with %name / *N refs
    std::vector<asm_constraint_entry> inputs;          // first  ':' section
    std::vector<asm_constraint_entry> outputs;         // second ':' section
    std::vector<std::string>          clobbers;        // third  ':' section; "cca" = auto
};

struct if_stmt : ast_node {
    expr_node*  cond      = nullptr;
    ast_node*   then_body = nullptr;
    ast_node*   else_body = nullptr; // optional
    bool        is_constexpr = false; // constexpr if / if constexpr
};

struct while_stmt : ast_node {
    expr_node* cond = nullptr;
    ast_node*  body = nullptr;
};

struct for_stmt : ast_node {
    ast_node*  init = nullptr; // decl or expr_stmt or null
    expr_node* cond = nullptr;
    expr_node* step = nullptr;
    ast_node*  body = nullptr;
};

struct switch_stmt : ast_node {
    expr_node*  subject = nullptr;
    std::vector<std::pair<std::optional<expr_node*>, block_stmt*>> cases; // nullopt = default
};

struct extern_std : ast_node {
    std::string module_name;
};

// ---- declarations ----

struct var_decl : ast_node {
    type_node*              type  = nullptr;
    std::string             name;
    std::optional<expr_node*> init;
    std::vector<expr_node*> ctor_args;          // implicit ctor: Type v(args...) / v{args...}
    bool                    ctor_brace = false; // true if {...} form was used
    bool                    has_ctor_parens = false; // true if () or {} present (even empty)
    bool                    is_constexpr = false;     // constexpr Type name = expr;
    bool                    is_consteval = false;     // consteval Type name; — user will call __construct__ manually
};

struct param_decl {
    type_node*  type = nullptr;
    std::string name;
    uint64_t    line = 0;
};

struct func_decl : ast_node {
    type_node*               ret_type    = nullptr;
    std::string              name;
    std::vector<param_decl>  params;
    bool                     is_variadic = false;
    block_stmt*              body        = nullptr; // null = forward decl
    bool                     is_extern_c = false;  // suppress name mangling
    std::string              mangled_name;          // set by analyzer; empty = use name
    bool                     is_overloaded = false; // set by analyzer
    bool                     is_noexcept = false;   // noexcept modifier (informational)
    std::vector<std::string> type_params;           // generic type parameters <T, U>
    // Error union: !T or E!T return type
    bool                     is_error_union = false; // function may return an error
    type_node*               err_type = nullptr;     // explicit error type E (null = inferred)
};

struct struct_decl : ast_node {
    std::string            name;
    std::vector<var_decl*> fields;
};

struct memstr_decl : ast_node {
    std::string            name;
    var_decl*              ptr_field  = nullptr; // .ptr field
    func_decl*             fn_mmap    = nullptr; // .vtable.mmap
    func_decl*             fn_rmap    = nullptr; // .vtable.rmap
    func_decl*             fn_deinit  = nullptr; // .vtable.deinit
};

// ---- try/except/throw ----
struct throw_stmt : ast_node {
    expr_node* value = nullptr;  // expression to throw (casted to i64 in IR)
};

struct try_stmt : ast_node {
    block_stmt* body      = nullptr;
    type_node*  exc_type  = nullptr;  // type in except (type e)
    std::string exc_name;             // variable name
    block_stmt* handler   = nullptr;
};

// ---- defer statement ----
struct defer_stmt : ast_node {
    expr_node*  expr = nullptr;  // defer expr;
    block_stmt* blk  = nullptr;  // defer { ... }
};

// ---- extern "C" block ----
struct extern_c_block : ast_node {
    std::vector<ast_node*> decls;
};

// ---- access modifier ----
enum class access_mod { pub, priv, prot };

// ---- class field (var_decl with access info) ----
struct class_field : ast_node {
    access_mod  access    = access_mod::pub;
    bool        is_static  = false;
    bool        is_virtual = false;
    type_node*  type       = nullptr;
    std::string name;
    std::optional<expr_node*> init;
};

// ---- initializer list entry ----
struct init_list_entry {
    std::string  member_name;
    expr_node*   value = nullptr;
};

// ---- class method ----
struct class_method : ast_node {
    access_mod  access              = access_mod::pub;
    bool        is_static           = false;
    bool        is_virtual          = false;
    bool        is_mandatory_virtual= false;
    bool        is_override         = false;
    bool        is_const_method     = false;
    bool        is_final            = false;
    bool        is_constructor      = false;
    bool        is_destructor       = false;
    bool        is_noexcept         = false;
    bool        is_explicit         = false;
    bool        is_conversion_op    = false;
    bool        is_operator_overload= false;
    std::string operator_str;     // e.g. "+", "-", "[]", etc.
    type_node*  conv_target_type = nullptr; // for conversion operators

    type_node*               ret_type   = nullptr;
    std::string              name;
    std::vector<param_decl>  params;   // explicit params (self param extracted separately)
    bool                     has_self        = false;
    bool                     self_const      = false;
    std::string              self_param_name = "self"; // name of the self param
    bool                     is_variadic= false;
    block_stmt*              body       = nullptr;

    std::vector<init_list_entry> init_list; // constructor init list

    // Mangled name set by analyzer (empty = use name)
    std::string mangled_name;
};

// ---- class declaration (istruc / memstr) ----
struct class_decl : ast_node {
    std::string                 name;
    std::string                 base_name;   // empty if no inheritance
    std::vector<class_field*>   fields;
    std::vector<class_method*>  methods;
    std::vector<func_decl*>     local_decls; // 'local' (friend-like) declarations

    // Mangled name set by analyzer for this class's vtable (if any virtual methods)
    bool has_virtual   = false;
    bool is_memstr     = false; // declared with `memstr` keyword (valid as &memstr)
    bool is_interface  = false; // declared with `interface` keyword (contract, no fields)
    std::vector<std::string> type_params;  // generic type parameters <T, U>
};

// ---- extend func_decl with overloading / mangling info ----
// (added as extensions; original func_decl unchanged for compatibility)

// ADT enum variant kinds
enum class enum_variant_kind {
    plain,       // success
    tuple,       // failure(T1, T2, ...)
    named_struct,// error { T1 f1; T2 f2; }
    istruc_body  // terminal_error .{ public T f; public void m() {} }
};

struct enum_variant : ast_node {
    std::string             name;
    enum_variant_kind       kind = enum_variant_kind::plain;
    std::optional<expr_node*> plain_val;  // plain: optional integer value

    // tuple fields (anonymous): types in order
    std::vector<type_node*> tuple_types;

    // named struct fields
    std::vector<var_decl*>  struct_fields;

    // istruc body: reuse class_decl for fields + methods
    class_decl*             istruc_body = nullptr;
};

struct enum_decl : ast_node {
    std::string                  name;
    std::vector<enum_variant*>   variants;
    // Legacy simple enum support: if all variants are plain, this is a C-style enum.
    bool                         is_adt = false;
};

struct union_decl : ast_node {
    std::string            name;
    std::vector<var_decl*> fields;
};

struct typedef_decl : ast_node {
    type_node*  underlying = nullptr;
    std::string alias;
};


struct namespace_decl : ast_node {
    std::string            name;
    std::vector<ast_node*> decls;
};

// `using name = tokens...;`  — contextual alias (works like typedef but for any token sequence)
struct using_decl : ast_node {
    std::string alias;       // left-hand name
    std::string expansion;   // raw token text (applied by analyzer as a type/keyword alias)
    type_node*  type_alias = nullptr; // non-null if the RHS parses as a type
};

// Range-based for loop:  for (T name : expr) body
struct for_range_stmt : ast_node {
    type_node*  var_type = nullptr;   // element type  (auto = inferred)
    std::string var_name;
    expr_node*  range    = nullptr;
    ast_node*   body     = nullptr;
};

// Error union return type marker  (!T  or  E!T)
// Stored on func_decl; the parser sets is_error_union=true and fills err_type/ok_type.
// ok_type is the normal return type, err_type is the explicit error type (null = inferred).

// top-level program
struct program_node : ast_node {
    std::vector<ast_node*> decls;
};

// ============================================================
// Parser
// ============================================================

class parser {
public:
    explicit parser(std::vector<token_t> tokens)
        : tokens(std::move(tokens)), current(0) {}

    bool had_parse_error = false;

    program_node* parse() {
        auto* prog = alloc<program_node>();
        while (!is_at_end()) {
            try {
                prog->decls.push_back(parse_top_level());
            } catch (const std::runtime_error& e) {
                std::cerr << e.what() << '\n';
                had_parse_error = true;
                synchronize();
            }
        }
        return prog;
    }

private:
    // -------------------------------------------------------- top-level
    ast_node* parse_top_level() {
        if (check(token_type::kw_struct))   return parse_struct_decl();
        if (check(token_type::kw_enum))     return parse_enum_decl();
        if (check(token_type::kw_union))    return parse_union_decl();
        if (check(token_type::kw_typedef))  return parse_typedef_decl();
        if (check(token_type::kw_istruc))     return parse_class_decl();
        if (check(token_type::kw_interface))  return parse_interface_decl();
        if (check(token_type::kw_extern_c))   return parse_extern_c_block();
        if (check(token_type::kw_extern_std)) return parse_extern_std();
        if (check(token_type::kw_smem))       return parse_memstr_decl();
        if (check(token_type::kw_namespace))  return parse_namespace_decl();
        if (check(token_type::kw_using))      return parse_using_decl();
        if (check(token_type::kw_const_resolve)) return parse_const_resolve_macro();
        return parse_func_or_var_decl();
    }

    // -------------------------------------------------------- type parsing
    type_node* parse_type() {
        auto* t = alloc<type_node>();

        // Nullable prefix: ?T
        if (check(token_type::question)) {
            advance(); // consume ?
            type_node* inner = parse_type();
            inner->is_nullable = true;
            return inner;
        }

        // &memstr parameter type
        if (check(token_type::addr) && peek_at(1).type == token_type::kw_smem) {
            advance(); // consume &
            advance(); // consume memstr
            t->is_memstr_ref = true;
            return t;
        }

        // storage class specifiers
        while (check(token_type::kw_extern) || check(token_type::kw_extern_std) ||
               check(token_type::kw_extern_c) || check(token_type::kw_inline) ||
               check(token_type::kw_register)) {
            if (match(token_type::kw_extern) || match(token_type::kw_extern_std)) t->is_extern = true;
            else if (match(token_type::kw_extern_c)) { t->is_extern = true; t->is_extern_c = true; }
            else if (match(token_type::kw_inline))   t->is_inline = true;
            else { advance(); t->is_register = true; }
        }

        // qualifiers
        while (check(token_type::kw_const) || check(token_type::kw_volatile)) {
            if (match(token_type::kw_const)) t->is_const = true;
            else                              advance();
        }
        if (match(token_type::kw_signed))   t->is_signed = true;
        if (match(token_type::kw_unsigned)) t->is_signed = false;

        static const std::vector<std::pair<token_type, prim_type_t>> prim_map = {
            {token_type::kw_char, prim_type_t::char_t},
            {token_type::kw_i8,   prim_type_t::i8},
            {token_type::kw_i16,  prim_type_t::i16},
            {token_type::kw_i32,  prim_type_t::i32},
            {token_type::kw_i64,  prim_type_t::i64},
            {token_type::kw_i128, prim_type_t::i128},
            {token_type::kw_i256, prim_type_t::i256},
            {token_type::kw_i512, prim_type_t::i512},
            {token_type::kw_u8,   prim_type_t::u8},
            {token_type::kw_u16,  prim_type_t::u16},
            {token_type::kw_u32,  prim_type_t::u32},
            {token_type::kw_u64,  prim_type_t::u64},
            {token_type::kw_u128, prim_type_t::u128},
            {token_type::kw_u256, prim_type_t::u256},
            {token_type::kw_u512, prim_type_t::u512},
            {token_type::kw_f8,   prim_type_t::f8},
            {token_type::kw_f16,  prim_type_t::f16},
            {token_type::kw_f32,  prim_type_t::f32},
            {token_type::kw_f64,  prim_type_t::f64},
            {token_type::kw_f128, prim_type_t::f128},
            {token_type::kw_f256, prim_type_t::f256},
            {token_type::kw_f512, prim_type_t::f512},
            {token_type::kw_bool, prim_type_t::boolean},
            {token_type::kw_b1,   prim_type_t::b1},
            {token_type::kw_b8,   prim_type_t::b8},
            {token_type::kw_b16,  prim_type_t::b16},
            {token_type::kw_b32,  prim_type_t::b32},
            {token_type::kw_b64,  prim_type_t::b64},
            {token_type::kw_b128, prim_type_t::b128},
            {token_type::kw_b256, prim_type_t::b256},
            {token_type::kw_b512, prim_type_t::b512},
            {token_type::kw_void, prim_type_t::void_t},
        };

        bool found = false;
        for (auto& [tt, pt] : prim_map) {
            if (match(tt)) { t->prim = pt; t->is_primitive = true; found = true; break; }
        }
        // 'auto' as a type placeholder (trailing-type form)
        if (!found && check(token_type::kw_auto)) {
            advance();
            t->is_auto = true;
            t->is_primitive = false;
            // Still consume pointer stars and array (e.g. const auto*)
            while (check(token_type::ast)) { advance(); t->pointer_depth++; }
            return t;
        }

        // 'self' or 'this' as type keyword inside method params (alias for the enclosing class)
        if (!found && (check(token_type::kw_self) || check(token_type::kw_this))) {
            advance();
            t->is_self_type = true;
            t->name = "__self__"; // resolved later by parse_method_params or analyzer
        }
        if (!found && !t->is_self_type) {
            auto tok = consume(token_type::id, "Expected type name");
            t->name  = tok.value;
            // Handle namespace::Type qualified names (maps to ns__NS_type internally)
            if (check(token_type::scope_res)) {
                advance(); // consume ::
                auto sub = consume(token_type::id, "Expected type name after '::'");
                t->name  = *t->name + "__NS_" + sub.value;
            }
            // Generic instantiation type args:  Name<T, U>
            if (check(token_type::lt)) {
                std::vector<type_node*> targs;
                if (try_parse_type_args(targs)) t->type_args = std::move(targs);
            }
        }

        // pointer stars (for return type of function pointer)
        while (check(token_type::ast)) { advance(); t->pointer_depth++; }

        // Function pointer type: returntype(params)*
        // After parsing base return type (with its own pointer stars), if we see '('
        // followed by a valid param list and ')' then '*', this is a function pointer type.
        if (check(token_type::oparen)) {
            size_t saved = current;
            advance(); // consume (
            // Try to parse as function pointer params
            bool ok = true;
            std::vector<type_node*>  fp_params;
            std::vector<std::string> fp_names;
            bool fp_variadic = false;
            if (!check(token_type::cparen)) {
                do {
                    if (check(token_type::dot) && peek_at(1).type == token_type::dot
                        && peek_at(2).type == token_type::dot) {
                        advance(); advance(); advance();
                        fp_variadic = true; break;
                    }
                    if (!is_type_start()) { ok = false; break; }
                    type_node* pt = parse_type();
                    std::string pname;
                    if (check(token_type::id) || check(token_type::kw_self)) pname = advance().value;
                    fp_params.push_back(pt);
                    fp_names.push_back(pname);
                } while (ok && match(token_type::comma));
            }
            if (ok && check(token_type::cparen)) {
                advance(); // consume )
                if (check(token_type::ast)) {
                    advance(); // consume *
                    // This IS a function pointer type
                    auto* fp_t            = alloc<type_node>();
                    fp_t->is_func_ptr     = true;
                    fp_t->fp_ret          = t;
                    fp_t->fp_params       = std::move(fp_params);
                    fp_t->fp_param_names  = std::move(fp_names);
                    fp_t->fp_variadic     = fp_variadic;
                    fp_t->pointer_depth   = 1; // it's a pointer to function
                    return fp_t;
                }
            }
            // Not a function pointer type; restore and fall through
            current = saved;
        }

        // array brackets
        if (match(token_type::obracket)) {
            if (!check(token_type::cbracket))
                t->array_size = parse_expr();
            consume(token_type::cbracket, "Expected ']' after array size");
        }

        return t;
    }

    // -------------------------------------------------------- func / var disambiguation
    ast_node* parse_func_or_var_decl() {
        bool is_cexpr  = false;
        bool is_ceval  = false;
        if (check(token_type::kw_constexpr)) { advance(); is_cexpr = true; }
        if (check(token_type::kw_consteval)) { advance(); is_ceval = true; }
        type_node* ret = parse_type();

        // Error union return: !T or E!T before function name
        // Handled by parse_error_return_type if type was just parsed
        // Check if we have !T: leading type followed by not_
        // (E!T means ret=E, then !, then T)
        bool is_err_union = false;
        type_node* err_type = nullptr;
        type_node* ok_type  = nullptr;
        if (check(token_type::not_) && peek_at(1).type != token_type::eq) {
            // E!T: err_type = ret, ok_type = T after !
            is_err_union = true;
            err_type = ret;
            advance(); // consume !
            ok_type = parse_type();
            ret = ok_type;
        }

        auto name_tok  = consume(token_type::id, "Expected declaration name");

        // Optional generic type parameters: name<T, U>
        std::vector<std::string> type_params = try_parse_type_params();

        if (match(token_type::oparen)) {
            auto* fd = parse_func_body(ret, name_tok);
            fd->type_params = std::move(type_params);
            if (is_err_union) { fd->is_error_union = true; fd->err_type = err_type; }
            return fd;
        }
        // Trailing type for variable: auto name: type = expr;
        if (ret->is_auto && check(token_type::colon)) {
            advance(); // consume ':'
            ret = parse_type();
        }
        auto* vd = parse_var_body(ret, name_tok);
        vd->is_constexpr = is_cexpr;
        vd->is_consteval = is_ceval;
        return vd;
    }

    // Parse optional <T, U, ...> generic type parameter list in a declaration context.
    // Only treats '<' as type params if it is immediately followed by an identifier list
    // closed by '>'. Returns empty vector if not a type-param list.
    std::vector<std::string> try_parse_type_params() {
        std::vector<std::string> params;
        if (!check(token_type::lt)) return params;
        // Lookahead: < id (, id)* >
        size_t saved = current;
        advance(); // consume '<'
        if (!check(token_type::id)) { current = saved; return params; }
        std::vector<std::string> tmp;
        tmp.push_back(advance().value);
        bool ok = true;
        while (match(token_type::comma)) {
            if (!check(token_type::id)) { ok = false; break; }
            tmp.push_back(advance().value);
        }
        if (ok && check(token_type::gt)) {
            advance(); // consume '>'
            return tmp;
        }
        current = saved;
        return params;
    }

    func_decl* parse_func_body(type_node* ret, token_t name_tok, bool extern_c = false) {
        auto* fd      = alloc<func_decl>();
        fd->line      = name_tok.line;
        fd->ret_type  = ret;
        fd->name      = name_tok.value;
        fd->is_extern_c = extern_c || (ret && (ret->is_extern_c || ret->is_extern));

        if (!check(token_type::cparen)) {
            do {
                if (check(token_type::dot) && peek_at(1).type == token_type::dot && peek_at(2).type == token_type::dot) {
                    advance(); advance(); advance();
                    fd->is_variadic = true;
                    break;
                }
                param_decl p;
                p.type = parse_type();
                if (check(token_type::id) || check(token_type::kw_self)) p.name = advance().value;
                p.line = previous().line;
                fd->params.push_back(p);
            } while (match(token_type::comma));
        }
        consume(token_type::cparen, "Expected ')' after parameters");

        // Optional function qualifiers after ')': noexcept, attr/derive (proc macro markers)
        while (check(token_type::kw_noexcept)) { advance(); fd->is_noexcept = true; }
        // Skip proc macro markers (attr/derive/macro/verify) — parsed but not yet implemented
        while (check(token_type::id) && (peek().value == "attr" || peek().value == "derive" ||
               peek().value == "macro" || peek().value == "verify")) advance();

        // Trailing return type: auto foo() int { } or auto foo() !int { } or auto foo() E!T { }
        if (fd->ret_type && fd->ret_type->is_auto) {
            // Expect the actual return type now
            if (is_type_start() || check(token_type::not_)) {
                if (check(token_type::not_)) {
                    // Inferred error union: !T
                    advance();
                    fd->ret_type = parse_type();
                    fd->is_error_union = true;
                    fd->err_type = nullptr; // inferred
                } else if (check(token_type::id) && peek_at(1).type == token_type::not_) {
                    // Explicit error union: E!T
                    fd->err_type = parse_type(); // parse E
                    advance(); // consume !
                    fd->ret_type = parse_type(); // parse T
                    fd->is_error_union = true;
                } else {
                    fd->ret_type = parse_type();
                }
            }
        } else if (!fd->ret_type || !fd->ret_type->is_auto) {
            // Even for non-auto leading types, allow trailing type if trailing !T notation
            // (handled at call site via is_err_union flag)
        }

        if (match(token_type::sm)) {
            fd->body = nullptr; // forward declaration
        } else {
            fd->body = parse_block();
        }
        return fd;
    }

    extern_std* parse_extern_std() {
        auto* ed = alloc<extern_std>();
        ed->line = advance().line; // 'extern_std'
        if (check(token_type::dot)) {
            // Dot-path syntax: extern std.module.submodule;
            std::string path;
            while (match(token_type::dot)) {
                if (!path.empty()) path += ".";
                path += consume(token_type::id, "Expected identifier in std module path").value;
            }
            consume(token_type::sm, "Expected ';' after extern std declaration");
            throw std::runtime_error(
                "Parser Error at line " + std::to_string(ed->line) +
                ": Standard library import 'extern std." + path +
                ";' must be at the top of the file");
        }
        ed->module_name = consume(token_type::string_lit, "Expected module name string").value;
        consume(token_type::sm, "Expected ';' after extern declaration");
        return ed;
    }

    var_decl* parse_var_body(type_node* t, token_t name_tok) {
        auto* vd  = alloc<var_decl>();
        vd->line  = name_tok.line;
        vd->type  = t;
        vd->name  = name_tok.value;
        // Array size comes after the name: int arr[10]
        if (match(token_type::obracket)) {
            if (!check(token_type::cbracket))
                t->array_size = parse_expr();
            consume(token_type::cbracket, "Expected ']' after array size");
        }
        if (match(token_type::assign)) vd->init = parse_expr();
        consume(token_type::sm, "Expected ';' after variable declaration");
        return vd;
    }

    // -------------------------------------------------------- struct / enum / union / typedef
    struct_decl* parse_struct_decl() {
        uint64_t ln = peek().line;
        advance(); // 'struct'
        auto* sd = alloc<struct_decl>();
        sd->line = ln;
        sd->name = consume(token_type::id, "Expected struct name").value;
        consume(token_type::obrace, "Expected '{' after struct name");
        while (!check(token_type::cbrace) && !is_at_end()) {
            type_node* ft = parse_type();
            auto fname    = consume(token_type::id, "Expected field name");
            auto* vd      = alloc<var_decl>();
            vd->line      = fname.line;
            vd->type      = ft;
            vd->name      = fname.value;
            // C-style array field: name[N]
            if (match(token_type::obracket)) {
                if (!check(token_type::cbracket))
                    ft->array_size = parse_expr();
                consume(token_type::cbracket, "Expected ']' after array size");
            }
            consume(token_type::sm, "Expected ';' after field");
            sd->fields.push_back(vd);
        }
        consume(token_type::cbrace, "Expected '}' after struct body");
        return sd;
    }

    enum_decl* parse_enum_decl() {
        uint64_t ln = peek().line;
        advance(); // 'enum'
        auto* ed = alloc<enum_decl>();
        ed->line = ln;
        ed->is_adt = false;
        ed->name = consume(token_type::id, "Expected enum name").value;
        consume(token_type::obrace, "Expected '{' after enum name");
        while (!check(token_type::cbrace) && !is_at_end()) {
            auto* ev = alloc<enum_variant>();
            ev->line = peek().line;
            ev->name = consume(token_type::id, "Expected variant name").value;

            if (check(token_type::oparen)) {
                // Tuple variant: failure(T1, T2, ...)
                advance(); // (
                ev->kind = enum_variant_kind::tuple;
                ed->is_adt = true;
                while (!check(token_type::cparen) && !is_at_end()) {
                    ev->tuple_types.push_back(parse_type());
                    if (!check(token_type::cparen))
                        consume(token_type::comma, "Expected ',' between tuple types");
                }
                consume(token_type::cparen, "Expected ')' after tuple types");
            } else if (check(token_type::obrace)) {
                // Named struct variant: error { T f1; T f2; }
                advance(); // {
                ev->kind = enum_variant_kind::named_struct;
                ed->is_adt = true;
                while (!check(token_type::cbrace) && !is_at_end()) {
                    type_node* ft = parse_type();
                    auto fname = consume(token_type::id, "Expected field name");
                    auto* vd = alloc<var_decl>();
                    vd->line = fname.line; vd->type = ft; vd->name = fname.value;
                    consume(token_type::sm, "Expected ';' after field");
                    ev->struct_fields.push_back(vd);
                }
                consume(token_type::cbrace, "Expected '}' after named struct variant");
            } else if (check(token_type::dot) && peek_at(1).type == token_type::obrace) {
                // istruc variant: terminal_error .{ ... }
                advance(); // .
                advance(); // {
                ev->kind = enum_variant_kind::istruc_body;
                ed->is_adt = true;
                auto* cd = alloc<class_decl>();
                cd->line = ev->line;
                cd->name = ev->name;
                while (!check(token_type::cbrace) && !is_at_end()) parse_class_member(cd, cd->name);
                consume(token_type::cbrace, "Expected '}' after istruc variant body");
                ev->istruc_body = cd;
            } else {
                // Plain variant: success  or  success = 42
                ev->kind = enum_variant_kind::plain;
                if (match(token_type::assign)) ev->plain_val = parse_expr();
            }

            ed->variants.push_back(ev);
            if (!check(token_type::cbrace)) consume(token_type::comma, "Expected ',' between enum variants");
        }
        consume(token_type::cbrace, "Expected '}' after enum body");
        return ed;
    }

    union_decl* parse_union_decl() {
        uint64_t ln = peek().line;
        advance(); // 'union'
        auto* ud = alloc<union_decl>();
        ud->line = ln;
        ud->name = consume(token_type::id, "Expected union name").value;
        consume(token_type::obrace, "Expected '{' after union name");
        while (!check(token_type::cbrace) && !is_at_end()) {
            type_node* ft = parse_type();
            auto fname    = consume(token_type::id, "Expected field name");
            auto* vd      = alloc<var_decl>();
            vd->type      = ft;
            vd->name      = fname.value;
            vd->line      = fname.line;
            consume(token_type::sm, "Expected ';' after field");
            ud->fields.push_back(vd);
        }
        consume(token_type::cbrace, "Expected '}' after union body");
        return ud;
    }

    ast_node* parse_memstr_decl() {
        uint64_t ln = peek().line;
        advance(); // consume 'memstr'
        std::string name = consume(token_type::id, "Expected memstr type name").value;
        consume(token_type::obrace, "Expected '{' after memstr name");

        // Detect syntax: if first token is '.', use legacy vtable syntax -> memstr_decl*
        if (check(token_type::dot)) {
            auto* md  = alloc<memstr_decl>();
            md->line  = ln;
            md->name  = name;
            while (!check(token_type::cbrace) && !is_at_end()) {
                if (check(token_type::dot)) {
                    advance();
                    std::string field = consume(token_type::id, "Expected field name after '.'").value;
                    if (field == "ptr") {
                        consume(token_type::assign, "Expected '=' after .ptr");
                        auto* vd = alloc<var_decl>();
                        vd->line = ln;
                        auto* t  = alloc<type_node>();
                        t->is_primitive = true; t->prim = prim_type_t::void_t; t->pointer_depth = 1;
                        vd->type = t; vd->name = "ptr";
                        vd->init = parse_expr();
                        consume(token_type::sm, "Expected ';' after .ptr = expr");
                        md->ptr_field = vd;
                    } else if (field == "vtable") {
                        consume(token_type::assign, "Expected '=' after .vtable");
                        consume(token_type::obrace, "Expected '{' for vtable");
                        while (!check(token_type::cbrace) && !is_at_end()) {
                            consume(token_type::dot, "Expected '.' in vtable field");
                            std::string vf = consume(token_type::id, "Expected vtable field name").value;
                            consume(token_type::assign, "Expected '='");
                            expr_node* fptr_expr = parse_expr();
                            consume(token_type::sm, "Expected ';'");
                            auto* fd = alloc<func_decl>();
                            fd->line = ln; fd->name = vf;
                            auto* es = alloc<expr_stmt>(); es->expr = fptr_expr;
                            auto* blk = alloc<block_stmt>(); blk->stmts.push_back(es);
                            fd->body = blk;
                            if      (vf == "mmap")   md->fn_mmap   = fd;
                            else if (vf == "rmap")   md->fn_rmap   = fd;
                            else if (vf == "deinit") md->fn_deinit = fd;
                        }
                        consume(token_type::cbrace, "Expected '}' after vtable");
                        consume(token_type::sm, "Expected ';' after vtable block");
                    } else {
                        throw std::runtime_error("Parser Error: unknown memstr field '." + field + "'");
                    }
                } else {
                    type_node* ret = parse_type();
                    auto name_tok  = consume(token_type::id, "Expected function name");
                    consume(token_type::oparen, "Expected '('");
                    auto* fd = parse_func_body(ret, name_tok);
                    if      (fd->name == "mmap")   md->fn_mmap   = fd;
                    else if (fd->name == "rmap")   md->fn_rmap   = fd;
                    else if (fd->name == "deinit") md->fn_deinit = fd;
                }
            }
            consume(token_type::cbrace, "Expected '}' after memstr body");
            return md;
        }

        // New class-body syntax: parse like istruc, return class_decl with is_memstr = true
        auto* cd    = alloc<class_decl>();
        cd->line     = ln;
        cd->name     = name;
        cd->is_memstr = true;
        while (!check(token_type::cbrace) && !is_at_end()) {
            parse_class_member(cd, name);
        }
        consume(token_type::cbrace, "Expected '}' after memstr body");
        match(token_type::sm);
        return cd;
    }

    // -------------------------------------------------------- extern "C" block
    extern_c_block* parse_extern_c_block() {
        uint64_t ln = peek().line;
        advance(); // consume 'extern "C"'
        auto* blk = alloc<extern_c_block>();
        blk->line = ln;
        if (match(token_type::obrace)) {
            while (!check(token_type::cbrace) && !is_at_end()) {
                try {
                    ast_node* decl = parse_func_or_var_decl_extern_c();
                    blk->decls.push_back(decl);
                } catch (const std::runtime_error& e) {
                    std::cerr << e.what() << '\n';
                    synchronize();
                }
            }
            consume(token_type::cbrace, "Expected '}' after extern \"C\" block");
        } else {
            // Single declaration: extern "C" rettype name(...)
            blk->decls.push_back(parse_func_or_var_decl_extern_c());
        }
        return blk;
    }

    ast_node* parse_func_or_var_decl_extern_c() {
        type_node* ret = parse_type();
        auto name_tok  = consume(token_type::id, "Expected declaration name");
        if (match(token_type::oparen)) {
            auto* fd = parse_func_body(ret, name_tok, /*extern_c=*/true);
            fd->is_extern_c = true;
            return fd;
        }
        return parse_var_body(ret, name_tok);
    }

    // -------------------------------------------------------- namespace
    namespace_decl* parse_namespace_decl() {
        uint64_t ln = peek().line;
        advance(); // consume 'namespace'
        auto* nd = alloc<namespace_decl>();
        nd->line = ln;
        nd->name = consume(token_type::id, "Expected namespace name").value;
        consume(token_type::obrace, "Expected '{' after namespace name");
        while (!check(token_type::cbrace) && !is_at_end()) {
            try {
                nd->decls.push_back(parse_top_level());
            } catch (const std::runtime_error& e) {
                std::cerr << e.what() << '\n';
                had_parse_error = true;
                synchronize();
            }
        }
        consume(token_type::cbrace, "Expected '}' after namespace body");
        return nd;
    }

    // -------------------------------------------------------- using alias
    // using name = tokens...;   (contextual alias)
    using_decl* parse_using_decl() {
        uint64_t ln = peek().line;
        advance(); // consume 'using'
        auto* ud = alloc<using_decl>();
        ud->line = ln;
        ud->alias = consume(token_type::id, "Expected alias name after 'using'").value;
        consume(token_type::assign, "Expected '=' in 'using' declaration");
        // Collect the RHS as a type if possible, else as raw text
        if (is_type_start()) {
            ud->type_alias = parse_type();
        } else {
            // Collect raw text until ';'
            std::string raw;
            while (!check(token_type::sm) && !is_at_end()) {
                raw += previous().value + " ";
                advance();
            }
            ud->expansion = raw;
        }
        consume(token_type::sm, "Expected ';' after 'using' declaration");
        return ud;
    }

    // -------------------------------------------------------- const_resolve macro
    // const_resolve name { patterns... }
    ast_node* parse_const_resolve_macro() {
        uint64_t ln = peek().line;
        advance(); // consume 'const_resolve'
        auto* nd = alloc<namespace_decl>(); // reuse namespace_decl as a stub container
        nd->line = ln;
        nd->name = "__macro_" + consume(token_type::id, "Expected macro name").value;
        consume(token_type::obrace, "Expected '{' after macro name");
        // Skip the body — balance braces and consume raw tokens
        int depth = 1;
        while (depth > 0 && !is_at_end()) {
            if (check(token_type::obrace)) { depth++; advance(); }
            else if (check(token_type::cbrace)) { if (--depth == 0) break; advance(); }
            else advance();
        }
        consume(token_type::cbrace, "Expected '}' to close macro body");
        return nd;
    }

    // -------------------------------------------------------- interface
    // interface InterfaceName { rettype methodname(params); ... }
    class_decl* parse_interface_decl() {
        uint64_t ln = peek().line;
        advance(); // consume 'interface'
        auto* cd     = alloc<class_decl>();
        cd->line     = ln;
        cd->is_interface = true;
        cd->name     = consume(token_type::id, "Expected interface name").value;
        consume(token_type::obrace, "Expected '{' after interface name");
        while (!check(token_type::cbrace) && !is_at_end()) {
            // Interface body: only method signatures (no body)
            uint64_t mln = peek().line;
            type_node* ret  = parse_type();
            auto mname_tok  = consume(token_type::id, "Expected method name in interface");
            consume(token_type::oparen, "Expected '(' after method name");
            // consume params
            auto* meth = alloc<class_method>();
            meth->line = mln;
            meth->name = mname_tok.value;
            meth->ret_type = ret;
            if (!check(token_type::cparen)) {
                do {
                    if (!is_type_start()) break;
                    param_decl p;
                    p.type = parse_type();
                    if (check(token_type::id) || check(token_type::kw_self)) p.name = advance().value;
                    p.line = previous().line;
                    meth->params.push_back(p);
                } while (match(token_type::comma));
            }
            consume(token_type::cparen, "Expected ')' after interface method params");
            consume(token_type::sm, "Expected ';' after interface method signature");
            cd->methods.push_back(meth);
        }
        consume(token_type::cbrace, "Expected '}' after interface body");
        match(token_type::sm);
        return cd;
    }

    // -------------------------------------------------------- class (istruc)
    class_decl* parse_class_decl() {
        uint64_t ln = peek().line;
        advance(); // consume 'istruc'
        auto* cd  = alloc<class_decl>();
        cd->line  = ln;
        cd->name  = consume(token_type::id, "Expected class name").value;

        // optional generic type parameters: ClassName<T, U>
        cd->type_params = try_parse_type_params();

        // optional interface implementation: ClassName : InterfaceName
        if (match(token_type::colon)) {
            cd->base_name = consume(token_type::id, "Expected interface name").value;
        }

        consume(token_type::obrace, "Expected '{' after class name");

        while (!check(token_type::cbrace) && !is_at_end()) {
            parse_class_member(cd, cd->name);
        }
        consume(token_type::cbrace, "Expected '}' after class body");
        // Optional semicolon after class body
        match(token_type::sm);
        return cd;
    }

    void parse_class_member(class_decl* cd, const std::string& class_name = "") {
        uint64_t ln = peek().line;

        // 'local' declarations (friend-like)
        if (check(token_type::kw_local)) {
            advance();
            type_node* ret = parse_type();
            auto name_tok  = consume(token_type::id, "Expected declaration name");
            if (match(token_type::oparen)) {
                cd->local_decls.push_back(parse_func_body(ret, name_tok));
            } else {
                // local variable declaration — just consume it as a var decl
                auto* vd = parse_var_body(ret, name_tok);
                (void)vd;
            }
            return;
        }

        // Parse access modifier (optional, default pub)
        access_mod acc = access_mod::pub;
        if (check(token_type::kw_public))    { advance(); acc = access_mod::pub;  }
        else if (check(token_type::kw_private))   { advance(); acc = access_mod::priv; }
        else if (check(token_type::kw_protected)) { advance(); acc = access_mod::prot; }

        // Parse method/field modifiers (stackable, any order).
        // virtual/mandatory/static/explicit may precede the return type;
        // noexcept/const/override/final may appear here too (also accepted after ')').
        bool is_virtual   = false;
        bool is_mandatory = false;
        bool is_static    = false;
        bool is_explicit  = false;
        bool is_noexcept  = false;
        bool pre_const    = false;
        bool pre_override = false;
        bool pre_final    = false;

        while (true) {
            if (check(token_type::kw_virtual))
                throw std::runtime_error("Parser Error at line " + std::to_string(peek().line) +
                    ": 'virtual' is not supported; use interfaces instead");
            else if (check(token_type::kw_mandatory))
                throw std::runtime_error("Parser Error at line " + std::to_string(peek().line) +
                    ": 'mandatory' is not supported; use interfaces instead");
            else if (check(token_type::kw_override))
                throw std::runtime_error("Parser Error at line " + std::to_string(peek().line) +
                    ": 'override' is not supported; use interfaces instead");
            else if (check(token_type::kw_static))   { advance(); is_static = true; }
            else if (check(token_type::kw_explicit)) { advance(); is_explicit = true; }
            else if (check(token_type::kw_noexcept)) { advance(); is_noexcept = true; }
            else if (check(token_type::kw_const))    { advance(); pre_const = true; }
            else if (check(token_type::kw_final))
                throw std::runtime_error("Parser Error at line " + std::to_string(peek().line) +
                    ": 'final' is not supported; use interfaces instead");
            else break;
        }

        // Conversion operator: operator T() ...
        if (check(token_type::kw_operator)) {
            advance(); // consume 'operator'
            // The next token(s) form a type (conversion target)
            auto* meth = alloc<class_method>();
            meth->line = ln; meth->access = acc;
            meth->is_virtual = is_virtual; meth->is_static = is_static;
            meth->is_explicit = is_explicit; meth->is_noexcept = is_noexcept;
            meth->is_const_method = pre_const; meth->is_override = pre_override; meth->is_final = pre_final;
            if (pre_override) meth->is_virtual = true;
            meth->is_conversion_op = true;
            meth->conv_target_type = parse_type();
            meth->ret_type = meth->conv_target_type;
            meth->name = "operator " + type_to_string(meth->conv_target_type);
            consume(token_type::oparen, "Expected '(' in conversion operator");
            parse_method_params(meth, class_name);
            parse_method_qualifiers(meth);
            parse_method_body(meth);
            cd->methods.push_back(meth);
            return;
        }

        // Parse return type
        type_node* ret = parse_type();

        // Operator overload: rettype operator<op>(...)
        if (check(token_type::kw_operator)) {
            advance(); // consume 'operator'
            auto* meth = alloc<class_method>();
            meth->line = ln; meth->access = acc;
            meth->is_virtual = is_virtual; meth->is_static = is_static;
            meth->is_explicit = is_explicit; meth->is_noexcept = is_noexcept;
            meth->is_const_method = pre_const; meth->is_override = pre_override; meth->is_final = pre_final;
            if (pre_override) meth->is_virtual = true;
            meth->is_operator_overload = true;
            meth->ret_type = ret;
            meth->operator_str = parse_operator_str();
            meth->name = "operator" + meth->operator_str;
            consume(token_type::oparen, "Expected '(' after operator");
            parse_method_params(meth, class_name);
            parse_method_qualifiers(meth);
            parse_method_body(meth);
            cd->methods.push_back(meth);
            return;
        }

        auto name_tok = consume(token_type::id, "Expected member name");

        // Method: name followed by '('
        if (check(token_type::oparen)) {
            advance(); // consume '('
            auto* meth = alloc<class_method>();
            meth->line = ln; meth->access = acc;
            meth->is_virtual = is_virtual;
            meth->is_mandatory_virtual = is_mandatory;
            meth->is_static = is_static;
            meth->is_explicit = is_explicit; meth->is_noexcept = is_noexcept;
            meth->is_const_method = pre_const; meth->is_override = pre_override; meth->is_final = pre_final;
            if (pre_override) meth->is_virtual = true;
            meth->ret_type  = ret;
            meth->name      = name_tok.value;
            meth->is_constructor = (name_tok.value == "__construct__");
            meth->is_destructor  = (name_tok.value == "__destruct__");
            parse_method_params(meth, class_name);
            // Optional constructor init list: : member(val), ...
            if (meth->is_constructor && check(token_type::colon)) {
                advance(); // consume ':'
                do {
                    init_list_entry entry;
                    entry.member_name = consume(token_type::id, "Expected member name in init list").value;
                    consume(token_type::oparen, "Expected '(' in init list");
                    entry.value = parse_expr();
                    consume(token_type::cparen, "Expected ')' in init list");
                    meth->init_list.push_back(entry);
                } while (match(token_type::comma));
            }
            parse_method_qualifiers(meth);
            parse_method_body(meth);
            cd->methods.push_back(meth);
            if (is_virtual || is_mandatory) cd->has_virtual = true;
            return;
        }

        // Field declaration
        auto* cf = alloc<class_field>();
        cf->line     = ln;
        cf->access   = acc;
        cf->is_static = is_static;
        cf->is_virtual = is_virtual;
        cf->type     = ret;
        cf->name     = name_tok.value;
        // C-style array field: name[N]
        if (match(token_type::obracket)) {
            if (!check(token_type::cbracket))
                ret->array_size = parse_expr();
            consume(token_type::cbracket, "Expected ']' after array size");
        }
        if (match(token_type::assign)) cf->init = parse_expr();
        consume(token_type::sm, "Expected ';' after field declaration");
        cd->fields.push_back(cf);
    }

    // Parse operator string after 'operator' keyword  (e.g. "+", "[]", "()", "==", etc.)
    std::string parse_operator_str() {
        // Consume the operator token(s) and return a string representation
        token_t t = peek();
        switch (t.type) {
            case token_type::plus:    advance(); return "+";
            case token_type::minus:   advance(); return "-";
            case token_type::ast:     advance(); return "*";
            case token_type::slash:   advance(); return "/";
            case token_type::mod:     advance(); return "%";
            case token_type::eq:      advance(); return "==";
            case token_type::ne:      advance(); return "!=";
            case token_type::lt:      advance(); return "<";
            case token_type::gt:      advance(); return ">";
            case token_type::lte:     advance(); return "<=";
            case token_type::gte:     advance(); return ">=";
            case token_type::and_:    advance(); return "&&";
            case token_type::or_:     advance(); return "||";
            case token_type::addr:    advance(); return "&";
            case token_type::bit_or:  advance(); return "|";
            case token_type::bit_xor: advance(); return "^";
            case token_type::bit_not: advance(); return "~";
            case token_type::left:    advance(); return "<<";
            case token_type::right:   advance(); return ">>";
            case token_type::assign:  advance(); return "=";
            case token_type::obracket: {
                advance();
                consume(token_type::cbracket, "Expected ']' after '[' in operator[]");
                return "[]";
            }
            case token_type::oparen: {
                advance();
                consume(token_type::cparen, "Expected ')' after '(' in operator()");
                return "()";
            }
            default:
                throw std::runtime_error("Parser Error at line " + std::to_string(t.line)
                    + ": Expected operator symbol after 'operator'");
        }
    }

    void parse_method_params(class_method* meth, const std::string& class_name = "") {
        // Already consumed '('; parse until ')'
        if (check(token_type::cparen)) { advance(); return; }
        do {
            // Check for variadic
            if (check(token_type::dot) && peek_at(1).type == token_type::dot
                && peek_at(2).type == token_type::dot) {
                advance(); advance(); advance();
                meth->is_variadic = true;
                break;
            }
                // Regular parameter
            type_node* pt = parse_type();
            // Resolve is_self_type to the actual class name so downstream is uniform
            if (pt->is_self_type && !class_name.empty()) pt->name = class_name;
            param_decl p;
            p.type = pt;
            if (check(token_type::id) || check(token_type::kw_self) || check(token_type::kw_this))
                p.name = advance().value;
            p.line = previous().line;
            meth->params.push_back(p);
        } while (match(token_type::comma));
        consume(token_type::cparen, "Expected ')' after method params");

        // Detect explicit self param: first param that is a pointer (depth > 0) to the class type
        if (!meth->has_self && !class_name.empty() && !meth->params.empty()) {
            auto& first = meth->params[0];
            if (first.type && first.type->pointer_depth > 0 && !first.type->is_primitive
                && first.type->name && (*first.type->name == class_name || first.type->is_self_type)) {
                meth->has_self        = true;
                meth->self_const      = first.type->is_const;
                meth->self_param_name = first.name.empty() ? "self" : first.name;
                meth->params.erase(meth->params.begin());
            }
        }
    }

    void parse_method_qualifiers(class_method* meth) {
        // After ')': optional noexcept (const suffix removed — use const param instead)
        while (true) {
            if (check(token_type::kw_noexcept)) { advance(); meth->is_noexcept = true; }
            else if (check(token_type::kw_const))
                throw std::runtime_error("Parser Error at line " + std::to_string(peek().line) +
                    ": 'const' method suffix not supported; use a const pointer param instead");
            else if (check(token_type::kw_override))
                throw std::runtime_error("Parser Error at line " + std::to_string(peek().line) +
                    ": 'override' is not supported; use interfaces instead");
            else if (check(token_type::kw_final))
                throw std::runtime_error("Parser Error at line " + std::to_string(peek().line) +
                    ": 'final' is not supported; use interfaces instead");
            else break;
        }
    }

    void parse_method_body(class_method* meth) {
        if (match(token_type::sm)) {
            meth->body = nullptr; // declaration only
        } else {
            meth->body = parse_block();
        }
    }

    // simple type to string for operator names
    static std::string type_to_string(const type_node* t) {
        if (!t) return "void";
        if (t->is_primitive && t->prim.has_value()) {
            // reuse prim_to_str but avoid including types.hxx here
            // just return the name field if available
        }
        if (t->name.has_value()) return t->name.value();
        return "type";
    }

    typedef_decl* parse_typedef_decl() {
        uint64_t ln = peek().line;
        advance(); // 'typedef'
        auto* td  = alloc<typedef_decl>();
        td->line  = ln;
        // typedef auto Name = Type;  — trailing-type form
        if (check(token_type::kw_auto)) {
            advance(); // consume 'auto'
            td->alias = consume(token_type::id, "Expected typedef alias").value;
            consume(token_type::assign, "Expected '=' in typedef auto");
            td->underlying = parse_type();
        } else {
            td->underlying = parse_type();
            td->alias = consume(token_type::id, "Expected typedef alias").value;
        }
        consume(token_type::sm, "Expected ';' after typedef");
        return td;
    }

    // -------------------------------------------------------- statements
    block_stmt* parse_block() {
        uint64_t ln = peek().line;
        consume(token_type::obrace, "Expected '{'");
        auto* blk = alloc<block_stmt>();
        blk->line = ln;
        while (!check(token_type::cbrace) && !is_at_end()) {
            blk->stmts.push_back(parse_stmt());
        }
        consume(token_type::cbrace, "Expected '}'");
        return blk;
    }

    ast_node* parse_stmt() {
        if (check(token_type::obrace))     return parse_block();
        if (check(token_type::kw_if))      return parse_if();
        if (check(token_type::kw_while))   return parse_while();
        if (check(token_type::kw_for))     return parse_for();
        if (check(token_type::kw_switch))  return parse_switch();
        if (check(token_type::kw_return))  return parse_return();
        if (check(token_type::kw_asm))     return parse_asm_stmt();
        if (check(token_type::kw_break))   { auto* n = alloc<break_stmt>();    n->line = advance().line; consume(token_type::sm, "Expected ';'"); return n; }
        if (check(token_type::kw_continue)){ auto* n = alloc<continue_stmt>(); n->line = advance().line; consume(token_type::sm, "Expected ';'"); return n; }
        if (check(token_type::kw_defer))   return parse_defer_stmt();
        if (check(token_type::kw_try))     return parse_try();
        if (check(token_type::kw_throw))   return parse_throw();

        // constexpr statements
        if (check(token_type::kw_constexpr)) {
            // constexpr if (cond) {...}
            if (peek_at(1).type == token_type::kw_if) {
                advance(); // consume 'constexpr'
                auto* n = parse_if();
                n->is_constexpr = true;
                return n;
            }
            // constexpr { ... }  (compile-time execution block — emitted normally)
            if (peek_at(1).type == token_type::obrace) {
                advance(); // consume 'constexpr'
                return parse_block();
            }
            // constexpr Type name = expr;
            advance(); // consume 'constexpr'
            auto* vd = parse_local_var_decl();
            vd->is_constexpr = true;
            return vd;
        }
        // consteval Type name; — manual constructor
        if (check(token_type::kw_consteval)) {
            advance(); // consume 'consteval'
            auto* vd = parse_local_var_decl();
            vd->is_consteval = true;
            return vd;
        }
        // local variable declaration: starts with a type keyword or identifier followed by identifier
        if (is_type_start()) return parse_local_var_decl();

        // expression statement
        auto* es  = alloc<expr_stmt>();
        es->line  = peek().line;
        es->expr  = parse_expr();
        consume(token_type::sm, "Expected ';' after expression");
        return es;
    }

    throw_stmt* parse_throw() {
        auto* n = alloc<throw_stmt>();
        n->line = advance().line; // consume 'throw'
        if (!check(token_type::sm))
            n->value = parse_expr();
        consume(token_type::sm, "Expected ';' after throw");
        return n;
    }

    try_stmt* parse_try() {
        auto* n  = alloc<try_stmt>();
        n->line  = advance().line; // consume 'try'
        n->body  = parse_block();
        consume(token_type::kw_except, "Expected 'except' after try block");
        consume(token_type::oparen,    "Expected '(' after except");
        // Check for catch-all: except (...)
        if (check(token_type::dot) && peek_at(1).type == token_type::dot && peek_at(2).type == token_type::dot) {
            advance(); advance(); advance(); // consume '...'
            n->exc_type = nullptr;
            n->exc_name = "";
        } else {
            n->exc_type = parse_type();
            n->exc_name = consume(token_type::id, "Expected exception variable name").value;
        }
        consume(token_type::cparen,    "Expected ')'");
        n->handler = parse_block();
        return n;
    }

    defer_stmt* parse_defer_stmt() {
        auto* n = alloc<defer_stmt>();
        n->line = advance().line; // consume 'defer'
        if (check(token_type::obrace)) {
            n->blk = parse_block();
        } else {
            n->expr = parse_expr();
            consume(token_type::sm, "Expected ';' after defer expression");
        }
        return n;
    }

    // Like is_type_start() but also accepts id*) patterns used in cast expressions, e.g. (T*)0.
    bool is_cast_start() const {
        if (is_type_start()) return true;
        // Generic/user type pointer cast: id followed by * then ) e.g. (T*) or (Foo*)
        token_type tt = peek().type;
        if (tt == token_type::id) {
            size_t k = 1;
            while (peek_at(k).type == token_type::ast) ++k;
            if (k > 1 && peek_at(k).type == token_type::cparen) return true;
        }
        return false;
    }

    bool is_type_start() const {
        // '?' prefix means nullable type
        if (peek().type == token_type::question) return true;
        static const std::vector<token_type> type_tokens = {
            token_type::kw_const, token_type::kw_volatile,
            token_type::kw_signed, token_type::kw_unsigned,
            token_type::kw_extern, token_type::kw_extern_std,
            token_type::kw_inline, token_type::kw_register,
            token_type::kw_auto,   // auto placeholder
            token_type::kw_char,
            token_type::kw_i8,   token_type::kw_i16,  token_type::kw_i32,
            token_type::kw_i64,  token_type::kw_i128, token_type::kw_i256, token_type::kw_i512,
            token_type::kw_u8,   token_type::kw_u16,  token_type::kw_u32,
            token_type::kw_u64,  token_type::kw_u128, token_type::kw_u256, token_type::kw_u512,
            token_type::kw_f8,   token_type::kw_f16,  token_type::kw_f32,
            token_type::kw_f64,  token_type::kw_f128, token_type::kw_f256, token_type::kw_f512,
            token_type::kw_bool,
            token_type::kw_b1,   token_type::kw_b8,   token_type::kw_b16,  token_type::kw_b32,
            token_type::kw_b64,  token_type::kw_b128, token_type::kw_b256, token_type::kw_b512,
            token_type::kw_void,
            token_type::kw_struct, token_type::kw_enum, token_type::kw_union,
            token_type::kw_smem,
        };
        token_type tt = peek().type;
        for (auto t : type_tokens) if (t == tt) return true;
        // identifier followed by identifier = user-defined type
        if (tt == token_type::id && peek_at(1).type == token_type::id) return true;
        // namespace::Type qualified type — only when followed by identifier or * (not '(' which is a call)
        if (tt == token_type::id && peek_at(1).type == token_type::scope_res
            && peek_at(2).type == token_type::id) {
            size_t k = 3;
            // Skip generic type args: ns::Type<T, U>
            if (peek_at(k).type == token_type::lt) {
                int depth = 0; size_t j = k;
                for (; j < 80; ++j) {
                    auto pt = peek_at(j).type;
                    if (pt == token_type::lt)  ++depth;
                    else if (pt == token_type::gt) { if (--depth == 0) { k = j + 1; break; } }
                    else if (pt == token_type::eof || pt == token_type::sm
                             || pt == token_type::obrace) return false;
                }
            }
            while (peek_at(k).type == token_type::ast) ++k;
            if (peek_at(k).type == token_type::id) return true;
        }
        // identifier followed by one or more * then identifier = pointer to user-defined type
        if (tt == token_type::id) {
            size_t k = 1;
            while (peek_at(k).type == token_type::ast) ++k;
            auto after_stars = peek_at(k).type;
            if (k > 1 && (after_stars == token_type::id || after_stars == token_type::kw_self)) return true;
        }
        // generic type instantiation:  Name< ... > name  (balanced angle scan)
        if (tt == token_type::id && peek_at(1).type == token_type::lt) {
            int depth = 0;
            size_t k = 1;
            for (; k < 64; ++k) {
                token_type pt = peek_at(k).type;
                if (pt == token_type::lt) ++depth;
                else if (pt == token_type::gt) { if (--depth == 0) { ++k; break; } }
                else if (pt == token_type::eof || pt == token_type::sm
                         || pt == token_type::obrace) return false;
            }
            if (depth == 0) {
                token_type after = peek_at(k).type;
                if (after == token_type::id || after == token_type::ast) return true;
            }
        }
        return false;
    }

    var_decl* parse_local_var_decl() {
        type_node* t   = parse_type();
        if (!check(token_type::id) && !check(token_type::kw_self))
            throw std::runtime_error("Parser Error at line " + std::to_string(peek().line) + ": Expected variable name");
        auto name_tok  = advance();
        // Trailing type: auto name: type = ...
        if (t->is_auto && check(token_type::colon)) {
            advance(); // consume ':'
            t = parse_type();
        }
        auto* vd       = alloc<var_decl>();
        vd->line       = name_tok.line;
        vd->type       = t;
        vd->name       = name_tok.value;
        // Array size comes after the name: int a[10]
        if (match(token_type::obracket)) {
            if (!check(token_type::cbracket))
                t->array_size = parse_expr();
            consume(token_type::cbracket, "Expected ']' after array size");
        }
        // Implicit constructor call syntax: Type name(args...) or Type name{args...}
        else if (check(token_type::oparen) || check(token_type::obrace)) {
            bool brace = check(token_type::obrace);
            advance(); // consume ( or {
            token_type closer = brace ? token_type::cbrace : token_type::cparen;
            vd->ctor_brace = brace;
            vd->has_ctor_parens = true;
            if (!check(closer)) {
                do {
                    vd->ctor_args.push_back(parse_expr());
                } while (match(token_type::comma));
            }
            consume(closer, brace ? "Expected '}' after constructor arguments"
                                  : "Expected ')' after constructor arguments");
            consume(token_type::sm, "Expected ';' after variable declaration");
            return vd;
        }
        if (match(token_type::assign)) vd->init = parse_expr();
        consume(token_type::sm, "Expected ';' after variable declaration");
        return vd;
    }

    if_stmt* parse_if() {
        auto* n = alloc<if_stmt>();
        n->line = advance().line; // 'if'
        // 'if constexpr (...)' — compile-time conditional
        if (check(token_type::kw_constexpr)) { advance(); n->is_constexpr = true; }
        consume(token_type::oparen, "Expected '(' after 'if'");
        n->cond = parse_expr();
        consume(token_type::cparen, "Expected ')' after condition");
        n->then_body = parse_stmt();
        if (match(token_type::kw_else)) n->else_body = parse_stmt();
        return n;
    }

    while_stmt* parse_while() {
        auto* n = alloc<while_stmt>();
        n->line = advance().line;
        consume(token_type::oparen, "Expected '(' after 'while'");
        n->cond = parse_expr();
        consume(token_type::cparen, "Expected ')' after condition");
        n->body = parse_stmt();
        return n;
    }

    ast_node* parse_for() {
        uint64_t ln = advance().line; // consume 'for'
        consume(token_type::oparen, "Expected '(' after 'for'");

        // Range-based for: for (T name : expr) — detect by lookahead for ':' before ';'
        // Heuristic: if a type is followed by identifier and then ':', it's range-for.
        {
            size_t saved = current;
            if (is_type_start()) {
                size_t k = 0;
                // Skip over the type tokens (rough heuristic: scan for id followed by ':')
                // We try to parse type + id and see if ':' follows.
                try {
                    type_node* elem_t = parse_type();
                    if (check(token_type::id)) {
                        std::string vname = advance().value;
                        // Trailing type for range var: auto name: T
                        if (elem_t->is_auto && check(token_type::colon)) {
                            advance(); // consume ':'
                            elem_t = parse_type();
                            // Now expect another ':' for range
                            if (check(token_type::colon)) {
                                advance(); // consume ':'
                                auto* fr = alloc<for_range_stmt>();
                                fr->line = ln;
                                fr->var_type = elem_t;
                                fr->var_name = vname;
                                fr->range = parse_expr();
                                consume(token_type::cparen, "Expected ')' after range-for");
                                fr->body = parse_stmt();
                                return fr;
                            }
                        }
                        if (check(token_type::colon)) {
                            advance(); // consume ':'
                            auto* fr = alloc<for_range_stmt>();
                            fr->line = ln;
                            fr->var_type = elem_t;
                            fr->var_name = vname;
                            fr->range = parse_expr();
                            consume(token_type::cparen, "Expected ')' after range-for");
                            fr->body = parse_stmt();
                            return fr;
                        }
                    }
                } catch (...) {}
                current = saved; // not range-for; fall through to normal for
            }
        }

        auto* n = alloc<for_stmt>();
        n->line = ln;
        if (!check(token_type::sm)) {
            if (is_type_start()) n->init = parse_local_var_decl();
            else { auto* es = alloc<expr_stmt>(); es->expr = parse_expr(); consume(token_type::sm, "Expected ';'"); n->init = es; }
        } else advance();
        if (!check(token_type::sm)) n->cond = parse_expr();
        consume(token_type::sm, "Expected ';' in for");
        if (!check(token_type::cparen)) n->step = parse_expr();
        consume(token_type::cparen, "Expected ')' after for clauses");
        n->body = parse_stmt();
        return n;
    }

    switch_stmt* parse_switch() {
        auto* n = alloc<switch_stmt>();
        n->line = advance().line;
        consume(token_type::oparen, "Expected '(' after 'switch'");
        n->subject = parse_expr();
        consume(token_type::cparen, "Expected ')'");
        consume(token_type::obrace, "Expected '{'");
        while (!check(token_type::cbrace) && !is_at_end()) {
            std::optional<expr_node*> label;
            if (match(token_type::kw_case)) label = parse_expr();
            else consume(token_type::kw_default, "Expected 'case' or 'default'");
            consume(token_type::colon, "Expected ':' after case label");
            auto* blk = alloc<block_stmt>();
            while (!check(token_type::kw_case) && !check(token_type::kw_default) && !check(token_type::cbrace) && !is_at_end())
                blk->stmts.push_back(parse_stmt());
            n->cases.push_back({label, blk});
        }
        consume(token_type::cbrace, "Expected '}' after switch");
        return n;
    }

    return_stmt* parse_return() {
        auto* n = alloc<return_stmt>();
        n->line = advance().line;
        if (!check(token_type::sm)) n->value = parse_expr();
        consume(token_type::sm, "Expected ';' after return");
        return n;
    }

    // -------------------------------------------------------- inline asm

    // Trim leading/trailing whitespace from a string in place.
    static void asm_trim(std::string& s) {
        size_t b = 0;
        while (b < s.size() && (s[b] == ' ' || s[b] == '\t' || s[b] == '\r' || s[b] == '\n')) b++;
        size_t e = s.size();
        while (e > b && (s[e-1] == ' ' || s[e-1] == '\t' || s[e-1] == '\r' || s[e-1] == '\n')) e--;
        s = s.substr(b, e - b);
    }

    // Parse "modifier"(varname) entries from a constraint section text.
    static void asm_parse_constraints(const std::string& text,
                                      std::vector<asm_constraint_entry>& out) {
        size_t pos = 0;
        size_t n   = text.size();
        while (pos < n) {
            // skip whitespace and commas
            while (pos < n && (text[pos] == ' ' || text[pos] == '\t' ||
                                text[pos] == '\r' || text[pos] == '\n' ||
                                text[pos] == ',')) pos++;
            if (pos >= n) break;
            if (text[pos] != '"') { pos++; continue; }
            pos++; // opening "
            std::string modifier;
            while (pos < n && text[pos] != '"') modifier += text[pos++];
            if (pos < n) pos++; // closing "
            // skip leading '=' from output modifier (section determines direction)
            if (!modifier.empty() && modifier[0] == '=') modifier = modifier.substr(1);
            // skip whitespace
            while (pos < n && (text[pos] == ' ' || text[pos] == '\t')) pos++;
            std::string varname;
            if (pos < n && text[pos] == '(') {
                pos++; // opening (
                int depth = 1;
                while (pos < n && depth > 0) {
                    if      (text[pos] == '(') { depth++; varname += text[pos++]; }
                    else if (text[pos] == ')') { depth--; if (depth > 0) varname += text[pos]; pos++; }
                    else                       { varname += text[pos++]; }
                }
            }
            asm_trim(varname);
            if (!varname.empty() && !modifier.empty())
                out.push_back({modifier, varname});
        }
    }

    // Parse comma-separated quoted clobber names from the third section.
    static void asm_parse_clobbers(const std::string& text,
                                   std::vector<std::string>& clobbers) {
        size_t pos = 0;
        size_t n   = text.size();
        while (pos < n) {
            while (pos < n && (text[pos] == ' ' || text[pos] == '\t' ||
                                text[pos] == '\r' || text[pos] == '\n' ||
                                text[pos] == ',')) pos++;
            if (pos >= n) break;
            if (text[pos] != '"') { pos++; continue; }
            pos++; // opening "
            std::string reg;
            while (pos < n && text[pos] != '"') reg += text[pos++];
            if (pos < n) pos++; // closing "
            if (!reg.empty()) clobbers.push_back(reg);
        }
    }

    // Split the raw asm body into instruction text + up to three constraint sections.
    static void asm_split_body(const std::string& body,
                               std::string& instructions,
                               std::vector<asm_constraint_entry>& inputs,
                               std::vector<asm_constraint_entry>& outputs,
                               std::vector<std::string>& clobbers) {
        // Each section starts when a line's first non-whitespace character is ':'.
        std::vector<std::string> sections;
        std::string cur;
        size_t pos = 0;
        size_t n   = body.size();
        while (pos <= n) {
            size_t nl  = body.find('\n', pos);
            size_t end = (nl == std::string::npos) ? n : nl;
            std::string ln = body.substr(pos, end - pos);
            pos = (nl == std::string::npos) ? n + 1 : nl + 1;

            // Is this a ':' section header?
            size_t first = ln.find_first_not_of(" \t\r");
            if (first != std::string::npos && ln[first] == ':') {
                sections.push_back(cur);
                cur = ln.substr(first + 1); // content after ':'
                cur += '\n';
            } else {
                cur += ln;
                cur += '\n';
            }
        }
        sections.push_back(cur);

        if (sections.size() > 0) { instructions = sections[0]; asm_trim(instructions); }
        if (sections.size() > 1) asm_parse_constraints(sections[1], inputs);
        if (sections.size() > 2) asm_parse_constraints(sections[2], outputs);
        if (sections.size() > 3) asm_parse_clobbers(sections[3], clobbers);
    }

    asm_stmt* parse_asm_stmt() {
        auto* n  = alloc<asm_stmt>();
        n->line  = advance().line; // consume kw_asm
        token_t body_tok = consume(token_type::asm_body, "Expected '{...}' body after __asm__");
        asm_split_body(body_tok.value,
                       n->raw_instructions, n->inputs, n->outputs, n->clobbers);
        return n;
    }

    // -------------------------------------------------------- expressions (Pratt)
    expr_node* parse_expr() { return parse_assignment(); }

    expr_node* parse_assignment() {
        expr_node* lhs = parse_ternary();

        static const std::vector<std::pair<token_type, binary_op>> assign_ops = {
            {token_type::assign,    binary_op::assign},
            {token_type::plus_eq,   binary_op::add_assign},
            {token_type::minus_eq,  binary_op::sub_assign},
            {token_type::star_eq,   binary_op::mul_assign},
            {token_type::slash_eq,  binary_op::div_assign},
            {token_type::mod_eq,    binary_op::mod_assign},
            {token_type::amp_eq,    binary_op::and_assign},
            {token_type::pipe_eq,   binary_op::or_assign},
            {token_type::caret_eq,  binary_op::xor_assign},
            {token_type::shl_eq,    binary_op::shl_assign},
            {token_type::shr_eq,    binary_op::shr_assign},
        };

        for (auto& [tt, op] : assign_ops) {
            if (check(tt)) {
                uint64_t ln = advance().line;
                expr_node* rhs = parse_assignment(); // right-associative
                auto* n = alloc<expr_node>();
                n->kind = expr_kind::assign;
                n->line = ln; n->lhs = lhs; n->rhs = rhs; n->bop = op;
                return n;
            }
        }
        return lhs;
    }

    expr_node* parse_ternary() {
        expr_node* cond = parse_or();
        if (!match(token_type::question)) return cond;
        auto* n  = alloc<expr_node>();
        n->kind  = expr_kind::ternary;
        n->line  = previous().line;
        n->cond  = cond;
        n->then_e = parse_expr();
        consume(token_type::colon, "Expected ':' in ternary");
        n->else_e = parse_ternary();
        return n;
    }

    expr_node* parse_or() { return parse_binary_left({token_type::or_},  {binary_op::log_or},  [this]{ return parse_and(); }); }
    expr_node* parse_and(){ return parse_binary_left({token_type::and_}, {binary_op::log_and}, [this]{ return parse_bit_or(); }); }
    expr_node* parse_bit_or()  { return parse_binary_left({token_type::bit_or},  {binary_op::bit_or},  [this]{ return parse_bit_xor(); }); }
    expr_node* parse_bit_xor() { return parse_binary_left({token_type::bit_xor}, {binary_op::bit_xor}, [this]{ return parse_bit_and(); }); }
    expr_node* parse_bit_and() { return parse_binary_left({token_type::addr},    {binary_op::bit_and}, [this]{ return parse_equality(); }); }

    expr_node* parse_equality() {
        return parse_binary_left({token_type::eq, token_type::ne},
                                 {binary_op::eq,  binary_op::ne},
                                 [this]{ return parse_relational(); });
    }
    expr_node* parse_relational() {
        return parse_binary_left({token_type::lt,  token_type::gt,  token_type::lte,  token_type::gte},
                                 {binary_op::lt,   binary_op::gt,   binary_op::lte,   binary_op::gte},
                                 [this]{ return parse_shift(); });
    }
    expr_node* parse_shift() {
        return parse_binary_left({token_type::left, token_type::right},
                                 {binary_op::shl,   binary_op::shr},
                                 [this]{ return parse_additive(); });
    }
    expr_node* parse_additive() {
        return parse_binary_left({token_type::plus, token_type::minus},
                                 {binary_op::add,   binary_op::sub},
                                 [this]{ return parse_multiplicative(); });
    }
    expr_node* parse_multiplicative() {
        return parse_binary_left({token_type::ast,  token_type::slash, token_type::mod},
                                 {binary_op::mul,   binary_op::div,   binary_op::mod},
                                 [this]{ return parse_unary(); });
    }

    template<typename F>
    expr_node* parse_binary_left(std::vector<token_type> ops, std::vector<binary_op> bops, F next) {
        expr_node* lhs = next();
        while (true) {
            bool matched = false;
            for (size_t i = 0; i < ops.size(); i++) {
                if (check(ops[i])) {
                    uint64_t ln = advance().line;
                    auto* n = alloc<expr_node>();
                    n->kind = expr_kind::binary;
                    n->line = ln; n->lhs = lhs; n->bop = bops[i];
                    n->rhs  = next();
                    lhs = n;
                    matched = true;
                    break;
                }
            }
            if (!matched) break;
        }
        return lhs;
    }

    expr_node* parse_unary() {
        if (check(token_type::not_)) {
            uint64_t ln = advance().line;
            auto* n = alloc<expr_node>(); n->kind = expr_kind::unary; n->line = ln;
            n->uop = unary_op::log_not; n->operand = parse_unary(); return n;
        }
        if (check(token_type::bit_not)) {
            uint64_t ln = advance().line;
            auto* n = alloc<expr_node>(); n->kind = expr_kind::unary; n->line = ln;
            n->uop = unary_op::bit_not; n->operand = parse_unary(); return n;
        }
        if (check(token_type::minus)) {
            uint64_t ln = advance().line;
            auto* n = alloc<expr_node>(); n->kind = expr_kind::unary; n->line = ln;
            n->uop = unary_op::neg; n->operand = parse_unary(); return n;
        }
        if (check(token_type::plus)) {
            uint64_t ln = advance().line;
            auto* n = alloc<expr_node>(); n->kind = expr_kind::unary; n->line = ln;
            n->uop = unary_op::pos; n->operand = parse_unary(); return n;
        }
        if (check(token_type::addr)) {
            uint64_t ln = advance().line;
            auto* n = alloc<expr_node>(); n->kind = expr_kind::unary; n->line = ln;
            n->uop = unary_op::addr_of; n->operand = parse_unary(); return n;
        }
        if (check(token_type::ast)) {
            uint64_t ln = advance().line;
            auto* n = alloc<expr_node>(); n->kind = expr_kind::unary; n->line = ln;
            n->uop = unary_op::deref; n->operand = parse_unary(); return n;
        }
        if (check(token_type::inc)) {
            uint64_t ln = advance().line;
            auto* n = alloc<expr_node>(); n->kind = expr_kind::unary; n->line = ln;
            n->uop = unary_op::pre_inc; n->operand = parse_unary(); return n;
        }
        if (check(token_type::dec)) {
            uint64_t ln = advance().line;
            auto* n = alloc<expr_node>(); n->kind = expr_kind::unary; n->line = ln;
            n->uop = unary_op::pre_dec; n->operand = parse_unary(); return n;
        }
        if (check(token_type::kw_sizeof)) return parse_sizeof();
        // noexcept(expr) operator: evaluates to a bool literal (informational -> always true)
        if (check(token_type::kw_noexcept) && peek_at(1).type == token_type::oparen) {
            uint64_t ln = advance().line; // 'noexcept'
            consume(token_type::oparen, "Expected '(' after noexcept");
            parse_expr(); // operand (ignored)
            consume(token_type::cparen, "Expected ')' after noexcept operand");
            auto* n = alloc<expr_node>();
            n->kind = expr_kind::bool_lit;
            n->line = ln;
            n->bool_val = true;
            return n;
        }
        return parse_postfix();
    }

    // Parse optional <T, U, ...> generic type-argument list. Rolls back fully on failure.
    bool try_parse_type_args(std::vector<type_node*>& out) {
        if (!check(token_type::lt)) return false;
        size_t saved = current;
        advance(); // consume '<'
        if (check(token_type::gt)) { current = saved; return false; }
        std::vector<type_node*> tmp;
        do {
            if (!is_type_arg_start()) { current = saved; return false; }
            tmp.push_back(parse_type());
        } while (match(token_type::comma));
        if (!check(token_type::gt)) { current = saved; return false; }
        advance(); // consume '>'
        out = std::move(tmp);
        return true;
    }

    bool is_type_arg_start() const {
        token_type tt = peek().type;
        if (tt == token_type::id) return true;
        if (tt == token_type::kw_const || tt == token_type::kw_unsigned ||
            tt == token_type::kw_signed || tt == token_type::kw_void) return true;
        // primitive numeric/bool type keywords are contiguous: kw_char .. kw_b512
        return tt >= token_type::kw_char && tt <= token_type::kw_b512;
    }

    expr_node* parse_sizeof() {
        auto* n = alloc<expr_node>();
        n->kind = expr_kind::sizeof_e;
        n->line = advance().line; // 'sizeof'
        consume(token_type::oparen, "Expected '(' after sizeof");
        // disambiguate type vs expression
        if (is_type_start()) {
            n->cast_type = parse_type();
        } else {
            n->operand = parse_expr();
        }
        consume(token_type::cparen, "Expected ')' after sizeof operand");
        return n;
    }

    expr_node* parse_postfix() {
        expr_node* base = parse_primary();
        while (true) {
            // Generic call: name<TypeArgs>(args)  (only if '<types>' is followed by '(')
            if (check(token_type::lt) && base->kind == expr_kind::identifier) {
                size_t saved = current;
                std::vector<type_node*> targs;
                if (try_parse_type_args(targs) && check(token_type::oparen)) {
                    advance(); // consume '('
                    auto* n   = alloc<expr_node>();
                    n->kind   = expr_kind::call;
                    n->line   = previous().line;
                    n->callee = base;
                    n->type_args = std::move(targs);
                    if (!check(token_type::cparen)) {
                        do { n->args.push_back(parse_expr()); } while (match(token_type::comma));
                    }
                    consume(token_type::cparen, "Expected ')' after arguments");
                    base = n;
                    continue;
                }
                current = saved; // not a generic call; fall through to comparison parsing
            }
            if (match(token_type::oparen)) {
                // function call
                auto* n   = alloc<expr_node>();
                n->kind   = expr_kind::call;
                n->line   = previous().line;
                n->callee = base;
                if (!check(token_type::cparen)) {
                    do { n->args.push_back(parse_expr()); } while (match(token_type::comma));
                }
                consume(token_type::cparen, "Expected ')' after arguments");
                base = n;
                continue;
            }
            if (match(token_type::obracket)) {
                auto* n   = alloc<expr_node>();
                n->kind   = expr_kind::subscript;
                n->line   = previous().line;
                n->object = base;
                n->index  = parse_expr();
                consume(token_type::cbracket, "Expected ']'");
                base = n;
                continue;
            }
            // ADT istruc-variant init: expr .{ .field = val, ... }
            // (used for terminal_error .{ .msg = "bad" } after EnumName::VariantName)
            if (check(token_type::dot) && peek_at(1).type == token_type::obrace) {
                advance(); // consume '.'
                auto* ci      = alloc<expr_node>();
                ci->kind      = expr_kind::class_init;
                ci->line      = previous().line;
                ci->init_type = nullptr;
                ci->object    = base; // retain base as context for type inference
                parse_class_init_fields(ci);
                base = ci;
                continue;
            }
            if (match(token_type::dot)) {
                auto* n       = alloc<expr_node>();
                n->kind       = expr_kind::member;
                n->line       = previous().line;
                n->object     = base;
                n->member_name = consume(token_type::id, "Expected member name").value;
                base = n;
                continue;
            }
            // -> is syntactic sugar for (*base).member — deprecated, use (*ptr).field instead
            if (match(token_type::arrow)) {
                uint64_t arrow_line = previous().line;
                std::cerr << "Warning at line " << arrow_line
                          << ": '->' is deprecated; use (*ptr).field instead\n";
                // Desugar: base->field  =>  (*base).field
                auto* deref   = alloc<expr_node>();
                deref->kind   = expr_kind::unary;
                deref->line   = arrow_line;
                deref->uop    = unary_op::deref;
                deref->operand = base;
                auto* n       = alloc<expr_node>();
                n->kind       = expr_kind::member;
                n->line       = arrow_line;
                n->object     = deref;
                n->member_name = consume(token_type::id, "Expected member name after '->'").value;
                base = n;
                continue;
            }
            if (check(token_type::inc)) {
                auto* n = alloc<expr_node>(); n->kind = expr_kind::unary;
                n->line = advance().line; n->uop = unary_op::post_inc; n->operand = base;
                base = n; continue;
            }
            if (check(token_type::dec)) {
                auto* n = alloc<expr_node>(); n->kind = expr_kind::unary;
                n->line = advance().line; n->uop = unary_op::post_dec; n->operand = base;
                base = n; continue;
            }
            // Name::member — scope resolution, deprecated in favour of '.'; produces a member expr
            // that the analyzer resolves as a class static method or namespace function.
            if (match(token_type::scope_res)) {
                uint64_t res_line = previous().line;
                auto* n        = alloc<expr_node>();
                n->kind        = expr_kind::member;
                n->line        = res_line;
                n->object      = base;
                n->member_name = consume(token_type::id, "Expected name after '::'").value;
                base = n;
                // After EnumName::VariantName, check for { .field = val } (named-struct variant init)
                if (check(token_type::obrace) && peek_at(1).type == token_type::dot) {
                    auto* ci = alloc<expr_node>();
                    ci->kind = expr_kind::class_init;
                    ci->line = res_line;
                    ci->init_type = nullptr; // type inferred from context (ADT enum variant)
                    // Store the member expr (EnumName::VariantName) as the callee
                    // so visit_class_init can detect this is an ADT enum variant init.
                    ci->object = base; // base is the member expr we just built
                    parse_class_init_fields(ci);
                    base = ci;
                }
                continue;
            }
            break;
        }
        return base;
    }

    // Parse '{ .field = val, ... }' into n->field_inits. '{' is the current token.
    void parse_class_init_fields(expr_node* n) {
        consume(token_type::obrace, "Expected '{' in class initializer");
        if (!check(token_type::cbrace)) {
            do {
                if (check(token_type::cbrace)) break; // trailing comma
                consume(token_type::dot, "Expected '.' before field name in class initializer");
                std::string fname = consume(token_type::id, "Expected field name in class initializer").value;
                consume(token_type::assign, "Expected '=' after field name in class initializer");
                expr_node* val = parse_expr();
                n->field_inits.emplace_back(fname, val);
            } while (match(token_type::comma));
        }
        consume(token_type::cbrace, "Expected '}' after class initializer");
    }

    expr_node* parse_primary() {
        // grouped / cast
        if (check(token_type::oparen)) {
            advance();
            if (is_cast_start()) {
                // cast expression
                auto* n    = alloc<expr_node>();
                n->kind    = expr_kind::cast;
                n->line    = previous().line;
                n->cast_type = parse_type();
                consume(token_type::cparen, "Expected ')' after cast type");
                n->operand = parse_unary();
                return n;
            }
            expr_node* inner = parse_expr();
            consume(token_type::cparen, "Expected ')' after expression");
            return inner;
        }

        if (check(token_type::int_lit) || check(token_type::num)) {
            auto tok = advance();
            auto* n  = alloc<expr_node>();
            n->kind  = expr_kind::int_lit;
            n->line  = tok.line;
            n->int_val = (int64_t)std::strtoull(tok.value.c_str(), nullptr, 0);
            return n;
        }
        if (check(token_type::float_lit)) {
            auto tok = advance();
            auto* n  = alloc<expr_node>();
            n->kind  = expr_kind::float_lit;
            n->line  = tok.line;
            n->flt_val = std::stod(tok.value);
            return n;
        }
        if (check(token_type::string_lit)) {
            auto tok = advance();
            auto* n  = alloc<expr_node>();
            n->kind  = expr_kind::string_lit;
            n->line  = tok.line;
            n->str_val = tok.value;
            return n;
        }
        if (check(token_type::char_lit)) {
            auto tok = advance();
            auto* n  = alloc<expr_node>();
            n->kind  = expr_kind::char_lit;
            n->line  = tok.line;
            n->str_val = tok.value;
            return n;
        }
        if (check(token_type::kw_true) || check(token_type::kw_false)) {
            auto tok = advance();
            auto* n  = alloc<expr_node>();
            n->kind  = expr_kind::bool_lit;
            n->line  = tok.line;
            n->bool_val = (tok.type == token_type::kw_true);
            return n;
        }
        if (check(token_type::kw_null)) {
            auto tok = advance();
            auto* n  = alloc<expr_node>();
            n->kind  = expr_kind::int_lit;
            n->line  = tok.line;
            n->int_val = 0;
            return n;
        }
        // Context-inferred class init:  .{ .field = val, ... }
        if (check(token_type::dot) && peek_at(1).type == token_type::obrace) {
            uint64_t ln = advance().line; // consume '.'
            auto* n = alloc<expr_node>();
            n->kind = expr_kind::class_init;
            n->line = ln;
            n->init_type = nullptr; // infer from context
            parse_class_init_fields(n);
            return n;
        }
        if (check(token_type::id) || check(token_type::kw_self)) {
            auto tok = advance();
            // Named-field class init:  TypeName { .field = val, ... }
            if (tok.type == token_type::id && check(token_type::obrace)
                && peek_at(1).type == token_type::dot) {
                auto* n = alloc<expr_node>();
                n->kind = expr_kind::class_init;
                n->line = tok.line;
                auto* tn = alloc<type_node>();
                tn->name = tok.value;
                n->init_type = tn;
                parse_class_init_fields(n);
                return n;
            }
            auto* n  = alloc<expr_node>();
            n->kind  = expr_kind::identifier;
            n->line  = tok.line;
            n->str_val = (tok.type == token_type::kw_self) ? "self" : tok.value;
            return n;
        }
        if (check(token_type::at)) {
            uint64_t ln = advance().line;
            auto* n    = alloc<expr_node>();
            n->kind    = expr_kind::annotation;
            n->line    = ln;
            n->str_val = consume(token_type::id, "Expected identifier after '@'").value;
            return n;
        }

        throw std::runtime_error("Parser Error at line " + std::to_string(peek().line)
                                 + ": Unexpected token '" + peek().value + "'");
    }

    // -------------------------------------------------------- utilities
    bool match(token_type type) {
        if (check(type)) { advance(); return true; }
        return false;
    }

    token_t consume(token_type type, const std::string& msg) {
        if (check(type)) return advance();
        throw std::runtime_error("Parser Error at line " + std::to_string(peek().line) + ": " + msg);
    }

    bool check(token_type type) const {
        return peek().type == type;
    }

    token_t peek() const             { return tokens[current]; }
    token_t peek_at(size_t n) const  { size_t i = current + n; return i < tokens.size() ? tokens[i] : tokens.back(); }
    token_t advance()                { if (!is_at_end()) current++; return previous(); }
    token_t previous() const         { return tokens[current - 1]; }
    bool is_at_end() const           { return peek().type == token_type::eof; }

    void synchronize() {
        advance();
        while (!is_at_end()) {
            if (previous().type == token_type::sm) return;
            switch (peek().type) {
                case token_type::kw_struct:      case token_type::kw_enum:
                case token_type::kw_union:       case token_type::kw_typedef:
                case token_type::kw_istruc:      case token_type::kw_extern_c:
                case token_type::kw_if:          case token_type::kw_while:
                case token_type::kw_for:         case token_type::kw_return:
                case token_type::kw_try:         case token_type::kw_throw:
                case token_type::kw_namespace:   case token_type::kw_defer:
                case token_type::kw_extern_std:
                    return;
                default: break;
            }
            advance();
        }
    }

    template<typename T, typename... Args>
    T* alloc(Args&&... args) {
        auto ptr = std::make_unique<T>(std::forward<Args>(args)...);
        T* raw = ptr.get();
        push_owned(std::move(ptr));
        return raw;
    }

    // Overloaded arena dispatch — each node family gets its own bucket.
    void push_owned(std::unique_ptr<expr_node> p) { owned_exprs.push_back(std::move(p)); }
    void push_owned(std::unique_ptr<type_node> p) { owned_types.push_back(std::move(p)); }
    template<typename T>
    void push_owned(std::unique_ptr<T> p) { owned_stmts.push_back(std::move(p)); }

    std::vector<token_t>                    tokens;
    size_t                                  current;
    std::vector<std::unique_ptr<ast_node>>  owned_stmts;
    std::vector<std::unique_ptr<expr_node>> owned_exprs;
    std::vector<std::unique_ptr<type_node>> owned_types;
};
