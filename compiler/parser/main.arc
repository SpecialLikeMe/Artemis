// Artemis recursive descent parser — builds the AST from a token stream.

namespace parser {

// ---- AST node kinds ----
enum ast_kind {
    nd_block        = 0,
    nd_expr_stmt    = 1,
    nd_return_stmt  = 2,
    nd_break_stmt   = 3,
    nd_continue_stmt= 4,
    nd_if_stmt      = 5,
    nd_while_stmt   = 6,
    nd_for_stmt     = 7,
    nd_for_range_stmt = 8,
    nd_switch_stmt  = 9,
    nd_asm_stmt     = 10,
    nd_defer_stmt   = 11,
    nd_errdefer_stmt= 12,
    nd_var_decl     = 13,
    nd_func_decl    = 14,
    nd_struct_decl  = 15,
    nd_class_decl   = 16,
    nd_enum_decl    = 17,
    nd_union_decl   = 18,
    nd_typedef_decl = 19,
    nd_namespace_decl = 20,
    nd_using_decl   = 21,
    nd_extern_c_block = 22,
    nd_program      = 23,
    nd_try_expr_stmt= 24,
    nd_res_block    = 25,
}

// ---- Base AST node ----
struct ast_node {
    i32 kind;
    u64 line;
}

// Dynamic array of ast_node pointers
struct node_vec {
    ast_node** data;
    i32        len;
    i32        cap;
}

void node_vec_init(node_vec* v) {
    v.data = (ast_node**)0;
    v.len  = 0;
    v.cap  = 0;
}

void node_vec_push(node_vec* v, ast_node* n) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 16 : v.cap * 2;
        v.data = (ast_node**)arc_realloc((i8*)v.data, sizeof(i8*) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = n;
    v.len = v.len + 1;
}

// ---- Statement nodes ----

struct block_stmt {
    i32        kind;
    u64        line;
    ast_node** stmts;
    i32        stmts_len;
}

struct expr_stmt {
    i32        kind;
    u64        line;
    expr_node* expr;
}

struct return_stmt {
    i32        kind;
    u64        line;
    expr_node* val;
    bool       has_val;
}

struct break_stmt {
    i32 kind;
    u64 line;
}

struct continue_stmt {
    i32 kind;
    u64 line;
}

struct if_stmt {
    i32        kind;
    u64        line;
    expr_node* cond;
    ast_node*  then_body;
    ast_node*  else_body;
    bool       is_constexpr;
    i8*        then_capture;
    i8*        else_capture;
}

struct while_stmt {
    i32        kind;
    u64        line;
    expr_node* cond;
    ast_node*  body;
}

struct for_stmt {
    i32        kind;
    u64        line;
    ast_node*  init;
    expr_node* cond;
    expr_node* step;
    ast_node*  body;
}

struct for_range_stmt {
    i32        kind;
    u64        line;
    type_node* var_type;
    i8*        var_name;
    expr_node* range;
    ast_node*  body;
}

// switch case entry
struct switch_case {
    expr_node** case_vals;   // array of case values (null entry = default)
    bool*       case_is_default;
    block_stmt** case_bodies;
    i32          cases_len;
}

struct switch_stmt {
    i32           kind;
    u64           line;
    expr_node*    val;
    expr_node***  case_vals;   // array of (expr_node*) or null for default
    block_stmt**  case_bodies;
    bool*         case_is_default;
    i32           cases_len;
    i32           cases_cap;
}

struct defer_stmt {
    i32        kind;
    u64        line;
    expr_node* expr;
    i8*        blk;   // actually block_stmt*
    bool       is_block;
}

struct asm_stmt {
    i32 kind;
    u64 line;
    i8* raw_instructions;
}

struct try_expr_stmt {
    i32        kind;
    u64        line;
    expr_node* expr;
}

struct res_block_stmt {
    i32   kind;
    u64   line;
    i8*   body;   // actually block_stmt*
}

// ---- Declaration nodes ----

struct param_decl {
    type_node* type;
    i8*        name;
    u64        line;
}

struct proc_attr {
    i8*  name;
    i8** args;
    i32  args_len;
}

struct var_decl {
    i32        kind;
    u64        line;
    type_node* type;
    i8*        name;
    expr_node* init;
    bool       has_init;
    bool       is_constexpr;
    bool       is_sta;
    bool       is_static_local; // `static type name;` inside a function
    bool       is_static;       // `static field;` inside an istruc → module global
    bool       has_ctor_parens;
    i8**       ctor_args;
    i32        ctor_args_len;
}

struct func_decl {
    i32         kind;
    u64         line;
    type_node*  ret_type;
    i8*         name;
    param_decl* params;
    i32         params_len;
    bool        is_variadic;
    i8*         body;        // actually block_stmt*
    bool        has_body;
    bool        is_extern_c;
    i8*         mangled_name;
    i8**        type_params;
    i32         type_params_len;
    bool        is_error_union;
    type_node*  err_type;
    proc_attr*  attributes;
    i32         attributes_len;
    bool        is_attr_macro;   // marked with 'attr' after ')'
    bool        is_derive_macro; // marked with 'derive' after ')'
    bool        is_static;       // marked with 'static'
    bool        is_auto_return;  // true if declared with 'auto' return type (trailing return)
}

struct struct_decl {
    i32         kind;
    u64         line;
    i8*         name;
    var_decl**  fields;
    i32         fields_len;
    i32         fields_cap;
    bool        is_union;
}

struct enum_variant {
    i32         kind;
    u64         line;
    i8*         name;
    i32         variant_kind;  // 0=plain, 1=tuple, 2=named_struct
    expr_node*  plain_val;
    bool        has_plain_val;
}

struct enum_decl {
    i32           kind;
    u64           line;
    i8*           name;
    i8**          variant_names;
    i64*          variant_vals;
    bool*         variant_has_val;
    i32           variants_len;
    i32           variants_cap;
    bool          is_adt;
    // ADT variant payloads: flat arrays, stride=8 per variant
    // variant_kinds[i]: 0=plain, 1=tuple, 2=named_struct, 3=istruc_dot
    // variant_field_names_flat[i*8 + j], variant_field_type_flat[i*8 + j]
    i32*          variant_kinds;
    i32*          variant_field_counts;     // number of fields for each variant
    i8**          variant_field_names_flat; // flat: [vi*8+fi] = field name (i8*)
    i8**          variant_field_type_flat;  // flat: [vi*8+fi] = parser.type_node* as i8*
    // ADT variant methods: flat arrays, stride=8 per variant
    i8**          variant_method_flat;      // flat: [vi*8+mi] = func_decl* as i8*
    i32*          variant_method_counts;    // number of methods per variant
}

struct typedef_decl {
    i32        kind;
    u64        line;
    i8*        name;
    type_node* target;
    bool       is_namespace_using;  // `using ns_name;` — imports all names from namespace
    i8*        ns_using_name;       // the namespace name to import
}

struct namespace_decl {
    i32        kind;
    u64        line;
    i8*        name;
    ast_node** decls;
    i32        decls_len;
    i32        decls_cap;
    i8**       type_params;      // generic type param names (null for non-generic)
    i32        type_params_len;
    bool       is_memstr;        // true when declared with 'memstr' keyword
    bool       is_istruc;        // true when declared with 'istruc'/'interface' (not 'namespace')
    bool       is_interface;     // true when declared with 'interface' keyword
    bool       is_union;         // true when declared as generic union
    i8**       bases;            // base/interface names from ': Base1, Base2'
    i32        bases_len;
    proc_attr* attributes;       // attached #[...] attributes
    i32        attributes_len;
}

struct extern_c_block {
    i32        kind;
    u64        line;
    ast_node** decls;
    i32        decls_len;
    i32        decls_cap;
}

struct program_node {
    i32        kind;
    u64        line;
    ast_node** decls;
    i32        decls_len;
    i32        decls_cap;
}

// ---- Allocation helpers ----

block_stmt* alloc_block_stmt() {
    block_stmt* n = (block_stmt*)arc_malloc(sizeof(parser__NS_block_stmt));
    memset((i8*)n, 0, sizeof(parser__NS_block_stmt));
    n.kind = nd_block;
    return n;
}

void block_stmt_push(block_stmt* blk, ast_node* s) {
    // Always realloc with doubled size (simple growth strategy)
    i32 old_len = blk.stmts_len;
    i32 nc = old_len == 0 ? 16 : old_len * 2;
    if (old_len == 0) {
        blk.stmts = (ast_node**)arc_malloc(sizeof(i8*) * (u64)nc);
    } else {
        blk.stmts = (ast_node**)arc_realloc((i8*)blk.stmts, sizeof(i8*) * (u64)nc);
    }
    blk.stmts[blk.stmts_len] = s;
    blk.stmts_len = blk.stmts_len + 1;
}

// ---- Macro definition (const_resolve) ----

istruc macro_def_t {
    i8*  name;
    i8** param_names;
    i32  param_count;
    i8*  template_toks;   // lexer.token_t* stored as i8*
    i32  template_len;
}

// ---- Parser istruc ----

istruc parser_t {
    lexer.token_t* tokens;
    i32             tokens_len;
    i32             current;
    bool            had_parse_error;
    macro_def_t**  macros;
    i32             macros_len;
    i32             macros_cap;
    ast_node*       pending_anon_var;  // for anonymous istruc per-instance init
    i32             anon_istruc_count; // counter for synthetic names

    void init(parser_t* self, lexer.token_t* toks, i32 len) {
        self.tokens             = toks;
        self.tokens_len         = len;
        self.current            = 0;
        self.had_parse_error    = false;
        self.macros_cap         = 8;
        self.macros_len         = 0;
        self.macros             = (macro_def_t**)arc_malloc(sizeof(i8*) * (u64)8);
        self.pending_anon_var   = (ast_node*)0;
        self.anon_istruc_count  = 0;
    }

    // ---- Token access helpers ----

    lexer.token_t peek_tok(parser_t* self) {
        if (self.current >= self.tokens_len) {
            lexer.token_t t;
            t.type  = eof_t;
            t.value = (i8*)0;
            t.line  = 0;
            return t;
        }
        return self.tokens[self.current];
    }

    lexer.token_t peek_at_tok(parser_t* self, i32 offset) {
        i32 idx = self.current + offset;
        if (idx >= self.tokens_len) {
            lexer.token_t t;
            t.type  = eof_t;
            t.value = (i8*)0;
            t.line  = 0;
            return t;
        }
        return self.tokens[idx];
    }

    lexer.token_t advance_tok(parser_t* self) {
        lexer.token_t t = self.peek_tok();
        if (self.current < self.tokens_len) {
            self.current = self.current + 1;
        }
        return t;
    }

    lexer.token_t previous_tok(parser_t* self) {
        if (self.current > 0) {
            return self.tokens[self.current - 1];
        }
        return self.peek_tok();
    }

    // ---- Field accessor helpers (avoid call().field lvalue issue) ----

    i32 peek_type(parser_t* self) {
        lexer.token_t _t = self.peek_tok();
        return _t.type;
    }

    u64 peek_line(parser_t* self) {
        lexer.token_t _t = self.peek_tok();
        return _t.line;
    }

    i32 peek_at_type(parser_t* self, i32 offset) {
        lexer.token_t _t = self.peek_at_tok(offset);
        return _t.type;
    }

    u64 advance_line_get(parser_t* self) {
        lexer.token_t _t = self.advance_tok();
        return _t.line;
    }

    i8* advance_value_get(parser_t* self) {
        lexer.token_t _t = self.advance_tok();
        return _t.value;
    }

    i32 prev_type(parser_t* self) {
        lexer.token_t _t = self.previous_tok();
        return _t.type;
    }

    u64 prev_line(parser_t* self) {
        lexer.token_t _t = self.previous_tok();
        return _t.line;
    }

    i8* consume_id_value(parser_t* self, i8* err_msg) {
        lexer.token_t _t = self.consume_tok(id, err_msg);
        return _t.value;
    }

    // ---- End helpers ----

    bool check_tok(parser_t* self, i32 type) {
        return self.peek_type() == type;
    }

    bool match_tok(parser_t* self, i32 type) {
        if (self.check_tok(type)) {
            self.advance_tok();
            return true;
        }
        return false;
    }

    bool is_at_end_p(parser_t* self) {
        return self.peek_type() == eof_t;
    }

    lexer.token_t consume_tok(parser_t* self, i32 type, i8* err_msg) {
        if (self.check_tok(type)) {
            return self.advance_tok();
        }
        // Error: print message and set error flag
        lexer.token_t cur = self.peek_tok();
        i8 errbuf[512];
        i8* tok_name = lexer.tok_type_name(cur.type);
        if ((cur.type == id) && cur.value != (i8*)0 && cur.value[0] != 0) {
            snprintf(errbuf, (u64)512, "error at line %d: %s; got %s '%s'",
                     cur.line, err_msg, tok_name, cur.value);
        } else {
            snprintf(errbuf, (u64)512, "error at line %d: %s; got %s",
                     cur.line, err_msg, tok_name);
        }
        printf("%s\n", errbuf);
        self.had_parse_error = true;
        return cur;
    }

    // Consume an identifier-or-keyword token for use as a name (field, member, etc.).
    // Accepts id tokens AND keyword tokens (kw_if and above) since keywords may legally
    // appear as field or member names in Arc source (e.g., `i32 type;`, `tok.type`).
    lexer.token_t consume_name_tok(parser_t* self, i8* err_msg) {
        i32 tt = self.peek_type();
        if (tt == id || tt >= kw_if) {
            return self.advance_tok();
        }
        lexer.token_t cur = self.peek_tok();
        i8 errbuf[512];
        i8* tok_name = lexer.tok_type_name(cur.type);
        snprintf(errbuf, (u64)512, "error at line %d: %s; got %s",
                 cur.line, err_msg, tok_name);
        printf("%s\n", errbuf);
        self.had_parse_error = true;
        return cur;
    }

    // ---- Error recovery ----

    void synchronize(parser_t* self) {
        self.advance_tok();
        while (!self.is_at_end_p()) {
            i32 prev = self.prev_type();
            if (prev == sm) { return; }
            i32 cur = self.peek_type();
            if (cur == kw_if     ||
                cur == kw_while  ||
                cur == kw_for    ||
                cur == kw_return ||
                cur == kw_struct ||
                cur == kw_enum   ||
                cur == cbrace) {
                return;
            }
            self.advance_tok();
        }
    }

    // ---- Macro helpers ----

    macro_def_t* find_macro(parser_t* self, i8* name) {
        i32 mi = 0;
        while (mi < self.macros_len) {
            macro_def_t* m = (macro_def_t*)self.macros[mi];
            if (strcmp(m.name, name) == 0) {
                return m;
            }
            mi = mi + 1;
        }
        return (macro_def_t*)0;
    }

    // Expand a macro call: consumes '(' args ')' from self, returns expanded expr
    expr_node* expand_macro_call(parser_t* self, macro_def_t* mdef) {
        // Collect argument tokens per arg
        i32 arg_buf_cap = 128;
        lexer.token_t* arg_buf = (lexer.token_t*)arc_malloc(sizeof(lexer__NS_token_t) * (u64)arg_buf_cap);
        i32 arg_buf_len = 0;
        i32* arg_starts = (i32*)arc_malloc(sizeof(i32) * (u64)16);
        i32* arg_lens   = (i32*)arc_malloc(sizeof(i32) * (u64)16);
        i32 arg_count = 0;
        i32 cur_arg_start = 0;

        self.consume_tok(oparen, "Expected '(' for macro call");
        i32 depth_m = 0;
        while ((!self.check_tok(cparen) || depth_m > 0) && !self.is_at_end_p()) {
            lexer.token_t at = self.peek_tok();
            if (at.type == oparen) { depth_m = depth_m + 1; }
            else if (at.type == cparen) { depth_m = depth_m - 1; }
            else if (at.type == comma && depth_m == 0) {
                arg_starts[arg_count] = cur_arg_start;
                arg_lens[arg_count]   = arg_buf_len - cur_arg_start;
                arg_count = arg_count + 1;
                cur_arg_start = arg_buf_len;
                self.advance_tok();
                continue;
            }
            if (arg_buf_len >= arg_buf_cap) {
                arg_buf_cap = arg_buf_cap * 2;
                arg_buf = (lexer.token_t*)arc_realloc((i8*)arg_buf, sizeof(lexer__NS_token_t) * (u64)arg_buf_cap);
            }
            arg_buf[arg_buf_len] = at;
            arg_buf_len = arg_buf_len + 1;
            self.advance_tok();
        }
        // last argument
        arg_starts[arg_count] = cur_arg_start;
        arg_lens[arg_count]   = arg_buf_len - cur_arg_start;
        if (arg_buf_len > cur_arg_start) { arg_count = arg_count + 1; }
        self.consume_tok(cparen, "Expected ')' after macro args");

        // Build expanded token list by substituting $param_name with arg tokens
        i32 exp_cap = 256;
        lexer.token_t* exp = (lexer.token_t*)arc_malloc(sizeof(lexer__NS_token_t) * (u64)exp_cap);
        i32 exp_len = 0;
        lexer.token_t* tmpl = (lexer.token_t*)mdef.template_toks;

        i32 ti = 0;
        while (ti < mdef.template_len) {
            lexer.token_t tt = tmpl[ti];
            if (tt.type == dollar && ti + 1 < mdef.template_len) {
                lexer.token_t nt = tmpl[ti + 1];
                if (nt.type == id) {
                    i32 param_idx = -1;
                    i32 pi = 0;
                    while (pi < mdef.param_count) {
                        if (strcmp(mdef.param_names[pi], nt.value) == 0) {
                            param_idx = pi;
                            pi = mdef.param_count; // break
                        }
                        pi = pi + 1;
                    }
                    if (param_idx >= 0 && param_idx < arg_count) {
                        i32 em_s = arg_starts[param_idx];
                        i32 em_l = arg_lens[param_idx];
                        i32 ai = 0;
                        while (ai < em_l) {
                            if (exp_len >= exp_cap) {
                                exp_cap = exp_cap * 2;
                                exp = (lexer.token_t*)arc_realloc((i8*)exp, sizeof(lexer__NS_token_t) * (u64)exp_cap);
                            }
                            exp[exp_len] = arg_buf[em_s + ai];
                            exp_len = exp_len + 1;
                            ai = ai + 1;
                        }
                    }
                    ti = ti + 2;
                    continue;
                }
            }
            if (exp_len >= exp_cap) {
                exp_cap = exp_cap * 2;
                exp = (lexer.token_t*)arc_realloc((i8*)exp, sizeof(lexer__NS_token_t) * (u64)exp_cap);
            }
            exp[exp_len] = tt;
            exp_len = exp_len + 1;
            ti = ti + 1;
        }
        // append EOF
        if (exp_len >= exp_cap) {
            exp_cap = exp_cap + 1;
            exp = (lexer.token_t*)arc_realloc((i8*)exp, sizeof(lexer__NS_token_t) * (u64)exp_cap);
        }
        lexer.token_t eoft;
        eoft.type  = eof_t;
        eoft.value = (i8*)0;
        eoft.line  = 0;
        exp[exp_len] = eoft;
        exp_len = exp_len + 1;

        // Parse expanded tokens with a sub-parser.
        // Try parse_stmt first (handles `i32 y = expr` macro bodies), then fall back to parse_expr.
        parser_t sub;
        sub.init(exp, exp_len);
        sub.macros     = self.macros;
        sub.macros_len = self.macros_len;
        sub.macros_cap = self.macros_cap;

        expr_node* result = (expr_node*)0;
        bool saved_parse_err = self.had_parse_error;  // save main parser error state
        if (sub.is_type_start()) {
            // Expanded tokens start with a type → parse as a statement (var decl)
            ast_node* stmt_result = sub.parse_stmt();
            result = (expr_node*)stmt_result;
        } else {
            result = sub.parse_expr();
        }
        // Sub-parser errors are internal; don't propagate to main parser
        if (!sub.had_parse_error) {
            ; // ok
        }

        arc_free((i8*)exp);
        arc_free((i8*)arg_buf);
        arc_free((i8*)arg_starts);
        arc_free((i8*)arg_lens);
        return result;
    }

    // ---- Type start detection ----

    bool is_type_start(parser_t* self) {
        i32 tt = self.peek_type();
        if (tt == question) { return true; }
        if (tt == addr && self.peek_at_type(1) == kw_smem) { return true; }
        if (tt == kw_type)     { return true; }
        if (tt == kw_const)    { return true; }
        if (tt == kw_volatile) { return true; }
        if (tt == kw_signed)   { return true; }
        if (tt == kw_unsigned) { return true; }
        if (tt == kw_extern)   { return true; }
        if (tt == kw_extern_c) { return true; }
        if (tt == kw_inline)   { return true; }
        if (tt == kw_auto)     { return true; }
        if (tt == kw_char)     { return true; }
        if (tt == kw_void)     { return true; }
        if (tt == kw_arb_int)  { return true; }
        if (tt == kw_arb_uint) { return true; }
        if (tt == kw_arb_float){ return true; }
        if (tt == kw_arb_bool)     { return true; }
        if (tt == kw_arb_rational) { return true; }
        if (tt == kw_arb_complex)  { return true; }
        if (tt == kw_arb_char_w)   { return true; }
        if (tt == kw_arb_str_w)    { return true; }
        if (tt == kw_arb_nat)      { return true; }
        if (tt == kw_arb_zint)     { return true; }
        if (tt == kw_arb_real)     { return true; }
        if (tt == kw_arb_alg)      { return true; }
        if (tt == kw_struct)    { return true; }
        if (tt == kw_enum)      { return true; }
        if (tt == kw_union)     { return true; }
        if (tt == kw_smem)      { return true; }
        if (tt == kw_token_type){ return true; }
        if (tt == kw_interface) { return true; }
        // id followed by id = user-defined type
        if (tt == id && self.peek_at_type(1) == id) { return true; }
        // namespace.Type: id.id id or id.id* or id.Generic<T> id
        if (tt == id && self.peek_at_type(1) == dot) {
            if (self.peek_at_type(2) == id) {
                // Check what follows the qualified name
                i32 k = 3;
                // skip more dots (for nested namespaces)
                bool searching = true;
                while (searching && self.peek_at_type(k) == dot
                       && self.peek_at_type(k + 1) == id) {
                    k = k + 2;
                }
                // skip generic type args: ns.Type<T, U>
                if (self.peek_at_type(k) == lt) {
                    i32 depth_ns = 0;
                    i32 j = k;
                    bool ok_ns = true;
                    while (ok_ns && j < k + 80) {
                        i32 tns = self.peek_at_type(j);
                        if (tns == lt)   { depth_ns = depth_ns + 1; j = j + 1; }
                        else if (tns == gt) {
                            depth_ns = depth_ns - 1;
                            j = j + 1;
                            if (depth_ns == 0) { k = j; ok_ns = false; }
                        }
                        else if (tns == eof_t || tns == sm || tns == obrace) { ok_ns = false; }
                        else { j = j + 1; }
                    }
                }
                // skip stars
                while (self.peek_at_type(k) == ast) { k = k + 1; }
                i32 after = self.peek_at_type(k);
                if (after == id) { return true; }
            }
        }
        // id* id = pointer to user type
        if (tt == id) {
            i32 k = 1;
            while (self.peek_at_type(k) == ast) { k = k + 1; }
            if (k > 1 && self.peek_at_type(k) == id) { return true; }
        }
        // Generic type: id<...> id — scan past balanced <> to check for trailing id
        if (tt == id && self.peek_at_type(1) == lt) {
            i32 k2 = 2;
            i32 depth2 = 1;
            while (depth2 > 0 && self.peek_at_type(k2) != eof_t) {
                i32 t2 = self.peek_at_type(k2);
                if (t2 == lt)  { depth2 = depth2 + 1; }
                else if (t2 == gt)  { depth2 = depth2 - 1; }
                else if (t2 == right) { depth2 = depth2 - 2; }
                // Generic type args cannot span statement boundaries
                else if (t2 == sm || t2 == obrace || t2 == cbrace) { break; }
                k2 = k2 + 1;
            }
            // After >, skip optional pointer stars
            while (self.peek_at_type(k2) == ast) { k2 = k2 + 1; }
            if (self.peek_at_type(k2) == id) { return true; }
        }
        return false;
    }

    // Like is_type_start() but also accepts id**) patterns for cast expressions, e.g. (T**)0
    bool is_cast_start(parser_t* self) {
        if (self.is_type_start()) { return true; }
        i32 tt = self.peek_type();
        if (tt == id) {
            i32 k = 1;
            // skip namespace qualifiers: ns.Type
            while (self.peek_at_type(k) == dot && self.peek_at_type(k + 1) == id) { k = k + 2; }
            // skip pointer stars
            while (self.peek_at_type(k) == ast) { k = k + 1; }
            if (k > 1 && self.peek_at_type(k) == cparen) { return true; }
        }
        return false;
    }

    // ---- Type parsing ----

    type_node* parse_type(parser_t* self) {
        type_node* t = alloc_type_node();

        // nullable: ?T
        if (self.check_tok(question)) {
            self.advance_tok();
            type_node* inner = self.parse_type();
            inner.is_nullable = true;
            arc_free((i8*)t);
            return inner;
        }

        // C++ reference: &T — treat as T* for bootstrap; &memstr is a fat pointer
        if (self.check_tok(addr)) {
            self.advance_tok();
            type_node* inner = self.parse_type();
            inner.pointer_depth = inner.pointer_depth + 1;
            if (inner.name != (i8*)0 && strcmp(inner.name, "memstr") == 0) {
                inner.is_memstr_ref = true;
            }
            arc_free((i8*)t);
            return inner;
        }

        // storage class
        bool parsing_storage = true;
        while (parsing_storage) {
            if (self.match_tok(kw_extern))   { t.is_extern = true; }
            else if (self.match_tok(kw_extern_c)) { t.is_extern = true; t.is_extern_c = true; }
            else if (self.match_tok(kw_inline))  { t.is_inline = true; }
            else { parsing_storage = false; }
        }

        // qualifiers
        bool parsing_qual = true;
        while (parsing_qual) {
            if (self.match_tok(kw_const))    { t.is_const = true; }
            else if (self.match_tok(kw_volatile)) { t.is_volatile = true; }
            else { parsing_qual = false; }
        }
        if (self.match_tok(kw_signed))   { t.is_signed = true; }
        if (self.match_tok(kw_unsigned)) { t.is_signed = false; }

        // interface NAME — parameter type for fat-pointer dispatch
        if (self.check_tok(kw_interface)) {
            self.advance_tok(); // consume 'interface'
            t.is_interface = true;
            t.is_primitive = false;
            if (self.check_tok(id)) {
                t.name = lexer.str_dup(self.advance_value_get());
            } else {
                t.name = lexer.str_dup("interface");
            }
            // Consume optional generic type args <T>
            if (self.check_tok(lt)) {
                self.advance_tok();
                i32 dep = 1;
                while (dep > 0 && !self.is_at_end_p()) {
                    if (self.check_tok(lt)) { dep = dep + 1; }
                    else if (self.check_tok(gt)) { dep = dep - 1; }
                    self.advance_tok();
                }
            }
            // Consume trailing pointer stars
            while (self.check_tok(ast)) {
                self.advance_tok();
                t.pointer_depth = t.pointer_depth + 1;
            }
            return t;
        }

        // comptime type (formerly sta)
        if (self.check_tok(kw_type)) {
            self.advance_tok();
            t.is_sta = true;
            t.is_primitive = false;
            t.name = lexer.str_dup("sta");
            return t;
        }

        // auto
        if (self.check_tok(kw_auto)) {
            self.advance_tok();
            t.is_auto = true;
            t.is_primitive = false;
            while (self.check_tok(ast)) {
                self.advance_tok();
                t.pointer_depth = t.pointer_depth + 1;
            }
            return t;
        }

        bool found = false;
        if (self.match_tok(kw_char)) {
            t.prim = char_t; t.bit_width = 8; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.match_tok(kw_void)) {
            t.prim = void_t; t.bit_width = 0; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(kw_arb_int)) {
            lexer.token_t w = self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_int; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(kw_arb_uint)) {
            lexer.token_t w = self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_uint; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(kw_arb_float)) {
            lexer.token_t w = self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_float; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(kw_arb_bool)) {
            lexer.token_t w = self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_bool; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(kw_arb_rational)) {
            lexer.token_t w = self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_rational; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(kw_arb_complex)) {
            lexer.token_t w = self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_complex; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(kw_arb_char_w)) {
            lexer.token_t w = self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_char_w; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(kw_arb_str_w)) {
            lexer.token_t w = self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_str_w; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(kw_arb_nat)) {
            lexer.token_t w = self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_nat; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(kw_arb_zint)) {
            lexer.token_t w = self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_zint; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(kw_arb_real)) {
            lexer.token_t w = self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_real; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(kw_arb_alg)) {
            lexer.token_t w = self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_alg; t.is_primitive = true; t.has_prim = true; found = true;
        }

        if (!found && self.check_tok(kw_smem)) {
            self.advance_tok();
            t.name = lexer.str_dup("memstr");
            found = true;
        }

        if (!found) {
            lexer.token_t name_tok = self.consume_tok(id, "Expected type name");
            t.name = lexer.str_dup(name_tok.value);

            // namespace-qualified: ns.Type
            bool ns_loop = true;
            while (ns_loop && self.check_tok(dot)) {
                i32 next_type = self.peek_at_type(1);
                if (next_type == id) {
                    self.advance_tok();  // consume dot
                    lexer.token_t sub = self.advance_tok();

                    // Build qualified name: old__NS_sub
                    i8 newname[1024];
                    snprintf(newname, (u64)1024, "%s__NS_%s", t.name, sub.value);
                    arc_free(t.name);
                    t.name = lexer.str_dup(newname);
                } else {
                    ns_loop = false;
                }
            }

            // Generic type parameters: Type<A, B> — parse and store for monomorphization
            if (self.check_tok(lt)) {
                self.advance_tok(); // consume '<'
                type_node** ta_arr = (type_node**)arc_malloc(sizeof(i8*) * 16);
                i32 ta_len = 0;
                while (!self.check_tok(gt) && !self.is_at_end_p()) {
                    if (self.is_type_start()) {
                        type_node* ta = self.parse_type();
                        if (ta_len < 16) {
                            ta_arr[ta_len] = ta;
                            ta_len = ta_len + 1;
                        }
                        self.match_tok(comma);
                    } else {
                        self.advance_tok(); // skip unknown tokens
                    }
                }
                self.match_tok(gt);
                t.type_args = (i8**)ta_arr;
                t.type_args_len = ta_len;
            }
        }

        // pointer stars
        while (self.check_tok(ast)) {
            self.advance_tok();
            t.pointer_depth = t.pointer_depth + 1;
        }

        // function pointer detection: type(params)*
        if (self.check_tok(oparen)) {
            i32 saved = self.current;
            self.advance_tok();  // consume (

            // Try to parse as function pointer params
            type_ptr_vec fp_params;
            type_ptr_vec_init(&fp_params);
            str_vec fp_names;
            str_vec_init(&fp_names);
            bool fp_variadic = false;
            bool ok = true;

            if (!self.check_tok(cparen)) {
                bool parsing_fp = true;
                while (ok && parsing_fp) {
                    if (self.check_tok(dot) &&
                        self.peek_at_type(1) == dot &&
                        self.peek_at_type(2) == dot) {
                        self.advance_tok(); self.advance_tok(); self.advance_tok();
                        fp_variadic = true;
                        parsing_fp = false;
                    } else if (self.is_type_start()) {
                        type_node* pt = self.parse_type();
                        type_ptr_vec_push(&fp_params, pt);
                        i8* pname = (i8*)0;
                        if (self.check_tok(id)) {
                            pname = lexer.str_dup(self.advance_value_get());
                        }
                        str_vec_push(&fp_names, pname);
                        if (!self.match_tok(comma)) {
                            parsing_fp = false;
                        }
                    } else {
                        ok = false;
                    }
                }
            }

            if (ok && self.check_tok(cparen)) {
                self.advance_tok();  // consume )
                if (self.check_tok(ast)) {
                    self.advance_tok();  // consume *
                    // This IS a function pointer type
                    type_node* fp_t = alloc_type_node();
                    fp_t.is_func_ptr     = true;
                    fp_t.fp_ret          = (i8*)t;
                    fp_t.fp_params       = (i8**)fp_params.data;
                    fp_t.fp_params_len   = fp_params.len;
                    fp_t.fp_param_names  = fp_names.data;
                    fp_t.fp_param_names_len = fp_names.len;
                    fp_t.fp_variadic     = fp_variadic;
                    fp_t.pointer_depth   = 1;
                    return fp_t;
                }
            }
            // Not a function pointer; restore
            self.current = saved;
        }

        // array brackets
        if (self.match_tok(obracket)) {
            if (!self.check_tok(cbracket)) {
                expr_node* sz = self.parse_expr();
                t.array_size_ptr = (i8*)sz;
            }
            self.consume_tok(cbracket, "Expected ']' after array size");
        }

        return t;
    }

    // ---- Variable body ----

    var_decl* parse_var_body(parser_t* self, type_node* ty, lexer.token_t name_tok) {
        var_decl* vd = (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
        memset((i8*)vd, 0, sizeof(parser__NS_var_decl));
        vd.kind     = nd_var_decl;
        vd.line     = (u64)name_tok.line;
        vd.type     = ty;
        vd.name     = lexer.str_dup(name_tok.value);

        // Array size after name: int arr[10]
        if (self.match_tok(obracket)) {
            if (!self.check_tok(cbracket)) {
                ty.array_size_ptr = (i8*)self.parse_expr();
            }
            self.consume_tok(cbracket, "Expected ']' after array size");
        }
        // Constructor call: TypeName varname(args...)
        if (self.match_tok(oparen)) {
            vd.has_ctor_parens = true;
            i32 ctor_cap = 4;
            vd.ctor_args = (i8**)arc_malloc(sizeof(i8*) * (u64)ctor_cap);
            vd.ctor_args_len = 0;
            if (!self.check_tok(cparen)) {
                bool p_ctor = true;
                while (p_ctor) {
                    if (vd.ctor_args_len >= ctor_cap) {
                        ctor_cap = ctor_cap * 2;
                        vd.ctor_args = (i8**)arc_realloc((i8*)vd.ctor_args, sizeof(i8*) * (u64)ctor_cap);
                    }
                    vd.ctor_args[vd.ctor_args_len] = (i8*)self.parse_assignment();
                    vd.ctor_args_len = vd.ctor_args_len + 1;
                    if (!self.match_tok(comma)) { p_ctor = false; }
                }
            }
            self.consume_tok(cparen, "Expected ')' after constructor args");
        } else if (self.match_tok(assign)) {
            vd.init     = self.parse_expr();
            vd.has_init = true;
        }
        self.consume_tok(sm, "Expected ';' after variable declaration");
        return vd;
    }

    // ---- Function body ----

    func_decl* parse_func_body(parser_t* self, type_node* ret, lexer.token_t name_tok, bool extern_c) {
        func_decl* fd = (func_decl*)arc_malloc(sizeof(parser__NS_func_decl));
        memset((i8*)fd, 0, sizeof(parser__NS_func_decl));
        fd.kind        = nd_func_decl;
        fd.line        = (u64)name_tok.line;
        fd.ret_type    = ret;
        fd.name        = lexer.str_dup(name_tok.value);
        fd.is_extern_c = extern_c;
        if (ret != (type_node*)0 && (ret.is_extern_c || ret.is_extern)) {
            fd.is_extern_c = true;
        }

        // Parse parameters
        i32 params_cap = 8;
        fd.params     = (param_decl*)arc_malloc(sizeof(parser__NS_param_decl) * (u64)params_cap);
        fd.params_len = 0;

        if (!self.check_tok(cparen)) {
            bool parsing_params = true;
            while (parsing_params) {
                if (self.check_tok(dot) &&
                    self.peek_at_type(1) == dot &&
                    self.peek_at_type(2) == dot) {
                    self.advance_tok(); self.advance_tok(); self.advance_tok();
                    fd.is_variadic = true;
                    parsing_params = false;
                } else {
                    if (fd.params_len >= params_cap) {
                        params_cap = params_cap * 2;
                        fd.params = (param_decl*)arc_realloc((i8*)fd.params, sizeof(parser__NS_param_decl) * (u64)params_cap);
                    }
                    type_node* pt = self.parse_type();
                    i8* pname = (i8*)0;
                    if (self.check_tok(id) || self.peek_type() >= kw_if) {
                        pname = lexer.str_dup(self.advance_value_get());
                    }
                    param_decl p;
                    p.type = pt;
                    p.name = pname;
                    p.line = (u64)self.prev_line();
                    fd.params[fd.params_len] = p;
                    fd.params_len = fd.params_len + 1;

                    if (!self.match_tok(comma)) {
                        parsing_params = false;
                    }
                }
            }
        }
        self.consume_tok(cparen, "Expected ')' after parameters");

        // Proc-macro markers: attr, derive (may appear after ')' and before '{')
        if (self.check_tok(kw_attr)) {
            self.advance_tok();
            fd.is_attr_macro = true;
            // Optional named category after 'attr' (e.g. 'attr verify')
            if (self.check_tok(id)) { self.advance_tok(); }
        } else if (self.check_tok(kw_derive)) {
            self.advance_tok();
            fd.is_derive_macro = true;
        }

        // Trailing return type for auto
        if (ret != (type_node*)0 && ret.is_auto) {
            fd.is_auto_return = true;
            if (self.check_tok(not_)) {
                self.advance_tok();
                fd.ret_type        = self.parse_type();
                fd.is_error_union  = true;
                fd.err_type        = (type_node*)0;
            } else if (self.is_type_start()) {
                fd.ret_type = self.parse_type();
            }
        }

        // Member initializer lists (: field(val)) are no longer supported.
        // Use explicit assignments in the constructor body instead.
        // A ':' here is a parse error.
        if (self.check_tok(colon)) {
            lexer.token_t colon_tok = self.peek_tok();
            printf("error at line %d: member initializer lists not supported; assign fields in the constructor body instead\n", (i32)colon_tok.line);
            self.had_parse_error = true;
            // Skip the malformed init list so we can continue parsing
            self.advance_tok(); // consume ':'
            while (!self.is_at_end_p() && !self.check_tok(obrace) && !self.check_tok(sm)) {
                self.advance_tok();
            }
        }

        if (self.match_tok(sm)) {
            fd.body     = (i8*)0;
            fd.has_body = false;
        } else {
            block_stmt* blk_nd = self.parse_block();
            fd.body     = (i8*)blk_nd;
            fd.has_body = true;
        }
        return fd;
    }

    // ---- Top-level declaration dispatch ----

    ast_node* parse_func_or_var_decl(parser_t* self) {
        bool is_cexpr = false;
        if (self.check_tok(kw_comptime)) {
            self.advance_tok(); is_cexpr = true;
            // comptime type T = SomeType; — first-class type alias at top level
            if (self.check_tok(kw_type) && self.peek_at_type(1) == id) {
                self.advance_tok(); // consume 'type'
                typedef_decl* td = (typedef_decl*)arc_malloc(sizeof(parser__NS_typedef_decl));
                memset((i8*)td, 0, sizeof(parser__NS_typedef_decl));
                td.kind = nd_typedef_decl;
                td.name = lexer.str_dup(self.consume_id_value("Expected name after 'comptime type'"));
                self.consume_tok(assign, "Expected '=' after type alias name");
                td.target = self.parse_type();
                self.match_tok(sm);
                return (ast_node*)td;
            }
        }

        type_node* ret = self.parse_type();

        // Error union: !T or E!T
        bool is_err_union = false;
        type_node* err_type = (type_node*)0;
        if (self.check_tok(not_) && self.peek_at_type(1) != assign) {
            is_err_union = true;
            err_type     = ret;
            self.advance_tok();  // consume !
            ret = self.parse_type();
        }

        // Handle operator overloads: "RetType operator+(...)
        if (self.check_tok(kw_operator)) {
            self.advance_tok(); // consume 'operator'
            // Build operator name from the symbol that follows
            i8 op_name[64];
            i32 tt2 = self.peek_type();
            // Consume the operator symbol(s)
            lexer.token_t op_tok = self.advance_tok();
            // Handle two-character operators (==, !=, <=, >=, +=, etc.)
            i32 tt3 = self.peek_type();
            if ((tt2 == assign || tt2 == lt || tt2 == gt || tt2 == not_ || tt2 == plus || tt2 == minus || tt2 == ast || tt2 == slash) &&
                    (tt3 == assign)) {
                self.advance_tok();
                snprintf(op_name, (u64)64, "operator%s=", op_tok.value);
            } else if (tt2 == obracket) {
                // operator[] — subscript operator; consume the closing ']'
                self.advance_tok();
                snprintf(op_name, (u64)64, "operator[]");
            } else if (tt2 == kw_arb_int) {
                snprintf(op_name, (u64)64, "operator_i%s", op_tok.value);
            } else if (tt2 == kw_arb_uint) {
                snprintf(op_name, (u64)64, "operator_u%s", op_tok.value);
            } else if (tt2 == kw_arb_float) {
                snprintf(op_name, (u64)64, "operator_f%s", op_tok.value);
            } else {
                snprintf(op_name, (u64)64, "operator%s", op_tok.value);
            }
            lexer.token_t name_tok2;
            name_tok2.type  = id;
            name_tok2.value = lexer.str_dup(op_name);
            name_tok2.line  = op_tok.line;
            self.consume_tok(oparen, "Expected '(' after operator name");
            func_decl* fd2 = self.parse_func_body(ret, name_tok2, false);
            if (is_err_union) { fd2.is_error_union = true; fd2.err_type = err_type; }
            return (ast_node*)fd2;
        }

        lexer.token_t name_tok = self.consume_tok(id, "Expected declaration name");

        // Parse generic type params: funcname<T, U>(...)
        i8** gtp_buf = (i8**)0;
        i32  gtp_len = 0;
        if (self.check_tok(lt)) {
            i32 gtp_cap = 4;
            gtp_buf = (i8**)arc_malloc(sizeof(i8*) * (u64)gtp_cap);
            self.advance_tok(); // consume '<'
            i32 depth_gf = 1;
            while (depth_gf > 0 && !self.is_at_end_p()) {
                i32 tgf = self.peek_type();
                if (tgf == gt && depth_gf == 1) {
                    depth_gf = 0; self.advance_tok();
                } else if (tgf == lt) { depth_gf = depth_gf + 1; self.advance_tok(); }
                else if (tgf == gt)   { depth_gf = depth_gf - 1; self.advance_tok(); }
                else if (tgf == right && depth_gf <= 2) { depth_gf = 0; self.advance_tok(); }
                else if (tgf == id) {
                    lexer.token_t tp_tok = self.advance_tok();
                    if (gtp_len >= gtp_cap) {
                        gtp_cap = gtp_cap * 2;
                        gtp_buf = (i8**)arc_realloc((i8*)gtp_buf, sizeof(i8*) * (u64)gtp_cap);
                    }
                    gtp_buf[gtp_len] = lexer.str_dup(tp_tok.value);
                    gtp_len = gtp_len + 1;
                } else { self.advance_tok(); }
            }
        }

        if (self.match_tok(oparen)) {
            func_decl* fd = self.parse_func_body(ret, name_tok, false);
            if (gtp_len > 0) {
                fd.type_params     = gtp_buf;
                fd.type_params_len = gtp_len;
            } else if (gtp_buf != (i8**)0) {
                arc_free((i8*)gtp_buf);
            }
            if (is_err_union) { fd.is_error_union = true; fd.err_type = err_type; }
            return (ast_node*)fd;
        }
        if (gtp_buf != (i8**)0) { arc_free((i8*)gtp_buf); }

        // Trailing type: auto name: type = expr;
        if (ret.is_auto && self.check_tok(colon)) {
            self.advance_tok();
            ret = self.parse_type();
        }
        var_decl* vd = self.parse_var_body(ret, name_tok);
        vd.is_constexpr = is_cexpr;
        if (ret.is_sta) { vd.is_sta = true; }
        return (ast_node*)vd;
    }

    ast_node* parse_func_or_var_decl_extern_c(parser_t* self) {
        type_node* ret = self.parse_type();
        lexer.token_t name_tok = self.consume_tok(id, "Expected declaration name");
        if (self.match_tok(oparen)) {
            func_decl* fd = self.parse_func_body(ret, name_tok, true);
            fd.is_extern_c = true;
            return (ast_node*)fd;
        }
        return (ast_node*)self.parse_var_body(ret, name_tok);
    }

    struct_decl* parse_struct_decl(parser_t* self) {
        u64 ln = (u64)self.peek_line();
        self.advance_tok();  // consume 'struct'
        struct_decl* sd = (struct_decl*)arc_malloc(sizeof(parser__NS_struct_decl));
        memset((i8*)sd, 0, sizeof(parser__NS_struct_decl));
        sd.kind = nd_struct_decl;
        sd.line = ln;
        sd.name = lexer.str_dup(self.consume_id_value("Expected struct name"));
        sd.fields_cap = 8;
        sd.fields = (var_decl**)arc_malloc(sizeof(i8*) * (u64)sd.fields_cap);
        self.consume_tok(obrace, "Expected '{' after struct name");

        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            type_node* ft = self.parse_type();
            lexer.token_t fname = self.consume_name_tok("Expected field name");
            var_decl* vd = (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
            memset((i8*)vd, 0, sizeof(parser__NS_var_decl));
            vd.kind = nd_var_decl;
            vd.line = (u64)fname.line;
            vd.type = ft;
            vd.name = lexer.str_dup(fname.value);

            if (self.match_tok(obracket)) {
                if (!self.check_tok(cbracket)) {
                    ft.array_size_ptr = (i8*)self.parse_expr();
                }
                self.consume_tok(cbracket, "Expected ']' after array size");
            }
            self.consume_tok(sm, "Expected ';' after field");

            if (sd.fields_len >= sd.fields_cap) {
                sd.fields_cap = sd.fields_cap * 2;
                sd.fields = (var_decl**)arc_realloc((i8*)sd.fields, sizeof(i8*) * (u64)sd.fields_cap);
            }
            sd.fields[sd.fields_len] = vd;
            sd.fields_len = sd.fields_len + 1;
        }
        self.consume_tok(cbrace, "Expected '}' after struct body");
        return sd;
    }

    ast_node* parse_union_decl(parser_t* self) {
        u64 ln = (u64)self.peek_line();
        self.advance_tok(); // consume 'union'
        lexer.token_t uname = self.consume_tok(id, "Expected union name");

        // Parse optional generic type params: <T, U, ...>
        i8* tp_names[16];
        i32 tp_count = 0;
        if (self.check_tok(lt)) {
            self.advance_tok(); // consume '<'
            while (!self.check_tok(gt) && !self.is_at_end_p()) {
                if (self.check_tok(id) && tp_count < 16) {
                    lexer.token_t tp_tok = self.peek_tok();
                    tp_names[tp_count] = lexer.str_dup(tp_tok.value);
                    tp_count = tp_count + 1;
                    self.advance_tok();
                } else { self.advance_tok(); }
                self.match_tok(comma);
            }
            self.match_tok(gt);
        }

        // Parse body (fields)
        struct_decl* sd = (struct_decl*)arc_malloc(sizeof(parser__NS_struct_decl));
        memset((i8*)sd, 0, sizeof(parser__NS_struct_decl));
        sd.kind = nd_struct_decl;
        sd.line = ln;
        sd.name = lexer.str_dup(uname.value);
        sd.is_union = true;
        sd.fields_cap = 8;
        sd.fields = (var_decl**)arc_malloc(sizeof(i8*) * (u64)sd.fields_cap);
        self.consume_tok(obrace, "Expected '{' after union name");
        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            type_node* ft = self.parse_type();
            lexer.token_t fname = self.consume_name_tok("Expected field name");
            var_decl* vd = (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
            memset((i8*)vd, 0, sizeof(parser__NS_var_decl));
            vd.kind = nd_var_decl;
            vd.line = (u64)fname.line;
            vd.type = ft;
            vd.name = lexer.str_dup(fname.value);
            if (self.match_tok(obracket)) {
                if (!self.check_tok(cbracket)) { ft.array_size_ptr = (i8*)self.parse_expr(); }
                self.consume_tok(cbracket, "Expected ']' after array size");
            }
            self.consume_tok(sm, "Expected ';' after union field");
            if (sd.fields_len >= sd.fields_cap) {
                sd.fields_cap = sd.fields_cap * 2;
                sd.fields = (var_decl**)arc_realloc((i8*)sd.fields, sizeof(i8*) * (u64)sd.fields_cap);
            }
            sd.fields[sd.fields_len] = vd;
            sd.fields_len = sd.fields_len + 1;
        }
        self.consume_tok(cbrace, "Expected '}' after union body");

        if (tp_count == 0) {
            return (ast_node*)sd;
        }

        // Generic union: wrap in namespace_decl so generic_classes registration works
        namespace_decl* nd = (namespace_decl*)arc_malloc(sizeof(parser__NS_namespace_decl));
        memset((i8*)nd, 0, sizeof(parser__NS_namespace_decl));
        nd.kind = nd_namespace_decl;
        nd.line = ln;
        nd.name = lexer.str_dup(uname.value);
        nd.is_union = true;
        nd.decls_cap = 4;
        nd.decls = (ast_node**)arc_malloc(sizeof(i8*) * (u64)nd.decls_cap);
        nd.decls[0] = (ast_node*)sd;
        nd.decls_len = 1;
        nd.type_params = (i8**)arc_malloc(sizeof(i8*) * (u64)tp_count);
        i32 tpi = 0;
        while (tpi < tp_count) {
            nd.type_params[tpi] = tp_names[tpi];
            tpi = tpi + 1;
        }
        nd.type_params_len = tp_count;
        return (ast_node*)nd;
    }

    ast_node* parse_enum_decl(parser_t* self) {
        u64 ln = (u64)self.peek_line();
        self.advance_tok();  // consume 'enum'
        enum_decl* ed = (enum_decl*)arc_malloc(sizeof(parser__NS_enum_decl));
        memset((i8*)ed, 0, sizeof(parser__NS_enum_decl));
        ed.kind = nd_enum_decl;
        ed.line = ln;
        i8* enum_name = lexer.str_dup(self.consume_id_value("Expected enum name"));
        ed.name = enum_name;

        // Parse optional generic type params: <T, U, ...>
        i8* etp_names[16];
        i32 etp_count = 0;
        if (self.check_tok(lt)) {
            self.advance_tok(); // consume '<'
            while (!self.check_tok(gt) && !self.is_at_end_p()) {
                if (self.check_tok(id) && etp_count < 16) {
                    lexer.token_t etp_tok = self.peek_tok();
                    etp_names[etp_count] = lexer.str_dup(etp_tok.value);
                    etp_count = etp_count + 1;
                    self.advance_tok();
                } else { self.advance_tok(); }
                self.match_tok(comma);
            }
            self.match_tok(gt);
        }

        ed.variants_cap = 16;
        ed.variant_names        = (i8**)arc_malloc(sizeof(i8*) * (u64)ed.variants_cap);
        ed.variant_vals         = (i64*)arc_malloc(sizeof(i64) * (u64)ed.variants_cap);
        ed.variant_has_val      = (bool*)arc_malloc(sizeof(bool) * (u64)ed.variants_cap);
        ed.variant_kinds        = (i32*)arc_malloc(sizeof(i32) * (u64)ed.variants_cap);
        ed.variant_field_counts = (i32*)arc_malloc(sizeof(i32) * (u64)ed.variants_cap);
        ed.variant_field_names_flat = (i8**)arc_malloc(sizeof(i8*) * (u64)(ed.variants_cap * 8));
        ed.variant_field_type_flat  = (i8**)arc_malloc(sizeof(i8*) * (u64)(ed.variants_cap * 8));
        ed.variant_method_flat      = (i8**)arc_malloc(sizeof(i8*) * (u64)(ed.variants_cap * 8));
        ed.variant_method_counts    = (i32*)arc_malloc(sizeof(i32) * (u64)ed.variants_cap);
        self.consume_tok(obrace, "Expected '{' after enum name");

        i64 next_val = 0;
        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            lexer.token_t var_name = self.consume_tok(id, "Expected variant name");

            // Grow if needed
            if (ed.variants_len >= ed.variants_cap) {
                ed.variants_cap = ed.variants_cap * 2;
                ed.variant_names        = (i8**)arc_realloc((i8*)ed.variant_names,        sizeof(i8*) * (u64)ed.variants_cap);
                ed.variant_vals         = (i64*)arc_realloc((i8*)ed.variant_vals,         sizeof(i64) * (u64)ed.variants_cap);
                ed.variant_has_val      = (bool*)arc_realloc((i8*)ed.variant_has_val,      sizeof(bool) * (u64)ed.variants_cap);
                ed.variant_kinds        = (i32*)arc_realloc((i8*)ed.variant_kinds,        sizeof(i32) * (u64)ed.variants_cap);
                ed.variant_field_counts = (i32*)arc_realloc((i8*)ed.variant_field_counts, sizeof(i32) * (u64)ed.variants_cap);
                ed.variant_field_names_flat = (i8**)arc_realloc((i8*)ed.variant_field_names_flat, sizeof(i8*) * (u64)(ed.variants_cap * 8));
                ed.variant_field_type_flat  = (i8**)arc_realloc((i8*)ed.variant_field_type_flat,  sizeof(i8*) * (u64)(ed.variants_cap * 8));
                ed.variant_method_flat      = (i8**)arc_realloc((i8*)ed.variant_method_flat,      sizeof(i8*) * (u64)(ed.variants_cap * 8));
                ed.variant_method_counts    = (i32*)arc_realloc((i8*)ed.variant_method_counts,    sizeof(i32) * (u64)ed.variants_cap);
            }

            i32 vi = ed.variants_len;
            ed.variant_names[vi]          = lexer.str_dup(var_name.value);
            ed.variant_kinds[vi]          = 0; // plain by default
            ed.variant_field_counts[vi]   = 0;
            ed.variant_method_counts[vi]  = 0;
            // Init flat slots for this variant (stride 8)
            {
                i32 si = 0;
                while (si < 8) {
                    ed.variant_field_names_flat[vi * 8 + si] = (i8*)0;
                    ed.variant_field_type_flat[vi * 8 + si]  = (i8*)0;
                    ed.variant_method_flat[vi * 8 + si]      = (i8*)0;
                    si = si + 1;
                }
            }

            // ADT tuple variant: Variant(type1, type2, ...)
            if (self.check_tok(oparen)) {
                self.advance_tok(); // consume '('
                ed.variant_kinds[vi] = 1; // tuple
                ed.is_adt = true;
                i32 fc = 0;
                while (!self.check_tok(cparen) && !self.is_at_end_p() && fc < 8) {
                    type_node* ft = self.parse_type();
                    ed.variant_field_type_flat[vi * 8 + fc]  = (i8*)ft;
                    ed.variant_field_names_flat[vi * 8 + fc] = (i8*)0;
                    fc = fc + 1;
                    self.match_tok(comma);
                }
                self.consume_tok(cparen, "Expected ')' in tuple variant");
                ed.variant_field_counts[vi] = fc;
            }

            // ADT named struct / istruc variant: Variant { ... } or Variant .{ ... }
            bool has_dot_brace = self.check_tok(dot);
            if (has_dot_brace) { self.advance_tok(); } // consume optional '.'
            if (self.check_tok(obrace)) {
                self.advance_tok(); // consume '{'
                ed.is_adt = true;
                ed.variant_kinds[vi] = has_dot_brace ? 3 : 2; // 3=istruc_dot, 2=named_struct
                i32 fc = 0;
                i32 depth_vs = 1;
                while (depth_vs > 0 && !self.is_at_end_p()) {
                    if (self.check_tok(obrace)) {
                        depth_vs = depth_vs + 1; self.advance_tok();
                    } else if (self.check_tok(cbrace)) {
                        depth_vs = depth_vs - 1;
                        if (depth_vs > 0) { self.advance_tok(); } else { break; }
                    } else if (depth_vs == 1 && self.is_type_start() && !self.check_tok(kw_const)) {
                        i32 saved_pos = self.current;
                        type_node* ft = self.parse_type();
                        if (self.check_tok(id)) {
                            lexer.token_t fname = self.consume_tok(id, "field name");
                            if (self.check_tok(sm)) {
                                self.advance_tok();
                                if (fc < 8) {
                                    ed.variant_field_names_flat[vi * 8 + fc] = lexer.str_dup(fname.value);
                                    ed.variant_field_type_flat[vi * 8 + fc]  = (i8*)ft;
                                    fc = fc + 1;
                                }
                            } else if (self.check_tok(oparen)) {
                                self.advance_tok(); // consume '('
                                func_decl* mfd = self.parse_func_body(ft, fname, false);
                                if (mfd != (func_decl*)0) {
                                    i32 mc = ed.variant_method_counts[vi];
                                    if (mc < 8) {
                                        ed.variant_method_flat[vi * 8 + mc] = (i8*)mfd;
                                        ed.variant_method_counts[vi] = mc + 1;
                                    }
                                }
                            } else { self.current = saved_pos; self.advance_tok(); }
                        } else { self.current = saved_pos; self.advance_tok(); }
                    } else if (depth_vs == 1 && self.check_tok(kw_const) && self.peek_at_type(1) != kw_const) {
                        i32 saved_pos = self.current;
                        type_node* ft = self.parse_type();
                        if (self.check_tok(id)) {
                            lexer.token_t fname = self.consume_tok(id, "field name");
                            if (self.check_tok(sm)) {
                                self.advance_tok();
                                if (fc < 8) {
                                    ed.variant_field_names_flat[vi * 8 + fc] = lexer.str_dup(fname.value);
                                    ed.variant_field_type_flat[vi * 8 + fc]  = (i8*)ft;
                                    fc = fc + 1;
                                }
                            } else if (self.check_tok(oparen)) {
                                self.advance_tok(); // consume '('
                                func_decl* mfd = self.parse_func_body(ft, fname, false);
                                if (mfd != (func_decl*)0) {
                                    i32 mc = ed.variant_method_counts[vi];
                                    if (mc < 8) {
                                        ed.variant_method_flat[vi * 8 + mc] = (i8*)mfd;
                                        ed.variant_method_counts[vi] = mc + 1;
                                    }
                                }
                            } else { self.current = saved_pos; self.advance_tok(); }
                        } else { self.current = saved_pos; self.advance_tok(); }
                    } else { self.advance_tok(); }
                }
                self.consume_tok(cbrace, "Expected '}' after variant body");
                ed.variant_field_counts[vi] = fc;
            }

            if (self.match_tok(assign)) {
                expr_node* val_expr = self.parse_expr();
                if (val_expr.kind == ek_int_lit) { next_val = val_expr.int_val; }
                ed.variant_vals[vi]    = next_val;
                ed.variant_has_val[vi] = true;
            } else {
                ed.variant_vals[vi]    = next_val;
                ed.variant_has_val[vi] = false;
            }
            next_val = next_val + 1;
            ed.variants_len = ed.variants_len + 1;

            if (!self.check_tok(cbrace)) {
                self.consume_tok(comma, "Expected ',' between enum variants");
            }
        }
        self.consume_tok(cbrace, "Expected '}' after enum body");
        if (etp_count == 0) {
            return (ast_node*)ed;
        }
        // Generic enum: wrap in namespace_decl for monomorphization
        namespace_decl* end = (namespace_decl*)arc_malloc(sizeof(parser__NS_namespace_decl));
        memset((i8*)end, 0, sizeof(parser__NS_namespace_decl));
        end.kind = nd_namespace_decl;
        end.line = ln;
        end.name = enum_name;
        end.decls_cap = 4;
        end.decls = (ast_node**)arc_malloc(sizeof(i8*) * (u64)end.decls_cap);
        end.decls[0] = (ast_node*)ed;
        end.decls_len = 1;
        end.type_params = (i8**)arc_malloc(sizeof(i8*) * (u64)etp_count);
        i32 etpi = 0;
        while (etpi < etp_count) {
            end.type_params[etpi] = etp_names[etpi];
            etpi = etpi + 1;
        }
        end.type_params_len = etp_count;
        return (ast_node*)end;
    }

    typedef_decl* parse_typedef_decl(parser_t* self) {
        u64 ln = (u64)self.peek_line();
        self.advance_tok();  // consume 'typedef'
        typedef_decl* td = (typedef_decl*)arc_malloc(sizeof(parser__NS_typedef_decl));
        memset((i8*)td, 0, sizeof(parser__NS_typedef_decl));
        td.kind = nd_typedef_decl;
        td.line = ln;

        if (self.check_tok(kw_auto)) {
            self.advance_tok();
            td.name = lexer.str_dup(self.consume_id_value("Expected typedef alias"));
            self.consume_tok(assign, "Expected '=' in typedef auto");
            td.target = self.parse_type();
        } else {
            td.target = self.parse_type();
            td.name   = lexer.str_dup(self.consume_id_value("Expected typedef alias"));
        }
        self.consume_tok(sm, "Expected ';' after typedef");
        return td;
    }

    namespace_decl* parse_namespace_decl(parser_t* self) {
        u64 ln = (u64)self.peek_line();
        self.advance_tok();  // consume 'namespace'
        namespace_decl* nd = (namespace_decl*)arc_malloc(sizeof(parser__NS_namespace_decl));
        memset((i8*)nd, 0, sizeof(parser__NS_namespace_decl));
        nd.kind = nd_namespace_decl;
        nd.line = ln;
        nd.name = lexer.str_dup(self.consume_id_value("Expected namespace name"));
        nd.decls_cap = 16;
        nd.decls = (ast_node**)arc_malloc(sizeof(i8*) * (u64)nd.decls_cap);
        self.consume_tok(obrace, "Expected '{' after namespace name");

        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            ast_node* decl = self.parse_top_level();
            if (decl != (ast_node*)0) {
                if (nd.decls_len >= nd.decls_cap) {
                    nd.decls_cap = nd.decls_cap * 2;
                    nd.decls = (ast_node**)arc_realloc((i8*)nd.decls, sizeof(i8*) * (u64)nd.decls_cap);
                }
                nd.decls[nd.decls_len] = decl;
                nd.decls_len = nd.decls_len + 1;
            }
        }
        self.consume_tok(cbrace, "Expected '}' after namespace body");
        return nd;
    }

