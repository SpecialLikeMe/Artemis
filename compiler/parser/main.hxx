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
};

struct param_decl {
    type_node*  type = nullptr;
    std::string name;
    uint64_t    line = 0;
};

struct func_decl : ast_node {
    type_node*               ret_type = nullptr;
    std::string              name;
    std::vector<param_decl>  params;
    bool                     is_variadic = false;
    block_stmt*              body        = nullptr; // null = forward decl
};

struct struct_decl : ast_node {
    std::string            name;
    std::vector<var_decl*> fields;
};

struct memstr_decl : ast_node {
    std::string            name;
    var_decl*              ptr;
    func_decl*             vtable[3];
};

struct enum_decl : ast_node {
    std::string                                name;
    std::vector<std::pair<std::string, std::optional<expr_node*>>> variants;
};

struct union_decl : ast_node {
    std::string            name;
    std::vector<var_decl*> fields;
};

struct typedef_decl : ast_node {
    type_node*  underlying = nullptr;
    std::string alias;
};


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

    program_node* parse() {
        auto* prog = alloc<program_node>();
        while (!is_at_end()) {
            try {
                prog->decls.push_back(parse_top_level());
            } catch (const std::runtime_error& e) {
                std::cerr << e.what() << '\n';
                synchronize();
            }
        }
        return prog;
    }

private:
    // -------------------------------------------------------- top-level
    ast_node* parse_top_level() {
        if (check(token_type::kw_struct))  return parse_struct_decl();
        if (check(token_type::kw_enum))    return parse_enum_decl();
        if (check(token_type::kw_union))   return parse_union_decl();
        if (check(token_type::kw_typedef)) return parse_typedef_decl();
        return parse_func_or_var_decl();
    }

    // -------------------------------------------------------- type parsing
    type_node* parse_type() {
        auto* t = alloc<type_node>();

        // storage class specifiers
        while (check(token_type::kw_extern) || check(token_type::kw_extern_std) ||
               check(token_type::kw_inline) || check(token_type::kw_register)) {
            if (match(token_type::kw_extern) || match(token_type::kw_extern_std)) t->is_extern = true;
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
        if (!found) {
            auto tok = consume(token_type::id, "Expected type name");
            t->name  = tok.value;
        }

        // pointer stars
        while (check(token_type::ast)) { advance(); t->pointer_depth++; }

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
        type_node* ret = parse_type();
        auto name_tok  = consume(token_type::id, "Expected declaration name");

        if (match(token_type::oparen)) return parse_func_body(ret, name_tok);
        return parse_var_body(ret, name_tok);
    }

    func_decl* parse_func_body(type_node* ret, token_t name_tok) {
        auto* fd      = alloc<func_decl>();
        fd->line      = name_tok.line;
        fd->ret_type  = ret;
        fd->name      = name_tok.value;

        if (!check(token_type::cparen)) {
            do {
                if (check(token_type::dot) && peek_at(1).type == token_type::dot && peek_at(2).type == token_type::dot) {
                    advance(); advance(); advance();
                    fd->is_variadic = true;
                    break;
                }
                param_decl p;
                p.type = parse_type();
                if (check(token_type::id)) p.name = advance().value;
                p.line = previous().line;
                fd->params.push_back(p);
            } while (match(token_type::comma));
        }
        consume(token_type::cparen, "Expected ')' after parameters");

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
        ed->module_name = consume(token_type::string_lit, "Expected module name string").value;
        consume(token_type::sm, "Expected ';' after extern declaration");
        return ed;
    }

    var_decl* parse_var_body(type_node* t, token_t name_tok) {
        auto* vd  = alloc<var_decl>();
        vd->line  = name_tok.line;
        vd->type  = t;
        vd->name  = name_tok.value;
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
        ed->name = consume(token_type::id, "Expected enum name").value;
        consume(token_type::obrace, "Expected '{' after enum name");
        while (!check(token_type::cbrace) && !is_at_end()) {
            std::string vname = consume(token_type::id, "Expected variant name").value;
            std::optional<expr_node*> val;
            if (match(token_type::assign)) val = parse_expr();
            ed->variants.push_back({vname, val});
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

    memstr_decl* parse_memstr_decl() {
        consume(token_type::kw_smem)
    }

    typedef_decl* parse_typedef_decl() {
        uint64_t ln = peek().line;
        advance(); // 'typedef'
        auto* td  = alloc<typedef_decl>();
        td->line  = ln;
        td->underlying = parse_type();
        td->alias = consume(token_type::id, "Expected typedef alias").value;
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

        // local variable declaration: starts with a type keyword or identifier followed by identifier
        if (is_type_start()) return parse_local_var_decl();

        // expression statement
        auto* es  = alloc<expr_stmt>();
        es->line  = peek().line;
        es->expr  = parse_expr();
        consume(token_type::sm, "Expected ';' after expression");
        return es;
    }

    bool is_type_start() const {
        static const std::vector<token_type> type_tokens = {
            token_type::kw_const, token_type::kw_volatile,
            token_type::kw_signed, token_type::kw_unsigned,
            token_type::kw_extern, token_type::kw_extern_std,
            token_type::kw_inline, token_type::kw_register,
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
        };
        token_type tt = peek().type;
        for (auto t : type_tokens) if (t == tt) return true;
        // identifier followed by identifier = user-defined type
        if (tt == token_type::id && peek_at(1).type == token_type::id) return true;
        return false;
    }

    var_decl* parse_local_var_decl() {
        type_node* t   = parse_type();
        auto name_tok  = consume(token_type::id, "Expected variable name");
        auto* vd       = alloc<var_decl>();
        vd->line       = name_tok.line;
        vd->type       = t;
        vd->name       = name_tok.value;
        if (match(token_type::assign)) vd->init = parse_expr();
        consume(token_type::sm, "Expected ';' after variable declaration");
        return vd;
    }

    if_stmt* parse_if() {
        auto* n = alloc<if_stmt>();
        n->line = advance().line; // 'if'
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

    for_stmt* parse_for() {
        auto* n = alloc<for_stmt>();
        n->line = advance().line;
        consume(token_type::oparen, "Expected '(' after 'for'");
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
        return parse_postfix();
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
            if (match(token_type::dot)) {
                auto* n       = alloc<expr_node>();
                n->kind       = expr_kind::member;
                n->line       = previous().line;
                n->object     = base;
                n->member_name = consume(token_type::id, "Expected member name").value;
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
            break;
        }
        return base;
    }

    expr_node* parse_primary() {
        // grouped / cast
        if (check(token_type::oparen)) {
            advance();
            if (is_type_start()) {
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
            n->int_val = std::stoll(tok.value, nullptr, 0);
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
        if (check(token_type::id)) {
            auto tok = advance();
            auto* n  = alloc<expr_node>();
            n->kind  = expr_kind::identifier;
            n->line  = tok.line;
            n->str_val = tok.value;
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
                case token_type::kw_struct: case token_type::kw_enum:
                case token_type::kw_union:  case token_type::kw_typedef:
                case token_type::kw_if:     case token_type::kw_while:
                case token_type::kw_for:    case token_type::kw_return:
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