    extern_c_block* parse_extern_c_block(parser_t* self) {
        u64 ln = (u64)self.peek_line();
        self.advance_tok();  // consume 'extern "C"'
        extern_c_block* blk = (extern_c_block*)arc_malloc(sizeof(parser__NS_extern_c_block));
        memset((i8*)blk, 0, sizeof(parser__NS_extern_c_block));
        blk.kind = nd_extern_c_block;
        blk.line = ln;
        blk.decls_cap = 16;
        blk.decls = (ast_node**)arc_malloc(sizeof(i8*) * (u64)blk.decls_cap);

        if (self.match_tok(obrace)) {
            while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                ast_node* decl = self.parse_func_or_var_decl_extern_c();
                if (decl != (ast_node*)0) {
                    if (blk.decls_len >= blk.decls_cap) {
                        blk.decls_cap = blk.decls_cap * 2;
                        blk.decls = (ast_node**)arc_realloc((i8*)blk.decls, sizeof(i8*) * (u64)blk.decls_cap);
                    }
                    blk.decls[blk.decls_len] = decl;
                    blk.decls_len = blk.decls_len + 1;
                }
            }
            self.consume_tok(cbrace, "Expected '}' after extern \"C\" block");
        } else {
            ast_node* decl = self.parse_func_or_var_decl_extern_c();
            blk.decls[0] = decl;
            blk.decls_len = 1;
        }
        return blk;
    }

    // Stub class_decl parser - we parse istruc bodies as namespace_decl for simplicity
    ast_node* parse_class_decl_stub(parser_t* self) {
        u64 ln = (u64)self.peek_line();
        bool decl_is_memstr  = self.check_tok(kw_smem);
        bool decl_is_interface = self.check_tok(kw_interface);
        self.advance_tok();  // consume 'istruc' or 'interface' or 'memstr'

        // Anonymous istruc: `istruc { ... } var_name;` or `auto x = istruc { ... };`
        // Detected when '{' follows immediately (no identifier name).
        lexer.token_t class_name;
        if (self.check_tok(obrace)) {
            // Generate synthetic name: __anon_istruc_N
            i8 syn_name[32];
            snprintf(syn_name, (u64)32, "__anon_istruc_%d", self.anon_istruc_count);
            self.anon_istruc_count = self.anon_istruc_count + 1;
            class_name.type  = id;
            class_name.value = lexer.str_dup(syn_name);
            class_name.line  = (i32)ln;
        } else {
            class_name = self.consume_tok(id, "Expected class name");
        }

        // Parse optional type params: <T, U> — stored for generic monomorphization
        i8* tp_names[16];
        i32 tp_count = 0;
        if (self.check_tok(lt)) {
            self.advance_tok(); // consume '<'
            while (!self.check_tok(gt) && !self.is_at_end_p()) {
                if (self.check_tok(id) && tp_count < 16) {
                    lexer.token_t tp_tok = self.peek_tok();
                    tp_names[tp_count] = lexer.str_dup(tp_tok.value);
                    tp_count = tp_count + 1;
                    self.advance_tok();
                } else {
                    self.advance_tok();
                }
                self.match_tok(comma);
            }
            self.match_tok(gt);
        }

        // Parse optional : BaseClass/Interface list (may include generic args, e.g. Foo<int>)
        i8* base_buf[16];
        i32 base_count = 0;
        if (self.match_tok(colon)) {
            while (self.check_tok(id)) {
                lexer.token_t base_tok = self.peek_tok();
                if (base_count < 16) {
                    base_buf[base_count] = lexer.str_dup(base_tok.value);
                    base_count = base_count + 1;
                }
                self.advance_tok(); // consume base name
                // Consume optional generic type args <T1, T2, ...>
                if (self.check_tok(lt)) {
                    self.advance_tok(); // consume '<'
                    i32 depth = 1;
                    while (depth > 0 && !self.is_at_end_p()) {
                        if (self.check_tok(lt)) { depth = depth + 1; }
                        else if (self.check_tok(gt)) { depth = depth - 1; }
                        self.advance_tok();
                    }
                }
                if (!self.match_tok(comma)) { break; }
            }
        }

        // Parse body as a namespace for simplicity
        namespace_decl* nd = (namespace_decl*)arc_malloc(sizeof(parser__NS_namespace_decl));
        memset((i8*)nd, 0, sizeof(parser__NS_namespace_decl));
        nd.kind        = nd_namespace_decl;
        nd.line        = ln;
        nd.name        = lexer.str_dup(class_name.value);
        nd.is_istruc   = true;
        nd.is_interface = decl_is_interface;
        nd.decls_cap   = 16;
        nd.decls = (ast_node**)arc_malloc(sizeof(i8*) * (u64)nd.decls_cap);
        if (base_count > 0) {
            nd.bases = (i8**)arc_malloc(sizeof(i8*) * (u64)base_count);
            i32 bi = 0;
            while (bi < base_count) {
                nd.bases[bi] = base_buf[bi];
                bi = bi + 1;
            }
            nd.bases_len = base_count;
        }

        self.consume_tok(obrace, "Expected '{' after class name");
        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            // Collect modifiers: const, static, inline, comptime
            bool mod_is_static = false;
            bool skip_mod = true;
            while (skip_mod) {
                i32 tt = self.peek_type();
                if (tt == kw_static)  { self.advance_tok(); mod_is_static = true; }
                else if (tt == kw_const || tt == kw_comptime || tt == kw_inline) {
                    self.advance_tok();
                } else {
                    skip_mod = false;
                }
            }

            if (self.check_tok(cbrace)) { break; }

            // Conversion operator: operator TypeName(...) — no return type prefix
            if (self.check_tok(kw_operator)) {
                i32 op_nt = self.peek_at_type(1);
                if (op_nt == kw_arb_int || op_nt == kw_arb_uint || op_nt == kw_arb_float) {
                    self.advance_tok(); // consume 'operator'
                    i32 op_tt = self.peek_type();
                    type_node* conv_ret = self.parse_type();
                    i8 conv_name[64];
                    if (op_tt == kw_arb_int) {
                        snprintf(conv_name, (u64)64, "operator_i%d", (i32)conv_ret.bit_width);
                    } else if (op_tt == kw_arb_uint) {
                        snprintf(conv_name, (u64)64, "operator_u%d", (i32)conv_ret.bit_width);
                    } else {
                        snprintf(conv_name, (u64)64, "operator_f%d", (i32)conv_ret.bit_width);
                    }
                    lexer.token_t conv_nt;
                    conv_nt.type  = id;
                    conv_nt.value = lexer.str_dup(conv_name);
                    conv_nt.line  = 0;
                    self.consume_tok(oparen, "Expected '(' for conversion operator");
                    func_decl* conv_fd = self.parse_func_body(conv_ret, conv_nt, false);
                    if (conv_fd != (func_decl*)0) {
                        if (nd.decls_len >= nd.decls_cap) {
                            nd.decls_cap = nd.decls_cap * 2;
                            nd.decls = (ast_node**)arc_realloc((i8*)nd.decls, sizeof(i8*) * (u64)nd.decls_cap);
                        }
                        nd.decls[nd.decls_len] = (ast_node*)conv_fd;
                        nd.decls_len = nd.decls_len + 1;
                    }
                    continue;
                }
            }

            ast_node* member = self.parse_func_or_var_decl();
            if (member != (ast_node*)0) {
                // Propagate static flag to functions or fields
                if (mod_is_static && member.kind == nd_func_decl) {
                    func_decl* mfd = (func_decl*)member;
                    mfd.is_static = true;
                }
                if (mod_is_static && member.kind == nd_var_decl) {
                    var_decl* mvd = (var_decl*)member;
                    mvd.is_static = true;
                }
                if (nd.decls_len >= nd.decls_cap) {
                    nd.decls_cap = nd.decls_cap * 2;
                    nd.decls = (ast_node**)arc_realloc((i8*)nd.decls, sizeof(i8*) * (u64)nd.decls_cap);
                }
                nd.decls[nd.decls_len] = member;
                nd.decls_len = nd.decls_len + 1;
            }
        }
        self.consume_tok(cbrace, "Expected '}' after class body");
        self.match_tok(sm);

        // Post-process: split var_decl fields vs func_decl methods.
        // Build a struct_decl for the fields, then a namespace_decl with
        // the struct_decl first, followed by the method func_decls.
        struct_decl* sd = (struct_decl*)arc_malloc(sizeof(parser__NS_struct_decl));
        memset((i8*)sd, 0, sizeof(parser__NS_struct_decl));
        sd.kind       = nd_struct_decl;
        sd.line       = ln;
        sd.name       = lexer.str_dup(nd.name);
        sd.fields_cap = 8;
        sd.fields     = (var_decl**)arc_malloc(sizeof(i8*) * (u64)sd.fields_cap);
        sd.fields_len = 0;

        namespace_decl* out = (namespace_decl*)arc_malloc(sizeof(parser__NS_namespace_decl));
        memset((i8*)out, 0, sizeof(parser__NS_namespace_decl));
        out.kind         = nd_namespace_decl;
        out.is_istruc    = true;
        out.is_interface = decl_is_interface;
        out.line         = ln;
        out.name         = nd.name;
        out.decls_cap    = nd.decls_len + 4;
        out.decls        = (ast_node**)arc_malloc(sizeof(i8*) * (u64)out.decls_cap);
        out.decls_len    = 0;
        out.bases        = nd.bases;
        out.bases_len    = nd.bases_len;

        // Add struct_decl as first child (fields collected below)
        out.decls[0]  = (ast_node*)sd;
        out.decls_len = 1;

        // Pass: fields → struct, methods → namespace, static fields → namespace as globals
        i32 pi = 0;
        while (pi < nd.decls_len) {
            ast_node* m = nd.decls[pi];
            if (m != (ast_node*)0 && m.kind == nd_var_decl) {
                var_decl* mvd = (var_decl*)m;
                if (mvd.is_static) {
                    // Static field: emit as module global named TYPENAME__static_FIELDNAME
                    i8 sname[512];
                    snprintf(sname, (u64)512, "%s__static_%s", nd.name, mvd.name);
                    mvd.name = lexer.str_dup(sname);
                    if (out.decls_len >= out.decls_cap) {
                        out.decls_cap = out.decls_cap * 2;
                        out.decls = (ast_node**)arc_realloc((i8*)out.decls, sizeof(i8*) * (u64)out.decls_cap);
                    }
                    out.decls[out.decls_len] = m;
                    out.decls_len = out.decls_len + 1;
                } else {
                    if (sd.fields_len >= sd.fields_cap) {
                        sd.fields_cap = sd.fields_cap * 2;
                        sd.fields = (var_decl**)arc_realloc((i8*)sd.fields, sizeof(i8*) * (u64)sd.fields_cap);
                    }
                    sd.fields[sd.fields_len] = mvd;
                    sd.fields_len = sd.fields_len + 1;
                }
            } else if (m != (ast_node*)0) {
                if (out.decls_len >= out.decls_cap) {
                    out.decls_cap = out.decls_cap * 2;
                    out.decls = (ast_node**)arc_realloc((i8*)out.decls, sizeof(i8*) * (u64)out.decls_cap);
                }
                out.decls[out.decls_len] = m;
                out.decls_len = out.decls_len + 1;
            }
            pi = pi + 1;
        }
        // Store generic type params if any
        if (tp_count > 0) {
            out.type_params = (i8**)arc_malloc(sizeof(i8*) * (u64)tp_count);
            i32 tpi = 0;
            while (tpi < tp_count) {
                out.type_params[tpi] = tp_names[tpi];
                tpi = tpi + 1;
            }
            out.type_params_len = tp_count;
        }
        out.is_memstr = decl_is_memstr;

        arc_free((i8*)nd.decls);
        arc_free((i8*)nd);

        // Anonymous istruc: if next token is an identifier (not ';'), parse instance name
        // and queue a var_decl for the main parse() loop to emit after the type decl.
        if (out.name != (i8*)0 && out.name[0] == '_' && out.name[1] == '_' &&
            strncmp(out.name, "__anon_istruc_", (u64)14) == 0) {
            if (self.check_tok(id)) {
                lexer.token_t inst_tok = self.advance_tok();
                var_decl* vd = (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
                memset((i8*)vd, 0, sizeof(parser__NS_var_decl));
                vd.kind = nd_var_decl;
                vd.line = (u64)inst_tok.line;
                vd.name = lexer.str_dup(inst_tok.value);
                type_node* inst_ty = (type_node*)arc_malloc(sizeof(parser__NS_type_node));
                memset((i8*)inst_ty, 0, sizeof(parser__NS_type_node));
                inst_ty.name = lexer.str_dup(out.name);
                inst_ty.is_primitive = false;
                vd.type = inst_ty;
                self.match_tok(sm);
                self.pending_anon_var = (ast_node*)vd;
            } else {
                self.match_tok(sm);
            }
        }

        return (ast_node*)out;
    }

    ast_node* parse_top_level(parser_t* self) {
        if (self.check_tok(kw_struct))     { return (ast_node*)self.parse_struct_decl(); }
        if (self.check_tok(kw_union))      { return self.parse_union_decl(); }
        if (self.check_tok(kw_enum))       { return self.parse_enum_decl(); }
        if (self.check_tok(kw_istruc))     { return self.parse_class_decl_stub(); }
        if (self.check_tok(kw_interface))  { return self.parse_class_decl_stub(); }
        if (self.check_tok(kw_extern_c))   { return (ast_node*)self.parse_extern_c_block(); }
        if (self.check_tok(kw_namespace))  { return (ast_node*)self.parse_namespace_decl(); }
        // Proc macro application: #[name] or #[name(args)] or #derive[name] or #![name] (file-level)
        if (self.check_tok(hash)) {
            self.advance_tok(); // consume '#'
            bool is_file_level = false;
            bool is_derive_app = false;
            if (self.check_tok(not_)) { self.advance_tok(); is_file_level = true; }
            // #derive[name] shorthand: check for 'derive' as keyword OR identifier before '['
            if ((self.check_tok(id) || self.check_tok(kw_derive)) && self.peek_at_type(1) == obracket) {
                lexer.token_t kw = self.advance_tok();
                if (strcmp(kw.value, "derive") == 0 || kw.type == kw_derive) { is_derive_app = true; }
                else { self.current = self.current - 1; } // put back if not "derive"
            }
            if (self.check_tok(obracket)) {
                self.advance_tok(); // consume '['
                // Collect macro name and optional args (accept identifiers AND keywords like 'derive', 'attr')
                i8* macro_name = (i8*)0;
                if (!self.check_tok(cbracket) && !self.is_at_end_p()) {
                    lexer.token_t mn_tok = self.advance_tok();
                    macro_name = mn_tok.value;
                    if (macro_name == (i8*)0 || macro_name[0] == 0) {
                        if (mn_tok.type == kw_derive) { macro_name = "derive"; }
                        else if (mn_tok.type == kw_attr) { macro_name = "attr"; }
                        else if (mn_tok.type == kw_inline) { macro_name = "inline"; }
                    }
                }
                // Parse optional (args) — capture identifiers as args for derive
                i8* attr_args_buf[16];
                i32 attr_args_count = 0;
                if (self.check_tok(oparen)) {
                    i32 pd = 1; self.advance_tok();
                    while (pd > 0 && !self.is_at_end_p()) {
                        if (self.check_tok(oparen)) { pd = pd + 1; self.advance_tok(); }
                        else if (self.check_tok(cparen)) {
                            pd = pd - 1;
                            if (pd > 0) { self.advance_tok(); }
                            else { self.advance_tok(); }
                        } else {
                            // Capture top-level identifier args (depth == 1)
                            if (pd == 1 && (self.check_tok(id) || self.check_tok(comma))) {
                                if (!self.check_tok(comma)) {
                                    lexer.token_t atok = self.advance_tok();
                                    if (attr_args_count < 16 && atok.value != (i8*)0) {
                                        attr_args_buf[attr_args_count] = lexer.str_dup(atok.value);
                                        attr_args_count = attr_args_count + 1;
                                    }
                                } else { self.advance_tok(); }
                            } else { self.advance_tok(); }
                        }
                    }
                }
                // Build args array if we captured any
                i8** attr_args = (i8**)0;
                if (attr_args_count > 0) {
                    attr_args = (i8**)arc_malloc(sizeof(i8*) * (u64)attr_args_count);
                    i32 aai = 0;
                    while (aai < attr_args_count) {
                        attr_args[aai] = attr_args_buf[aai];
                        aai = aai + 1;
                    }
                }
                self.consume_tok(cbracket, "Expected ']' after attribute");
                // Parse the decorated declaration and attach the attribute
                ast_node* decorated = self.parse_top_level();
                if (decorated != (ast_node*)0 && macro_name != (i8*)0) {
                    if (decorated.kind == nd_func_decl) {
                        func_decl* dfd = (func_decl*)decorated;
                        i32 nc = dfd.attributes_len + 1;
                        proc_attr* new_attrs = (proc_attr*)arc_realloc((i8*)dfd.attributes, sizeof(parser__NS_proc_attr) * (u64)nc);
                        new_attrs[nc - 1].name     = macro_name;
                        new_attrs[nc - 1].args     = attr_args;
                        new_attrs[nc - 1].args_len = attr_args_count;
                        dfd.attributes     = new_attrs;
                        dfd.attributes_len = nc;
                    } else if (decorated.kind == nd_namespace_decl) {
                        namespace_decl* dns = (namespace_decl*)decorated;
                        i32 nc2 = dns.attributes_len + 1;
                        proc_attr* new_attrs2 = (proc_attr*)arc_realloc((i8*)dns.attributes, sizeof(parser__NS_proc_attr) * (u64)nc2);
                        new_attrs2[nc2 - 1].name     = macro_name;
                        new_attrs2[nc2 - 1].args     = attr_args;
                        new_attrs2[nc2 - 1].args_len = attr_args_count;
                        dns.attributes     = new_attrs2;
                        dns.attributes_len = nc2;
                    }
                }
                return decorated;
            }
            // Malformed # — skip to end of line and continue
            while (!self.is_at_end_p() && !self.check_tok(sm)) { self.advance_tok(); }
            return self.parse_top_level();
        }
        if (self.check_tok(kw_smem)) { return self.parse_class_decl_stub(); }
        // using — two syntaxes accepted:
        //   using Name = Type;  (C++ style, Name is id and next token is '=')
        //   using Type Name;    (C typedef compat)
        if (self.check_tok(kw_using)) {
            self.advance_tok(); // consume 'using'
            typedef_decl* td = (typedef_decl*)arc_malloc(sizeof(parser__NS_typedef_decl));
            memset((i8*)td, 0, sizeof(parser__NS_typedef_decl));
            td.kind = nd_typedef_decl;
            // Peek one ahead: if current is 'id' AND next is '=', it's C++ style.
            lexer.token_t next_tok = self.peek_at_tok(1);
            bool cpp_style = self.check_tok(id) && (next_tok.type == assign);
            // `using name;` or `using ns.name;` — namespace import (no '=', no type-before-name)
            // Detect: id or dotted-id immediately followed by ';'
            bool ns_import = false;
            if (self.check_tok(id) && !cpp_style) {
                // Look ahead for ';' (possibly after dot-separated segments)
                i32 saved2 = self.current;
                self.advance_tok(); // consume first id
                while (self.match_tok(dot) && self.check_tok(id)) { self.advance_tok(); }
                if (self.check_tok(sm)) { ns_import = true; }
                self.current = saved2;
            }
            if (ns_import) {
                // using ns_name;  — collect the full dotted name
                i8 ns_buf[512]; ns_buf[0] = 0;
                i32 ns_len = 0;
                while (self.check_tok(id)) {
                    i8* seg = self.advance_value_get();
                    i32 seg_len = (i32)strlen(seg);
                    if (ns_len + seg_len + 1 < 512) {
                        if (ns_len > 0) { ns_buf[ns_len] = '.'; ns_len = ns_len + 1; }
                        i32 si = 0;
                        while (si < seg_len) { ns_buf[ns_len] = seg[si]; ns_len = ns_len + 1; si = si + 1; }
                        ns_buf[ns_len] = 0;
                    }
                    if (!self.match_tok(dot)) { break; }
                }
                td.is_namespace_using = true;
                td.ns_using_name = lexer.str_dup(ns_buf);
            } else if (self.check_tok(kw_auto)) {
                // using auto Name = Type;
                self.advance_tok(); // consume 'auto'
                td.name = lexer.str_dup(self.consume_id_value("Expected alias name after using auto"));
                self.consume_tok(assign, "Expected '=' in using auto");
                td.target = self.parse_type();
            } else if (cpp_style) {
                // using Name = Type;
                td.name = lexer.str_dup(self.consume_id_value("Expected alias name after using"));
                self.consume_tok(assign, "Expected '=' in using declaration");
                td.target = self.parse_type();
            } else {
                // using Type Name;
                td.target = self.parse_type();
                td.name   = lexer.str_dup(self.consume_id_value("Expected alias name after type"));
            }
            self.consume_tok(sm, "Expected ';' after using declaration");
            return (ast_node*)td;
        }
        // const_resolve macro definitions
        if (self.check_tok(kw_const_resolve)) {
            self.advance_tok(); // consume keyword
            i8* macro_name = (i8*)0;
            if (self.check_tok(id)) {
                lexer.token_t nm_tok = self.advance_tok();
                macro_name = lexer.str_dup(nm_tok.value);
            }
            if (macro_name == (i8*)0) { return (ast_node*)0; }
            self.consume_tok(obrace, "Expected '{' after const_resolve name");
            // Parse rules until '}'
            while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                i8* param_names_buf[16];
                i32 param_count = 0;
                // Pattern: (...) or [...]
                i32 pat_open  = self.check_tok(oparen)   ? oparen   : (self.check_tok(obracket) ? obracket : -1);
                i32 pat_close = (pat_open == oparen)      ? cparen   : (pat_open == obracket ? cbracket : -1);
                if (pat_open != -1) {
                    self.advance_tok(); // consume open
                    while (!self.check_tok(pat_close) && !self.is_at_end_p()) {
                        if (self.check_tok(dollar)) {
                            self.advance_tok(); // '$'
                            i8* pname = (i8*)0;
                            if (self.check_tok(id)) {
                                lexer.token_t pn_tok = self.advance_tok();
                                pname = lexer.str_dup(pn_tok.value);
                            }
                            if (self.check_tok(colon)) {
                                self.advance_tok(); // ':'
                                self.advance_tok(); // type fragment
                            }
                            if (pname != (i8*)0 && param_count < 16) {
                                param_names_buf[param_count] = pname;
                                param_count = param_count + 1;
                            }
                        } else {
                            self.advance_tok(); // skip literal match tokens
                        }
                        if (self.check_tok(comma) && !self.check_tok(pat_close)) { self.advance_tok(); }
                    }
                    self.consume_tok(pat_close, "Expected closing delimiter for macro pattern");
                }
                // Consume '=>'
                if (self.check_tok(assign)) { self.advance_tok(); }
                if (self.check_tok(gt))     { self.advance_tok(); }
                // Collect template tokens
                i32 tpl_cap = 64;
                lexer.token_t* tpl = (lexer.token_t*)arc_malloc(sizeof(lexer__NS_token_t) * (u64)tpl_cap);
                i32 tpl_len = 0;
                if (self.check_tok(obrace)) {
                    self.advance_tok(); // consume '{'
                    i32 depth_t = 1;
                    while (depth_t > 0 && !self.is_at_end_p()) {
                        lexer.token_t cur = self.peek_tok();
                        if (cur.type == obrace) { depth_t = depth_t + 1; }
                        else if (cur.type == cbrace) {
                            depth_t = depth_t - 1;
                            if (depth_t == 0) { self.advance_tok(); break; }
                        }
                        if (tpl_len >= tpl_cap) {
                            tpl_cap = tpl_cap * 2;
                            tpl = (lexer.token_t*)arc_realloc((i8*)tpl, sizeof(lexer__NS_token_t) * (u64)tpl_cap);
                        }
                        tpl[tpl_len] = cur;
                        tpl_len = tpl_len + 1;
                        self.advance_tok();
                    }
                }
                // Store macro definition
                macro_def_t* mdef = (macro_def_t*)arc_malloc(sizeof(parser__NS_macro_def_t));
                mdef.name         = macro_name;
                mdef.param_count  = param_count;
                mdef.template_toks = (i8*)tpl;
                mdef.template_len  = tpl_len;
                mdef.param_names   = (i8**)arc_malloc(sizeof(i8*) * (u64)(param_count + 1));
                i32 pi = 0;
                while (pi < param_count) {
                    mdef.param_names[pi] = param_names_buf[pi];
                    pi = pi + 1;
                }
                if (self.macros_len >= self.macros_cap) {
                    self.macros_cap = self.macros_cap * 2;
                    self.macros = (macro_def_t**)arc_realloc((i8*)self.macros, sizeof(i8*) * (u64)self.macros_cap);
                }
                self.macros[self.macros_len] = mdef;
                self.macros_len = self.macros_len + 1;
                if (self.check_tok(comma)) { self.advance_tok(); }
            }
            self.consume_tok(cbrace, "Expected '}' after const_resolve body");
            return (ast_node*)0;
        }
        return self.parse_func_or_var_decl();
    }

    // ---- Block and statement parsing ----

    block_stmt* parse_block(parser_t* self) {
        u64 ln = (u64)self.peek_line();
        self.consume_tok(obrace, "Expected '{'");
        block_stmt* blk = (block_stmt*)arc_malloc(sizeof(parser__NS_block_stmt));
        memset((i8*)blk, 0, sizeof(parser__NS_block_stmt));
        blk.kind = nd_block;
        blk.line = ln;

        i32 stmts_cap = 16;
        blk.stmts = (ast_node**)arc_malloc(sizeof(i8*) * (u64)stmts_cap);
        blk.stmts_len = 0;

        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            ast_node* s = self.parse_stmt();
            if (s != (ast_node*)0) {
                if (blk.stmts_len >= stmts_cap) {
                    stmts_cap = stmts_cap * 2;
                    blk.stmts = (ast_node**)arc_realloc((i8*)blk.stmts, sizeof(i8*) * (u64)stmts_cap);
                }
                blk.stmts[blk.stmts_len] = s;
                blk.stmts_len = blk.stmts_len + 1;
            }
            // Anonymous istruc: parse_stmt returns the type_decl and queues the instance
            // var_decl in pending_anon_var. Emit it here so it lives in the same scope.
            if (self.pending_anon_var != (ast_node*)0) {
                ast_node* av = self.pending_anon_var;
                self.pending_anon_var = (ast_node*)0;
                if (blk.stmts_len >= stmts_cap) {
                    stmts_cap = stmts_cap * 2;
                    blk.stmts = (ast_node**)arc_realloc((i8*)blk.stmts, sizeof(i8*) * (u64)stmts_cap);
                }
                blk.stmts[blk.stmts_len] = av;
                blk.stmts_len = blk.stmts_len + 1;
            }
        }
        self.consume_tok(cbrace, "Expected '}'");
        return blk;
    }

    var_decl* parse_local_var_decl(parser_t* self) {
        type_node* t = self.parse_type();
        if (!self.check_tok(id)) {
            {
                i8* got_name = lexer.tok_type_name(self.peek_type());
                printf("error at line %d: expected variable name; got %s\n",
                        self.peek_line(), got_name);
            }
            self.had_parse_error = true;
        }
        lexer.token_t name_tok = self.advance_tok();
        // Trailing type: auto name: type
        if (t.is_auto && self.check_tok(colon)) {
            self.advance_tok();
            t = self.parse_type();
        }
        var_decl* vd = (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
        memset((i8*)vd, 0, sizeof(parser__NS_var_decl));
        vd.kind    = nd_var_decl;
        vd.line    = (u64)name_tok.line;
        vd.type    = t;
        vd.name    = lexer.str_dup(name_tok.value);
        vd.is_sta  = t.is_sta;

        if (self.match_tok(obracket)) {
            if (!self.check_tok(cbracket)) {
                t.array_size_ptr = (i8*)self.parse_expr();
            }
            self.consume_tok(cbracket, "Expected ']' after array size");
        }
        // Constructor call: TypeName varname(args...)
        if (self.match_tok(oparen)) {
            vd.has_ctor_parens = true;
            i32 ctor_cap2 = 4;
            vd.ctor_args = (i8**)arc_malloc(sizeof(i8*) * (u64)ctor_cap2);
            vd.ctor_args_len = 0;
            if (!self.check_tok(cparen)) {
                bool p_ctor2 = true;
                while (p_ctor2) {
                    if (vd.ctor_args_len >= ctor_cap2) {
                        ctor_cap2 = ctor_cap2 * 2;
                        vd.ctor_args = (i8**)arc_realloc((i8*)vd.ctor_args, sizeof(i8*) * (u64)ctor_cap2);
                    }
                    vd.ctor_args[vd.ctor_args_len] = (i8*)self.parse_assignment();
                    vd.ctor_args_len = vd.ctor_args_len + 1;
                    if (!self.match_tok(comma)) { p_ctor2 = false; }
                }
            }
            self.consume_tok(cparen, "Expected ')' after constructor args");
        } else if (self.match_tok(assign)) {
            vd.init     = self.parse_expr();
            vd.has_init = true;
        }
        self.consume_tok(sm, "Expected ';' after variable declaration");
        return vd;
    }

    ast_node* parse_if_stmt(parser_t* self) {
        if_stmt* n = (if_stmt*)arc_malloc(sizeof(parser__NS_if_stmt));
        memset((i8*)n, 0, sizeof(parser__NS_if_stmt));
        n.kind = nd_if_stmt;
        n.line = (u64)self.advance_line_get();  // consume 'if'

        if (self.check_tok(kw_comptime)) { self.advance_tok(); n.is_constexpr = true; }
        bool has_parens = self.match_tok(oparen);
        n.cond = self.parse_expr();
        if (has_parens) { self.consume_tok(cparen, "Expected ')' after condition"); }

        // Optional |capture|
        if (self.match_tok(bit_or)) {
            n.then_capture = lexer.str_dup(self.consume_id_value("Expected identifier in capture"));
            self.consume_tok(bit_or, "Expected '|' after capture");
        }

        n.then_body = self.parse_stmt();
        if (self.match_tok(kw_else)) {
            if (self.match_tok(bit_or)) {
                n.else_capture = lexer.str_dup(self.consume_id_value("Expected identifier in capture"));
                self.consume_tok(bit_or, "Expected '|' after capture");
            }
            n.else_body = self.parse_stmt();
        }
        return (ast_node*)n;
    }

    ast_node* parse_while_stmt(parser_t* self) {
        while_stmt* n = (while_stmt*)arc_malloc(sizeof(parser__NS_while_stmt));
        memset((i8*)n, 0, sizeof(parser__NS_while_stmt));
        n.kind = nd_while_stmt;
        n.line = (u64)self.advance_line_get();

        bool has_parens = self.match_tok(oparen);
        n.cond = self.parse_expr();
        if (has_parens) { self.consume_tok(cparen, "Expected ')' after condition"); }
        n.body = self.parse_stmt();
        return (ast_node*)n;
    }

    ast_node* parse_for_stmt(parser_t* self) {
        u64 ln = (u64)self.advance_line_get();  // consume 'for'
        bool has_parens = self.match_tok(oparen);

        // Try range-for: for (T name : expr)
        if (self.is_type_start()) {
            i32 saved_pos = self.current;
            bool saved_err = self.had_parse_error;
            type_node* rvar_type = self.parse_type();
            if (self.check_tok(id) && self.peek_at_type(1) == colon) {
                for_range_stmt* rn = (for_range_stmt*)arc_malloc(sizeof(parser__NS_for_range_stmt));
                memset((i8*)rn, 0, sizeof(parser__NS_for_range_stmt));
                rn.kind = nd_for_range_stmt;
                rn.line = ln;
                rn.var_type = rvar_type;
                rn.var_name = self.advance_value_get();  // consume name
                self.advance_tok();  // consume ':'
                rn.range = self.parse_expr();
                if (has_parens) { self.consume_tok(cparen, "Expected ')' after range-for"); }
                rn.body = self.parse_stmt();
                return (ast_node*)rn;
            }
            // Not a range-for; restore and fall through to C-style for
            self.current = saved_pos;
            self.had_parse_error = saved_err;
        }

        for_stmt* n = (for_stmt*)arc_malloc(sizeof(parser__NS_for_stmt));
        memset((i8*)n, 0, sizeof(parser__NS_for_stmt));
        n.kind = nd_for_stmt;
        n.line = ln;

        if (!self.check_tok(sm)) {
            if (self.is_type_start()) {
                n.init = (ast_node*)self.parse_local_var_decl();
            } else {
                expr_stmt* es = (expr_stmt*)arc_malloc(sizeof(parser__NS_expr_stmt));
                memset((i8*)es, 0, sizeof(parser__NS_expr_stmt));
                es.kind = nd_expr_stmt;
                es.expr = self.parse_expr();
                self.consume_tok(sm, "Expected ';'");
                n.init = (ast_node*)es;
            }
        } else {
            self.advance_tok();  // consume ';'
        }

        if (!self.check_tok(sm)) {
            n.cond = self.parse_expr();
        }
        self.consume_tok(sm, "Expected ';' in for");

        bool no_step = has_parens ? self.check_tok(cparen) : self.check_tok(obrace);
        if (!no_step) {
            n.step = self.parse_expr();
        }
        if (has_parens) { self.consume_tok(cparen, "Expected ')' after for clauses"); }
        n.body = self.parse_stmt();
        return (ast_node*)n;
    }

    ast_node* parse_switch_stmt(parser_t* self) {
        switch_stmt* n = (switch_stmt*)arc_malloc(sizeof(parser__NS_switch_stmt));
        memset((i8*)n, 0, sizeof(parser__NS_switch_stmt));
        n.kind = nd_switch_stmt;
        n.line = (u64)self.advance_line_get();

        bool has_parens = self.match_tok(oparen);
        n.val = self.parse_expr();
        if (has_parens) { self.consume_tok(cparen, "Expected ')'"); }
        self.consume_tok(obrace, "Expected '{'");

        i32 cases_cap = 8;
        n.case_vals       = (expr_node***)arc_malloc(sizeof(i8*) * (u64)cases_cap);
        n.case_bodies     = (block_stmt**)arc_malloc(sizeof(i8*) * (u64)cases_cap);
        n.case_is_default = (bool*)arc_malloc(sizeof(bool) * (u64)cases_cap);
        n.cases_len = 0;
        n.cases_cap = cases_cap;

        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            bool is_default = false;
            expr_node* case_val = (expr_node*)0;

            if (self.match_tok(kw_case)) {
                case_val = self.parse_expr();
            } else {
                self.consume_tok(kw_default, "Expected 'case' or 'default'");
                is_default = true;
            }
            self.consume_tok(colon, "Expected ':' after case label");

            block_stmt* body = (block_stmt*)arc_malloc(sizeof(parser__NS_block_stmt));
            memset((i8*)body, 0, sizeof(parser__NS_block_stmt));
            body.kind = nd_block;
            i32 body_cap = 8;
            body.stmts = (ast_node**)arc_malloc(sizeof(i8*) * (u64)body_cap);

            while (!self.check_tok(kw_case) &&
                   !self.check_tok(kw_default) &&
                   !self.check_tok(cbrace) &&
                   !self.is_at_end_p()) {
                ast_node* s = self.parse_stmt();
                if (s != (ast_node*)0) {
                    if (body.stmts_len >= body_cap) {
                        body_cap = body_cap * 2;
                        body.stmts = (ast_node**)arc_realloc((i8*)body.stmts, sizeof(i8*) * (u64)body_cap);
                    }
                    body.stmts[body.stmts_len] = s;
                    body.stmts_len = body.stmts_len + 1;
                }
            }

            if (n.cases_len >= n.cases_cap) {
                n.cases_cap = n.cases_cap * 2;
                n.case_vals       = (expr_node***)arc_realloc((i8*)n.case_vals,       sizeof(i8*) * (u64)n.cases_cap);
                n.case_bodies     = (block_stmt**)arc_realloc((i8*)n.case_bodies,     sizeof(i8*) * (u64)n.cases_cap);
                n.case_is_default = (bool*)arc_realloc((i8*)n.case_is_default, sizeof(bool) * (u64)n.cases_cap);
            }
            n.case_vals[n.cases_len]       = (expr_node**)case_val;
            n.case_bodies[n.cases_len]     = body;
            n.case_is_default[n.cases_len] = is_default;
            n.cases_len = n.cases_len + 1;
        }
        self.consume_tok(cbrace, "Expected '}' after switch");
        return (ast_node*)n;
    }

    ast_node* parse_return_stmt(parser_t* self) {
        return_stmt* n = (return_stmt*)arc_malloc(sizeof(parser__NS_return_stmt));
        memset((i8*)n, 0, sizeof(parser__NS_return_stmt));
        n.kind = nd_return_stmt;
        n.line = (u64)self.advance_line_get();
        if (!self.check_tok(sm)) {
            n.val     = self.parse_expr();
            n.has_val = true;
        }
        self.consume_tok(sm, "Expected ';' after return");
        return (ast_node*)n;
    }

    ast_node* parse_defer_stmt(parser_t* self) {
        defer_stmt* n = (defer_stmt*)arc_malloc(sizeof(parser__NS_defer_stmt));
        memset((i8*)n, 0, sizeof(parser__NS_defer_stmt));
        n.kind = self.check_tok(kw_errdefer) ? nd_errdefer_stmt : nd_defer_stmt;
        n.line = (u64)self.advance_line_get();
        if (self.check_tok(obrace)) {
            n.blk      = (i8*)self.parse_block();
            n.is_block = true;
        } else {
            n.expr = self.parse_expr();
            self.consume_tok(sm, "Expected ';' after defer expression");
        }
        return (ast_node*)n;
    }

    ast_node* parse_stmt(parser_t* self) {
        // Empty statement
        if (self.check_tok(sm)) {
            block_stmt* blk = (block_stmt*)arc_malloc(sizeof(parser__NS_block_stmt));
            memset((i8*)blk, 0, sizeof(parser__NS_block_stmt));
            blk.kind = nd_block;
            blk.line = (u64)self.advance_line_get();
            return (ast_node*)blk;
        }
        if (self.check_tok(obrace))      { return (ast_node*)self.parse_block(); }
        if (self.check_tok(kw_if))       { return self.parse_if_stmt(); }
        if (self.check_tok(kw_while))    { return self.parse_while_stmt(); }
        if (self.check_tok(kw_for))      { return self.parse_for_stmt(); }
        if (self.check_tok(kw_switch))   { return self.parse_switch_stmt(); }
        if (self.check_tok(kw_return))   { return self.parse_return_stmt(); }
        if (self.check_tok(kw_defer))    { return self.parse_defer_stmt(); }
        if (self.check_tok(kw_errdefer)) { return self.parse_defer_stmt(); }

        if (self.check_tok(kw_break)) {
            break_stmt* n = (break_stmt*)arc_malloc(sizeof(parser__NS_break_stmt));
            memset((i8*)n, 0, sizeof(parser__NS_break_stmt));
            n.kind = nd_break_stmt;
            n.line = (u64)self.advance_line_get();
            self.consume_tok(sm, "Expected ';'");
            return (ast_node*)n;
        }
        if (self.check_tok(kw_continue)) {
            continue_stmt* n = (continue_stmt*)arc_malloc(sizeof(parser__NS_continue_stmt));
            memset((i8*)n, 0, sizeof(parser__NS_continue_stmt));
            n.kind = nd_continue_stmt;
            n.line = (u64)self.advance_line_get();
            self.consume_tok(sm, "Expected ';'");
            return (ast_node*)n;
        }

        if (self.check_tok(kw_try)) {
            try_expr_stmt* n = (try_expr_stmt*)arc_malloc(sizeof(parser__NS_try_expr_stmt));
            memset((i8*)n, 0, sizeof(parser__NS_try_expr_stmt));
            n.kind = nd_try_expr_stmt;
            n.line = (u64)self.advance_line_get();
            n.expr = self.parse_expr();
            self.consume_tok(sm, "Expected ';' after try expression");
            return (ast_node*)n;
        }

        if (self.check_tok(kw_static)) {
            self.advance_tok();
            if (self.is_type_start()) {
                var_decl* vd = self.parse_local_var_decl();
                vd.is_static_local = true;
                return (ast_node*)vd;
            }
            return self.parse_stmt();
        }

        if (self.check_tok(kw_comptime)) {
            self.advance_tok();
            // comptime type T = SomeType; — first-class type alias
            if (self.check_tok(kw_type)) {
                lexer.token_t ahead = self.peek_at_tok(1);
                if (ahead.type == assign) {
                    // `comptime type = ...` — type itself as a value (skip)
                } else {
                    // `comptime type Name = TypeExpr;`
                    self.advance_tok(); // consume 'type'
                    typedef_decl* td = (typedef_decl*)arc_malloc(sizeof(parser__NS_typedef_decl));
                    memset((i8*)td, 0, sizeof(parser__NS_typedef_decl));
                    td.kind = nd_typedef_decl;
                    td.name = lexer.str_dup(self.consume_id_value("Expected name after 'comptime type'"));
                    self.consume_tok(assign, "Expected '=' after type alias name");
                    td.target = self.parse_type();
                    self.match_tok(sm);
                    return (ast_node*)td;
                }
            }
            if (self.is_type_start()) {
                var_decl* vd = self.parse_local_var_decl();
                vd.is_constexpr = true;
                return (ast_node*)vd;
            }
            // comptime if: mark the resulting if_stmt as is_constexpr
            if (self.check_tok(kw_if)) {
                ast_node* res2 = self.parse_if_stmt();
                if (res2 != (ast_node*)0 && res2.kind == nd_if_stmt) {
                    if_stmt* cif = (if_stmt*)res2;
                    cif.is_constexpr = true;
                }
                return res2;
            }
            return self.parse_stmt();
        }

        if (self.check_tok(kw_asm)) {
            asm_stmt* n = (asm_stmt*)arc_malloc(sizeof(parser__NS_asm_stmt));
            memset((i8*)n, 0, sizeof(parser__NS_asm_stmt));
            n.kind = nd_asm_stmt;
            n.line = (u64)self.advance_line_get();
            lexer.token_t body_tok = self.consume_tok(asm_body, "Expected '{...}' after __asm__");
            n.raw_instructions = lexer.str_dup(body_tok.value);
            return (ast_node*)n;
        }

        // Anonymous istruc instance within a function body: `istruc { ... } var_name;`
        // peek_at_type(1) lets us distinguish `istruc { ... } x;` from normal istruc decls
        // Return only the type_decl here; parse_block will emit pending_anon_var directly
        // into the parent block so the variable stays in the same scope as subsequent stmts.
        if (self.check_tok(kw_istruc) && self.peek_at_type(1) == obrace) {
            ast_node* type_decl = self.parse_class_decl_stub();
            // pending_anon_var is set by parse_class_decl_stub; parse_block will pick it up
            return type_decl;
        }

        if (self.is_type_start()) {
            return (ast_node*)self.parse_local_var_decl();
        }

        // Expression statement
        expr_stmt* es = (expr_stmt*)arc_malloc(sizeof(parser__NS_expr_stmt));
        memset((i8*)es, 0, sizeof(parser__NS_expr_stmt));
        es.kind = nd_expr_stmt;
        es.line = (u64)self.peek_line();
        es.expr = self.parse_expr();
        if (es.expr != (expr_node*)0 && es.expr.kind == ek_except_expr) {
            self.match_tok(sm);
        } else {
            self.consume_tok(sm, "Expected ';' after expression");
        }
        return (ast_node*)es;
    }

    // ---- Expression parsing (Pratt precedence climbing) ----

    expr_node* parse_expr(parser_t* self) {
        return self.parse_assignment();
    }

    expr_node* parse_assignment(parser_t* self) {
        expr_node* lhs = self.parse_null_coal();

        i32 bop = -1;
        i32 tt  = self.peek_type();
        if (tt == assign)    { bop = bop_assign; }
        else if (tt == plus_eq)  { bop = bop_add_assign; }
        else if (tt == minus_eq) { bop = bop_sub_assign; }
        else if (tt == star_eq)  { bop = bop_mul_assign; }
        else if (tt == slash_eq) { bop = bop_div_assign; }
        else if (tt == mod_eq)   { bop = bop_mod_assign; }
        else if (tt == amp_eq)   { bop = bop_and_assign; }
        else if (tt == pipe_eq)  { bop = bop_or_assign; }
        else if (tt == caret_eq) { bop = bop_xor_assign; }
        else if (tt == shl_eq)   { bop = bop_shl_assign; }
        else if (tt == shr_eq)   { bop = bop_shr_assign; }

        if (bop >= 0) {
            u64 ln = (u64)self.advance_line_get();
            expr_node* rhs = self.parse_assignment();
            expr_node* n = alloc_expr_node();
            n.kind = ek_assign;
            n.line = ln;
            n.lhs  = lhs;
            n.rhs  = rhs;
            n.bop  = bop;
            return n;
        }
        return lhs;
    }

    expr_node* parse_null_coal(parser_t* self) {
        expr_node* lhs = self.parse_ternary();
        while (self.check_tok(question_question)) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_null_coal;
            n.line = (u64)self.prev_line();
            n.lhs  = lhs;
            if (self.check_tok(obrace)) {
                n.handler_block = (i8*)self.parse_block();
            } else {
                n.rhs = self.parse_ternary();
            }
            lhs = n;
        }
        return lhs;
    }

    expr_node* parse_ternary(parser_t* self) {
        expr_node* cond = self.parse_or();
        if (!self.match_tok(question)) { return cond; }
        expr_node* n = alloc_expr_node();
        n.kind  = ek_ternary;
        n.line  = (u64)self.prev_line();
        n.cond  = cond;
        n.then_e = self.parse_expr();
        self.consume_tok(colon, "Expected ':' in ternary");
        n.else_e = self.parse_ternary();
        return n;
    }

    expr_node* parse_or(parser_t* self) {
        expr_node* lhs = self.parse_and();
        while (self.check_tok(or_)) {
            u64 ln = (u64)self.advance_line_get();
            expr_node* n = alloc_expr_node();
            n.kind = ek_binary;
            n.line = ln;
            n.lhs  = lhs;
            n.bop  = bop_log_or;
            n.rhs  = self.parse_and();
            lhs = n;
        }
        return lhs;
    }

    expr_node* parse_and(parser_t* self) {
        expr_node* lhs = self.parse_bitor();
        while (self.check_tok(and_)) {
            u64 ln = (u64)self.advance_line_get();
            expr_node* n = alloc_expr_node();
            n.kind = ek_binary;
            n.line = ln;
            n.lhs  = lhs;
            n.bop  = bop_log_and;
            n.rhs  = self.parse_bitor();
            lhs = n;
        }
        return lhs;
    }

    expr_node* parse_bitor(parser_t* self) {
        expr_node* lhs = self.parse_bitxor();
        while (self.check_tok(bit_or)) {
            u64 ln = (u64)self.advance_line_get();
            expr_node* n = alloc_expr_node();
            n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop_bit_or;
            n.rhs = self.parse_bitxor();
            lhs = n;
        }
        return lhs;
    }

    expr_node* parse_bitxor(parser_t* self) {
        expr_node* lhs = self.parse_bitand();
        while (self.check_tok(bit_xor)) {
            u64 ln = (u64)self.advance_line_get();
            expr_node* n = alloc_expr_node();
            n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop_bit_xor;
            n.rhs = self.parse_bitand();
            lhs = n;
        }
        return lhs;
    }

    expr_node* parse_bitand(parser_t* self) {
        expr_node* lhs = self.parse_equality();
        while (self.check_tok(addr)) {
            u64 ln = (u64)self.advance_line_get();
            expr_node* n = alloc_expr_node();
            n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop_bit_and;
            n.rhs = self.parse_equality();
            lhs = n;
        }
        return lhs;
    }

    expr_node* parse_equality(parser_t* self) {
        expr_node* lhs = self.parse_compare();
        bool running = true;
        while (running) {
            i32 bop = -1;
            if (self.check_tok(eq)) { bop = bop_eq; }
            else if (self.check_tok(ne)) { bop = bop_ne; }
            if (bop < 0) { running = false; }
            else {
                u64 ln = (u64)self.advance_line_get();
                expr_node* n = alloc_expr_node();
                n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop;
                n.rhs = self.parse_compare();
                lhs = n;
            }
        }
        return lhs;
    }

    expr_node* parse_compare(parser_t* self) {
        expr_node* lhs = self.parse_shift();
        bool running = true;
        while (running) {
            i32 bop = -1;
            if (self.check_tok(lt))  { bop = bop_lt; }
            else if (self.check_tok(gt))  { bop = bop_gt; }
            else if (self.check_tok(lte)) { bop = bop_lte; }
            else if (self.check_tok(gte)) { bop = bop_gte; }
            if (bop < 0) { running = false; }
            else {
                u64 ln = (u64)self.advance_line_get();
                expr_node* n = alloc_expr_node();
                n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop;
                n.rhs = self.parse_shift();
                lhs = n;
            }
        }
        return lhs;
    }

    expr_node* parse_shift(parser_t* self) {
        expr_node* lhs = self.parse_add();
        bool running = true;
        while (running) {
            i32 bop = -1;
            if (self.check_tok(left))  { bop = bop_shl; }
            else if (self.check_tok(right)) { bop = bop_shr; }
            if (bop < 0) { running = false; }
            else {
                u64 ln = (u64)self.advance_line_get();
                expr_node* n = alloc_expr_node();
                n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop;
                n.rhs = self.parse_add();
                lhs = n;
            }
        }
        return lhs;
    }

    expr_node* parse_add(parser_t* self) {
        expr_node* lhs = self.parse_mul();
        bool running = true;
        while (running) {
            i32 bop = -1;
            if (self.check_tok(plus))  { bop = bop_add; }
            else if (self.check_tok(minus)) { bop = bop_sub; }
            if (bop < 0) { running = false; }
            else {
                u64 ln = (u64)self.advance_line_get();
                expr_node* n = alloc_expr_node();
                n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop;
                n.rhs = self.parse_mul();
                lhs = n;
            }
        }
        return lhs;
    }

    expr_node* parse_mul(parser_t* self) {
        expr_node* lhs = self.parse_unary();
        bool running = true;
        while (running) {
            i32 bop = -1;
            if (self.check_tok(ast))   { bop = bop_mul; }
            else if (self.check_tok(slash)) { bop = bop_div; }
            else if (self.check_tok(mod))   { bop = bop_mod; }
            if (bop < 0) { running = false; }
            else {
                u64 ln = (u64)self.advance_line_get();
                expr_node* n = alloc_expr_node();
                n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop;
                n.rhs = self.parse_unary();
                lhs = n;
            }
        }
        return lhs;
    }

    expr_node* parse_unary(parser_t* self) {
        i32 tt = self.peek_type();
        u64 ln = (u64)self.peek_line();

        if (tt == minus) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_neg;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == plus) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_pos;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == bit_not) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_bit_not;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == not_) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_log_not;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == inc) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_pre_inc;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == dec) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_pre_dec;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == ast) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_deref;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == addr) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_addr_of;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == kw_try) {
            // try expr — propagates error upward; yields value on success
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_try_expr;
            n.line = ln;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == kw_error) {
            // error.Variant or error.Variant(payload) — return -1 sentinel
            self.advance_tok(); // consume 'error'
            expr_node* payload_expr = (expr_node*)0;
            if (self.check_tok(dot)) {
                self.advance_tok(); // consume '.'
                if (self.check_tok(id)) { self.advance_tok(); } // consume variant name
                // Optional payload: error.Variant(expr)
                if (self.check_tok(oparen)) {
                    self.advance_tok(); // consume '('
                    if (!self.check_tok(cparen)) { payload_expr = self.parse_expr(); }
                    self.consume_tok(cparen, "Expected ')' after error payload");
                }
            }
            expr_node* n = alloc_expr_node();
            n.kind    = ek_error_lit;
            n.line    = ln;
            n.operand = payload_expr;
            return n;
        }
        if (tt == kw_sizeof) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_sizeof_e; n.line = ln;
            self.consume_tok(oparen, "Expected '(' after sizeof");
            if (self.is_type_start()) {
                n.cast_type = self.parse_type();
            } else {
                n.operand = self.parse_expr();
            }
            self.consume_tok(cparen, "Expected ')' after sizeof argument");
            return n;
        }

        // Cast: (type)expr — check if next is ( followed by a type
        if (tt == oparen) {
            i32 saved = self.current;
            self.advance_tok();  // consume (
            if (self.is_cast_start()) {
                type_node* ct = self.parse_type();
                if (self.check_tok(cparen)) {
                    self.advance_tok();  // consume )
                    expr_node* n = alloc_expr_node();
                    n.kind = ek_cast; n.line = ln;
                    n.cast_type = ct;
                    n.operand = self.parse_unary();
                    return n;
                }
            }
            self.current = saved;
        }

        return self.parse_postfix();
    }

    expr_node* parse_postfix(parser_t* self) {
        expr_node* lhs = self.parse_primary();

        bool running = true;
        while (running) {
            if (self.check_tok(dot) && self.peek_at_type(1) != obrace) {
                self.advance_tok();
                lexer.token_t mem_name = self.consume_name_tok("Expected member name after '.'");
                if (self.match_tok(oparen)) {
                    // Method call: obj.method(args)
                    expr_node* callee = alloc_expr_node();
                    callee.kind = ek_member;
                    callee.line = (u64)mem_name.line;
                    callee.object = lhs;
                    callee.member_name = lexer.str_dup(mem_name.value);
                    expr_node* call_n = alloc_expr_node();
                    call_n.kind = ek_call;
                    call_n.line = (u64)mem_name.line;
                    call_n.callee = callee;
                    // Parse arguments
                    expr_ptr_vec args;
                    expr_ptr_vec_init(&args);
                    if (!self.check_tok(cparen)) {
                        bool parsing_args = true;
                        while (parsing_args) {
                            expr_ptr_vec_push(&args, self.parse_expr());
                            if (!self.match_tok(comma)) { parsing_args = false; }
                        }
                    }
                    self.consume_tok(cparen, "Expected ')' after arguments");
                    call_n.args     = args.data;
                    call_n.args_len = args.len;
                    lhs = call_n;
                } else {
                    expr_node* n = alloc_expr_node();
                    n.kind = ek_member;
                    n.line = (u64)mem_name.line;
                    n.object = lhs;
                    n.member_name = lexer.str_dup(mem_name.value);
                    lhs = n;
                }
            } else if (self.check_tok(obracket)) {
                self.advance_tok();
                expr_node* idx = self.parse_expr();
                self.consume_tok(cbracket, "Expected ']'");
                expr_node* n = alloc_expr_node();
                n.kind  = ek_subscript;
                n.line  = (u64)self.prev_line();
                n.object = lhs;
                n.index  = idx;
                lhs = n;
            } else if (self.check_tok(oparen)) {
                // Postfix call: expr(args) — for function pointer / lambda invocation
                u64 call_ln = (u64)self.peek_line();
                self.advance_tok(); // consume '('
                expr_node* call_n = alloc_expr_node();
                call_n.kind   = ek_call;
                call_n.line   = call_ln;
                call_n.callee = lhs;
                expr_ptr_vec call_args;
                expr_ptr_vec_init(&call_args);
                if (!self.check_tok(cparen)) {
                    bool pa = true;
                    while (pa) {
                        expr_ptr_vec_push(&call_args, self.parse_expr());
                        if (!self.match_tok(comma)) { pa = false; }
                    }
                }
                self.consume_tok(cparen, "Expected ')' after call arguments");
                call_n.args     = call_args.data;
                call_n.args_len = call_args.len;
                lhs = call_n;
            } else if (self.check_tok(inc)) {
                u64 ln = (u64)self.advance_line_get();
                expr_node* n = alloc_expr_node();
                n.kind = ek_unary; n.line = ln; n.uop = uop_post_inc; n.operand = lhs;
                lhs = n;
            } else if (self.check_tok(dec)) {
                u64 ln = (u64)self.advance_line_get();
                expr_node* n = alloc_expr_node();
                n.kind = ek_unary; n.line = ln; n.uop = uop_post_dec; n.operand = lhs;
                lhs = n;
            } else if (self.check_tok(kw_catch)) {
                self.advance_tok(); // consume 'catch'
                i8* handler_var = (i8*)0;
                if (self.check_tok(bit_or)) {
                    self.advance_tok(); // consume '|'
                    if (self.check_tok(id)) {
                        lexer.token_t evar_tok = self.advance_tok();
                        handler_var = lexer.str_dup(evar_tok.value);
                    }
                    self.consume_tok(bit_or, "Expected '|' after catch variable");
                }
                i8* handler_blk = (i8*)0;
                if (self.check_tok(obrace)) {
                    handler_blk = (i8*)self.parse_block();
                }
                expr_node* n = alloc_expr_node();
                n.kind = ek_except_expr;
                n.line = (u64)self.prev_line();
                n.object = lhs;
                n.member_name = handler_var;
                n.handler_block = handler_blk;
                lhs = n;
            } else if (self.check_tok(obrace) && self.peek_at_type(1) == dot) {
                // ADT named-struct constructor: expr { .field = val, ... }
                u64 brace_ln = (u64)self.advance_line_get(); // consume '{'
                expr_node* n = alloc_expr_node();
                n.kind = ek_class_init; n.line = brace_ln;
                n.object = lhs; // base expression (e.g., event.key_press)
                str_vec field_names; str_vec_init(&field_names);
                expr_ptr_vec field_vals; expr_ptr_vec_init(&field_vals);
                while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                    self.consume_tok(dot, "Expected '.' in field init");
                    lexer.token_t fn2 = self.consume_name_tok("Expected field name");
                    self.consume_tok(assign, "Expected '=' in field init");
                    expr_node* fv = self.parse_expr();
                    str_vec_push(&field_names, lexer.str_dup(fn2.value));
                    expr_ptr_vec_push(&field_vals, fv);
                    self.match_tok(comma);
                }
                self.consume_tok(cbrace, "Expected '}' after field inits");
                n.field_names = field_names.data;
                n.field_vals  = field_vals.data;
                n.field_count = field_names.len;
                lhs = n;
            } else if (self.check_tok(dot) && self.peek_at_type(1) == obrace) {
                // ADT istruc constructor: expr .{ .field = val, ... }
                u64 dot_ln = (u64)self.advance_line_get(); // consume '.'
                self.advance_tok(); // consume '{'
                expr_node* n = alloc_expr_node();
                n.kind = ek_class_init; n.line = dot_ln;
                n.object = lhs;
                n.is_implicit_init = true;
                str_vec field_names; str_vec_init(&field_names);
                expr_ptr_vec field_vals; expr_ptr_vec_init(&field_vals);
                while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                    self.consume_tok(dot, "Expected '.' in field init");
                    lexer.token_t fn2 = self.consume_name_tok("Expected field name");
                    self.consume_tok(assign, "Expected '=' in field init");
                    expr_node* fv = self.parse_expr();
                    str_vec_push(&field_names, lexer.str_dup(fn2.value));
                    expr_ptr_vec_push(&field_vals, fv);
                    self.match_tok(comma);
                }
                self.consume_tok(cbrace, "Expected '}' after field inits");
                n.field_names = field_names.data;
                n.field_vals  = field_vals.data;
                n.field_count = field_names.len;
                lhs = n;
            } else {
                running = false;
            }
        }
        return lhs;
    }

    // Lambda expression: [captures](params) RetType? { body }
    // Captures: [=] = all by value, [&] = all by ref, [=a,&b] = explicit
    expr_node* parse_lambda_expr(parser_t* self) {
        u64 ln = (u64)self.peek_line();
        self.advance_tok(); // consume '['

        // Parse capture list
        i32   cap_cap  = 8;
        i8**  cap_names = (i8**)arc_malloc(sizeof(i8*) * (u64)cap_cap);
        i32*  cap_byref = (i32*)arc_malloc(sizeof(i32) * (u64)cap_cap);
        i32   cap_len   = 0;
        bool  cap_all_val = false;
        bool  cap_all_ref = false;

        while (!self.check_tok(cbracket) && !self.is_at_end_p()) {
            if (self.check_tok(assign)) {
                self.advance_tok();
                if (self.check_tok(cbracket) || self.check_tok(comma)) {
                    // bare '=' — capture all by value
                    cap_all_val = true;
                } else {
                    // =name — explicit by-value capture
                    if (cap_len >= cap_cap) {
                        cap_cap = cap_cap * 2;
                        cap_names = (i8**)arc_realloc((i8*)cap_names, sizeof(i8*) * (u64)cap_cap);
                        cap_byref = (i32*)arc_realloc((i8*)cap_byref, sizeof(i32) * (u64)cap_cap);
                    }
                    lexer.token_t cn = self.advance_tok();
                    cap_names[cap_len] = lexer.str_dup(cn.value);
                    cap_byref[cap_len] = 0;
                    cap_len = cap_len + 1;
                }
            } else if (self.check_tok(addr)) {
                self.advance_tok();
                if (self.check_tok(cbracket) || self.check_tok(comma)) {
                    // bare '&' — capture all by reference
                    cap_all_ref = true;
                } else {
                    // &name — explicit by-ref capture
                    if (cap_len >= cap_cap) {
                        cap_cap = cap_cap * 2;
                        cap_names = (i8**)arc_realloc((i8*)cap_names, sizeof(i8*) * (u64)cap_cap);
                        cap_byref = (i32*)arc_realloc((i8*)cap_byref, sizeof(i32) * (u64)cap_cap);
                    }
                    lexer.token_t cn = self.advance_tok();
                    cap_names[cap_len] = lexer.str_dup(cn.value);
                    cap_byref[cap_len] = 1;
                    cap_len = cap_len + 1;
                }
            } else if (self.check_tok(id)) {
                // name (bare identifier) — capture by value
                if (cap_len >= cap_cap) {
                    cap_cap = cap_cap * 2;
                    cap_names = (i8**)arc_realloc((i8*)cap_names, sizeof(i8*) * (u64)cap_cap);
                    cap_byref = (i32*)arc_realloc((i8*)cap_byref, sizeof(i32) * (u64)cap_cap);
                }
                lexer.token_t cn = self.advance_tok();
                cap_names[cap_len] = lexer.str_dup(cn.value);
                cap_byref[cap_len] = 0;
                cap_len = cap_len + 1;
            } else {
                self.advance_tok(); // skip unknown tokens in capture list
            }
            if (self.check_tok(comma)) { self.advance_tok(); }
        }
        self.consume_tok(cbracket, "Expected ']' to close lambda capture list");

        // Parse parameter list
        self.consume_tok(oparen, "Expected '(' after lambda capture list");
        i32         param_cap   = 8;
        type_node** param_types = (type_node**)arc_malloc(sizeof(i8*) * (u64)param_cap);
        i8**        param_names = (i8**)arc_malloc(sizeof(i8*) * (u64)param_cap);
        i32         param_len   = 0;
        while (!self.check_tok(cparen) && !self.is_at_end_p()) {
            if (self.check_tok(comma)) { self.advance_tok(); continue; }
            type_node* pt = self.parse_type();
            if (param_len >= param_cap) {
                param_cap = param_cap * 2;
                param_types = (type_node**)arc_realloc((i8*)param_types, sizeof(i8*) * (u64)param_cap);
                param_names = (i8**)arc_realloc((i8*)param_names, sizeof(i8*) * (u64)param_cap);
            }
            param_types[param_len] = pt;
            if (self.check_tok(id)) {
                param_names[param_len] = lexer.str_dup(self.advance_value_get());
            } else {
                i8 pname[32];
                snprintf(pname, (u64)32, "__lp%d", param_len);
                param_names[param_len] = lexer.str_dup(pname);
            }
            param_len = param_len + 1;
        }
        self.consume_tok(cparen, "Expected ')' after lambda parameters");

        // Optional return type (omit if next is '{')
        type_node* ret_type = (type_node*)0;
        if (!self.check_tok(obrace)) {
            ret_type = self.parse_type();
        }

        // Body
        block_stmt* body = self.parse_block();

        // Build the ek_lambda node
        expr_node* n = alloc_expr_node();
        n.kind    = ek_lambda;
        n.line    = ln;
        n.lambda_cap_names   = cap_names;
        n.lambda_cap_byref   = cap_byref;
        n.lambda_cap_len     = cap_len;
        n.lambda_param_types = param_types;
        n.lambda_param_names = param_names;
        n.lambda_param_len   = param_len;
        n.lambda_ret_type    = ret_type;
        n.lambda_body        = (i8*)body;
        // lambda_synth_name filled by IR stage

        // Store global capture flags in str_val as a 2-char string "vr"
        // first char 'v'=capture_all_val, 'r'=capture_all_ref
        i8* flags = (i8*)arc_malloc(3);
        flags[0] = cap_all_val ? 'v' : '_';
        flags[1] = cap_all_ref ? 'r' : '_';
        flags[2] = 0;
        n.str_val = flags;
        return n;
    }

    expr_node* parse_primary(parser_t* self) {
        lexer.token_t tok = self.peek_tok();
        i32 tt  = tok.type;
        u64 ln  = (u64)tok.line;

        if (tt == int_lit) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind    = ek_int_lit;
            n.line    = ln;
            n.int_val = strtoll(tok.value, (i8**)0, 0);
            n.str_val = lexer.str_dup(tok.value);
            return n;
        }
        if (tt == float_lit) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind    = ek_float_lit;
            n.line    = ln;
            n.flt_val = strtod(tok.value, (i8**)0);
            n.str_val = lexer.str_dup(tok.value);
            return n;
        }
        if (tt == string_lit) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind    = ek_string_lit;
            n.line    = ln;
            n.str_val = lexer.str_dup(tok.value);
            return n;
        }
        if (tt == char_lit) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind    = ek_char_lit;
            n.line    = ln;
            n.str_val = lexer.str_dup(tok.value);
            if (tok.value != (i8*)0 && tok.value[0] != 0) {
                n.int_val = (i64)tok.value[0];
            }
            return n;
        }
        if (tt == kw_true) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind     = ek_bool_lit; n.line = ln; n.bool_val = true;
            return n;
        }
        if (tt == kw_false) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind     = ek_bool_lit; n.line = ln; n.bool_val = false;
            return n;
        }
        if (tt == kw_null) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_null_lit; n.line = ln;
            return n;
        }

        // ref expr — context-aware address-of (depth determined at IR emit time)
        if (tt == kw_ref) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind    = ek_ref_expr;
            n.line    = ln;
            n.operand = self.parse_unary();
            return n;
        }

        // Lambda expression: [captures](params) RetType? { body }
        if (tt == obracket) {
            return self.parse_lambda_expr();
        }

        // quote { ... } — capture raw token sequence as a tokenstream literal
        if (tt == kw_quote) {
            self.advance_tok();
            self.consume_tok(obrace, "Expected '{' after quote");
            expr_node* n = alloc_expr_node();
            n.kind = ek_quote;
            n.line = ln;
            // Capture token text until matching '}'
            i32 depth_q = 1;
            i32 buf_cap = 256; i32 buf_len = 0;
            i8* buf = (i8*)arc_malloc((u64)buf_cap);
            buf[0] = 0;
            while (depth_q > 0 && !self.is_at_end_p()) {
                lexer.token_t qt = self.advance_tok();
                if (qt.type == obrace) { depth_q = depth_q + 1; }
                if (qt.type == cbrace) { depth_q = depth_q - 1; if (depth_q == 0) { break; } }
                if (qt.value != (i8*)0) {
                    i32 vlen = (i32)strlen(qt.value);
                    while (buf_len + vlen + 2 >= buf_cap) {
                        buf_cap = buf_cap * 2;
                        buf = (i8*)arc_realloc(buf, (u64)buf_cap);
                    }
                    i32 vi = 0;
                    while (vi < vlen) { buf[buf_len] = qt.value[vi]; buf_len = buf_len + 1; vi = vi + 1; }
                    buf[buf_len] = ' '; buf_len = buf_len + 1;
                    buf[buf_len] = 0;
                }
            }
            n.str_val = lexer.str_dup(buf);
            arc_free(buf);
            return n;
        }

        if (tt == at) {
            self.advance_tok();
            if (self.check_tok(id)) {
                lexer.token_t annot = self.advance_tok();
                // @typeinfo(T) intrinsic — compile-time type reflection
                if (strcmp(annot.value, "typeinfo") == 0 && self.check_tok(oparen)) {
                    self.advance_tok(); // consume (
                    expr_node* ti_n = alloc_expr_node();
                    ti_n.kind = ek_typeinfo_e;
                    ti_n.line = ln;
                    ti_n.cast_type = self.parse_type();
                    self.consume_tok(cparen, "Expected ')' after @typeinfo argument");
                    return ti_n;
                }
                // @shcopy(x) — explicit shallow copy
                if (strcmp(annot.value, "shcopy") == 0 && self.check_tok(oparen)) {
                    self.advance_tok();
                    expr_node* n = alloc_expr_node(); n.kind = ek_shcopy; n.line = ln;
                    n.operand = self.parse_expr();
                    self.consume_tok(cparen, "Expected ')' after @shcopy argument");
                    return n;
                }
                // @decopy(x) — deep copy
                if (strcmp(annot.value, "decopy") == 0 && self.check_tok(oparen)) {
                    self.advance_tok();
                    expr_node* n = alloc_expr_node(); n.kind = ek_decopy; n.line = ln;
                    n.operand = self.parse_expr();
                    self.consume_tok(cparen, "Expected ')' after @decopy argument");
                    return n;
                }
                // @move(x) — move (transfer ownership, zero source)
                if (strcmp(annot.value, "move") == 0 && self.check_tok(oparen)) {
                    self.advance_tok();
                    expr_node* n = alloc_expr_node(); n.kind = ek_move_expr; n.line = ln;
                    n.operand = self.parse_expr();
                    self.consume_tok(cparen, "Expected ')' after @move argument");
                    return n;
                }
                expr_node* n = alloc_expr_node();
                n.kind    = ek_annotation;
                n.line    = ln;
                n.str_val = lexer.str_dup(annot.value);
                return n;
            }
            expr_node* n = alloc_expr_node();
            n.kind = ek_annotation; n.line = ln; n.str_val = lexer.str_dup("");
            return n;
        }

        if (tt == id) {
            self.advance_tok();
            i8* name = lexer.str_dup(tok.value);

            // Generic call: func<Type>(args) — parse and save type args
            i8** gen_ta_ptrs = (i8**)0;
            i32 gen_ta_len   = 0;
            if (self.check_tok(lt)) {
                i32 saved_g = self.current;
                self.advance_tok(); // consume '<'
                i32 gen_ta_cap = 4;
                gen_ta_ptrs = (i8**)arc_malloc(sizeof(i8*) * (u64)gen_ta_cap);
                i32 depth_gc = 1;
                while (depth_gc > 0 && !self.is_at_end_p()) {
                    i32 tgc = self.peek_type();
                    if (tgc == gt && depth_gc == 1) {
                        depth_gc = 0; self.advance_tok();
                    } else if (tgc == lt) { depth_gc = depth_gc + 1; self.advance_tok(); }
                    else if (tgc == gt)   { depth_gc = depth_gc - 1; self.advance_tok(); }
                    else if (tgc == right && depth_gc <= 2) { depth_gc = 0; self.advance_tok(); }
                    else if (tgc == comma) { self.advance_tok(); }
                    else if (tgc == question) { depth_gc = 0; } // ternary — not generic args
                    else if (tgc == cparen || tgc == cbrace || tgc == sm) { depth_gc = 0; } // not inside generic args
                    else if (self.is_type_start()) {
                        type_node* gta = self.parse_type();
                        if (gen_ta_len >= gen_ta_cap) {
                            gen_ta_cap = gen_ta_cap * 2;
                            gen_ta_ptrs = (i8**)arc_realloc((i8*)gen_ta_ptrs, sizeof(i8*) * (u64)gen_ta_cap);
                        }
                        gen_ta_ptrs[gen_ta_len] = (i8*)gta;
                        gen_ta_len = gen_ta_len + 1;
                    } else { self.advance_tok(); }
                }
                // Only treat as generic if followed by '('
                if (!self.check_tok(oparen)) {
                    self.current = saved_g;
                    arc_free((i8*)gen_ta_ptrs);
                    gen_ta_ptrs = (i8**)0;
                    gen_ta_len  = 0;
                }
            }

            // Macro expansion: check if name is a const_resolve macro
            if (self.check_tok(oparen)) {
                macro_def_t* mdef = self.find_macro(name);
                if (mdef != (macro_def_t*)0) {
                    return self.expand_macro_call(mdef);
                }
            }

            // Function call or identifier
            if (self.match_tok(oparen)) {
                expr_node* callee = alloc_expr_node();
                callee.kind    = ek_identifier;
                callee.line    = ln;
                callee.str_val = name;

                expr_node* call_n = alloc_expr_node();
                call_n.kind   = ek_call;
                call_n.line   = ln;
                call_n.callee = callee;

                expr_ptr_vec args;
                expr_ptr_vec_init(&args);
                if (!self.check_tok(cparen)) {
                    bool parsing_a = true;
                    while (parsing_a) {
                        expr_ptr_vec_push(&args, self.parse_expr());
                        if (!self.match_tok(comma)) { parsing_a = false; }
                    }
                }
                self.consume_tok(cparen, "Expected ')' after arguments");
                call_n.args          = args.data;
                call_n.args_len      = args.len;
                call_n.type_args     = (type_node**)gen_ta_ptrs;
                call_n.type_args_len = gen_ta_len;
                return call_n;
            }

            // Struct/class init: Name { .field = val, ... }
            if (self.check_tok(obrace)) {
                // Quick check: look ahead to see if first token is '.'
                if (self.peek_at_type(1) == dot) {
                    self.advance_tok();  // consume {
                    expr_node* n = alloc_expr_node();
                    n.kind = ek_class_init;
                    n.line = ln;
                    type_node* it = alloc_type_node();
                    it.name = name;
                    n.init_type = it;

                    str_vec field_names;
                    str_vec_init(&field_names);
                    expr_ptr_vec field_vals;
                    expr_ptr_vec_init(&field_vals);

                    while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                        self.consume_tok(dot, "Expected '.' in field init");
                        lexer.token_t fn = self.consume_name_tok("Expected field name");
                        self.consume_tok(assign, "Expected '=' in field init");
                        expr_node* fv = self.parse_expr();
                        str_vec_push(&field_names, lexer.str_dup(fn.value));
                        expr_ptr_vec_push(&field_vals, fv);
                        self.match_tok(comma);
                    }
                    self.consume_tok(cbrace, "Expected '}' after field inits");
                    n.field_names  = field_names.data;
                    n.field_vals   = field_vals.data;
                    n.field_count  = field_names.len;
                    return n;
                }
            }

            expr_node* n = alloc_expr_node();
            n.kind    = ek_identifier;
            n.line    = ln;
            n.str_val = name;
            return n;
        }

        if (tt == oparen) {
            self.advance_tok();
            expr_node* e = self.parse_expr();
            self.consume_tok(cparen, "Expected ')'");
            return e;
        }

        if (tt == dot && self.peek_at_type(1) == obrace) {
            // Implicit init: .{ .field = val }
            self.advance_tok();  // consume .
            self.advance_tok();  // consume {
            expr_node* n = alloc_expr_node();
            n.kind = ek_class_init;
            n.line = ln;
            n.is_implicit_init = true;

            str_vec field_names;
            str_vec_init(&field_names);
            expr_ptr_vec field_vals;
            expr_ptr_vec_init(&field_vals);

            while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                self.consume_tok(dot, "Expected '.' in field init");
                lexer.token_t fn = self.consume_name_tok("Expected field name");
                self.consume_tok(assign, "Expected '=' in field init");
                expr_node* fv = self.parse_expr();
                str_vec_push(&field_names, lexer.str_dup(fn.value));
                expr_ptr_vec_push(&field_vals, fv);
                self.match_tok(comma);
            }
            self.consume_tok(cbrace, "Expected '}' after field inits");
            n.field_names = field_names.data;
            n.field_vals  = field_vals.data;
            n.field_count = field_names.len;
            return n;
        }

        // Keywords used as identifier references (e.g., a parameter named 'type').
        // Treat any keyword token as a bare identifier when in expression position.
        if (tt >= kw_if) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind    = ek_identifier;
            n.line    = ln;
            n.str_val = lexer.str_dup(tok.value);
            return n;
        }

        // Error: unexpected token in expression
        {
            i8* tok_name = lexer.tok_type_name(tt);
            i8* tok_val  = tok.value;
            if (tt == id && tok_val != (i8*)0 && tok_val[0] != 0) {
                printf("error at line %d: unexpected %s '%s' in expression\n", (i32)ln, tok_name, tok_val);
            } else {
                printf("error at line %d: unexpected %s in expression\n", (i32)ln, tok_name);
            }
        }
        self.had_parse_error = true;
        self.advance_tok();
        expr_node* n = alloc_expr_node();
        n.kind = ek_int_lit; n.line = ln; n.int_val = 0;
        return n;
    }

    // ---- Main parse entry point ----

    program_node* parse(parser_t* self) {
        program_node* prog = (program_node*)arc_malloc(sizeof(parser__NS_program_node));
        memset((i8*)prog, 0, sizeof(parser__NS_program_node));
        prog.kind = nd_program;
        prog.decls_cap = 64;
        prog.decls = (ast_node**)arc_malloc(sizeof(i8*) * (u64)prog.decls_cap);

        while (!self.is_at_end_p()) {
            ast_node* decl = self.parse_top_level();
            if (decl != (ast_node*)0) {
                if (prog.decls_len >= prog.decls_cap) {
                    prog.decls_cap = prog.decls_cap * 2;
                    prog.decls = (ast_node**)arc_realloc((i8*)prog.decls, sizeof(i8*) * (u64)prog.decls_cap);
                }
                prog.decls[prog.decls_len] = decl;
                prog.decls_len = prog.decls_len + 1;
            }
            // Emit any pending anonymous-istruc instance var queued by parse_class_decl_stub
            if (self.pending_anon_var != (ast_node*)0) {
                if (prog.decls_len >= prog.decls_cap) {
                    prog.decls_cap = prog.decls_cap * 2;
                    prog.decls = (ast_node**)arc_realloc((i8*)prog.decls, sizeof(i8*) * (u64)prog.decls_cap);
                }
                prog.decls[prog.decls_len] = self.pending_anon_var;
                prog.decls_len = prog.decls_len + 1;
                self.pending_anon_var = (ast_node*)0;
            }
        }
        return prog;
    }
}

} // namespace parser
