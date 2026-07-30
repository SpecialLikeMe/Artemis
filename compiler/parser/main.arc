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
    // 25 was nd_res_block ('res' keyword, removed). Left unused so the remaining
    // discriminants keep their values.
    nd_match_stmt   = 26,
}

// ---- Base AST node ----
struct ast_node {
    let kind: i32;
    let line: u64;
}

// Dynamic array of ast_node pointers
struct node_vec {
    let data: **ast_node;
    let len: i32;
    let cap: i32;
}

fn node_vec_init(v: *node_vec) void {
    v.data = (ast_node**)0;
    v.len  = 0;
    v.cap  = 0;
}

fn node_vec_push(v: *node_vec, n: *ast_node) void {
    if (v.len >= v.cap) {
        let mut nc: i32= v.cap == 0 ? 16 : v.cap * 2;
        v.data = (ast_node**)arc_realloc((i8*)v.data, sizeof(i8*) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = n;
    v.len = v.len + 1;
}

// ---- Statement nodes ----

struct block_stmt {
    let kind: i32;
    let line: u64;
    let stmts: **ast_node;
    let stmts_len: i32;
    let is_unsafe: bool;   // `@unsafe { ... }` — scoped opt-in for unsafe operations
}

struct expr_stmt {
    let kind: i32;
    let line: u64;
    let expr: *expr_node;
}

struct return_stmt {
    let kind: i32;
    let line: u64;
    let val: *expr_node;
    let has_val: bool;
}

struct break_stmt {
    let kind: i32;
    let line: u64;
}

struct continue_stmt {
    let kind: i32;
    let line: u64;
}

struct if_stmt {
    let kind: i32;
    let line: u64;
    let cond: *expr_node;
    let then_body: *ast_node;
    let else_body: *ast_node;
    let is_constexpr: bool;
    let then_capture: *i8;
    let else_capture: *i8;
}

struct while_stmt {
    let kind: i32;
    let line: u64;
    let cond: *expr_node;
    let body: *ast_node;
}

struct for_stmt {
    let kind: i32;
    let line: u64;
    let init: *ast_node;
    let cond: *expr_node;
    let step: *expr_node;
    let body: *ast_node;
}

struct for_range_stmt {
    let kind: i32;
    let line: u64;
    let var_type: *type_node;
    let var_name: *i8;
    let range: *expr_node;
    let body: *ast_node;
}

// switch case entry
struct switch_case {
    let case_vals: **expr_node;   // array of case values (null entry = default)
    let case_is_default: *bool;
    let case_bodies: **block_stmt;
    let cases_len: i32;
}

struct switch_stmt {
    let kind: i32;
    let line: u64;
    let val: *expr_node;
    let case_vals: ***expr_node;   // array of (expr_node*) or null for default
    let case_bodies: **block_stmt;
    let case_is_default: *bool;
    let cases_len: i32;
    let cases_cap: i32;
}

struct defer_stmt {
    let kind: i32;
    let line: u64;
    let expr: *expr_node;
    let blk: *i8;   // actually block_stmt*
    let is_block: bool;
}

struct asm_stmt {
    let kind: i32;
    let line: u64;
    let raw_instructions: *i8;
}

struct try_expr_stmt {
    let kind: i32;
    let line: u64;
    let expr: *expr_node;
}

// ---- Declaration nodes ----

struct param_decl {
    let type: *type_node;
    let name: *i8;
    let line: u64;
}

struct proc_attr {
    let name: *i8;
    let args: **i8;
    let args_len: i32;
}

struct var_decl {
    let kind: i32;
    let line: u64;
    let type: *type_node;
    let name: *i8;
    let init: *expr_node;
    let has_init: bool;
    let is_constexpr: bool;
    let is_sta: bool;
    let is_static_local: bool; // `static type name;` inside a function
    let is_static: bool;       // `static field;` inside an istruc → module global
    let has_ctor_parens: bool;
    let ctor_args: **i8;
    let ctor_args_len: i32;
    let is_pub: bool;
    let attributes: *proc_attr;
    let attributes_len: i32;
    let is_mutable: bool;  // declared with `let mut`
    let is_extern: bool;   // `extern let name: T;` — defined in another translation unit
}

struct func_decl {
    let kind: i32;
    let line: u64;
    let ret_type: *type_node;
    let name: *i8;
    let params: *param_decl;
    let params_len: i32;
    let is_variadic: bool;
    let body: *i8;        // actually block_stmt*
    let has_body: bool;
    let is_extern_c: bool;
    let mangled_name: *i8;   // overload-mangled name; also the key call sites resolve by
    let link_name: *i8;      // @link_name("sym") — emitted symbol only, never a lookup key
    let type_params: **i8;
    let type_params_len: i32;
    let is_error_union: bool;
    let err_type: *type_node;
    let attributes: *proc_attr;
    let attributes_len: i32;
    let is_attr_macro: bool;   // marked with 'attr' after ')'
    let is_derive_macro: bool; // marked with 'derive' after ')'
    let is_static: bool;       // marked with 'static'
    let is_auto_return: bool;  // true if declared with 'auto' return type (trailing return)
    let is_pub: bool;
    let is_unsafe: bool;  // prefixed with @unsafe
    let is_extern_kw: bool;  // declared with `extern fn` keyword (not inside extern "C" block)
}

struct struct_decl {
    let kind: i32;
    let line: u64;
    let name: *i8;
    let fields: **var_decl;
    let fields_len: i32;
    let fields_cap: i32;
    let is_union: bool;
}

struct enum_variant {
    let kind: i32;
    let line: u64;
    let name: *i8;
    let variant_kind: i32;  // 0=plain, 1=tuple, 2=named_struct
    let plain_val: *expr_node;
    let has_plain_val: bool;
}

struct enum_decl {
    let kind: i32;
    let line: u64;
    let name: *i8;
    let variant_names: **i8;
    let variant_vals: *i64;
    let variant_has_val: *bool;
    let variants_len: i32;
    let variants_cap: i32;
    let is_adt: bool;
    // ADT variant payloads: flat arrays, stride=8 per variant
    // variant_kinds[i]: 0=plain, 1=tuple, 2=named_struct, 3=istruc_dot
    // variant_field_names_flat[i*8 + j], variant_field_type_flat[i*8 + j]
    let variant_kinds: *i32;
    let variant_field_counts: *i32;     // number of fields for each variant
    let variant_field_names_flat: **i8; // flat: [vi*8+fi] = field name (i8*)
    let variant_field_type_flat: **i8;  // flat: [vi*8+fi] = parser.type_node* as i8*
    // ADT variant methods: flat arrays, stride=8 per variant
    let variant_method_flat: **i8;      // flat: [vi*8+mi] = func_decl* as i8*
    let variant_method_counts: *i32;    // number of methods per variant
}

struct typedef_decl {
    let kind: i32;
    let line: u64;
    let name: *i8;
    let target: *type_node;
    let is_namespace_using: bool;  // `using ns_name;` — imports all names from namespace
    let ns_using_name: *i8;       // the namespace name to import
}

struct namespace_decl {
    let kind: i32;
    let line: u64;
    let name: *i8;
    let decls: **ast_node;
    let decls_len: i32;
    let decls_cap: i32;
    let type_params: **i8;      // generic type param names (null for non-generic)
    let type_params_len: i32;
    let is_memstr: bool;        // true when declared with 'memstr' keyword
    let is_istruc: bool;        // true when declared with 'istruc'/'interface' (not 'namespace')
    let is_interface: bool;     // true when declared with 'interface' keyword
    let is_union: bool;         // true when declared as generic union
    let bases: **i8;            // base/interface names from ': Base1, Base2'
    let bases_len: i32;
    let attributes: *proc_attr;       // attached #[...] attributes
    let attributes_len: i32;
}

struct extern_c_block {
    let kind: i32;
    let line: u64;
    let decls: **ast_node;
    let decls_len: i32;
    let decls_cap: i32;
}

struct program_node {
    let kind: i32;
    let line: u64;
    let decls: **ast_node;
    let decls_len: i32;
    let decls_cap: i32;
}

// ---- Pattern node (for match) ----

enum pat_kind {
    pk_wildcard    = 0,  // _
    pk_literal     = 1,  // 42, "str", 'c', true, false, null
    pk_ident       = 2,  // bare name — enum variant or binding
    pk_binding     = 3,  // name @ sub_pat
    pk_range       = 4,  // lo..hi or lo..=hi
    pk_or          = 5,  // pat1 | pat2
    pk_struct      = 6,  // .{ field: pat, .. } or Variant { field: pat }
    pk_tuple       = 7,  // Variant(p1, p2, ...)
    pk_rest        = 8,  // .. (ignore rest)
    pk_neg         = 9,  // -literal (negative literal)
}

struct pat_field {
    let name: *i8;       // field name (null for positional)
    let pat: *i8;        // pat_node* (stored as i8* for forward ref)
}

struct pat_node {
    let kind: i32;
    let line: u64;
    // pk_literal
    let lit_expr: *i8;   // expr_node* for the literal value
    // pk_ident / pk_binding / pk_struct / pk_tuple
    let name: *i8;       // variant/binding name
    // pk_binding
    let sub_pat: *i8;    // pat_node* sub-pattern
    // pk_range
    let range_lo: *i8;   // expr_node* low bound
    let range_hi: *i8;   // expr_node* high bound (null = open end)
    let range_inclusive: bool; // ..= vs ..
    // pk_or
    let or_lhs: *i8;     // pat_node*
    let or_rhs: *i8;     // pat_node*
    // pk_struct / pk_tuple: fields
    let fields: *pat_field;
    let fields_len: i32;
    let has_rest: bool;  // has .. in struct/tuple pattern
    // pk_neg
    let neg_expr: *i8;   // expr_node* inner literal
}

struct match_arm {
    let pat: *pat_node;
    let guard: *i8;      // expr_node* (null if no guard)
    let body: *ast_node; // block or expr-stmt
}

struct match_stmt {
    let kind: i32;
    let line: u64;
    let subject: *i8;    // expr_node*
    let arms: **match_arm;
    let arms_len: i32;
    let arms_cap: i32;
    let is_expr: bool;   // used as expression (let x: T = match ...)
}

// ---- Allocation helpers ----

fn alloc_block_stmt() *block_stmt {
    let mut n: *block_stmt= (block_stmt*)arc_malloc(sizeof(parser__NS_block_stmt));
    memset((i8*)n, 0, sizeof(parser__NS_block_stmt));
    n.kind = nd_block;
    return n;
}

fn block_stmt_push(blk: *block_stmt, s: *ast_node) void {
    // Always realloc with doubled size (simple growth strategy)
    let mut old_len: i32= blk.stmts_len;
    let mut nc: i32= old_len == 0 ? 16 : old_len * 2;
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
    let mut name: *i8;
    let mut param_names: **i8;
    let mut param_count: i32;
    let mut template_toks: *i8;   // lexer.token_t* stored as i8*
    let mut template_len: i32;
}

// ---- Parser istruc ----

istruc parser_t {
    let mut tokens: *lexer.token_t;
    let mut tokens_len: i32;
    let mut current: i32;
    let mut had_parse_error: bool;
    let mut macros: **macro_def_t;
    let mut macros_len: i32;
    let mut macros_cap: i32;
    let mut pending_anon_var: *ast_node;  // for anonymous istruc per-instance init
    let mut anon_istruc_count: i32; // counter for synthetic names
    let mut import_src_path: *i8;    // path of the current source file (for @import resolution)
    let mut import_stdlib_path: *i8; // stdlib directory for @import("std/...") paths

    fn init(self: *parser_t, toks: *lexer.token_t, len: i32) void {
        self.tokens             = toks;
        self.tokens_len         = len;
        self.current            = 0;
        self.had_parse_error    = false;
        self.macros_cap         = 8;
        self.macros_len         = 0;
        self.macros             = (macro_def_t**)arc_malloc(sizeof(i8*) * (u64)8);
        self.pending_anon_var   = (ast_node*)0;
        self.anon_istruc_count  = 0;
        self.import_src_path    = (i8*)0;
        self.import_stdlib_path = (i8*)0;
    }

    // ---- Token access helpers ----

    fn peek_tok(self: *parser_t) lexer.token_t {
        if (self.current >= self.tokens_len) {
            let mut t: lexer.token_t;
            t.type  = eof_t;
            t.value = (i8*)0;
            t.line  = 0;
            return t;
        }
        return self.tokens[self.current];
    }

    fn peek_at_tok(self: *parser_t, offset: i32) lexer.token_t {
        let mut idx: i32= self.current + offset;
        if (idx >= self.tokens_len) {
            let mut t: lexer.token_t;
            t.type  = eof_t;
            t.value = (i8*)0;
            t.line  = 0;
            return t;
        }
        return self.tokens[idx];
    }

    fn advance_tok(self: *parser_t) lexer.token_t {
        let mut t: lexer.token_t= self.peek_tok();
        if (self.current < self.tokens_len) {
            self.current = self.current + 1;
        }
        return t;
    }

    fn previous_tok(self: *parser_t) lexer.token_t {
        if (self.current > 0) {
            return self.tokens[self.current - 1];
        }
        return self.peek_tok();
    }

    // ---- Field accessor helpers (avoid call().field lvalue issue) ----

    fn peek_type(self: *parser_t) i32 {
        let mut _t: lexer.token_t= self.peek_tok();
        return _t.type;
    }

    fn peek_line(self: *parser_t) u64 {
        let mut _t: lexer.token_t= self.peek_tok();
        return _t.line;
    }

    fn peek_at_type(self: *parser_t, offset: i32) i32 {
        let mut _t: lexer.token_t= self.peek_at_tok(offset);
        return _t.type;
    }

    fn advance_line_get(self: *parser_t) u64 {
        let mut _t: lexer.token_t= self.advance_tok();
        return _t.line;
    }

    fn advance_value_get(self: *parser_t) *i8 {
        let mut _t: lexer.token_t= self.advance_tok();
        return _t.value;
    }

    fn prev_type(self: *parser_t) i32 {
        let mut _t: lexer.token_t= self.previous_tok();
        return _t.type;
    }

    fn prev_line(self: *parser_t) u64 {
        let mut _t: lexer.token_t= self.previous_tok();
        return _t.line;
    }

    fn consume_id_value(self: *parser_t, err_msg: *i8) *i8 {
        let mut _t: lexer.token_t= self.consume_tok(id, err_msg);
        return _t.value;
    }

    // ---- End helpers ----

    // Soft-keyword helpers — "memstr" is a builtin type name, not a reserved keyword.
    fn is_memstr_kw(self: *parser_t) bool {
        if (!self.check_tok(id)) { return false; }
        let mut t: lexer.token_t= self.peek_tok();
        return t.value != (i8*)0 && strcmp(t.value, "memstr") == 0;
    }
    fn memstr_at(self: *parser_t, offset: i32) bool {
        if (self.peek_at_type(offset) != id) { return false; }
        let mut t: lexer.token_t= self.peek_at_tok(offset);
        return t.value != (i8*)0 && strcmp(t.value, "memstr") == 0;
    }

    fn check_tok(self: *parser_t, tok_type: i32) bool {
        return self.peek_type() == tok_type;
    }

    fn match_tok(self: *parser_t, tok_type: i32) bool {
        if (self.check_tok(tok_type)) {
            self.advance_tok();
            return true;
        }
        return false;
    }

    fn is_at_end_p(self: *parser_t) bool {
        return self.peek_type() == eof_t;
    }

    fn consume_tok(self: *parser_t, tok_type: i32, err_msg: *i8) lexer.token_t {
        if (self.check_tok(tok_type)) {
            return self.advance_tok();
        }
        // Error: print message and set error flag
        let mut cur: lexer.token_t= self.peek_tok();
        let mut errbuf: [512]i8;
        let mut tok_name: *i8= lexer.tok_type_name(cur.type);
        if ((cur.type == id) && cur.value != (i8*)0 && cur.value[0] != 0) {
            afmt(errbuf, (u64)512, "error at line %d: %s; got %s '%s'", .{ cur.line, err_msg, tok_name, cur.value });
        } else {
            afmt(errbuf, (u64)512, "error at line %d: %s; got %s", .{ cur.line, err_msg, tok_name });
        }
        aprint("%s\n", .{ errbuf });
        self.had_parse_error = true;
        return cur;
    }

    // Consume an identifier-or-keyword token for use as a name (field, member, etc.).
    // Accepts id tokens AND keyword tokens (kw_if and above) since keywords may legally
    // appear as field or member names in Arc source (e.g., `i32 type;`, `tok.type`).
    fn consume_name_tok(self: *parser_t, err_msg: *i8) lexer.token_t {
        let mut tt: i32= self.peek_type();
        if (tt == id || tt >= kw_if) {
            return self.advance_tok();
        }
        let mut cur: lexer.token_t= self.peek_tok();
        let mut errbuf: [512]i8;
        let mut tok_name: *i8= lexer.tok_type_name(cur.type);
        afmt(errbuf, (u64)512, "error at line %d: %s; got %s", .{ cur.line, err_msg, tok_name });
        aprint("%s\n", .{ errbuf });
        self.had_parse_error = true;
        return cur;
    }

    // ---- Error recovery ----

    fn synchronize(self: *parser_t) void {
        self.advance_tok();
        while (!self.is_at_end_p()) {
            let mut prev: i32= self.prev_type();
            if (prev == sm) { return; }
            let mut cur: i32= self.peek_type();
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

    fn find_macro(self: *parser_t, name: *i8) *macro_def_t {
        let mut mi: i32= 0;
        while (mi < self.macros_len) {
            let mut m: *macro_def_t= (macro_def_t*)self.macros[mi];
            if (strcmp(m.name, name) == 0) {
                return m;
            }
            mi = mi + 1;
        }
        return (macro_def_t*)0;
    }

    // Expand a macro call: consumes '(' args ')' from self, returns expanded expr
    fn expand_macro_call(self: *parser_t, mdef: *macro_def_t) *expr_node {
        // Collect argument tokens per arg
        let mut arg_buf_cap: i32= 128;
        let mut arg_buf: *lexer.token_t= (lexer.token_t*)arc_malloc(sizeof(lexer__NS_token_t) * (u64)arg_buf_cap);
        let mut arg_buf_len: i32= 0;
        let mut arg_starts: *i32= (i32*)arc_malloc(sizeof(i32) * (u64)16);
        let mut arg_lens: *i32= (i32*)arc_malloc(sizeof(i32) * (u64)16);
        let mut arg_count: i32= 0;
        let mut cur_arg_start: i32= 0;

        self.consume_tok(oparen, "Expected '(' for macro call");
        let mut depth_m: i32= 0;
        while ((!self.check_tok(cparen) || depth_m > 0) && !self.is_at_end_p()) {
            let mut at: lexer.token_t= self.peek_tok();
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
        let mut exp_cap: i32= 256;
        let mut exp: *lexer.token_t= (lexer.token_t*)arc_malloc(sizeof(lexer__NS_token_t) * (u64)exp_cap);
        let mut exp_len: i32= 0;
        let mut tmpl: *lexer.token_t= (lexer.token_t*)mdef.template_toks;

        let mut ti: i32= 0;
        while (ti < mdef.template_len) {
            let mut tt: lexer.token_t= tmpl[ti];
            if (tt.type == dollar && ti + 1 < mdef.template_len) {
                let mut nt: lexer.token_t= tmpl[ti + 1];
                if (nt.type == id) {
                    let mut param_idx: i32= -1;
                    let mut pi: i32= 0;
                    while (pi < mdef.param_count) {
                        if (strcmp(mdef.param_names[pi], nt.value) == 0) {
                            param_idx = pi;
                            pi = mdef.param_count; // break
                        }
                        pi = pi + 1;
                    }
                    if (param_idx >= 0 && param_idx < arg_count) {
                        let mut em_s: i32= arg_starts[param_idx];
                        let mut em_l: i32= arg_lens[param_idx];
                        let mut ai: i32= 0;
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
        let mut eoft: lexer.token_t;
        eoft.type  = eof_t;
        eoft.value = (i8*)0;
        eoft.line  = 0;
        exp[exp_len] = eoft;
        exp_len = exp_len + 1;

        // Parse expanded tokens with a sub-parser.
        // Try parse_stmt first (handles `i32 y = expr` macro bodies), then fall back to parse_expr.
        let mut sub: parser_t;
        sub.init(exp, exp_len);
        sub.macros     = self.macros;
        sub.macros_len = self.macros_len;
        sub.macros_cap = self.macros_cap;

        let mut result: *expr_node= (expr_node*)0;
        let mut saved_parse_err: bool= self.had_parse_error;  // save main parser error state
        if (sub.is_type_start() || sub.check_tok(kw_let) || sub.check_tok(kw_const) || sub.check_tok(kw_static)) {
            // Expanded tokens start with a declaration keyword → parse as statement
            let mut stmt_result: *ast_node= sub.parse_stmt();
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

    fn is_type_start(self: *parser_t) bool {
        let mut tt: i32= self.peek_type();
        if (tt == question) { return true; }
        if (tt == addr && self.memstr_at(1)) { return true; }
        if (tt == kw_type)     { return true; }
        if (tt == kw_const)    { return true; }
        if (tt == kw_volatile) { return true; }
        if (tt == kw_signed)   { return true; }
        if (tt == kw_unsigned) { return true; }
        if (tt == kw_extern)   { return true; }
        if (tt == kw_extern_c) { return true; }
        if (tt == kw_inline)   { return true; }
        if (tt == kw_auto)     { return true; }
        if (tt == ty_char)     { return true; }
        if (tt == ty_void)     { return true; }
        if (tt == ty_arb_int)  { return true; }
        if (tt == ty_arb_uint) { return true; }
        if (tt == ty_arb_float){ return true; }
        if (tt == ty_arb_bool)     { return true; }
        if (tt == ty_arb_rational) { return true; }
        if (tt == ty_arb_complex)  { return true; }
        if (tt == ty_arb_char_w)   { return true; }
        if (tt == ty_arb_str_w)    { return true; }
        if (tt == ty_arb_nat)      { return true; }
        if (tt == ty_arb_zint)     { return true; }
        if (tt == ty_arb_real)     { return true; }
        if (tt == ty_arb_alg)      { return true; }
        if (tt == kw_struct)    { return true; }
        if (tt == kw_enum)      { return true; }
        if (tt == kw_union)     { return true; }
        if (self.is_memstr_kw()) { return true; }
        if (tt == kw_token_type){ return true; }
        if (tt == kw_interface) { return true; }
        if (tt == kw_anytype)   { return true; }
        if (tt == kw_usize)     { return true; }
        if (tt == kw_isize)     { return true; }
        if (tt == kw_iofs)      { return true; }
        // id followed by id = user-defined type
        if (tt == id && self.peek_at_type(1) == id) { return true; }
        // namespace.Type: id.id id or id.id* or id.Generic<T> id
        if (tt == id && self.peek_at_type(1) == dot) {
            if (self.peek_at_type(2) == id) {
                // Check what follows the qualified name
                let mut k: i32= 3;
                // skip more dots (for nested namespaces)
                let mut searching: bool= true;
                while (searching && self.peek_at_type(k) == dot
                       && self.peek_at_type(k + 1) == id) {
                    k = k + 2;
                }
                // skip generic type args: ns.Type<T, U>
                if (self.peek_at_type(k) == lt) {
                    let mut depth_ns: i32= 0;
                    let mut j: i32= k;
                    let mut ok_ns: bool= true;
                    while (ok_ns && j < k + 80) {
                        let mut tns: i32= self.peek_at_type(j);
                        if (tns == lt)   { depth_ns = depth_ns + 1; j = j + 1; }
                        else if (tns == gt) {
                            depth_ns = depth_ns - 1;
                            j = j + 1;
                            if (depth_ns == 0) { k = j; ok_ns = false; }
                        }
                        else if (tns == gte) {
                            // '>=' lexed as one token — treat as '>'
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
                let mut after: i32= self.peek_at_type(k);
                if (after == id) { return true; }
            }
        }
        // id* id = pointer to user type
        if (tt == id) {
            let mut k: i32= 1;
            while (self.peek_at_type(k) == ast) { k = k + 1; }
            if (k > 1 && self.peek_at_type(k) == id) { return true; }
        }
        // Generic type: id<...> id — scan past balanced <> to check for trailing id
        if (tt == id && self.peek_at_type(1) == lt) {
            let mut k2: i32= 2;
            let mut depth2: i32= 1;
            while (depth2 > 0 && self.peek_at_type(k2) != eof_t) {
                let mut t2: i32= self.peek_at_type(k2);
                if (t2 == lt)  { depth2 = depth2 + 1; }
                else if (t2 == gt)  { depth2 = depth2 - 1; }
                else if (t2 == gte) { depth2 = depth2 - 1; } // '>=' lexed as one token
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
    fn is_cast_start(self: *parser_t) bool {
        if (self.is_type_start()) { return true; }
        let mut tt: i32= self.peek_type();
        if (tt == id) {
            let mut k: i32= 1;
            // skip namespace qualifiers: ns.Type
            while (self.peek_at_type(k) == dot && self.peek_at_type(k + 1) == id) { k = k + 2; }
            // skip generic type args: id<...>
            if (self.peek_at_type(k) == lt) {
                let mut depth_c: i32= 1;
                k = k + 1;
                while (depth_c > 0 && k < 64) {
                    let mut tgc: i32= self.peek_at_type(k);
                    if (tgc == lt)  { depth_c = depth_c + 1; }
                    else if (tgc == gt) { depth_c = depth_c - 1; }
                    else if (tgc == gte) { depth_c = depth_c - 1; } // '>=' lexed as one token
                    else if (tgc == right) { depth_c = depth_c - 2; }
                    else if (tgc == sm || tgc == cbrace || tgc == eof_t) { break; }
                    k = k + 1;
                }
            }
            // skip pointer stars
            while (self.peek_at_type(k) == ast) { k = k + 1; }
            if (k > 1 && self.peek_at_type(k) == cparen) { return true; }
        }
        return false;
    }

    // ---- Type parsing ----

    fn parse_type(self: *parser_t) *type_node {
        let mut t: *type_node= alloc_type_node();

        // @typeof(expr) or @cstype(expr) in type position
        if (self.check_tok(at)) {
            let mut at_saved: i32= self.current;
            self.advance_tok(); // consume '@'
            if (self.check_tok(id)) {
                let mut at_tok: lexer.token_t= self.peek_tok();
                if (strcmp(at_tok.value, "typeof") == 0) {
                    self.advance_tok(); // consume 'typeof'
                    if (self.check_tok(oparen)) {
                        self.advance_tok(); // consume '('
                        let mut te: *expr_node= self.parse_expr();
                        self.consume_tok(cparen, "Expected ')' after @typeof expression");
                        t.is_typeof = true;
                        t.typeof_expr = (i8*)te;
                        t.is_auto = true; // treated as auto until type is inferred
                        return t;
                    }
                }
                // @cstype(type_info_expr) — inverse of @typeinfo: synthesize type from type_info.
                // Round-trip: @cstype(@typeinfo(T)) == T.
                if (strcmp(at_tok.value, "cstype") == 0) {
                    self.advance_tok(); // consume 'cstype'
                    if (self.check_tok(oparen)) {
                        self.advance_tok(); // consume '('
                        let mut te: *expr_node= self.parse_expr();
                        self.consume_tok(cparen, "Expected ')' after @cstype expression");
                        // If arg is @typeinfo(T), extract T and use directly (round-trip identity).
                        if (te.kind == 13 && te.cast_type != (type_node*)0) {
                            return te.cast_type;
                        }
                        // General case: infer from initializer (type_info is a runtime value).
                        t.is_auto = true;
                        return t;
                    }
                }
            }
            self.current = at_saved; // backtrack
        }

        // nullable: ?T
        if (self.check_tok(question)) {
            self.advance_tok();
            let mut inner: *type_node= self.parse_type();
            inner.is_nullable = true;
            arc_free((i8*)t);
            return inner;
        }

        // Error union: !T
        if (self.check_tok(not_)) {
            self.advance_tok();
            let mut inner: *type_node= self.parse_type();
            inner.is_error_union = true;
            arc_free((i8*)t);
            return inner;
        }

        // C++ reference: &T — treat as T* for bootstrap; &memstr is a fat pointer
        if (self.check_tok(addr)) {
            self.advance_tok();
            let mut inner: *type_node= self.parse_type();
            inner.pointer_depth = inner.pointer_depth + 1;
            if (inner.name != (i8*)0 && strcmp(inner.name, "memstr") == 0) {
                inner.is_memstr_ref = true;
            }
            arc_free((i8*)t);
            return inner;
        }

        // New-style prefix pointer: *T or *const T
        if (self.check_tok(ast)) {
            self.advance_tok();
            let mut ptr_data_c: bool= self.match_tok(kw_const);
            let mut inner_p: *type_node= self.parse_type();
            inner_p.pointer_depth = inner_p.pointer_depth + 1;
            if (ptr_data_c) { inner_p.ptr_data_const = true; }
            arc_free((i8*)t);
            return inner_p;
        }

        // New-style prefix array/slice types: []T, [N]T, [_]T, [*]T, [:S]T, [*:S]T, [N:S]T
        if (self.check_tok(obracket)) {
            self.advance_tok(); // consume '['
            // [*] many-item pointer or [*:S] sentinel many-pointer
            if (self.check_tok(ast)) {
                self.advance_tok(); // consume '*'
                if (self.match_tok(colon)) {
                    if (!self.check_tok(cbracket)) { self.parse_expr(); }
                }
                self.consume_tok(cbracket, "Expected ']'");
                let mut inner_mp: *type_node= self.parse_type();
                inner_mp.pointer_depth = inner_mp.pointer_depth + 1;
                arc_free((i8*)t);
                return inner_mp;
            }
            // [:S] sentinel slice
            if (self.check_tok(colon)) {
                self.advance_tok(); // consume ':'
                if (!self.check_tok(cbracket)) { self.parse_expr(); }
                self.consume_tok(cbracket, "Expected ']'");
                let mut inner_ss: *type_node= self.parse_type();
                inner_ss.pointer_depth = inner_ss.pointer_depth + 1;
                arc_free((i8*)t);
                return inner_ss;
            }
            // [] slice (empty brackets)
            if (self.check_tok(cbracket)) {
                self.advance_tok(); // consume ']'
                let mut inner_sl: *type_node= self.parse_type();
                inner_sl.pointer_depth = inner_sl.pointer_depth + 1;
                arc_free((i8*)t);
                return inner_sl;
            }
            // [_] inferred-size array
            if (self.check_tok(id)) {
                let mut peek_u: lexer.token_t= self.peek_tok();
                if (strcmp(peek_u.value, "_") == 0) {
                    self.advance_tok(); // consume '_'
                    if (self.match_tok(colon)) {
                        if (!self.check_tok(cbracket)) { self.parse_expr(); }
                    }
                    self.consume_tok(cbracket, "Expected ']' after [_]");
                    let mut inner_ia: *type_node= self.parse_type();
                    arc_free((i8*)t);
                    return inner_ia;
                }
            }
            // [N] or [N:S] fixed or sentinel array
            let mut arr_sz2: *expr_node= self.parse_expr();
            if (self.match_tok(colon)) {
                if (!self.check_tok(cbracket)) { self.parse_expr(); }
            }
            self.consume_tok(cbracket, "Expected ']' after array size");
            let mut inner_fa: *type_node= self.parse_type();
            inner_fa.array_size_ptr = (i8*)arr_sz2;
            arc_free((i8*)t);
            return inner_fa;
        }

        // New-style function type: (params)RetType
        // Syntax: (ParamType name, ...) ReturnType
        // e.g.: (i32, i32)i32  or  (i32 x)void  or  ()void
        // With pointers: *(i32)i32 = pointer-to-fn-taking-int-returning-int
        if (self.check_tok(oparen)) {
            self.advance_tok();  // consume '('
            let mut fp_params2: type_ptr_vec;
            type_ptr_vec_init(&fp_params2);
            let mut fp_names2: str_vec;
            str_vec_init(&fp_names2);
            let mut fp_variadic2: bool= false;
            if (!self.check_tok(cparen)) {
                let mut parsing_fp2: bool= true;
                while (parsing_fp2) {
                    if (self.check_tok(dotdot) && self.peek_at_type(1) == dot) {
                        self.advance_tok(); self.advance_tok();
                        fp_variadic2 = true;
                        parsing_fp2 = false;
                    } else if (self.is_type_start() || self.check_tok(oparen) || self.check_tok(ast) ||
                               self.check_tok(obracket) ||
                               (self.check_tok(id) && (self.peek_at_type(1) == comma ||
                                                        self.peek_at_type(1) == cparen))) {
                        let mut pt2: *type_node= self.parse_type();
                        type_ptr_vec_push(&fp_params2, pt2);
                        let mut pname2: *i8= (i8*)0;
                        if (self.check_tok(id)) {
                            pname2 = lexer.str_dup(self.advance_value_get());
                        }
                        str_vec_push(&fp_names2, pname2);
                        if (!self.match_tok(comma)) { parsing_fp2 = false; }
                    } else {
                        parsing_fp2 = false;
                    }
                }
            }
            self.consume_tok(cparen, "Expected ')' after function type params");
            let mut fp_ret2: *type_node= self.parse_type();
            let mut fp_t2: *type_node= alloc_type_node();
            fp_t2.is_func_ptr        = true;
            fp_t2.fp_ret             = (i8*)fp_ret2;
            fp_t2.fp_params          = (i8**)fp_params2.data;
            fp_t2.fp_params_len      = fp_params2.len;
            fp_t2.fp_param_names     = fp_names2.data;
            fp_t2.fp_param_names_len = fp_names2.len;
            fp_t2.fp_variadic        = fp_variadic2;
            fp_t2.pointer_depth      = 0;
            arc_free((i8*)t);
            return fp_t2;
        }

        // storage class
        let mut parsing_storage: bool= true;
        while (parsing_storage) {
            if (self.match_tok(kw_extern))   { t.is_extern = true; }
            else if (self.match_tok(kw_extern_c)) { t.is_extern = true; t.is_extern_c = true; }
            else if (self.match_tok(kw_inline))  { t.is_inline = true; }
            else { parsing_storage = false; }
        }

        // qualifiers (including static in type position: `let x: static volatile T`)
        let mut parsing_qual: bool= true;
        while (parsing_qual) {
            if (self.match_tok(kw_const))        { t.is_const = true; }
            else if (self.match_tok(kw_volatile)) { t.is_volatile = true; }
            else if (self.match_tok(kw_static))   { t.is_static_kw = true; }
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
            // Parse optional generic type args <T> and store them
            if (self.check_tok(lt)) {
                self.advance_tok(); // consume '<'
                let mut ta_cap_i: i32= 16;
                let mut ta_arr_i: **type_node= (type_node**)arc_malloc(sizeof(i8*) * (u64)ta_cap_i);
                let mut ta_len_i: i32= 0;
                while (!self.check_tok(gt) && !self.check_tok(gte) && !self.is_at_end_p()) {
                    if (self.check_tok(comma)) { self.advance_tok(); continue; }
                    let mut is_ta: bool= self.is_type_start();
                    if (!is_ta && self.check_tok(id)) {
                        let mut nt: i32= self.peek_at_type(1);
                        if (nt == comma || nt == gt || nt == gte) { is_ta = true; }
                    }
                    if (is_ta) {
                        let mut ta_i: *type_node= self.parse_type();
                        if (ta_len_i >= ta_cap_i) {
                            ta_cap_i = ta_cap_i * 2;
                            ta_arr_i = (type_node**)arc_realloc((i8*)ta_arr_i, sizeof(i8*) * (u64)ta_cap_i);
                        }
                        ta_arr_i[ta_len_i] = ta_i; ta_len_i = ta_len_i + 1;
                        self.match_tok(comma);
                    } else { self.advance_tok(); }
                }
                if (self.check_tok(gt)) { self.advance_tok(); }
                else if (self.check_tok(gte)) { self.tokens[self.current].type = assign; }
                if (ta_len_i > 0) {
                    t.type_args = (i8**)ta_arr_i;
                    t.type_args_len = ta_len_i;
                } else {
                    arc_free((i8*)ta_arr_i);
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

        let mut found: bool= false;
        if (self.match_tok(ty_char)) {
            t.prim = char_t; t.bit_width = 8; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.match_tok(ty_void)) {
            t.prim = void_t; t.bit_width = 0; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(ty_arb_int)) {
            let mut w: lexer.token_t= self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_int; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(ty_arb_uint)) {
            let mut w: lexer.token_t= self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_uint; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(ty_arb_float)) {
            let mut w: lexer.token_t= self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_float; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(ty_arb_bool)) {
            let mut w: lexer.token_t= self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_bool; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(ty_arb_rational)) {
            let mut w: lexer.token_t= self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_rational; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(ty_arb_complex)) {
            let mut w: lexer.token_t= self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_complex; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(ty_arb_char_w)) {
            let mut w: lexer.token_t= self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_char_w; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(ty_arb_str_w)) {
            let mut w: lexer.token_t= self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_str_w; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(ty_arb_nat)) {
            let mut w: lexer.token_t= self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_nat; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(ty_arb_zint)) {
            let mut w: lexer.token_t= self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_zint; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(ty_arb_real)) {
            let mut w: lexer.token_t= self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_real; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(ty_arb_alg)) {
            let mut w: lexer.token_t= self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_alg; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.match_tok(kw_usize)) {
            t.bit_width = 64; t.prim = arb_usize; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.match_tok(kw_isize)) {
            t.bit_width = 64; t.prim = arb_isize; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.match_tok(kw_iofs)) {
            t.bit_width = 65; t.prim = arb_iofs; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.match_tok(kw_anytype)) {
            t.is_anytype = true; t.is_primitive = true; found = true;
        }

        if (!found && self.is_memstr_kw()) {
            self.advance_tok();
            t.name = lexer.str_dup("memstr");
            found = true;
        }

        if (!found) {
            let mut name_tok: lexer.token_t= self.consume_tok(id, "Expected type name");
            t.name = lexer.str_dup(name_tok.value);

            // namespace-qualified: ns.Type
            let mut ns_loop: bool= true;
            while (ns_loop && self.check_tok(dot)) {
                let mut next_type: i32= self.peek_at_type(1);
                if (next_type == id) {
                    self.advance_tok();  // consume dot
                    let mut sub: lexer.token_t= self.advance_tok();

                    // Build qualified name: old__NS_sub
                    let mut newname: [1024]i8;
                    afmt(newname, (u64)1024, "%s__NS_%s", .{ t.name, sub.value });
                    arc_free(t.name);
                    t.name = lexer.str_dup(newname);
                } else {
                    ns_loop = false;
                }
            }

            // Generic type parameters: Type<A, B> — parse and store for monomorphization
            if (self.check_tok(lt)) {
                self.advance_tok(); // consume '<'
                let mut ta_cap: i32= 16;
                let mut ta_arr: **type_node= (type_node**)arc_malloc(sizeof(i8*) * (u64)ta_cap);
                let mut ta_len: i32= 0;
                while (!self.check_tok(gt) && !self.check_tok(gte) && !self.check_tok(right) && !self.is_at_end_p()) {
                    let mut is_type_arg: bool= self.is_type_start();
                    // Also treat bare 'id' (K, V, etc.) followed by ',' or '>' as a type arg
                    if (!is_type_arg && self.check_tok(id)) {
                        let mut ta_next: i32= self.peek_at_type(1);
                        if (ta_next == comma || ta_next == gt || ta_next == gte) {
                            is_type_arg = true;
                        }
                    }
                    if (is_type_arg) {
                        let mut ta: *type_node= self.parse_type();
                        if (ta_len >= ta_cap) {
                            ta_cap = ta_cap * 2;
                            ta_arr = (type_node**)arc_realloc((i8*)ta_arr, sizeof(i8*) * (u64)ta_cap);
                        }
                        ta_arr[ta_len] = ta;
                        ta_len = ta_len + 1;
                        self.match_tok(comma);
                    } else {
                        self.advance_tok(); // skip unknown tokens
                    }
                }
                // Close the generic args — split compound tokens if needed
                if (self.check_tok(gt)) {
                    self.advance_tok(); // consume plain '>'
                } else if (self.check_tok(gte)) {
                    // '>=' was lexed as one token: treat '>' as closing the generic args
                    // and mutate the token to '=' so the caller sees an assignment
                    self.tokens[self.current].type = assign;
                } else if (self.check_tok(right)) {
                    // '>>' was lexed as one token: treat first '>' as closing, leave second '>'
                    self.tokens[self.current].type = gt;
                }
                t.type_args = (i8**)ta_arr;
                t.type_args_len = ta_len;
            }
        }

        // Postfix function-pointer type: RetType(params)* — e.g. `void(K, V)*` is a
        // pointer to a function taking (K, V) and returning void. (The prefix form
        // `(params)RetType` is handled earlier.)
        //
        // `(` here is ambiguous with constructor-parens on a variable declaration
        // (`let mut a: Bump(65536);`), so commit to the function-pointer reading only
        // when a '*' follows the matching ')'. A constructor call is never starred.
        if (self.check_tok(oparen)) {
            let mut scan: i32= 1;      // offset of token after '('
            let mut depth: i32= 1;
            while (depth > 0) {
                let mut st: i32= self.peek_at_type(scan);
                if (st == eof_t) { depth = 0; scan = -1; }
                else {
                    if (st == oparen) { depth = depth + 1; }
                    else if (st == cparen) { depth = depth - 1; }
                    scan = scan + 1;
                }
            }
            if (scan > 0 && self.peek_at_type(scan) == ast) {
                self.advance_tok(); // consume '('
                let mut pf_params: type_ptr_vec;
                type_ptr_vec_init(&pf_params);
                let mut pf_names: str_vec;
                str_vec_init(&pf_names);
                let mut pf_variadic: bool= false;
                if (!self.check_tok(cparen)) {
                    let mut parsing_pf: bool= true;
                    while (parsing_pf) {
                        if (self.check_tok(dotdot) && self.peek_at_type(1) == dot) {
                            self.advance_tok(); self.advance_tok();
                            pf_variadic = true; parsing_pf = false;
                        } else if (self.is_type_start() || self.check_tok(oparen) ||
                                   self.check_tok(ast) || self.check_tok(obracket) ||
                                   self.check_tok(id)) {
                            let mut pfp: *type_node= self.parse_type();
                            type_ptr_vec_push(&pf_params, pfp);
                            let mut pfn: *i8= (i8*)0;
                            if (self.check_tok(id)) { pfn = lexer.str_dup(self.advance_value_get()); }
                            str_vec_push(&pf_names, pfn);
                            if (!self.match_tok(comma)) { parsing_pf = false; }
                        } else { parsing_pf = false; }
                    }
                }
                self.consume_tok(cparen, "Expected ')' after function pointer parameters");
                let mut pf_t: *type_node= alloc_type_node();
                pf_t.is_func_ptr        = true;
                pf_t.fp_ret             = (i8*)t;
                pf_t.fp_params          = (i8**)pf_params.data;
                pf_t.fp_params_len      = pf_params.len;
                pf_t.fp_param_names     = pf_names.data;
                pf_t.fp_param_names_len = pf_names.len;
                pf_t.fp_variadic        = pf_variadic;
                pf_t.pointer_depth      = 0;
                while (self.check_tok(ast)) { self.advance_tok(); }
                return pf_t;
            }
        }

        // pointer stars
        while (self.check_tok(ast)) {
            self.advance_tok();
            t.pointer_depth = t.pointer_depth + 1;
        }

        // array brackets
        if (self.match_tok(obracket)) {
            if (!self.check_tok(cbracket)) {
                let mut sz: *expr_node= self.parse_expr();
                t.array_size_ptr = (i8*)sz;
            }
            self.consume_tok(cbracket, "Expected ']' after array size");
        }

        return t;
    }

    // ---- Variable body ----

    fn parse_var_body(self: *parser_t, ty: *type_node, name_tok: lexer.token_t) *var_decl {
        let mut vd: *var_decl= (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
        memset((i8*)vd, 0, sizeof(parser__NS_var_decl));
        vd.kind       = nd_var_decl;
        vd.line       = (u64)name_tok.line;
        vd.type       = ty;
        vd.name       = lexer.str_dup(name_tok.value);
        vd.is_mutable = true;  // C-style var body declarations are mutable

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
            let mut ctor_cap: i32= 4;
            vd.ctor_args = (i8**)arc_malloc(sizeof(i8*) * (u64)ctor_cap);
            vd.ctor_args_len = 0;
            if (!self.check_tok(cparen)) {
                let mut p_ctor: bool= true;
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

    fn parse_func_body(self: *parser_t, ret: *type_node, name_tok: lexer.token_t, extern_c: bool) *func_decl {
        let mut fd: *func_decl= (func_decl*)arc_malloc(sizeof(parser__NS_func_decl));
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
        let mut params_cap: i32= 8;
        fd.params     = (param_decl*)arc_malloc(sizeof(parser__NS_param_decl) * (u64)params_cap);
        fd.params_len = 0;

        if (!self.check_tok(cparen)) {
            let mut parsing_params: bool= true;
            while (parsing_params) {
                if (self.check_tok(dotdot) &&
                    self.peek_at_type(1) == dot) {
                    self.advance_tok(); self.advance_tok();
                    fd.is_variadic = true;
                    parsing_params = false;
                } else {
                    if (fd.params_len >= params_cap) {
                        params_cap = params_cap * 2;
                        fd.params = (param_decl*)arc_realloc((i8*)fd.params, sizeof(parser__NS_param_decl) * (u64)params_cap);
                    }
                    let mut pt: *type_node= (type_node*)0;
                    let mut pname: *i8= (i8*)0;
                    // New-style: name: Type  (id followed by ':')
                    if ((self.check_tok(id) || self.peek_type() >= kw_let) && self.peek_at_type(1) == colon) {
                        pname = lexer.str_dup(self.advance_value_get());
                        self.advance_tok(); // consume ':'
                        pt = self.parse_type();
                    } else {
                        // Old-style: Type [name]
                        pt = self.parse_type();
                        if (self.check_tok(id) || self.peek_type() >= kw_if) {
                            pname = lexer.str_dup(self.advance_value_get());
                        }
                    }
                    if (pt == (type_node*)0) { pt = alloc_type_node(); pt.is_auto = true; }
                    let mut p: param_decl;
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
            let mut colon_tok: lexer.token_t= self.peek_tok();
            aprint("error at line %d: member initializer lists not supported; assign fields in the constructor body instead\n", .{ (i32)colon_tok.line });
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
            let mut blk_nd: *block_stmt= self.parse_block();
            fd.body     = (i8*)blk_nd;
            fd.has_body = true;
        }
        return fd;
    }

    // ---- New-style fn declaration: fn name<T>(p: Type, ...) RetType { } ----

    fn parse_fn_decl_new(self: *parser_t, extern_c: bool) *func_decl {
        let mut ln: u64= (u64)self.advance_line_get(); // consume 'fn'
        let mut fd: *func_decl= (func_decl*)arc_malloc(sizeof(parser__NS_func_decl));
        memset((i8*)fd, 0, sizeof(parser__NS_func_decl));
        fd.kind        = nd_func_decl;
        fd.line        = ln;
        fd.is_extern_c = extern_c;

        // operator overload: fn operator+(...)
        if (self.check_tok(kw_operator)) {
            self.advance_tok();
            let mut op_name2: [64]i8;
            let mut tt2: i32= self.peek_type();
            let mut op_tok2: lexer.token_t= self.advance_tok();
            let mut tt3: i32= self.peek_type();
            if ((tt2 == assign || tt2 == lt || tt2 == gt || tt2 == not_ || tt2 == plus || tt2 == minus || tt2 == ast || tt2 == slash) &&
                    (tt3 == assign)) {
                self.advance_tok();
                afmt(op_name2, (u64)64, "operator%s=", .{ op_tok2.value });
            } else if (tt2 == obracket) {
                self.advance_tok();
                afmt(op_name2, (u64)64, "operator[]", .{});
            } else {
                afmt(op_name2, (u64)64, "operator%s", .{ op_tok2.value });
            }
            fd.name = lexer.str_dup(op_name2);
        } else {
            let mut name_tok3: lexer.token_t= self.advance_tok();
            fd.name = lexer.str_dup(name_tok3.value);
        }

        // Optional generic type params: <T, U>
        let mut gtp_buf2: **i8= (i8**)0;
        let mut gtp_len2: i32= 0;
        if (self.check_tok(lt)) {
            let mut gtp_cap2: i32= 4;
            gtp_buf2 = (i8**)arc_malloc(sizeof(i8*) * (u64)gtp_cap2);
            self.advance_tok(); // consume '<'
            let mut depth_gf2: i32= 1;
            while (depth_gf2 > 0 && !self.is_at_end_p()) {
                let mut tgf2: i32= self.peek_type();
                if (tgf2 == gt && depth_gf2 == 1) {
                    depth_gf2 = 0; self.advance_tok();
                } else if (tgf2 == lt) { depth_gf2 = depth_gf2 + 1; self.advance_tok(); }
                else if (tgf2 == gt)   { depth_gf2 = depth_gf2 - 1; self.advance_tok(); }
                else if (tgf2 == right && depth_gf2 <= 2) { depth_gf2 = 0; self.advance_tok(); }
                else if (tgf2 == id) {
                    let mut tp_tok2: lexer.token_t= self.advance_tok();
                    if (gtp_len2 >= gtp_cap2) {
                        gtp_cap2 = gtp_cap2 * 2;
                        gtp_buf2 = (i8**)arc_realloc((i8*)gtp_buf2, sizeof(i8*) * (u64)gtp_cap2);
                    }
                    gtp_buf2[gtp_len2] = lexer.str_dup(tp_tok2.value);
                    gtp_len2 = gtp_len2 + 1;
                } else { self.advance_tok(); }
            }
        }
        if (gtp_len2 > 0) {
            fd.type_params     = gtp_buf2;
            fd.type_params_len = gtp_len2;
        } else if (gtp_buf2 != (i8**)0) {
            arc_free((i8*)gtp_buf2);
        }

        // Parameters '('
        self.consume_tok(oparen, "Expected '(' after function name");

        let mut params_cap2: i32= 8;
        fd.params     = (param_decl*)arc_malloc(sizeof(parser__NS_param_decl) * (u64)params_cap2);
        fd.params_len = 0;

        if (!self.check_tok(cparen)) {
            let mut parsing_params2: bool= true;
            while (parsing_params2) {
                if (self.check_tok(dotdot) &&
                    self.peek_at_type(1) == dot) {
                    self.advance_tok(); self.advance_tok();
                    fd.is_variadic = true;
                    parsing_params2 = false;
                } else if (self.check_tok(kw_comptime) && self.peek_at_type(1) == id && self.peek_at_type(2) == colon) {
                    // comptime type param: 'comptime' name ':' 'type'
                    // Adds the name to type_params (same mechanism as <T> generics).
                    // Does NOT push to fd.params — consumed as type arg at call site.
                    self.advance_tok(); // consume 'comptime'
                    let mut tp_name2: *i8= lexer.str_dup(self.advance_value_get()); // consume name
                    self.advance_tok(); // consume ':'
                    if (self.check_tok(kw_type)) { self.advance_tok(); } // consume 'type'
                    // Grow type_params array (appending after any <T> params)
                    if (fd.type_params_len == 0) {
                        fd.type_params = (i8**)arc_malloc(sizeof(i8*) * 8);
                    } else if (fd.type_params_len % 8 == 0) {
                        fd.type_params = (i8**)arc_realloc((i8*)fd.type_params, sizeof(i8*) * (u64)(fd.type_params_len + 8));
                    }
                    fd.type_params[fd.type_params_len] = tp_name2;
                    fd.type_params_len = fd.type_params_len + 1;
                    if (!self.match_tok(comma)) { parsing_params2 = false; }
                } else {
                    if (fd.params_len >= params_cap2) {
                        params_cap2 = params_cap2 * 2;
                        fd.params = (param_decl*)arc_realloc((i8*)fd.params, sizeof(parser__NS_param_decl) * (u64)params_cap2);
                    }
                    // New-style: name: Type  or  old-style: Type name
                    let mut pt2: *type_node= (type_node*)0;
                    let mut pname2: *i8= (i8*)0;
                    if ((self.check_tok(id) || self.peek_type() >= kw_let) && self.peek_at_type(1) == colon) {
                        // name: Type
                        pname2 = lexer.str_dup(self.advance_value_get());
                        self.advance_tok(); // consume ':'
                        pt2 = self.parse_type();
                    } else if (self.is_type_start() || self.check_tok(ast) || self.check_tok(obracket)) {
                        pt2 = self.parse_type();
                        if (self.check_tok(id) || self.peek_type() >= kw_if) {
                            pname2 = lexer.str_dup(self.advance_value_get());
                        }
                    } else {
                        // keyword used as param name
                        pname2 = lexer.str_dup(self.advance_value_get());
                        self.consume_tok(colon, "Expected ':'");
                        pt2 = self.parse_type();
                    }
                    if (pt2 == (type_node*)0) { pt2 = alloc_type_node(); pt2.is_auto = true; }
                    let mut p2: param_decl;
                    p2.type = pt2;
                    p2.name = pname2;
                    p2.line = (u64)self.prev_line();
                    fd.params[fd.params_len] = p2;
                    fd.params_len = fd.params_len + 1;
                    if (!self.match_tok(comma)) { parsing_params2 = false; }
                }
            }
        }
        self.consume_tok(cparen, "Expected ')' after parameters");

        // Proc-macro markers
        if (self.check_tok(kw_attr)) {
            self.advance_tok();
            fd.is_attr_macro = true;
            if (self.check_tok(id)) { self.advance_tok(); }
        } else if (self.check_tok(kw_derive)) {
            self.advance_tok();
            fd.is_derive_macro = true;
        }

        // Return type: [!]Type or nothing (void)
        let mut fn_ret: *type_node= alloc_type_node();
        fn_ret.prim = void_t;
        fn_ret.bit_width = 0;
        fn_ret.is_primitive = true;
        fn_ret.has_prim = true;

        if (self.check_tok(not_) && self.peek_at_type(1) != assign) {
            self.advance_tok();
            arc_free((i8*)fn_ret);
            fn_ret = self.parse_type();
            fd.is_error_union = true;
            fd.err_type = (type_node*)0;
        } else if (self.is_type_start() || self.check_tok(ast) || self.check_tok(obracket) ||
                   (self.check_tok(id) && !self.check_tok(obrace) && !self.check_tok(sm))) {
            // Accept any type start including bare user-defined types (id not followed by body)
            arc_free((i8*)fn_ret);
            fn_ret = self.parse_type();
        }
        fd.ret_type = fn_ret;

        // Optional proc-macro markers: attr [category], derive
        if (self.check_tok(kw_attr)) {
            self.advance_tok();
            fd.is_attr_macro = true;
            if (self.check_tok(id)) { self.advance_tok(); }
        } else if (self.check_tok(kw_derive)) {
            self.advance_tok();
            fd.is_derive_macro = true;
        }

        // Body or ;
        if (self.match_tok(sm)) {
            fd.body     = (i8*)0;
            fd.has_body = false;
        } else {
            let mut blk2: *block_stmt= self.parse_block();
            fd.body     = (i8*)blk2;
            fd.has_body = true;
        }
        return fd;
    }

    // ---- Top-level declaration dispatch ----

    fn parse_func_or_var_decl(self: *parser_t) *ast_node {
        // Optional visibility prefix
        let mut is_pub_decl: bool= false;
        if (self.check_tok(kw_pub)) { self.advance_tok(); is_pub_decl = true; }
        else if (self.check_tok(kw_priv)) { self.advance_tok(); }

        // New-style: let [mut] name: Type;  or  const name: Type = expr;
        if (self.check_tok(kw_let) || (self.check_tok(kw_const) && self.peek_at_type(1) == id &&
                (self.peek_at_type(2) == assign || self.peek_at_type(2) == colon || self.peek_at_type(2) == sm))) {
            let mut is_cfield2: bool= self.match_tok(kw_const);
            if (!is_cfield2) {
                self.advance_tok(); // consume 'let'
                self.match_tok(kw_mut); // ignore mut for struct fields
            }
            let mut fld_name_tok: lexer.token_t= self.advance_tok();
            let mut fld_type: *type_node= alloc_type_node();
            fld_type.is_auto = true;
            if (self.match_tok(colon)) {
                arc_free((i8*)fld_type);
                fld_type = self.parse_type();
            }
            let mut fld_vd: *var_decl= (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
            memset((i8*)fld_vd, 0, sizeof(parser__NS_var_decl));
            fld_vd.kind = nd_var_decl;
            fld_vd.line = (u64)fld_name_tok.line;
            fld_vd.type = fld_type;
            fld_vd.name = lexer.str_dup(fld_name_tok.value);
            fld_vd.is_constexpr = is_cfield2;
            fld_vd.is_pub = is_pub_decl;
            if (self.match_tok(assign)) {
                // const name = struct { ... } — treat as named struct declaration
                if (self.check_tok(kw_struct) && self.peek_at_type(1) == obrace) {
                    self.advance_tok(); // consume 'struct'
                    let mut sd_c: *struct_decl= self.parse_anon_struct_body(fld_name_tok.value);
                    self.match_tok(sm);
                    return (ast_node*)sd_c;
                }
                fld_vd.init = self.parse_expr();
                fld_vd.has_init = true;
            }
            self.consume_tok(sm, "Expected ';'");
            return (ast_node*)fld_vd;
        }
        // New-style: [pub] [@unsafe] fn name(params) RetType { }
        // @unsafe fn and @unsafe extern fn
        let mut is_unsafe_decl: bool= false;
        if (self.check_tok(at) && self.peek_at_type(1) == id) {
            let mut next_val: *i8= self.tokens[self.current + 1].value;
            if (strcmp(next_val, "unsafe") == 0) {
                is_unsafe_decl = true;
                self.advance_tok(); // consume '@'
                self.advance_tok(); // consume 'unsafe'
            }
        }
        if (self.check_tok(kw_fn)) {
            let mut pfd: *func_decl= self.parse_fn_decl_new(false);
            if (pfd != (func_decl*)0) { pfd.is_pub = is_pub_decl; pfd.is_unsafe = is_unsafe_decl; }
            return (ast_node*)pfd;
        }

        let mut is_cexpr: bool= false;
        if (self.check_tok(kw_comptime)) {
            self.advance_tok(); is_cexpr = true;
            // comptime type T = SomeType; — first-class type alias at top level
            if (self.check_tok(kw_type) && self.peek_at_type(1) == id) {
                self.advance_tok(); // consume 'type'
                let mut td: *typedef_decl= (typedef_decl*)arc_malloc(sizeof(parser__NS_typedef_decl));
                memset((i8*)td, 0, sizeof(parser__NS_typedef_decl));
                td.kind = nd_typedef_decl;
                td.name = lexer.str_dup(self.consume_id_value("Expected name after 'comptime type'"));
                self.consume_tok(assign, "Expected '=' after type alias name");
                td.target = self.parse_type();
                self.match_tok(sm);
                return (ast_node*)td;
            }
        }

        // New-style: [@unsafe] extern fn name(params) RetType;
        if (self.check_tok(kw_extern) && self.peek_at_type(1) == kw_fn) {
            self.advance_tok(); // consume 'extern'
            let mut ef2: *func_decl= self.parse_fn_decl_new(false);
            if (ef2 != (func_decl*)0) { ef2.is_extern_c = true; ef2.is_unsafe = is_unsafe_decl; ef2.is_extern_kw = true; }
            return (ast_node*)ef2;
        }

        // New-style: [@unsafe] extern let name: Type;  — a global defined in another
        // translation unit (e.g. the C runtime's `stdout`). No initializer: the
        // definition lives elsewhere, so this only emits an external declaration.
        if (self.check_tok(kw_extern) && self.peek_at_type(1) == kw_let) {
            self.advance_tok(); // consume 'extern'
            self.advance_tok(); // consume 'let'
            let mut evd: *var_decl= (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
            memset((i8*)evd, 0, sizeof(parser__NS_var_decl));
            evd.kind       = nd_var_decl;
            evd.line       = (u64)self.peek_line();
            evd.name       = lexer.str_dup(self.consume_id_value("Expected name after 'extern let'"));
            self.consume_tok(colon, "Expected ':' after extern variable name");
            evd.type       = self.parse_type();
            if (evd.type != (type_node*)0) { evd.type.is_extern = true; }
            evd.is_mutable = true;
            evd.is_extern  = true;
            self.match_tok(sm);
            return (ast_node*)evd;
        }

        let mut ret: *type_node= self.parse_type();

        // Error union: !T or E!T
        let mut is_err_union: bool= false;
        let mut err_type: *type_node= (type_node*)0;
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
            let mut op_name: [64]i8;
            let mut tt2: i32= self.peek_type();
            // Consume the operator symbol(s)
            let mut op_tok: lexer.token_t= self.advance_tok();
            // Handle two-character operators (==, !=, <=, >=, +=, etc.)
            let mut tt3: i32= self.peek_type();
            if ((tt2 == assign || tt2 == lt || tt2 == gt || tt2 == not_ || tt2 == plus || tt2 == minus || tt2 == ast || tt2 == slash) &&
                    (tt3 == assign)) {
                self.advance_tok();
                afmt(op_name, (u64)64, "operator%s=", .{ op_tok.value });
            } else if (tt2 == obracket) {
                // operator[] — subscript operator; consume the closing ']'
                self.advance_tok();
                afmt(op_name, (u64)64, "operator[]", .{});
            } else if (tt2 == ty_arb_int) {
                afmt(op_name, (u64)64, "operator_i%s", .{ op_tok.value });
            } else if (tt2 == ty_arb_uint) {
                afmt(op_name, (u64)64, "operator_u%s", .{ op_tok.value });
            } else if (tt2 == ty_arb_float) {
                afmt(op_name, (u64)64, "operator_f%s", .{ op_tok.value });
            } else {
                afmt(op_name, (u64)64, "operator%s", .{ op_tok.value });
            }
            let mut name_tok2: lexer.token_t;
            name_tok2.type  = id;
            name_tok2.value = lexer.str_dup(op_name);
            name_tok2.line  = op_tok.line;
            self.consume_tok(oparen, "Expected '(' after operator name");
            let mut fd2: *func_decl= self.parse_func_body(ret, name_tok2, false);
            if (is_err_union) { fd2.is_error_union = true; fd2.err_type = err_type; }
            return (ast_node*)fd2;
        }

        let mut name_tok: lexer.token_t= self.consume_tok(id, "Expected declaration name");

        // Parse generic type params: funcname<T, U>(...)
        let mut gtp_buf: **i8= (i8**)0;
        let mut gtp_len: i32= 0;
        if (self.check_tok(lt)) {
            let mut gtp_cap: i32= 4;
            gtp_buf = (i8**)arc_malloc(sizeof(i8*) * (u64)gtp_cap);
            self.advance_tok(); // consume '<'
            let mut depth_gf: i32= 1;
            while (depth_gf > 0 && !self.is_at_end_p()) {
                let mut tgf: i32= self.peek_type();
                if (tgf == gt && depth_gf == 1) {
                    depth_gf = 0; self.advance_tok();
                } else if (tgf == lt) { depth_gf = depth_gf + 1; self.advance_tok(); }
                else if (tgf == gt)   { depth_gf = depth_gf - 1; self.advance_tok(); }
                else if (tgf == right && depth_gf <= 2) { depth_gf = 0; self.advance_tok(); }
                else if (tgf == id) {
                    let mut tp_tok: lexer.token_t= self.advance_tok();
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
            let mut fd: *func_decl= self.parse_func_body(ret, name_tok, false);
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
        let mut vd: *var_decl= self.parse_var_body(ret, name_tok);
        vd.is_constexpr = is_cexpr;
        if (ret.is_sta) { vd.is_sta = true; }
        return (ast_node*)vd;
    }

    fn parse_func_or_var_decl_extern_c(self: *parser_t) *ast_node {
        // New-style: fn name(params) RetType;
        if (self.check_tok(kw_fn)) {
            let mut ec_fd: *func_decl= self.parse_fn_decl_new(true);
            if (ec_fd != (func_decl*)0) { ec_fd.is_extern_c = true; }
            return (ast_node*)ec_fd;
        }
        // Old-style: RetType name(params);
        let mut ret: *type_node= self.parse_type();
        let mut name_tok: lexer.token_t= self.consume_tok(id, "Expected declaration name");
        if (self.match_tok(oparen)) {
            let mut fd: *func_decl= self.parse_func_body(ret, name_tok, true);
            fd.is_extern_c = true;
            return (ast_node*)fd;
        }
        return (ast_node*)self.parse_var_body(ret, name_tok);
    }

    // Parse struct body `{ fields }` with a given name (struct keyword already consumed).
    fn parse_anon_struct_body(self: *parser_t, name: *i8) *struct_decl {
        let mut ln: u64= (u64)self.peek_line();
        let mut sd: *struct_decl= (struct_decl*)arc_malloc(sizeof(parser__NS_struct_decl));
        memset((i8*)sd, 0, sizeof(parser__NS_struct_decl));
        sd.kind = nd_struct_decl;
        sd.line = ln;
        sd.name = lexer.str_dup(name);
        sd.fields_cap = 8;
        sd.fields = (var_decl**)arc_malloc(sizeof(i8*) * (u64)sd.fields_cap);
        self.consume_tok(obrace, "Expected '{' after struct");
        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            let mut vd: *var_decl= (var_decl*)0;
            if (self.check_tok(kw_let) || self.check_tok(kw_const)) {
                let mut sf_const: bool= self.match_tok(kw_const);
                if (!sf_const) { self.advance_tok(); self.match_tok(kw_mut); }
                let mut sf_name: lexer.token_t= self.consume_name_tok("Expected field name");
                let mut sf_type: *type_node= alloc_type_node();
                sf_type.is_auto = true;
                if (self.match_tok(colon)) { arc_free((i8*)sf_type); sf_type = self.parse_type(); }
                vd = (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
                memset((i8*)vd, 0, sizeof(parser__NS_var_decl));
                vd.kind = nd_var_decl; vd.line = (u64)sf_name.line;
                vd.type = sf_type; vd.name = lexer.str_dup(sf_name.value);
                vd.is_constexpr = sf_const;
                if (self.match_tok(assign)) { vd.init = self.parse_expr(); vd.has_init = true; }
                self.consume_tok(sm, "Expected ';' after field");
            } else {
                let mut ft: *type_node= self.parse_type();
                let mut fname: lexer.token_t= self.consume_name_tok("Expected field name");
                vd = (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
                memset((i8*)vd, 0, sizeof(parser__NS_var_decl));
                vd.kind = nd_var_decl; vd.line = (u64)fname.line;
                vd.type = ft; vd.name = lexer.str_dup(fname.value);
                self.consume_tok(sm, "Expected ';' after field");
            }
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

    fn parse_struct_decl(self: *parser_t) *struct_decl {
        let mut ln: u64= (u64)self.peek_line();
        self.advance_tok();  // consume 'struct'
        let mut sd: *struct_decl= (struct_decl*)arc_malloc(sizeof(parser__NS_struct_decl));
        memset((i8*)sd, 0, sizeof(parser__NS_struct_decl));
        sd.kind = nd_struct_decl;
        sd.line = ln;
        sd.name = lexer.str_dup(self.consume_id_value("Expected struct name"));
        sd.fields_cap = 8;
        sd.fields = (var_decl**)arc_malloc(sizeof(i8*) * (u64)sd.fields_cap);
        self.consume_tok(obrace, "Expected '{' after struct name");

        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            let mut vd: *var_decl= (var_decl*)0;
            // New-style field: let [mut] name: Type; or const name: Type = val;
            if (self.check_tok(kw_let) || self.check_tok(kw_const)) {
                let mut sf_const: bool= self.match_tok(kw_const);
                if (!sf_const) {
                    self.advance_tok(); // consume 'let'
                    self.match_tok(kw_mut);
                }
                let mut sf_name: lexer.token_t= self.consume_name_tok("Expected field name");
                let mut sf_type: *type_node= alloc_type_node();
                sf_type.is_auto = true;
                if (self.match_tok(colon)) {
                    arc_free((i8*)sf_type);
                    sf_type = self.parse_type();
                }
                vd = (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
                memset((i8*)vd, 0, sizeof(parser__NS_var_decl));
                vd.kind = nd_var_decl;
                vd.line = (u64)sf_name.line;
                vd.type = sf_type;
                vd.name = lexer.str_dup(sf_name.value);
                vd.is_constexpr = sf_const;
                if (self.match_tok(assign)) { vd.init = self.parse_expr(); vd.has_init = true; }
                self.consume_tok(sm, "Expected ';' after field");
            } else {
                // Old-style field: Type name;
                let mut ft: *type_node= self.parse_type();
                let mut fname: lexer.token_t= self.consume_name_tok("Expected field name");
                vd = (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
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
            }

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

    fn parse_union_decl(self: *parser_t) *ast_node {
        let mut ln: u64= (u64)self.peek_line();
        self.advance_tok(); // consume 'union'
        let mut uname: lexer.token_t= self.consume_tok(id, "Expected union name");

        // Parse optional generic type params: <T, U, ...>
        let mut tp_names: [16]*i8;
        let mut tp_count: i32= 0;
        if (self.check_tok(lt)) {
            self.advance_tok(); // consume '<'
            while (!self.check_tok(gt) && !self.is_at_end_p()) {
                if (self.check_tok(id) && tp_count < 16) {
                    let mut tp_tok: lexer.token_t= self.peek_tok();
                    tp_names[tp_count] = lexer.str_dup(tp_tok.value);
                    tp_count = tp_count + 1;
                    self.advance_tok();
                } else { self.advance_tok(); }
                self.match_tok(comma);
            }
            self.match_tok(gt);
        }

        // Parse body (fields)
        let mut sd: *struct_decl= (struct_decl*)arc_malloc(sizeof(parser__NS_struct_decl));
        memset((i8*)sd, 0, sizeof(parser__NS_struct_decl));
        sd.kind = nd_struct_decl;
        sd.line = ln;
        sd.name = lexer.str_dup(uname.value);
        sd.is_union = true;
        sd.fields_cap = 8;
        sd.fields = (var_decl**)arc_malloc(sizeof(i8*) * (u64)sd.fields_cap);
        self.consume_tok(obrace, "Expected '{' after union name");
        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            let mut vd: *var_decl= (var_decl*)0;
            if (self.check_tok(kw_let) || self.check_tok(kw_const)) {
                let mut uf_const: bool= self.match_tok(kw_const);
                if (!uf_const) { self.advance_tok(); self.match_tok(kw_mut); }
                let mut uf_name: lexer.token_t= self.consume_name_tok("Expected field name");
                let mut uf_type: *type_node= alloc_type_node();
                uf_type.is_auto = true;
                if (self.match_tok(colon)) { arc_free((i8*)uf_type); uf_type = self.parse_type(); }
                vd = (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
                memset((i8*)vd, 0, sizeof(parser__NS_var_decl));
                vd.kind = nd_var_decl; vd.line = (u64)uf_name.line;
                vd.type = uf_type; vd.name = lexer.str_dup(uf_name.value);
                vd.is_constexpr = uf_const;
                if (self.match_tok(assign)) { vd.init = self.parse_expr(); vd.has_init = true; }
                self.consume_tok(sm, "Expected ';' after union field");
            } else {
                let mut ft: *type_node= self.parse_type();
                let mut fname: lexer.token_t= self.consume_name_tok("Expected field name");
                vd = (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
                memset((i8*)vd, 0, sizeof(parser__NS_var_decl));
                vd.kind = nd_var_decl; vd.line = (u64)fname.line;
                vd.type = ft; vd.name = lexer.str_dup(fname.value);
                if (self.match_tok(obracket)) {
                    if (!self.check_tok(cbracket)) { ft.array_size_ptr = (i8*)self.parse_expr(); }
                    self.consume_tok(cbracket, "Expected ']' after array size");
                }
                self.consume_tok(sm, "Expected ';' after union field");
            }
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
        let mut nd: *namespace_decl= (namespace_decl*)arc_malloc(sizeof(parser__NS_namespace_decl));
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
        let mut tpi: i32= 0;
        while (tpi < tp_count) {
            nd.type_params[tpi] = tp_names[tpi];
            tpi = tpi + 1;
        }
        nd.type_params_len = tp_count;
        return (ast_node*)nd;
    }

    fn parse_enum_decl(self: *parser_t) *ast_node {
        let mut ln: u64= (u64)self.peek_line();
        self.advance_tok();  // consume 'enum'
        let mut ed: *enum_decl= (enum_decl*)arc_malloc(sizeof(parser__NS_enum_decl));
        memset((i8*)ed, 0, sizeof(parser__NS_enum_decl));
        ed.kind = nd_enum_decl;
        ed.line = ln;
        let mut enum_name: *i8= lexer.str_dup(self.consume_id_value("Expected enum name"));
        ed.name = enum_name;

        // Parse optional generic type params: <T, U, ...>
        let mut etp_names: [16]*i8;
        let mut etp_count: i32= 0;
        if (self.check_tok(lt)) {
            self.advance_tok(); // consume '<'
            while (!self.check_tok(gt) && !self.is_at_end_p()) {
                if (self.check_tok(id) && etp_count < 16) {
                    let mut etp_tok: lexer.token_t= self.peek_tok();
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

        let mut next_val: i64= 0;
        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            let mut var_name: lexer.token_t= self.consume_tok(id, "Expected variant name");

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

            let mut vi: i32= ed.variants_len;
            ed.variant_names[vi]          = lexer.str_dup(var_name.value);
            ed.variant_kinds[vi]          = 0; // plain by default
            ed.variant_field_counts[vi]   = 0;
            ed.variant_method_counts[vi]  = 0;
            // Init flat slots for this variant (stride 8)
            {
                let mut si: i32= 0;
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
                let mut fc: i32= 0;
                while (!self.check_tok(cparen) && !self.is_at_end_p() && fc < 8) {
                    let mut ft: *type_node= self.parse_type();
                    ed.variant_field_type_flat[vi * 8 + fc]  = (i8*)ft;
                    ed.variant_field_names_flat[vi * 8 + fc] = (i8*)0;
                    fc = fc + 1;
                    self.match_tok(comma);
                }
                self.consume_tok(cparen, "Expected ')' in tuple variant");
                ed.variant_field_counts[vi] = fc;
            }

            // ADT named struct / istruc variant: Variant { ... } or Variant .{ ... }
            let mut has_dot_brace: bool= self.check_tok(dot);
            if (has_dot_brace) { self.advance_tok(); } // consume optional '.'
            if (self.check_tok(obrace)) {
                self.advance_tok(); // consume '{'
                ed.is_adt = true;
                ed.variant_kinds[vi] = has_dot_brace ? 3 : 2; // 3=istruc_dot, 2=named_struct
                let mut fc: i32= 0;
                let mut depth_vs: i32= 1;
                while (depth_vs > 0 && !self.is_at_end_p()) {
                    if (self.check_tok(obrace)) {
                        depth_vs = depth_vs + 1; self.advance_tok();
                    } else if (self.check_tok(cbrace)) {
                        depth_vs = depth_vs - 1;
                        if (depth_vs > 0) { self.advance_tok(); } else { break; }
                    } else if (depth_vs == 1 && self.is_type_start() && !self.check_tok(kw_const)) {
                        let mut saved_pos: i32= self.current;
                        let mut ft: *type_node= self.parse_type();
                        if (self.check_tok(id)) {
                            let mut fname: lexer.token_t= self.consume_tok(id, "field name");
                            if (self.check_tok(sm)) {
                                self.advance_tok();
                                if (fc < 8) {
                                    ed.variant_field_names_flat[vi * 8 + fc] = lexer.str_dup(fname.value);
                                    ed.variant_field_type_flat[vi * 8 + fc]  = (i8*)ft;
                                    fc = fc + 1;
                                }
                            } else if (self.check_tok(oparen)) {
                                self.advance_tok(); // consume '('
                                let mut mfd: *func_decl= self.parse_func_body(ft, fname, false);
                                if (mfd != (func_decl*)0) {
                                    let mut mc: i32= ed.variant_method_counts[vi];
                                    if (mc < 8) {
                                        ed.variant_method_flat[vi * 8 + mc] = (i8*)mfd;
                                        ed.variant_method_counts[vi] = mc + 1;
                                    }
                                }
                            } else { self.current = saved_pos; self.advance_tok(); }
                        } else { self.current = saved_pos; self.advance_tok(); }
                    } else if (depth_vs == 1 && self.check_tok(kw_const) && self.peek_at_type(1) != kw_const) {
                        let mut saved_pos: i32= self.current;
                        let mut ft: *type_node= self.parse_type();
                        if (self.check_tok(id)) {
                            let mut fname: lexer.token_t= self.consume_tok(id, "field name");
                            if (self.check_tok(sm)) {
                                self.advance_tok();
                                if (fc < 8) {
                                    ed.variant_field_names_flat[vi * 8 + fc] = lexer.str_dup(fname.value);
                                    ed.variant_field_type_flat[vi * 8 + fc]  = (i8*)ft;
                                    fc = fc + 1;
                                }
                            } else if (self.check_tok(oparen)) {
                                self.advance_tok(); // consume '('
                                let mut mfd: *func_decl= self.parse_func_body(ft, fname, false);
                                if (mfd != (func_decl*)0) {
                                    let mut mc: i32= ed.variant_method_counts[vi];
                                    if (mc < 8) {
                                        ed.variant_method_flat[vi * 8 + mc] = (i8*)mfd;
                                        ed.variant_method_counts[vi] = mc + 1;
                                    }
                                }
                            } else { self.current = saved_pos; self.advance_tok(); }
                        } else { self.current = saved_pos; self.advance_tok(); }
                    } else if (depth_vs == 1 && self.check_tok(kw_let)) {
                        // New-style field: let [mut] name: Type;
                        self.advance_tok(); // consume 'let'
                        self.match_tok(kw_mut); // optional 'mut'
                        if (self.check_tok(id)) {
                            let mut fname: lexer.token_t= self.advance_tok();
                            let mut ft: *type_node= alloc_type_node();
                            ft.is_auto = true;
                            if (self.match_tok(colon)) {
                                arc_free((i8*)ft);
                                ft = self.parse_type();
                            }
                            self.match_tok(sm);
                            if (fc < 8) {
                                ed.variant_field_names_flat[vi * 8 + fc] = lexer.str_dup(fname.value);
                                ed.variant_field_type_flat[vi * 8 + fc]  = (i8*)ft;
                                fc = fc + 1;
                            }
                        } else { self.advance_tok(); }
                    } else if (depth_vs == 1 && self.check_tok(kw_fn)) {
                        // New-style method: fn name(params) RetType { body }
                        let mut mfd2: *func_decl= self.parse_fn_decl_new(false);
                        if (mfd2 != (func_decl*)0) {
                            let mut mc2: i32= ed.variant_method_counts[vi];
                            if (mc2 < 8) {
                                ed.variant_method_flat[vi * 8 + mc2] = (i8*)mfd2;
                                ed.variant_method_counts[vi] = mc2 + 1;
                            }
                        }
                    } else { self.advance_tok(); }
                }
                self.consume_tok(cbrace, "Expected '}' after variant body");
                ed.variant_field_counts[vi] = fc;
            }

            if (self.match_tok(assign)) {
                let mut val_expr: *expr_node= self.parse_expr();
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
        let mut end: *namespace_decl= (namespace_decl*)arc_malloc(sizeof(parser__NS_namespace_decl));
        memset((i8*)end, 0, sizeof(parser__NS_namespace_decl));
        end.kind = nd_namespace_decl;
        end.line = ln;
        end.name = enum_name;
        end.decls_cap = 4;
        end.decls = (ast_node**)arc_malloc(sizeof(i8*) * (u64)end.decls_cap);
        end.decls[0] = (ast_node*)ed;
        end.decls_len = 1;
        end.type_params = (i8**)arc_malloc(sizeof(i8*) * (u64)etp_count);
        let mut etpi: i32= 0;
        while (etpi < etp_count) {
            end.type_params[etpi] = etp_names[etpi];
            etpi = etpi + 1;
        }
        end.type_params_len = etp_count;
        return (ast_node*)end;
    }

    fn parse_typedef_decl(self: *parser_t) *typedef_decl {
        let mut ln: u64= (u64)self.peek_line();
        self.advance_tok();  // consume 'typedef'
        let mut td: *typedef_decl= (typedef_decl*)arc_malloc(sizeof(parser__NS_typedef_decl));
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

    fn parse_namespace_decl(self: *parser_t) *namespace_decl {
        let mut ln: u64= (u64)self.peek_line();
        self.advance_tok();  // consume 'namespace'
        let mut nd: *namespace_decl= (namespace_decl*)arc_malloc(sizeof(parser__NS_namespace_decl));
        memset((i8*)nd, 0, sizeof(parser__NS_namespace_decl));
        nd.kind = nd_namespace_decl;
        nd.line = ln;
        nd.name = lexer.str_dup(self.consume_id_value("Expected namespace name"));
        nd.decls_cap = 16;
        nd.decls = (ast_node**)arc_malloc(sizeof(i8*) * (u64)nd.decls_cap);
        self.consume_tok(obrace, "Expected '{' after namespace name");

        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            let mut decl: *ast_node= self.parse_top_level();
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

    // `blk_unsafe` carries a leading `@unsafe` on the block, marking every declaration
    // inside it — otherwise each member would need its own annotation.
    fn parse_extern_c_block(self: *parser_t, blk_unsafe: bool) *extern_c_block {
        let mut ln: u64= (u64)self.peek_line();
        self.advance_tok();  // consume 'extern "C"'
        let mut blk: *extern_c_block= (extern_c_block*)arc_malloc(sizeof(parser__NS_extern_c_block));
        memset((i8*)blk, 0, sizeof(parser__NS_extern_c_block));
        blk.kind = nd_extern_c_block;
        blk.line = ln;
        blk.decls_cap = 16;
        blk.decls = (ast_node**)arc_malloc(sizeof(i8*) * (u64)blk.decls_cap);

        if (self.match_tok(obrace)) {
            while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                let mut decl: *ast_node= self.parse_func_or_var_decl_extern_c();
                if (decl != (ast_node*)0) {
                    if (blk_unsafe && decl.kind == nd_func_decl) {
                        let mut mfd: *func_decl= (func_decl*)decl;
                        mfd.is_unsafe = true;
                    }
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
            let mut decl: *ast_node= self.parse_func_or_var_decl_extern_c();
            if (blk_unsafe && decl != (ast_node*)0 && decl.kind == nd_func_decl) {
                let mut sfd: *func_decl= (func_decl*)decl;
                sfd.is_unsafe = true;
            }
            blk.decls[0] = decl;
            blk.decls_len = 1;
        }
        return blk;
    }

    // Parses `istruc` / `interface` / `memstr` declarations. The body is represented
    // as a namespace_decl (with is_istruc/is_interface/is_memstr set) rather than a
    // separate class node, so methods and nested types reuse the namespace machinery.
    fn parse_istruc_decl(self: *parser_t) *ast_node {
        let mut ln: u64= (u64)self.peek_line();
        let mut decl_is_memstr: bool= self.is_memstr_kw();
        let mut decl_is_interface: bool= self.check_tok(kw_interface);
        self.advance_tok();  // consume 'istruc' or 'interface' or 'memstr'

        // Anonymous istruc: `istruc { ... } var_name;` or `auto x = istruc { ... };`
        // Detected when '{' follows immediately (no identifier name).
        let mut class_name: lexer.token_t;
        if (self.check_tok(obrace)) {
            // Generate synthetic name: __anon_istruc_N
            let mut syn_name: [32]i8;
            afmt(syn_name, (u64)32, "__anon_istruc_%d", .{ self.anon_istruc_count });
            self.anon_istruc_count = self.anon_istruc_count + 1;
            class_name.type  = id;
            class_name.value = lexer.str_dup(syn_name);
            class_name.line  = (i32)ln;
        } else {
            class_name = self.consume_tok(id, "Expected class name");
        }

        // Parse optional type params: <T, U> — stored for generic monomorphization
        let mut tp_names: [16]*i8;
        let mut tp_count: i32= 0;
        if (self.check_tok(lt)) {
            self.advance_tok(); // consume '<'
            while (!self.check_tok(gt) && !self.is_at_end_p()) {
                if (self.check_tok(id) && tp_count < 16) {
                    let mut tp_tok: lexer.token_t= self.peek_tok();
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
        let mut base_buf: [16]*i8;
        let mut base_count: i32= 0;
        if (self.match_tok(colon)) {
            while (self.check_tok(id)) {
                let mut base_tok: lexer.token_t= self.peek_tok();
                if (base_count < 16) {
                    base_buf[base_count] = lexer.str_dup(base_tok.value);
                    base_count = base_count + 1;
                }
                self.advance_tok(); // consume base name
                // Consume optional generic type args <T1, T2, ...>
                if (self.check_tok(lt)) {
                    self.advance_tok(); // consume '<'
                    let mut depth: i32= 1;
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
        let mut nd: *namespace_decl= (namespace_decl*)arc_malloc(sizeof(parser__NS_namespace_decl));
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
            let mut bi: i32= 0;
            while (bi < base_count) {
                nd.bases[bi] = base_buf[bi];
                bi = bi + 1;
            }
            nd.bases_len = base_count;
        }

        // Forward declaration: istruc Name;
        if (self.check_tok(sm)) {
            self.advance_tok(); // consume ';'
            nd.decls_len = 0;
            return (ast_node*)nd;
        }

        self.consume_tok(obrace, "Expected '{' after class name");
        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            // Collect modifiers: const, static, inline, comptime, pub, priv
            let mut mod_is_static: bool= false;
            let mut skip_mod: bool= true;
            while (skip_mod) {
                let mut tt: i32= self.peek_type();
                if (tt == kw_static)  { self.advance_tok(); mod_is_static = true; }
                else if (tt == kw_pub || tt == kw_priv) { self.advance_tok(); }
                else if (tt == kw_comptime || tt == kw_inline) {
                    self.advance_tok();
                } else {
                    skip_mod = false;
                }
            }

            if (self.check_tok(cbrace)) { break; }

            // Conversion operator: operator TypeName(...) — no return type prefix
            if (self.check_tok(kw_operator)) {
                let mut op_nt: i32= self.peek_at_type(1);
                if (op_nt == ty_arb_int || op_nt == ty_arb_uint || op_nt == ty_arb_float) {
                    self.advance_tok(); // consume 'operator'
                    let mut op_tt: i32= self.peek_type();
                    let mut conv_ret: *type_node= self.parse_type();
                    let mut conv_name: [64]i8;
                    if (op_tt == ty_arb_int) {
                        afmt(conv_name, (u64)64, "operator_i%d", .{ (i32)conv_ret.bit_width });
                    } else if (op_tt == ty_arb_uint) {
                        afmt(conv_name, (u64)64, "operator_u%d", .{ (i32)conv_ret.bit_width });
                    } else {
                        afmt(conv_name, (u64)64, "operator_f%d", .{ (i32)conv_ret.bit_width });
                    }
                    let mut conv_nt: lexer.token_t;
                    conv_nt.type  = id;
                    conv_nt.value = lexer.str_dup(conv_name);
                    conv_nt.line  = 0;
                    self.consume_tok(oparen, "Expected '(' for conversion operator");
                    let mut conv_fd: *func_decl= self.parse_func_body(conv_ret, conv_nt, false);
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

            let mut member: *ast_node= self.parse_func_or_var_decl();
            if (member != (ast_node*)0) {
                // Propagate static flag to functions or fields
                if (mod_is_static && member.kind == nd_func_decl) {
                    let mut mfd: *func_decl= (func_decl*)member;
                    mfd.is_static = true;
                }
                if (mod_is_static && member.kind == nd_var_decl) {
                    let mut mvd: *var_decl= (var_decl*)member;
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
        let mut sd: *struct_decl= (struct_decl*)arc_malloc(sizeof(parser__NS_struct_decl));
        memset((i8*)sd, 0, sizeof(parser__NS_struct_decl));
        sd.kind       = nd_struct_decl;
        sd.line       = ln;
        sd.name       = lexer.str_dup(nd.name);
        sd.fields_cap = 8;
        sd.fields     = (var_decl**)arc_malloc(sizeof(i8*) * (u64)sd.fields_cap);
        sd.fields_len = 0;

        let mut out: *namespace_decl= (namespace_decl*)arc_malloc(sizeof(parser__NS_namespace_decl));
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
        let mut pi: i32= 0;
        while (pi < nd.decls_len) {
            let mut m: *ast_node= nd.decls[pi];
            if (m != (ast_node*)0 && m.kind == nd_var_decl) {
                let mut mvd: *var_decl= (var_decl*)m;
                if (mvd.is_static) {
                    // Static field: emit as module global named TYPENAME__static_FIELDNAME
                    let mut sname: [512]i8;
                    afmt(sname, (u64)512, "%s__static_%s", .{ nd.name, mvd.name });
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
            let mut tpi: i32= 0;
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
                let mut inst_tok: lexer.token_t= self.advance_tok();
                let mut vd: *var_decl= (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
                memset((i8*)vd, 0, sizeof(parser__NS_var_decl));
                vd.kind = nd_var_decl;
                vd.line = (u64)inst_tok.line;
                vd.name = lexer.str_dup(inst_tok.value);
                let mut inst_ty: *type_node= (type_node*)arc_malloc(sizeof(parser__NS_type_node));
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

    // Implement the at-import builtin as a parser-level module system.
    // Reads and parses the given file, returning a namespace_decl containing
    // all its top-level declarations under the given name.
    fn parse_import_as_namespace(self: *parser_t, ns_name: *i8) *namespace_decl {
        self.advance_tok();  // consume '@'
        self.advance_tok();  // consume 'import'
        self.consume_tok(oparen, "Expected '(' after '@import'");

        let mut path_tok: lexer.token_t= self.advance_tok();
        if (path_tok.type != string_lit) {
            aprint("error: @import expects a string literal path\n", .{});
            self.had_parse_error = true;
            self.consume_tok(cparen, "Expected ')'");
            let mut empty_nd: *namespace_decl= (namespace_decl*)arc_malloc(sizeof(parser__NS_namespace_decl));
            memset((i8*)empty_nd, 0, sizeof(parser__NS_namespace_decl));
            empty_nd.kind = nd_namespace_decl;
            empty_nd.name = ns_name;
            empty_nd.decls = (ast_node**)arc_malloc(sizeof(i8*) * 8u);
            empty_nd.decls_len = 0; empty_nd.decls_cap = 8;
            return empty_nd;
        }
        let mut rel_path: *i8= path_tok.value;
        self.consume_tok(cparen, "Expected ')' after import path");

        // Compute the base directory of the current source file
        let mut base_dir_buf: [2048]i8;
        base_dir_buf[0] = '.'; base_dir_buf[1] = '/'; base_dir_buf[2] = 0;
        if (self.import_src_path != (i8*)0) {
            let mut si: i32= 0;
            let mut last_sep: i32= -1;
            while (self.import_src_path[si] != 0) {
                if (self.import_src_path[si] == '/' || self.import_src_path[si] == '\\') { last_sep = si; }
                si = si + 1;
            }
            if (last_sep >= 0) {
                let mut sj: i32= 0;
                while (sj <= last_sep) { base_dir_buf[sj] = self.import_src_path[sj]; sj = sj + 1; }
                base_dir_buf[last_sep + 1] = 0;
            }
        }

        // Resolve the full path.
        // 'std/...' paths resolve via the stdlib directory if available.
        let mut full_path_buf: [2048]i8;
        let mut is_std_path: bool= (rel_path[0]=='s' && rel_path[1]=='t' && rel_path[2]=='d' && rel_path[3]=='/');
        if (is_std_path && self.import_stdlib_path != (i8*)0) {
            afmt(full_path_buf, 2048u, "%s/%s", .{ self.import_stdlib_path, rel_path + 4 });
        } else if (rel_path[0] == '/' || rel_path[0] == '\\') {
            afmt(full_path_buf, 2048u, "%s", .{ rel_path });
        } else {
            afmt(full_path_buf, 2048u, "%s%s", .{ base_dir_buf, rel_path });
        }

        // Read source
        let mut file_src: *i8= preproc.pp_read_file(full_path_buf);
        if (file_src == (i8*)0) {
            aprint("error: @import: cannot open '%s'\n", .{ full_path_buf });
            self.had_parse_error = true;
            let mut empty_nd2: *namespace_decl= (namespace_decl*)arc_malloc(sizeof(parser__NS_namespace_decl));
            memset((i8*)empty_nd2, 0, sizeof(parser__NS_namespace_decl));
            empty_nd2.kind = nd_namespace_decl;
            empty_nd2.name = ns_name;
            empty_nd2.decls = (ast_node**)arc_malloc(sizeof(i8*) * 8u);
            empty_nd2.decls_len = 0; empty_nd2.decls_cap = 8;
            return empty_nd2;
        }

        // Preprocess
        let mut pp_content: *i8= preproc.preprocess(file_src, full_path_buf, self.import_stdlib_path);
        arc_free(file_src);

        // Tokenize
        let mut sub_lex: lexer.lexer_t;
        sub_lex.init(pp_content, (u64)strlen(pp_content));
        let mut sub_toks: lexer.token_vec= sub_lex.tokenize();

        // Parse with a sub-parser that knows where this file lives
        let mut sub_par: parser_t;
        sub_par.init(sub_toks.data, sub_toks.len);
        sub_par.import_src_path    = lexer.str_dup(full_path_buf);
        sub_par.import_stdlib_path = self.import_stdlib_path;
        let mut sub_prog: *program_node= sub_par.parse();
        arc_free(pp_content);

        // Wrap all declarations in a namespace_decl named ns_name
        let mut nd: *namespace_decl= (namespace_decl*)arc_malloc(sizeof(parser__NS_namespace_decl));
        memset((i8*)nd, 0, sizeof(parser__NS_namespace_decl));
        nd.kind      = nd_namespace_decl;
        nd.name      = ns_name;
        nd.decls     = sub_prog.decls;
        nd.decls_len = sub_prog.decls_len;
        nd.decls_cap = sub_prog.decls_cap;
        arc_free((i8*)sub_prog);

        return nd;
    }

    // Like parse_import_as_namespace but takes the path directly (no @import(...) tokens consumed).
    // Returns a null-name namespace_decl whose decls are spliced by parse() directly into the program.
    fn parse_import_splice(self: *parser_t, rel_path: *i8) *namespace_decl {
        let mut base_dir_buf: [2048]i8;
        base_dir_buf[0] = '.'; base_dir_buf[1] = '/'; base_dir_buf[2] = 0;
        if (self.import_src_path != (i8*)0) {
            let mut si: i32= 0;
            let mut last_sep: i32= -1;
            while (self.import_src_path[si] != 0) {
                if (self.import_src_path[si] == '/' || self.import_src_path[si] == '\\') { last_sep = si; }
                si = si + 1;
            }
            if (last_sep >= 0) {
                let mut sj: i32= 0;
                while (sj <= last_sep) { base_dir_buf[sj] = self.import_src_path[sj]; sj = sj + 1; }
                base_dir_buf[last_sep + 1] = 0;
            }
        }
        let mut full_path_buf: [2048]i8;
        let mut is_std_path: bool= (rel_path[0]=='s' && rel_path[1]=='t' && rel_path[2]=='d' && rel_path[3]=='/');
        if (is_std_path && self.import_stdlib_path != (i8*)0) {
            afmt(full_path_buf, 2048u, "%s/%s", .{ self.import_stdlib_path, rel_path + 4 });
        } else if (rel_path[0] == '/' || rel_path[0] == '\\') {
            afmt(full_path_buf, 2048u, "%s", .{ rel_path });
        } else {
            afmt(full_path_buf, 2048u, "%s%s", .{ base_dir_buf, rel_path });
        }
        let mut err_nd: *namespace_decl= (namespace_decl*)arc_malloc(sizeof(parser__NS_namespace_decl));
        memset((i8*)err_nd, 0, sizeof(parser__NS_namespace_decl));
        err_nd.kind = nd_namespace_decl;
        err_nd.name = (i8*)0;
        err_nd.decls = (ast_node**)arc_malloc(sizeof(i8*) * 8u);
        err_nd.decls_len = 0; err_nd.decls_cap = 8;
        let mut file_src: *i8= preproc.pp_read_file(full_path_buf);
        if (file_src == (i8*)0) {
            aprint("error: extern import: cannot open '%s'\n", .{ full_path_buf });
            self.had_parse_error = true;
            return err_nd;
        }
        let mut pp_content: *i8= preproc.preprocess(file_src, full_path_buf, self.import_stdlib_path);
        arc_free(file_src);
        let mut sub_lex: lexer.lexer_t;
        sub_lex.init(pp_content, (u64)strlen(pp_content));
        let mut sub_toks: lexer.token_vec= sub_lex.tokenize();
        let mut sub_par: parser_t;
        sub_par.init(sub_toks.data, sub_toks.len);
        sub_par.import_src_path    = lexer.str_dup(full_path_buf);
        sub_par.import_stdlib_path = self.import_stdlib_path;
        let mut sub_prog: *program_node= sub_par.parse();
        arc_free(pp_content);
        let mut nd: *namespace_decl= (namespace_decl*)arc_malloc(sizeof(parser__NS_namespace_decl));
        memset((i8*)nd, 0, sizeof(parser__NS_namespace_decl));
        nd.kind      = nd_namespace_decl;
        nd.name      = (i8*)0;
        nd.decls     = sub_prog.decls;
        nd.decls_len = sub_prog.decls_len;
        nd.decls_cap = sub_prog.decls_cap;
        arc_free((i8*)sub_prog);
        arc_free((i8*)err_nd);
        return nd;
    }

    fn parse_top_level(self: *parser_t) *ast_node {
        // Optional visibility, @unsafe and @link_name prefixes, in any order — writing
        // `@unsafe pub fn` is as natural as `pub @unsafe fn`, and accepting only one
        // spelling would silently drop the annotation from the other.
        let mut is_pub_tl: bool= false;
        let mut is_unsafe_tl: bool= false;
        let mut link_name_tl: *i8= (i8*)0;
        let mut scanning_prefix: bool= true;
        while (scanning_prefix) {
            if (self.check_tok(kw_pub))       { self.advance_tok(); is_pub_tl = true; }
            else if (self.check_tok(kw_priv)) { self.advance_tok(); }
            else if (self.check_tok(at) && self.peek_at_type(1) == id &&
                     self.tokens[self.current + 1].value != (i8*)0 &&
                     strcmp(self.tokens[self.current + 1].value, "unsafe") == 0) {
                is_unsafe_tl = true;
                self.advance_tok(); // consume '@'
                self.advance_tok(); // consume 'unsafe'
            }
            // @link_name("sym") — the symbol this declaration binds to, when it differs
            // from the Arc name. Lets a raw FFI declaration sit beside a safe wrapper
            // that reuses the plain name.
            else if (self.check_tok(at) && self.peek_at_type(1) == id &&
                     self.tokens[self.current + 1].value != (i8*)0 &&
                     strcmp(self.tokens[self.current + 1].value, "link_name") == 0) {
                self.advance_tok(); // consume '@'
                self.advance_tok(); // consume 'link_name'
                self.consume_tok(oparen, "Expected '(' after @link_name");
                let mut ln_tok: lexer.token_t= self.advance_tok();
                if (ln_tok.type == string_lit && ln_tok.value != (i8*)0) {
                    link_name_tl = lexer.str_dup(ln_tok.value);
                } else {
                    aprint("error at line %d: @link_name expects a string literal\n", .{ (i32)ln_tok.line });
                    self.had_parse_error = true;
                }
                self.consume_tok(cparen, "Expected ')' after @link_name symbol");
            }
            else { scanning_prefix = false; }
        }
        // New-style fn declaration
        if (self.check_tok(kw_fn)) {
            let mut tl_fd: *func_decl= self.parse_fn_decl_new(false);
            if (tl_fd != (func_decl*)0) {
                tl_fd.is_pub = is_pub_tl; tl_fd.is_unsafe = is_unsafe_tl;
                if (link_name_tl != (i8*)0) { tl_fd.link_name = link_name_tl; }
            }
            return (ast_node*)tl_fd;
        }
        // New-style let/const at top level (global variables)
        if (self.check_tok(kw_let) || (self.check_tok(kw_const) && self.peek_at_type(1) == id &&
                (self.peek_at_type(2) == assign || self.peek_at_type(2) == colon || self.peek_at_type(2) == sm))) {
            let mut is_gl_const: bool= self.match_tok(kw_const);
            if (!is_gl_const) {
                self.advance_tok(); // consume 'let'
                self.match_tok(kw_mut);
            }
            let mut gl_name_tok: lexer.token_t= self.advance_tok();
            let mut gl_type: *type_node= alloc_type_node();
            gl_type.is_auto = true;
            if (self.match_tok(colon)) {
                arc_free((i8*)gl_type);
                gl_type = self.parse_type();
            }
            // 'const Name: type = TypeAlias;' — emit as typedef (type alias)
            if (gl_type.is_sta && is_gl_const) {
                arc_free((i8*)gl_type);
                let mut td: *typedef_decl= (typedef_decl*)arc_malloc(sizeof(parser__NS_typedef_decl));
                memset((i8*)td, 0, sizeof(parser__NS_typedef_decl));
                td.kind = nd_typedef_decl;
                td.name = lexer.str_dup(gl_name_tok.value);
                self.consume_tok(assign, "Expected '=' in type alias declaration");
                td.target = self.parse_type();
                self.consume_tok(sm, "Expected ';'");
                return (ast_node*)td;
            }
            let mut gl_vd: *var_decl= (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
            memset((i8*)gl_vd, 0, sizeof(parser__NS_var_decl));
            gl_vd.kind = nd_var_decl;
            gl_vd.line = (u64)gl_name_tok.line;
            gl_vd.type = gl_type;
            gl_vd.name = lexer.str_dup(gl_name_tok.value);
            gl_vd.is_constexpr = is_gl_const;
            gl_vd.is_pub = is_pub_tl;
            if (self.match_tok(assign)) {
                // const NAME = at-import(path) -- module import; handled here not in expr
                if (is_gl_const && self.check_tok(at) && self.peek_at_type(1) == fn_import) {
                    let mut imp_nd: *namespace_decl= self.parse_import_as_namespace(lexer.str_dup(gl_name_tok.value));
                    self.consume_tok(sm, "Expected ';' after module import");
                    arc_free((i8*)gl_vd);
                    arc_free((i8*)gl_type);
                    return (ast_node*)imp_nd;
                }
                // const NAME = struct/union/enum/istruc { ... } -- anonymous type with binding name
                if (is_gl_const && (self.check_tok(kw_struct) || self.check_tok(kw_union) ||
                                    self.check_tok(kw_enum)   || self.check_tok(kw_istruc) ||
                                    self.check_tok(kw_interface) || self.is_memstr_kw())) {
                    arc_free((i8*)gl_vd); arc_free((i8*)gl_type);
                    if (self.check_tok(kw_struct) || self.check_tok(kw_union)) {
                        let mut is_union_c: bool= self.check_tok(kw_union);
                        self.advance_tok();
                        let mut sd2: *struct_decl= self.parse_anon_struct_body(gl_name_tok.value);
                        if (is_union_c) { sd2.is_union = true; }
                        self.match_tok(sm);
                        return (ast_node*)sd2;
                    }
                    if (self.check_tok(kw_enum)) { return self.parse_enum_decl(); }
                    return self.parse_istruc_decl();
                }
                gl_vd.init = self.parse_expr();
                gl_vd.has_init = true;
            }
            self.consume_tok(sm, "Expected ';'");
            return (ast_node*)gl_vd;
        }
        if (self.check_tok(kw_struct))     { return (ast_node*)self.parse_struct_decl(); }
        if (self.check_tok(kw_union))      { return self.parse_union_decl(); }
        if (self.check_tok(kw_enum))       { return self.parse_enum_decl(); }
        if (self.check_tok(kw_istruc))     { return self.parse_istruc_decl(); }
        if (self.check_tok(kw_interface))  { return self.parse_istruc_decl(); }
        if (self.check_tok(kw_extern_c))   { return (ast_node*)self.parse_extern_c_block(is_unsafe_tl); }
        if (self.check_tok(kw_namespace))  { return (ast_node*)self.parse_namespace_decl(); }
        // Proc macro application: #[name] or #[name(args)] or #derive[name] or #![name] (file-level)
        if (self.check_tok(hash)) {
            self.advance_tok(); // consume '#'
            let mut is_file_level: bool= false;
            let mut is_derive_app: bool= false;
            if (self.check_tok(not_)) { self.advance_tok(); is_file_level = true; }
            // #derive[name] shorthand: check for 'derive' as keyword OR identifier before '['
            if ((self.check_tok(id) || self.check_tok(kw_derive)) && self.peek_at_type(1) == obracket) {
                let mut kw: lexer.token_t= self.advance_tok();
                if (strcmp(kw.value, "derive") == 0 || kw.type == kw_derive) { is_derive_app = true; }
                else { self.current = self.current - 1; } // put back if not "derive"
            }
            if (self.check_tok(obracket)) {
                self.advance_tok(); // consume '['
                // Collect macro name and optional args (accept identifiers AND keywords like 'derive', 'attr')
                let mut macro_name: *i8= (i8*)0;
                if (!self.check_tok(cbracket) && !self.is_at_end_p()) {
                    let mut mn_tok: lexer.token_t= self.advance_tok();
                    macro_name = mn_tok.value;
                    if (macro_name == (i8*)0 || macro_name[0] == 0) {
                        if (mn_tok.type == kw_derive) { macro_name = "derive"; }
                        else if (mn_tok.type == kw_attr) { macro_name = "attr"; }
                        else if (mn_tok.type == kw_inline) { macro_name = "inline"; }
                    }
                    // Parse dotted segments: bar.mymacro → "bar.mymacro"
                    if (macro_name != (i8*)0 && macro_name[0] != 0) {
                        let mut full_mn: [256]i8;
                        afmt(full_mn, (u64)256, "%s", .{ macro_name });
                        let mut dot_loop: bool= true;
                        while (dot_loop && self.check_tok(dot) && !self.is_at_end_p()) {
                            self.advance_tok(); // consume '.'
                            if (self.check_tok(id) || self.peek_type() >= kw_if) {
                                let mut seg2: lexer.token_t= self.advance_tok();
                                if (seg2.value != (i8*)0 && seg2.value[0] != 0) {
                                    let mut tmp2: [256]i8;
                                    afmt(tmp2, (u64)256, "%s.%s", .{ full_mn, seg2.value });
                                    afmt(full_mn, (u64)256, "%s", .{ tmp2 });
                                }
                            } else { dot_loop = false; }
                        }
                        macro_name = lexer.str_dup(full_mn);
                    }
                }
                // Parse optional (args) — capture identifiers as args for derive
                let mut attr_args_buf: [16]*i8;
                let mut attr_args_count: i32= 0;
                if (self.check_tok(oparen)) {
                    let mut pd: i32= 1; self.advance_tok();
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
                                    let mut atok: lexer.token_t= self.advance_tok();
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
                let mut attr_args: **i8= (i8**)0;
                if (attr_args_count > 0) {
                    attr_args = (i8**)arc_malloc(sizeof(i8*) * (u64)attr_args_count);
                    let mut aai: i32= 0;
                    while (aai < attr_args_count) {
                        attr_args[aai] = attr_args_buf[aai];
                        aai = aai + 1;
                    }
                }
                let mut pre_cbr_err: bool= self.had_parse_error;
                self.consume_tok(cbracket, "Expected ']' after attribute");
                if (self.had_parse_error && !pre_cbr_err) {
                    // consume_tok failed — skip to ']' to prevent infinite error loops
                    while (!self.check_tok(cbracket) && !self.is_at_end_p() &&
                           !self.check_tok(sm) && !self.check_tok(obrace)) {
                        self.advance_tok();
                    }
                    if (self.check_tok(cbracket)) { self.advance_tok(); }
                }
                // Parse the decorated declaration and attach the attribute
                let mut decorated: *ast_node= self.parse_top_level();
                if (decorated != (ast_node*)0 && macro_name != (i8*)0) {
                    if (decorated.kind == nd_func_decl) {
                        let mut dfd: *func_decl= (func_decl*)decorated;
                        let mut nc: i32= dfd.attributes_len + 1;
                        let mut new_attrs: *proc_attr= (proc_attr*)arc_realloc((i8*)dfd.attributes, sizeof(parser__NS_proc_attr) * (u64)nc);
                        new_attrs[nc - 1].name     = macro_name;
                        new_attrs[nc - 1].args     = attr_args;
                        new_attrs[nc - 1].args_len = attr_args_count;
                        dfd.attributes     = new_attrs;
                        dfd.attributes_len = nc;
                    } else if (decorated.kind == nd_namespace_decl) {
                        let mut dns: *namespace_decl= (namespace_decl*)decorated;
                        let mut nc2: i32= dns.attributes_len + 1;
                        let mut new_attrs2: *proc_attr= (proc_attr*)arc_realloc((i8*)dns.attributes, sizeof(parser__NS_proc_attr) * (u64)nc2);
                        new_attrs2[nc2 - 1].name     = macro_name;
                        new_attrs2[nc2 - 1].args     = attr_args;
                        new_attrs2[nc2 - 1].args_len = attr_args_count;
                        dns.attributes     = new_attrs2;
                        dns.attributes_len = nc2;
                    } else if (decorated.kind == nd_var_decl) {
                        let mut dvd: *var_decl= (var_decl*)decorated;
                        let mut nc3: i32= dvd.attributes_len + 1;
                        let mut new_attrs3: *proc_attr= (proc_attr*)arc_realloc((i8*)dvd.attributes, sizeof(parser__NS_proc_attr) * (u64)nc3);
                        new_attrs3[nc3 - 1].name     = macro_name;
                        new_attrs3[nc3 - 1].args     = attr_args;
                        new_attrs3[nc3 - 1].args_len = attr_args_count;
                        dvd.attributes     = new_attrs3;
                        dvd.attributes_len = nc3;
                    }
                }
                return decorated;
            }
            // Malformed # — skip to end of line and continue
            while (!self.is_at_end_p() && !self.check_tok(sm)) { self.advance_tok(); }
            return self.parse_top_level();
        }
        if (self.is_memstr_kw()) { return self.parse_istruc_decl(); }
        // const NAME = struct { ... } already handled above in kw_const branch.
        // Standalone struct/union/enum/istruc without const binding:
        // (duplicates the checks above but handles the case where pub was consumed earlier)
        if (self.check_tok(kw_struct))     { return (ast_node*)self.parse_struct_decl(); }
        if (self.check_tok(kw_union))      { return self.parse_union_decl(); }
        if (self.check_tok(kw_enum))       { return self.parse_enum_decl(); }
        if (self.check_tok(kw_istruc) || self.check_tok(kw_interface)) { return self.parse_istruc_decl(); }
        // using — two syntaxes accepted:
        //   using Name = Type;  (C++ style, Name is id and next token is '=')
        //   using Type Name;    (C typedef compat)
        if (self.check_tok(kw_using)) {
            self.advance_tok(); // consume 'using'
            let mut td: *typedef_decl= (typedef_decl*)arc_malloc(sizeof(parser__NS_typedef_decl));
            memset((i8*)td, 0, sizeof(parser__NS_typedef_decl));
            td.kind = nd_typedef_decl;
            // Peek one ahead: if current is 'id' (or keyword name) AND next is '=', it's C++ style.
            let mut next_tok: lexer.token_t= self.peek_at_tok(1);
            let mut cpp_style: bool= (self.check_tok(id) || self.peek_type() >= kw_if) && (next_tok.type == assign);
            // `using name;` or `using ns.name;` — namespace import (no '=', no type-before-name)
            // Detect: id or dotted-id immediately followed by ';'
            let mut ns_import: bool= false;
            if (self.check_tok(id) && !cpp_style) {
                // Look ahead for ';' (possibly after dot-separated segments)
                let mut saved2: i32= self.current;
                self.advance_tok(); // consume first id
                while (self.match_tok(dot) && self.check_tok(id)) { self.advance_tok(); }
                if (self.check_tok(sm)) { ns_import = true; }
                self.current = saved2;
            }
            if (ns_import) {
                // using ns_name;  — collect the full dotted name
                let mut ns_buf: [512]i8; ns_buf[0] = 0;
                let mut ns_len: i32= 0;
                while (self.check_tok(id)) {
                    let mut seg: *i8= self.advance_value_get();
                    let mut seg_len: i32= (i32)strlen(seg);
                    if (ns_len + seg_len + 1 < 512) {
                        if (ns_len > 0) { ns_buf[ns_len] = '.'; ns_len = ns_len + 1; }
                        let mut si: i32= 0;
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
                // using Name = Type; (Name may be a keyword like 'let', 'var')
                let mut uname_tok: lexer.token_t= self.consume_name_tok("Expected alias name after using");
                td.name = lexer.str_dup(uname_tok.value);
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
            let mut macro_name: *i8= (i8*)0;
            if (self.check_tok(id)) {
                let mut nm_tok: lexer.token_t= self.advance_tok();
                macro_name = lexer.str_dup(nm_tok.value);
            }
            if (macro_name == (i8*)0) { return (ast_node*)0; }
            self.consume_tok(obrace, "Expected '{' after const_resolve name");
            // Parse rules until '}'
            while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                let mut param_names_buf: [16]*i8;
                let mut param_count: i32= 0;
                // Pattern: (...) or [...]
                let mut pat_open: i32= self.check_tok(oparen)   ? oparen   : (self.check_tok(obracket) ? obracket : -1);
                let mut pat_close: i32= (pat_open == oparen)      ? cparen   : (pat_open == obracket ? cbracket : -1);
                if (pat_open != -1) {
                    self.advance_tok(); // consume open
                    while (!self.check_tok(pat_close) && !self.is_at_end_p()) {
                        if (self.check_tok(dollar)) {
                            self.advance_tok(); // '$'
                            let mut pname: *i8= (i8*)0;
                            if (self.check_tok(id)) {
                                let mut pn_tok: lexer.token_t= self.advance_tok();
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
                // Consume '=>' (fat_arrow token, or legacy assign+gt)
                if (self.check_tok(fat_arrow)) {
                    self.advance_tok();
                } else {
                    if (self.check_tok(assign)) { self.advance_tok(); }
                    if (self.check_tok(gt))     { self.advance_tok(); }
                }
                // Collect template tokens
                let mut tpl_cap: i32= 64;
                let mut tpl: *lexer.token_t= (lexer.token_t*)arc_malloc(sizeof(lexer__NS_token_t) * (u64)tpl_cap);
                let mut tpl_len: i32= 0;
                if (self.check_tok(obrace)) {
                    self.advance_tok(); // consume '{'
                    let mut depth_t: i32= 1;
                    while (depth_t > 0 && !self.is_at_end_p()) {
                        let mut cur: lexer.token_t= self.peek_tok();
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
                let mut mdef: *macro_def_t= (macro_def_t*)arc_malloc(sizeof(parser__NS_macro_def_t));
                mdef.name         = macro_name;
                mdef.param_count  = param_count;
                mdef.template_toks = (i8*)tpl;
                mdef.template_len  = tpl_len;
                mdef.param_names   = (i8**)arc_malloc(sizeof(i8*) * (u64)(param_count + 1));
                let mut pi: i32= 0;
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
        // extern std.X; or extern aciso.X; — splice stdlib/package module into current scope
        // (normally handled by the preprocessor, but kept here as a parse-time fallback)
        if (self.check_tok(kw_extern) && self.peek_at_type(1) == id) {
            let mut saved_cur: i32= self.current;
            self.advance_tok(); // consume 'extern'
            let mut pkg_tok: lexer.token_t= self.advance_tok(); // consume package name
            if (self.check_tok(dot) && self.peek_at_type(1) == id) {
                self.advance_tok(); // consume '.'
                let mut mod_tok: lexer.token_t= self.advance_tok(); // consume module name
                if (self.match_tok(sm)) {
                    let mut ext_path_buf: [512]i8;
                    // aciso packages live in modules/PKG/ relative to source dir
                    let mut is_aciso: bool= (pkg_tok.value[0]=='a' && pkg_tok.value[1]=='c' && pkg_tok.value[2]=='i' && pkg_tok.value[3]=='s' && pkg_tok.value[4]=='o' && pkg_tok.value[5]==0);
                    if (is_aciso) {
                        afmt(ext_path_buf, 512u, "modules/%s/%s.arc", .{ mod_tok.value, mod_tok.value });
                    } else {
                        // std/ prefix is recognized by parse_import_splice → resolves via stdlib path
                        afmt(ext_path_buf, 512u, "%s/%s.arc", .{ pkg_tok.value, mod_tok.value });
                    }
                    return (ast_node*)self.parse_import_splice(ext_path_buf);
                }
            }
            self.current = saved_cur; // not the pattern — fall through
        }
        // - = @import("path");  wildcard import: splice module decls directly into scope
        if (self.check_tok(minus) && self.peek_at_type(1) == assign &&
            self.peek_at_type(2) == at && self.peek_at_type(3) == fn_import) {
            self.advance_tok(); // consume '-'
            self.advance_tok(); // consume '='
            self.advance_tok(); // consume '@'
            self.advance_tok(); // consume 'import'
            self.consume_tok(oparen, "Expected '(' after @import");
            let mut wc_path_tok: lexer.token_t= self.advance_tok();
            self.consume_tok(cparen, "Expected ')' after import path");
            self.consume_tok(sm, "Expected ';'");
            if (wc_path_tok.type == string_lit && wc_path_tok.value != (i8*)0) {
                return (ast_node*)self.parse_import_splice(wc_path_tok.value);
            }
            aprint("error: @import expects a string literal path\n", .{});
            self.had_parse_error = true;
            return (ast_node*)0;
        }
        // New-style: [@unsafe] extern fn name(params) RetType;
        if (self.check_tok(kw_extern) && self.peek_at_type(1) == kw_fn) {
            self.advance_tok(); // consume 'extern'
            let mut ef: *func_decl= self.parse_fn_decl_new(false);
            if (ef != (func_decl*)0) {
                ef.is_extern_c = true; ef.is_unsafe = is_unsafe_tl; ef.is_extern_kw = true;
                if (link_name_tl != (i8*)0) { ef.link_name = link_name_tl; }
            }
            return (ast_node*)ef;
        }
        // New-style: [@unsafe] extern let name: Type;  — a global defined in another
        // translation unit (e.g. the C runtime's `stderr`). No initializer is parsed:
        // the definition lives elsewhere, so codegen emits only a declaration.
        if (self.check_tok(kw_extern) && self.peek_at_type(1) == kw_let) {
            self.advance_tok(); // consume 'extern'
            self.advance_tok(); // consume 'let'
            let mut evd_tl: *var_decl= (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
            memset((i8*)evd_tl, 0, sizeof(parser__NS_var_decl));
            evd_tl.kind       = nd_var_decl;
            evd_tl.line       = (u64)self.peek_line();
            evd_tl.name       = lexer.str_dup(self.consume_id_value("Expected name after 'extern let'"));
            self.consume_tok(colon, "Expected ':' after extern variable name");
            evd_tl.type       = self.parse_type();
            evd_tl.is_mutable = true;
            evd_tl.is_extern  = true;
            evd_tl.is_pub     = true;
            self.match_tok(sm);
            return (ast_node*)evd_tl;
        }
        // Reject leading-type declarations: use 'fn', 'let', 'const', etc. instead.
        if (self.is_type_start()) {
            let mut err_ln: i32= self.peek_line();
            aprint("error at line %d: leading-type declarations are not allowed; use 'fn name(params) RetType' or 'let name: Type = ...'\n", .{ err_ln });
            self.had_parse_error = true;
            // Skip to next ';' or end of '{...}' block to resync
            while (!self.is_at_end_p() && !self.check_tok(sm) && !self.check_tok(cbrace)) {
                if (self.check_tok(obrace)) {
                    let mut depth: i32 = 1;
                    self.advance_tok();
                    while (depth > 0 && !self.is_at_end_p()) {
                        if (self.check_tok(obrace)) { depth = depth + 1; }
                        else if (self.check_tok(cbrace)) { depth = depth - 1; }
                        self.advance_tok();
                    }
                    break;
                }
                self.advance_tok();
            }
            if (self.check_tok(sm)) { self.advance_tok(); }
            return (ast_node*)0;
        }
        // Safety guard: unknown tokens at top level must be skipped to avoid infinite loops.
        // '{' blocks, '}' closers, and raw expressions have no top-level meaning.
        if (self.check_tok(obrace)) {
            let mut err_ln3: i32= self.peek_line();
            aprint("error at line %d: unexpected '{' at top level\n", .{ err_ln3 });
            self.had_parse_error = true;
            let mut skip_depth: i32= 1; self.advance_tok();
            while (skip_depth > 0 && !self.is_at_end_p()) {
                if (self.check_tok(obrace)) { skip_depth = skip_depth + 1; }
                else if (self.check_tok(cbrace)) { skip_depth = skip_depth - 1; }
                self.advance_tok();
            }
            return (ast_node*)0;
        }
        if (self.check_tok(cbrace) || self.check_tok(sm)) {
            self.advance_tok();
            return (ast_node*)0;
        }
        return self.parse_func_or_var_decl();
    }

    // ---- Block and statement parsing ----

    fn parse_block(self: *parser_t) *block_stmt {
        let mut ln: u64= (u64)self.peek_line();
        self.consume_tok(obrace, "Expected '{'");
        let mut blk: *block_stmt= (block_stmt*)arc_malloc(sizeof(parser__NS_block_stmt));
        memset((i8*)blk, 0, sizeof(parser__NS_block_stmt));
        blk.kind = nd_block;
        blk.line = ln;

        let mut stmts_cap: i32= 16;
        blk.stmts = (ast_node**)arc_malloc(sizeof(i8*) * (u64)stmts_cap);
        blk.stmts_len = 0;

        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            let mut s: *ast_node= self.parse_stmt();
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
                let mut av: *ast_node= self.pending_anon_var;
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

    fn parse_local_var_decl(self: *parser_t) *var_decl {
        let mut t: *type_node= self.parse_type();
        if (!self.check_tok(id)) {
            {
                let mut got_name: *i8= lexer.tok_type_name(self.peek_type());
                aprint("error at line %d: expected variable name; got %s\n", .{ self.peek_line(), got_name });
            }
            self.had_parse_error = true;
        }
        let mut name_tok: lexer.token_t= self.advance_tok();
        // Trailing type: auto name: type
        if (t.is_auto && self.check_tok(colon)) {
            self.advance_tok();
            t = self.parse_type();
        }
        let mut vd: *var_decl= (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
        memset((i8*)vd, 0, sizeof(parser__NS_var_decl));
        vd.kind       = nd_var_decl;
        vd.line       = (u64)name_tok.line;
        vd.type       = t;
        vd.name       = lexer.str_dup(name_tok.value);
        vd.is_sta     = t.is_sta;
        vd.is_mutable = true;  // old-style C declarations are mutable by default

        if (self.match_tok(obracket)) {
            if (!self.check_tok(cbracket)) {
                t.array_size_ptr = (i8*)self.parse_expr();
            }
            self.consume_tok(cbracket, "Expected ']' after array size");
        }
        // Constructor call: TypeName varname(args...)
        if (self.match_tok(oparen)) {
            vd.has_ctor_parens = true;
            let mut ctor_cap2: i32= 4;
            vd.ctor_args = (i8**)arc_malloc(sizeof(i8*) * (u64)ctor_cap2);
            vd.ctor_args_len = 0;
            if (!self.check_tok(cparen)) {
                let mut p_ctor2: bool= true;
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

    fn parse_if_stmt(self: *parser_t) *ast_node {
        let mut n: *if_stmt= (if_stmt*)arc_malloc(sizeof(parser__NS_if_stmt));
        memset((i8*)n, 0, sizeof(parser__NS_if_stmt));
        n.kind = nd_if_stmt;
        n.line = (u64)self.advance_line_get();  // consume 'if'

        if (self.check_tok(kw_comptime)) { self.advance_tok(); n.is_constexpr = true; }
        let mut has_parens: bool= self.match_tok(oparen);
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

    fn parse_while_stmt(self: *parser_t) *ast_node {
        let mut n: *while_stmt= (while_stmt*)arc_malloc(sizeof(parser__NS_while_stmt));
        memset((i8*)n, 0, sizeof(parser__NS_while_stmt));
        n.kind = nd_while_stmt;
        n.line = (u64)self.advance_line_get();

        let mut has_parens: bool= self.match_tok(oparen);
        n.cond = self.parse_expr();
        if (has_parens) { self.consume_tok(cparen, "Expected ')' after condition"); }
        n.body = self.parse_stmt();
        return (ast_node*)n;
    }

    fn parse_for_stmt(self: *parser_t) *ast_node {
        let mut ln: u64= (u64)self.advance_line_get();  // consume 'for'
        let mut has_parens: bool= self.match_tok(oparen);

        // New-style: for (let [mut] name: Type : expr)  range-for
        //        or: for (let mut name: Type = expr; ...)  c-for
        if (self.check_tok(kw_let)) {
            self.advance_tok(); // consume 'let'
            let mut for_is_mut: bool= self.match_tok(kw_mut);
            let mut for_var_tok: lexer.token_t= self.advance_tok();
            let mut for_vtype: *type_node= alloc_type_node();
            for_vtype.is_auto = true;
            if (self.match_tok(colon)) {
                // Type annotation: parse the type
                // After type: ':' means range-for, '=' or ';' means c-for
                // But if type ends with ':' (e.g. the colon was a range sep without type), handle that
                // Check if next token immediately is ':' (no type - missing type annotation)
                if (self.check_tok(colon)) {
                    // 'let name:: ...' — double colon, skip type, treat as range-for
                    // (should not happen in well-formed code)
                } else if (!self.check_tok(sm) && !self.check_tok(assign)) {
                    arc_free((i8*)for_vtype);
                    for_vtype = self.parse_type();
                }
            }
            if (self.check_tok(colon)) {
                // Range-for
                self.advance_tok(); // consume ':'
                let mut frn: *for_range_stmt= (for_range_stmt*)arc_malloc(sizeof(parser__NS_for_range_stmt));
                memset((i8*)frn, 0, sizeof(parser__NS_for_range_stmt));
                frn.kind = nd_for_range_stmt;
                frn.line = ln;
                frn.var_type = for_vtype;
                frn.var_name = lexer.str_dup(for_var_tok.value);
                frn.range = self.parse_expr();
                if (has_parens) { self.consume_tok(cparen, "Expected ')'"); }
                frn.body = self.parse_stmt();
                return (ast_node*)frn;
            }
            // C-style for init
            let mut for_init_vd: *var_decl= (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
            memset((i8*)for_init_vd, 0, sizeof(parser__NS_var_decl));
            for_init_vd.kind = nd_var_decl;
            for_init_vd.line = ln;
            for_init_vd.type = for_vtype;
            for_init_vd.name = lexer.str_dup(for_var_tok.value);
            for_init_vd.is_mutable = for_is_mut;
            if (self.match_tok(assign)) {
                for_init_vd.init = self.parse_expr();
                for_init_vd.has_init = true;
            }
            self.consume_tok(sm, "Expected ';' in for");
            let mut fn2: *for_stmt= (for_stmt*)arc_malloc(sizeof(parser__NS_for_stmt));
            memset((i8*)fn2, 0, sizeof(parser__NS_for_stmt));
            fn2.kind = nd_for_stmt;
            fn2.line = ln;
            fn2.init = (ast_node*)for_init_vd;
            if (!self.check_tok(sm)) { fn2.cond = self.parse_expr(); }
            self.consume_tok(sm, "Expected ';' in for");
            let mut no_step2: bool= has_parens ? self.check_tok(cparen) : self.check_tok(obrace);
            if (!no_step2) { fn2.step = self.parse_expr(); }
            if (has_parens) { self.consume_tok(cparen, "Expected ')' after for clauses"); }
            fn2.body = self.parse_stmt();
            return (ast_node*)fn2;
        }

        // Try range-for: for (T name : expr)
        if (self.is_type_start()) {
            let mut saved_pos: i32= self.current;
            let mut saved_err: bool= self.had_parse_error;
            let mut rvar_type: *type_node= self.parse_type();
            if (self.check_tok(id) && self.peek_at_type(1) == colon) {
                let mut rn: *for_range_stmt= (for_range_stmt*)arc_malloc(sizeof(parser__NS_for_range_stmt));
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

        let mut n: *for_stmt= (for_stmt*)arc_malloc(sizeof(parser__NS_for_stmt));
        memset((i8*)n, 0, sizeof(parser__NS_for_stmt));
        n.kind = nd_for_stmt;
        n.line = ln;

        if (!self.check_tok(sm)) {
            if (self.is_type_start()) {
                n.init = (ast_node*)self.parse_local_var_decl();
            } else {
                let mut es: *expr_stmt= (expr_stmt*)arc_malloc(sizeof(parser__NS_expr_stmt));
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

        let mut no_step: bool= has_parens ? self.check_tok(cparen) : self.check_tok(obrace);
        if (!no_step) {
            n.step = self.parse_expr();
        }
        if (has_parens) { self.consume_tok(cparen, "Expected ')' after for clauses"); }
        n.body = self.parse_stmt();
        return (ast_node*)n;
    }

    fn parse_switch_stmt(self: *parser_t) *ast_node {
        let mut n: *switch_stmt= (switch_stmt*)arc_malloc(sizeof(parser__NS_switch_stmt));
        memset((i8*)n, 0, sizeof(parser__NS_switch_stmt));
        n.kind = nd_switch_stmt;
        n.line = (u64)self.advance_line_get();

        let mut has_parens: bool= self.match_tok(oparen);
        n.val = self.parse_expr();
        if (has_parens) { self.consume_tok(cparen, "Expected ')'"); }
        self.consume_tok(obrace, "Expected '{'");

        let mut cases_cap: i32= 8;
        n.case_vals       = (expr_node***)arc_malloc(sizeof(i8*) * (u64)cases_cap);
        n.case_bodies     = (block_stmt**)arc_malloc(sizeof(i8*) * (u64)cases_cap);
        n.case_is_default = (bool*)arc_malloc(sizeof(bool) * (u64)cases_cap);
        n.cases_len = 0;
        n.cases_cap = cases_cap;

        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            let mut is_default: bool= false;
            let mut case_val: *expr_node= (expr_node*)0;

            if (self.match_tok(kw_case)) {
                case_val = self.parse_expr();
            } else {
                self.consume_tok(kw_default, "Expected 'case' or 'default'");
                is_default = true;
            }
            self.consume_tok(colon, "Expected ':' after case label");

            let mut body: *block_stmt= (block_stmt*)arc_malloc(sizeof(parser__NS_block_stmt));
            memset((i8*)body, 0, sizeof(parser__NS_block_stmt));
            body.kind = nd_block;
            let mut body_cap: i32= 8;
            body.stmts = (ast_node**)arc_malloc(sizeof(i8*) * (u64)body_cap);

            while (!self.check_tok(kw_case) &&
                   !self.check_tok(kw_default) &&
                   !self.check_tok(cbrace) &&
                   !self.is_at_end_p()) {
                let mut s: *ast_node= self.parse_stmt();
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

    fn alloc_pat_node(self: *parser_t) *pat_node {
        let mut p: *pat_node= (pat_node*)arc_malloc(sizeof(parser__NS_pat_node));
        memset((i8*)p, 0, sizeof(parser__NS_pat_node));
        return p;
    }

    fn parse_pattern(self: *parser_t) *pat_node {
        let mut lhs: *pat_node= self.parse_single_pattern();
        while (self.check_tok(bit_or)) {
            self.advance_tok();
            let mut rhs: *pat_node= self.parse_single_pattern();
            let mut or_p: *pat_node= self.alloc_pat_node();
            or_p.kind = pk_or;
            or_p.or_lhs = (i8*)lhs;
            or_p.or_rhs = (i8*)rhs;
            lhs = or_p;
        }
        return lhs;
    }

    fn parse_single_pattern(self: *parser_t) *pat_node {
        let mut tok_line2: u64= self.peek_line();

        // Anonymous struct pattern: .{ field, field: pat, .. }
        if (self.check_tok(dot) && self.peek_at_type(1) == obrace) {
            self.advance_tok(); // consume '.'
            self.advance_tok(); // consume '{'
            let mut fld_capA: i32= 8;
            let mut fldsA: *pat_field= (pat_field*)arc_malloc(sizeof(parser__NS_pat_field) * (u64)fld_capA);
            let mut fldsA_len: i32= 0;
            let mut has_restA: bool= false;
            while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                if (self.check_tok(dotdot)) { self.advance_tok(); has_restA = true; self.match_tok(comma); break; }
                let mut fnA_tok: lexer.token_t= self.advance_tok();
                let mut fnA: *i8= lexer.str_dup(fnA_tok.value);
                let mut fpA: *pat_node= (pat_node*)0;
                if (self.match_tok(colon)) {
                    fpA = self.parse_pattern();
                } else {
                    let mut pbA: *pat_node= self.alloc_pat_node();
                    pbA.kind = pk_ident; pbA.line = tok_line2;
                    pbA.name = lexer.str_dup(fnA_tok.value);
                    fpA = pbA;
                }
                if (fldsA_len >= fld_capA) {
                    fld_capA = fld_capA * 2;
                    fldsA = (pat_field*)arc_realloc((i8*)fldsA, sizeof(parser__NS_pat_field) * (u64)fld_capA);
                }
                fldsA[fldsA_len].name = fnA;
                fldsA[fldsA_len].pat  = (i8*)fpA;
                fldsA_len = fldsA_len + 1;
                if (!self.match_tok(comma)) { break; }
            }
            self.consume_tok(cbrace, "Expected '}' after struct pattern");
            let mut psA: *pat_node= self.alloc_pat_node();
            psA.kind = pk_struct; psA.line = tok_line2;
            psA.name = (i8*)0;
            psA.fields = fldsA; psA.fields_len = fldsA_len; psA.has_rest = has_restA;
            return psA;
        }

        // Wildcard: _
        if (self.check_tok(id)) {
            let mut _ptok: lexer.token_t= self.peek_tok();
            let mut pv: *i8= _ptok.value;
            if (pv != (i8*)0 && pv[0] == '_' && pv[1] == 0) {
                self.advance_tok();
                let mut pw: *pat_node= self.alloc_pat_node();
                pw.kind = pk_wildcard;
                pw.line = tok_line2;
                return pw;
            }
        }

        // Rest: ..
        if (self.check_tok(dotdot)) {
            self.advance_tok();
            let mut pr: *pat_node= self.alloc_pat_node();
            pr.kind = pk_rest;
            pr.line = tok_line2;
            return pr;
        }

        // Negative literal: -number
        if (self.check_tok(minus)) {
            self.advance_tok();
            let mut neg_inner: *expr_node= self.parse_primary();
            // Build unary neg expression node
            let mut neg_expr2: *expr_node= (expr_node*)arc_malloc(sizeof(parser__NS_expr_node));
            memset((i8*)neg_expr2, 0, sizeof(parser__NS_expr_node));
            neg_expr2.kind = ek_unary;
            neg_expr2.uop = uop_neg;
            neg_expr2.operand = neg_inner;
            // Check for range after neg literal: -N .. hi or -N ..= hi
            if (self.check_tok(dotdot) || self.check_tok(dotdot_eq)) {
                let mut rng_inc2: bool= self.check_tok(dotdot_eq);
                self.advance_tok();
                let mut hi_e2: *expr_node= self.parse_primary();
                let mut rp2: *pat_node= self.alloc_pat_node();
                rp2.kind = pk_range;
                rp2.line = tok_line2;
                rp2.range_lo = (i8*)neg_expr2;  // expr_node* as i8*
                rp2.range_hi = (i8*)hi_e2;
                rp2.range_inclusive = rng_inc2;
                return rp2;
            }
            // Plain negative literal pattern
            let mut pneg: *pat_node= self.alloc_pat_node();
            pneg.kind = pk_neg;
            pneg.line = tok_line2;
            pneg.neg_expr = (i8*)neg_expr2;  // store full unary-neg expr
            return pneg;
        }

        // String / char / bool / null literals
        if (self.check_tok(string_lit) || self.check_tok(char_lit) ||
            self.check_tok(kw_true) || self.check_tok(kw_false) || self.check_tok(kw_null)) {
            let mut plit: *pat_node= self.alloc_pat_node();
            plit.kind = pk_literal;
            plit.line = tok_line2;
            plit.lit_expr = (i8*)self.parse_primary();
            return plit;
        }

        // Integer / hex / float literal — may start a range
        if (self.check_tok(int_lit) || self.check_tok(float_lit)) {
            let mut lit_e2: *expr_node= self.parse_primary();
            if (self.check_tok(dotdot) || self.check_tok(dotdot_eq)) {
                let mut rng_inc3: bool= self.check_tok(dotdot_eq);
                self.advance_tok();
                let mut rhi3: *expr_node= (expr_node*)0;
                if (!self.check_tok(fat_arrow) && !self.check_tok(bit_or) && !self.check_tok(kw_if)) {
                    rhi3 = self.parse_primary();
                }
                let mut rp3: *pat_node= self.alloc_pat_node();
                rp3.kind = pk_range;
                rp3.line = tok_line2;
                rp3.range_lo = (i8*)lit_e2;
                rp3.range_hi = (i8*)rhi3;
                rp3.range_inclusive = rng_inc3;
                return rp3;
            }
            let mut plit2: *pat_node= self.alloc_pat_node();
            plit2.kind = pk_literal;
            plit2.line = tok_line2;
            plit2.lit_expr = (i8*)lit_e2;
            return plit2;
        }

        // Identifier: binding (@), struct {}, tuple (), range, or plain ident
        if (self.check_tok(id)) {
            let mut name_tok2: lexer.token_t= self.advance_tok();
            let mut pname2: *i8= lexer.str_dup(name_tok2.value);

            // Scope resolution: EnumName::VariantName — two consecutive colons
            // Combines into "EnumName__VariantName" for ctx.global_vars lookup.
            if (self.check_tok(colon) && self.peek_at_type(1) == colon) {
                self.advance_tok(); // consume first ':'
                self.advance_tok(); // consume second ':'
                let mut var_tok2: lexer.token_t= self.advance_tok(); // variant name
                let mut combined: [512]i8;
                afmt(combined, (u64)512, "%s__%s", .{ pname2, var_tok2.value });
                pname2 = lexer.str_dup(combined);
            }

            // Binding: name @ subpat
            if (self.check_tok(at)) {
                self.advance_tok();
                let mut sub2: *pat_node= self.parse_single_pattern();
                let mut pb2: *pat_node= self.alloc_pat_node();
                pb2.kind = pk_binding;
                pb2.line = tok_line2;
                pb2.name = pname2;
                pb2.sub_pat = (i8*)sub2;
                return pb2;
            }

            // Struct pattern: Name { field: pat, field, .. }
            if (self.check_tok(obrace)) {
                self.advance_tok(); // consume '{'
                let mut fld_cap4: i32= 8;
                let mut flds4: *pat_field= (pat_field*)arc_malloc(sizeof(parser__NS_pat_field) * (u64)fld_cap4);
                let mut flds4_len: i32= 0;
                let mut has_rest4: bool= false;
                while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                    if (self.check_tok(dotdot)) {
                        self.advance_tok(); has_rest4 = true;
                        self.match_tok(comma); break;
                    }
                    let mut fn2: *i8= (i8*)0;
                    let mut fp4: *pat_node= (pat_node*)0;
                    let mut fname2_tok: lexer.token_t= self.advance_tok();
                    fn2 = lexer.str_dup(fname2_tok.value);
                    if (self.match_tok(colon)) {
                        fp4 = self.parse_pattern();
                    } else {
                        // shorthand: field name == binding name
                        let mut pb4: *pat_node= self.alloc_pat_node();
                        pb4.kind = pk_ident;
                        pb4.line = tok_line2;
                        pb4.name = lexer.str_dup(fname2_tok.value);
                        fp4 = pb4;
                    }
                    if (flds4_len >= fld_cap4) {
                        fld_cap4 = fld_cap4 * 2;
                        flds4 = (pat_field*)arc_realloc((i8*)flds4, sizeof(parser__NS_pat_field) * (u64)fld_cap4);
                    }
                    flds4[flds4_len].name = fn2;
                    flds4[flds4_len].pat  = (i8*)fp4;
                    flds4_len = flds4_len + 1;
                    if (!self.match_tok(comma)) { break; }
                }
                self.consume_tok(cbrace, "Expected '}' after struct pattern");
                let mut ps4: *pat_node= self.alloc_pat_node();
                ps4.kind = pk_struct;
                ps4.line = tok_line2;
                ps4.name = pname2;
                ps4.fields = flds4;
                ps4.fields_len = flds4_len;
                ps4.has_rest = has_rest4;
                return ps4;
            }

            // Tuple/variant: Name(pat, pat, ...)
            if (self.check_tok(oparen)) {
                self.advance_tok(); // consume '('
                let mut fld_cap5: i32= 8;
                let mut flds5: *pat_field= (pat_field*)arc_malloc(sizeof(parser__NS_pat_field) * (u64)fld_cap5);
                let mut flds5_len: i32= 0;
                while (!self.check_tok(cparen) && !self.is_at_end_p()) {
                    let mut fp5: *pat_node= self.parse_pattern();
                    if (flds5_len >= fld_cap5) {
                        fld_cap5 = fld_cap5 * 2;
                        flds5 = (pat_field*)arc_realloc((i8*)flds5, sizeof(parser__NS_pat_field) * (u64)fld_cap5);
                    }
                    flds5[flds5_len].name = (i8*)0;
                    flds5[flds5_len].pat  = (i8*)fp5;
                    flds5_len = flds5_len + 1;
                    if (!self.match_tok(comma)) { break; }
                }
                self.consume_tok(cparen, "Expected ')' after tuple pattern");
                let mut pt5: *pat_node= self.alloc_pat_node();
                pt5.kind = pk_tuple;
                pt5.line = tok_line2;
                pt5.name = pname2;
                pt5.fields = flds5;
                pt5.fields_len = flds5_len;
                return pt5;
            }

            // Range from identifier constant: CONST .. hi
            if (self.check_tok(dotdot) || self.check_tok(dotdot_eq)) {
                let mut rng_inc6: bool= self.check_tok(dotdot_eq);
                self.advance_tok();
                let mut rhi6: *expr_node= (expr_node*)0;
                if (!self.check_tok(fat_arrow) && !self.check_tok(bit_or) && !self.check_tok(kw_if)) {
                    rhi6 = self.parse_primary();
                }
                // Build identifier expr for range_lo
                let mut id_lo6: *expr_node= (expr_node*)arc_malloc(sizeof(parser__NS_expr_node));
                memset((i8*)id_lo6, 0, sizeof(parser__NS_expr_node));
                id_lo6.kind = ek_identifier;
                id_lo6.str_val = pname2;
                let mut rp6: *pat_node= self.alloc_pat_node();
                rp6.kind = pk_range;
                rp6.line = tok_line2;
                rp6.range_lo = (i8*)id_lo6;  // expr_node* as i8*
                rp6.range_hi = (i8*)rhi6;    // expr_node* as i8*
                rp6.range_inclusive = rng_inc6;
                return rp6;
            }

            // Plain identifier pattern
            let mut pi6: *pat_node= self.alloc_pat_node();
            pi6.kind = pk_ident;
            pi6.line = tok_line2;
            pi6.name = pname2;
            return pi6;
        }

        // Unknown — skip and return wildcard
        aprint("error at line %d: expected pattern\n", .{ (i32)tok_line2 });
        self.had_parse_error = true;
        self.advance_tok();
        let mut punk: *pat_node= self.alloc_pat_node();
        punk.kind = pk_wildcard;
        punk.line = tok_line2;
        return punk;
    }

    fn parse_match_stmt(self: *parser_t) *ast_node {
        let mut ms: *match_stmt= (match_stmt*)arc_malloc(sizeof(parser__NS_match_stmt));
        memset((i8*)ms, 0, sizeof(parser__NS_match_stmt));
        ms.kind = nd_match_stmt;
        ms.line = self.advance_line_get(); // consume 'match'

        let mut has_paren3: bool= self.match_tok(oparen);
        ms.subject = (i8*)self.parse_expr();
        if (has_paren3) { self.consume_tok(cparen, "Expected ')'"); }

        self.consume_tok(obrace, "Expected '{' after match subject");

        let mut arms_cap3: i32= 8;
        ms.arms = (match_arm**)arc_malloc(sizeof(i8*) * (u64)arms_cap3);
        ms.arms_len = 0;
        ms.arms_cap = arms_cap3;

        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            let mut arm3: *match_arm= (match_arm*)arc_malloc(sizeof(parser__NS_match_arm));
            memset((i8*)arm3, 0, sizeof(parser__NS_match_arm));

            arm3.pat = self.parse_pattern();

            // Optional guard: if (cond)
            if (self.check_tok(kw_if)) {
                self.advance_tok();
                let mut guard_paren: bool= self.match_tok(oparen);
                arm3.guard = (i8*)self.parse_expr();
                if (guard_paren) { self.consume_tok(cparen, "Expected ')' after guard"); }
            }

            self.consume_tok(fat_arrow, "Expected '=>' after match pattern");

            // Body: block { } or bare expression (no braces, trailing comma acts as separator)
            if (self.check_tok(obrace)) {
                arm3.body = (ast_node*)self.parse_block();
            } else {
                let mut arm_es: *expr_stmt= (expr_stmt*)arc_malloc(sizeof(parser__NS_expr_stmt));
                memset((i8*)arm_es, 0, sizeof(parser__NS_expr_stmt));
                arm_es.kind = nd_expr_stmt;
                arm_es.line = (u64)self.peek_line();
                arm_es.expr = self.parse_expr();
                self.match_tok(sm); // optional trailing semicolon
                arm3.body = (ast_node*)arm_es;
            }

            // Optional trailing comma between arms
            self.match_tok(comma);

            if (ms.arms_len >= ms.arms_cap) {
                ms.arms_cap = ms.arms_cap * 2;
                ms.arms = (match_arm**)arc_realloc((i8*)ms.arms, sizeof(i8*) * (u64)ms.arms_cap);
            }
            ms.arms[ms.arms_len] = arm3;
            ms.arms_len = ms.arms_len + 1;
        }

        self.consume_tok(cbrace, "Expected '}' after match arms");
        return (ast_node*)ms;
    }

    fn parse_return_stmt(self: *parser_t) *ast_node {
        let mut n: *return_stmt= (return_stmt*)arc_malloc(sizeof(parser__NS_return_stmt));
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

    fn parse_defer_stmt(self: *parser_t) *ast_node {
        let mut n: *defer_stmt= (defer_stmt*)arc_malloc(sizeof(parser__NS_defer_stmt));
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

    fn parse_stmt(self: *parser_t) *ast_node {
        // `@unsafe { ... }` — a scoped unsafe region. Lets a safe function perform
        // unsafe operations over a bounded span without marking its whole signature
        // unsafe, which would otherwise propagate up the call graph to main().
        if (self.check_tok(at) && self.peek_at_type(1) == id &&
                self.tokens[self.current + 1].value != (i8*)0 &&
                strcmp(self.tokens[self.current + 1].value, "unsafe") == 0 &&
                self.peek_at_type(2) == obrace) {
            self.advance_tok(); // consume '@'
            self.advance_tok(); // consume 'unsafe'
            let mut ub: *block_stmt= self.parse_block();
            if (ub != (block_stmt*)0) { ub.is_unsafe = true; }
            return (ast_node*)ub;
        }

        // Empty statement
        if (self.check_tok(sm)) {
            let mut blk: *block_stmt= (block_stmt*)arc_malloc(sizeof(parser__NS_block_stmt));
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
        if (self.check_tok(kw_match))    { return self.parse_match_stmt(); }
        if (self.check_tok(kw_return))   { return self.parse_return_stmt(); }
        if (self.check_tok(kw_defer))    { return self.parse_defer_stmt(); }
        if (self.check_tok(kw_errdefer)) { return self.parse_defer_stmt(); }

        // `using ns;` inside a function body. Previously only recognised at top
        // level, so in a body it fell through to expression parsing and failed on
        // the namespace name. The IR side already handles nd_using_decl.
        if (self.check_tok(kw_using)) {
            let mut u_line: u64= (u64)self.peek_line();
            self.advance_tok(); // consume 'using'
            let mut u_buf: [512]i8; u_buf[0] = 0;
            let mut u_len: i32= 0;
            while (self.check_tok(id)) {
                let mut seg: *i8= self.advance_value_get();
                let mut seg_len: i32= (i32)strlen(seg);
                if (u_len > 0 && u_len + 1 < 512) { u_buf[u_len] = '.'; u_len = u_len + 1; }
                let mut si: i32= 0;
                while (si < seg_len && u_len + 1 < 512) { u_buf[u_len] = seg[si]; u_len = u_len + 1; si = si + 1; }
                u_buf[u_len] = 0;
                if (!self.match_tok(dot)) { break; }
            }
            self.consume_tok(sm, "Expected ';' after 'using'");
            let mut ud_s: *typedef_decl= (typedef_decl*)arc_malloc(sizeof(parser__NS_typedef_decl));
            memset((i8*)ud_s, 0, sizeof(parser__NS_typedef_decl));
            ud_s.kind                = nd_using_decl;
            ud_s.line                = u_line;
            ud_s.is_namespace_using  = true;
            ud_s.ns_using_name       = lexer.str_dup(u_buf);
            return (ast_node*)ud_s;
        }

        if (self.check_tok(kw_break)) {
            let mut n: *break_stmt= (break_stmt*)arc_malloc(sizeof(parser__NS_break_stmt));
            memset((i8*)n, 0, sizeof(parser__NS_break_stmt));
            n.kind = nd_break_stmt;
            n.line = (u64)self.advance_line_get();
            self.consume_tok(sm, "Expected ';'");
            return (ast_node*)n;
        }
        if (self.check_tok(kw_continue)) {
            let mut n: *continue_stmt= (continue_stmt*)arc_malloc(sizeof(parser__NS_continue_stmt));
            memset((i8*)n, 0, sizeof(parser__NS_continue_stmt));
            n.kind = nd_continue_stmt;
            n.line = (u64)self.advance_line_get();
            self.consume_tok(sm, "Expected ';'");
            return (ast_node*)n;
        }

        if (self.check_tok(kw_try)) {
            let mut n: *try_expr_stmt= (try_expr_stmt*)arc_malloc(sizeof(parser__NS_try_expr_stmt));
            memset((i8*)n, 0, sizeof(parser__NS_try_expr_stmt));
            n.kind = nd_try_expr_stmt;
            n.line = (u64)self.advance_line_get();
            n.expr = self.parse_expr();
            self.consume_tok(sm, "Expected ';' after try expression");
            return (ast_node*)n;
        }

        if (self.check_tok(kw_static)) {
            aprint("error at line %d: 'static' before 'let' is invalid; use 'let name: static Type'\n", .{ self.peek_line() });
            self.had_parse_error = true;
            // Recover: skip 'static' and continue parsing the rest as a normal let
            self.advance_tok();
            return self.parse_stmt();
        }

        if (self.check_tok(kw_comptime)) {
            self.advance_tok();
            // comptime type T = SomeType; — first-class type alias
            if (self.check_tok(kw_type)) {
                let mut ahead: lexer.token_t= self.peek_at_tok(1);
                if (ahead.type == assign) {
                    // `comptime type = ...` — type itself as a value (skip)
                } else {
                    // `comptime type Name = TypeExpr;`
                    self.advance_tok(); // consume 'type'
                    let mut td: *typedef_decl= (typedef_decl*)arc_malloc(sizeof(parser__NS_typedef_decl));
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
                let mut vd: *var_decl= self.parse_local_var_decl();
                vd.is_constexpr = true;
                return (ast_node*)vd;
            }
            // comptime if: mark the resulting if_stmt as is_constexpr
            if (self.check_tok(kw_if)) {
                let mut res2: *ast_node= self.parse_if_stmt();
                if (res2 != (ast_node*)0 && res2.kind == nd_if_stmt) {
                    let mut cif: *if_stmt= (if_stmt*)res2;
                    cif.is_constexpr = true;
                }
                return res2;
            }
            return self.parse_stmt();
        }

        if (self.check_tok(kw_asm)) {
            let mut n: *asm_stmt= (asm_stmt*)arc_malloc(sizeof(parser__NS_asm_stmt));
            memset((i8*)n, 0, sizeof(parser__NS_asm_stmt));
            n.kind = nd_asm_stmt;
            n.line = (u64)self.advance_line_get();
            let mut body_tok: lexer.token_t= self.consume_tok(asm_body, "Expected '{...}' after __asm__");
            n.raw_instructions = lexer.str_dup(body_tok.value);
            return (ast_node*)n;
        }

        // Anonymous istruc instance within a function body: `istruc { ... } var_name;`
        // peek_at_type(1) lets us distinguish `istruc { ... } x;` from normal istruc decls
        // Return only the type_decl here; parse_block will emit pending_anon_var directly
        // into the parent block so the variable stays in the same scope as subsequent stmts.
        if (self.check_tok(kw_istruc) && self.peek_at_type(1) == obrace) {
            let mut type_decl: *ast_node= self.parse_istruc_decl();
            // pending_anon_var is set by parse_istruc_decl; parse_block will pick it up
            return type_decl;
        }

        // New-style: let [mut] name [: Type] [= expr];
        if (self.check_tok(kw_let)) {
            self.advance_tok(); // consume 'let'
            let mut stmt_is_mut: bool= self.match_tok(kw_mut);
            let mut let_name_tok: lexer.token_t= self.advance_tok();
            let mut let_type: *type_node= alloc_type_node();
            let_type.is_auto = true;
            if (self.match_tok(colon)) {
                arc_free((i8*)let_type);
                let_type = self.parse_type();
            }
            let mut let_vd: *var_decl= (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
            memset((i8*)let_vd, 0, sizeof(parser__NS_var_decl));
            let_vd.kind = nd_var_decl;
            let_vd.line = (u64)let_name_tok.line;
            let_vd.type = let_type;
            let_vd.name = lexer.str_dup(let_name_tok.value);
            let_vd.is_mutable = stmt_is_mut;
            // Propagate `static` type qualifier to storage class
            if (let_type != (type_node*)0 && let_type.is_static_kw) {
                let_vd.is_static_local = true;
            }
            // Constructor args: let mut p: Type(args);
            if (let_type != (type_node*)0 && !let_type.is_auto && self.match_tok(oparen)) {
                let_vd.has_ctor_parens = true;
                let mut ctor_cap3: i32= 4;
                let_vd.ctor_args = (i8**)arc_malloc(sizeof(i8*) * (u64)ctor_cap3);
                let_vd.ctor_args_len = 0;
                if (!self.check_tok(cparen)) {
                    let mut p_ctor3: bool= true;
                    while (p_ctor3) {
                        if (let_vd.ctor_args_len >= ctor_cap3) {
                            ctor_cap3 = ctor_cap3 * 2;
                            let_vd.ctor_args = (i8**)arc_realloc((i8*)let_vd.ctor_args, sizeof(i8*) * (u64)ctor_cap3);
                        }
                        let_vd.ctor_args[let_vd.ctor_args_len] = (i8*)self.parse_assignment();
                        let_vd.ctor_args_len = let_vd.ctor_args_len + 1;
                        if (!self.match_tok(comma)) { p_ctor3 = false; }
                    }
                }
                self.consume_tok(cparen, "Expected ')' after constructor args");
            } else if (self.match_tok(assign)) {
                let_vd.init = self.parse_expr();
                let_vd.has_init = true;
            }
            self.consume_tok(sm, "Expected ';' after let declaration");
            return (ast_node*)let_vd;
        }

        // New-style: const name [: Type] = expr;
        // Distinguish from old-style: const Type name = expr;
        // New-style: const followed by id then '=' or ':'
        if (self.check_tok(kw_const)) {
            let mut peek2_type: i32= self.peek_at_type(1);
            let mut peek3_type: i32= self.peek_at_type(2);
            // New-style const: 'const name =' or 'const name:'
            let mut new_const: bool= (peek2_type == id || peek2_type >= kw_let) &&
                             (peek3_type == assign || peek3_type == colon || peek3_type == sm);
            if (new_const) {
                self.advance_tok(); // consume 'const'
                let mut const_name_tok: lexer.token_t= self.advance_tok();
                let mut const_type: *type_node= alloc_type_node();
                const_type.is_auto = true;
                if (self.match_tok(colon)) {
                    arc_free((i8*)const_type);
                    const_type = self.parse_type();
                }
                let mut const_vd: *var_decl= (var_decl*)arc_malloc(sizeof(parser__NS_var_decl));
                memset((i8*)const_vd, 0, sizeof(parser__NS_var_decl));
                const_vd.kind = nd_var_decl;
                const_vd.line = (u64)const_name_tok.line;
                const_vd.type = const_type;
                const_vd.name = lexer.str_dup(const_name_tok.value);
                const_vd.is_constexpr = true;
                if (self.match_tok(assign)) {
                    // const name = struct { ... } — treat as named struct declaration
                    if (self.check_tok(kw_struct) && self.peek_at_type(1) == obrace) {
                        self.advance_tok(); // consume 'struct'
                        let mut sd_c2: *struct_decl= self.parse_anon_struct_body(const_name_tok.value);
                        self.match_tok(sm);
                        return (ast_node*)sd_c2;
                    }
                    const_vd.init = self.parse_expr();
                    const_vd.has_init = true;
                }
                self.consume_tok(sm, "Expected ';' after const declaration");
                return (ast_node*)const_vd;
            }
        }

        // Reject leading-type local variable declarations: 'i32 x = 0;' should be 'let mut x: i32 = 0;'
        // Check for primitive type keyword followed by an identifier (or '*' for pointer type).
        {
            let mut ltt: i32= self.peek_type();
            let mut lt_is_prim: bool= (ltt == ty_arb_int || ltt == ty_arb_uint || ltt == ty_arb_float ||
                                       ltt == ty_arb_bool || ltt == ty_void || ltt == ty_char || ltt == kw_auto);
            let mut lt_next: i32= self.peek_at_type(1);
            let mut lt_next_is_name: bool= (lt_next == id || lt_next == ast);
            if (lt_is_prim && lt_next_is_name) {
                let mut err_ln2: i32= self.peek_line();
                aprint("error at line %d: leading-type declarations are not allowed; use 'let mut name: Type = ...' instead\n", .{ err_ln2 });
                self.had_parse_error = true;
                while (!self.is_at_end_p() && !self.check_tok(sm) && !self.check_tok(cbrace)) {
                    self.advance_tok();
                }
                if (self.check_tok(sm)) { self.advance_tok(); }
                return (ast_node*)0;
            }
        }

        // Expression statement
        let mut es: *expr_stmt= (expr_stmt*)arc_malloc(sizeof(parser__NS_expr_stmt));
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

    fn parse_expr(self: *parser_t) *expr_node {
        return self.parse_assignment();
    }

    fn parse_range(self: *parser_t) *expr_node {
        let mut lhs: *expr_node= self.parse_null_coal();
        if (self.check_tok(dotdot) || self.check_tok(dotdot_eq)) {
            let mut incl: bool= self.check_tok(dotdot_eq);
            self.advance_tok();
            let mut rhs: *expr_node= self.parse_null_coal();
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_range;
            n.line = (u64)self.prev_line();
            n.lhs  = lhs;
            n.rhs  = rhs;
            n.bool_val = incl;
            return n;
        }
        return lhs;
    }

    fn parse_assignment(self: *parser_t) *expr_node {
        let mut lhs: *expr_node= self.parse_range();

        let mut bop: i32= -1;
        let mut tt: i32= self.peek_type();
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
            let mut ln: u64= (u64)self.advance_line_get();
            let mut rhs: *expr_node= self.parse_assignment();
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_assign;
            n.line = ln;
            n.lhs  = lhs;
            n.rhs  = rhs;
            n.bop  = bop;
            return n;
        }
        return lhs;
    }

    fn parse_null_coal(self: *parser_t) *expr_node {
        let mut lhs: *expr_node= self.parse_ternary();
        while (self.check_tok(question_question)) {
            self.advance_tok();
            let mut n: *expr_node= alloc_expr_node();
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

    fn parse_ternary(self: *parser_t) *expr_node {
        let mut cond: *expr_node= self.parse_or();
        if (!self.match_tok(question)) { return cond; }
        let mut n: *expr_node= alloc_expr_node();
        n.kind  = ek_ternary;
        n.line  = (u64)self.prev_line();
        n.cond  = cond;
        n.then_e = self.parse_expr();
        self.consume_tok(colon, "Expected ':' in ternary");
        n.else_e = self.parse_ternary();
        return n;
    }

    fn parse_or(self: *parser_t) *expr_node {
        let mut lhs: *expr_node= self.parse_and();
        while (self.check_tok(or_)) {
            let mut ln: u64= (u64)self.advance_line_get();
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_binary;
            n.line = ln;
            n.lhs  = lhs;
            n.bop  = bop_log_or;
            n.rhs  = self.parse_and();
            lhs = n;
        }
        return lhs;
    }

    fn parse_and(self: *parser_t) *expr_node {
        let mut lhs: *expr_node= self.parse_bitor();
        while (self.check_tok(and_)) {
            let mut ln: u64= (u64)self.advance_line_get();
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_binary;
            n.line = ln;
            n.lhs  = lhs;
            n.bop  = bop_log_and;
            n.rhs  = self.parse_bitor();
            lhs = n;
        }
        return lhs;
    }

    fn parse_bitor(self: *parser_t) *expr_node {
        let mut lhs: *expr_node= self.parse_bitxor();
        while (self.check_tok(bit_or)) {
            let mut ln: u64= (u64)self.advance_line_get();
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop_bit_or;
            n.rhs = self.parse_bitxor();
            lhs = n;
        }
        return lhs;
    }

    fn parse_bitxor(self: *parser_t) *expr_node {
        let mut lhs: *expr_node= self.parse_bitand();
        while (self.check_tok(bit_xor)) {
            let mut ln: u64= (u64)self.advance_line_get();
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop_bit_xor;
            n.rhs = self.parse_bitand();
            lhs = n;
        }
        return lhs;
    }

    fn parse_bitand(self: *parser_t) *expr_node {
        let mut lhs: *expr_node= self.parse_equality();
        while (self.check_tok(addr)) {
            let mut ln: u64= (u64)self.advance_line_get();
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop_bit_and;
            n.rhs = self.parse_equality();
            lhs = n;
        }
        return lhs;
    }

    fn parse_equality(self: *parser_t) *expr_node {
        let mut lhs: *expr_node= self.parse_compare();
        let mut running: bool= true;
        while (running) {
            let mut bop: i32= -1;
            if (self.check_tok(eq)) { bop = bop_eq; }
            else if (self.check_tok(ne)) { bop = bop_ne; }
            if (bop < 0) { running = false; }
            else {
                let mut ln: u64= (u64)self.advance_line_get();
                let mut n: *expr_node= alloc_expr_node();
                n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop;
                n.rhs = self.parse_compare();
                lhs = n;
            }
        }
        return lhs;
    }

    fn parse_compare(self: *parser_t) *expr_node {
        let mut lhs: *expr_node= self.parse_shift();
        let mut running: bool= true;
        while (running) {
            let mut bop: i32= -1;
            if (self.check_tok(lt))  { bop = bop_lt; }
            else if (self.check_tok(gt))  { bop = bop_gt; }
            else if (self.check_tok(lte)) { bop = bop_lte; }
            else if (self.check_tok(gte)) { bop = bop_gte; }
            if (bop < 0) { running = false; }
            else {
                let mut ln: u64= (u64)self.advance_line_get();
                let mut n: *expr_node= alloc_expr_node();
                n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop;
                n.rhs = self.parse_shift();
                lhs = n;
            }
        }
        return lhs;
    }

    fn parse_shift(self: *parser_t) *expr_node {
        let mut lhs: *expr_node= self.parse_add();
        let mut running: bool= true;
        while (running) {
            let mut bop: i32= -1;
            if (self.check_tok(left))  { bop = bop_shl; }
            else if (self.check_tok(right)) { bop = bop_shr; }
            if (bop < 0) { running = false; }
            else {
                let mut ln: u64= (u64)self.advance_line_get();
                let mut n: *expr_node= alloc_expr_node();
                n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop;
                n.rhs = self.parse_add();
                lhs = n;
            }
        }
        return lhs;
    }

    fn parse_add(self: *parser_t) *expr_node {
        let mut lhs: *expr_node= self.parse_mul();
        let mut running: bool= true;
        while (running) {
            let mut bop: i32= -1;
            if (self.check_tok(plus))  { bop = bop_add; }
            else if (self.check_tok(minus)) { bop = bop_sub; }
            if (bop < 0) { running = false; }
            else {
                let mut ln: u64= (u64)self.advance_line_get();
                let mut n: *expr_node= alloc_expr_node();
                n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop;
                n.rhs = self.parse_mul();
                lhs = n;
            }
        }
        return lhs;
    }

    fn parse_mul(self: *parser_t) *expr_node {
        let mut lhs: *expr_node= self.parse_unary();
        let mut running: bool= true;
        while (running) {
            let mut bop: i32= -1;
            if (self.check_tok(ast))   { bop = bop_mul; }
            else if (self.check_tok(slash)) { bop = bop_div; }
            else if (self.check_tok(mod))   { bop = bop_mod; }
            if (bop < 0) { running = false; }
            else {
                let mut ln: u64= (u64)self.advance_line_get();
                let mut n: *expr_node= alloc_expr_node();
                n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop;
                n.rhs = self.parse_unary();
                lhs = n;
            }
        }
        return lhs;
    }

    fn parse_unary(self: *parser_t) *expr_node {
        let mut tt: i32= self.peek_type();
        let mut ln: u64= (u64)self.peek_line();

        if (tt == minus) {
            self.advance_tok();
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_neg;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == plus) {
            self.advance_tok();
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_pos;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == bit_not) {
            self.advance_tok();
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_bit_not;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == not_) {
            self.advance_tok();
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_log_not;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == inc) {
            self.advance_tok();
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_pre_inc;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == dec) {
            self.advance_tok();
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_pre_dec;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == ast) {
            self.advance_tok();
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_deref;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == addr) {
            self.advance_tok();
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_addr_of;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == kw_try) {
            // try expr — propagates error upward; yields value on success
            self.advance_tok();
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_try_expr;
            n.line = ln;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == kw_error) {
            // error.Variant or error.Variant(payload) — error union return value
            self.advance_tok(); // consume 'error'
            let mut payload_expr: *expr_node= (expr_node*)0;
            let mut variant_name: *i8= (i8*)0;
            if (!self.check_tok(dot)) {
                // Emit clear diagnostic instead of silently producing a broken AST node
                aprint("error at line %d: expected '.' after 'error' (use 'error.VariantName' syntax)\n", .{ (i32)ln });
                // Synchronize: skip to end of statement
                let mut n: *expr_node= alloc_expr_node();
                n.kind = ek_error_lit; n.line = ln;
                return n;
            }
            self.advance_tok(); // consume '.'
            if (self.check_tok(id)) {
                variant_name = lexer.str_dup(self.advance_value_get()); // consume and STORE variant name
            } else {
                // e.g. `error .{}` — without a name there is no variant to construct,
                // and leaving the following tokens stranded produces cascade errors far
                // from the real mistake.
                aprint("error at line %d: expected a variant name after 'error.' (use 'error.VariantName')\n", .{ (i32)ln });
                self.had_parse_error = true;
                let mut nb: *expr_node= alloc_expr_node();
                nb.kind = ek_error_lit; nb.line = ln;
                return nb;
            }
            // Optional payload: error.Variant(expr)
            if (self.check_tok(oparen)) {
                self.advance_tok(); // consume '('
                if (!self.check_tok(cparen)) { payload_expr = self.parse_expr(); }
                self.consume_tok(cparen, "Expected ')' after error payload");
            } else if (self.check_tok(obrace) || self.check_tok(dot)) {
                // `error.Name {}` / `error.Name .{}` — only the parenthesised payload
                // form is supported. Say so rather than leaving the braces stranded.
                aprint("error at line %d: error payload must use parentheses: 'error.%s(expr)'\n", .{ (i32)ln, variant_name });
                self.had_parse_error = true;
                let mut nc: *expr_node= alloc_expr_node();
                nc.kind = ek_error_lit; nc.line = ln; nc.str_val = variant_name;
                return nc;
            }
            let mut n: *expr_node= alloc_expr_node();
            n.kind       = ek_error_lit;
            n.line       = ln;
            n.str_val    = variant_name;  // store variant name for codegen
            n.operand    = payload_expr;
            return n;
        }
        if (tt == kw_sizeof) {
            self.advance_tok();
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_sizeof_e; n.line = ln;
            self.consume_tok(oparen, "Expected '(' after sizeof");
            // Accept generic/pointer user types: id<...> and id* inside sizeof
            let mut sz_is_type: bool= self.is_type_start();
            if (!sz_is_type && self.check_tok(id)) {
                let mut sz_next: i32= self.peek_at_type(1);
                if (sz_next == lt || sz_next == ast) { sz_is_type = true; }
            }
            if (sz_is_type) {
                n.cast_type = self.parse_type();
            } else {
                n.operand = self.parse_expr();
            }
            self.consume_tok(cparen, "Expected ')' after sizeof argument");
            return n;
        }

        // Cast: (type)expr — check if next is ( followed by a type
        if (tt == oparen) {
            let mut saved: i32= self.current;
            self.advance_tok();  // consume (
            if (self.is_cast_start()) {
                let mut ct: *type_node= self.parse_type();
                if (self.check_tok(cparen)) {
                    self.advance_tok();  // consume )
                    let mut n: *expr_node= alloc_expr_node();
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

    fn parse_postfix(self: *parser_t) *expr_node {
        let mut lhs: *expr_node= self.parse_primary();

        let mut running: bool= true;
        while (running) {
            if (self.check_tok(dot) && self.peek_at_type(1) != obrace) {
                self.advance_tok();
                let mut mem_name: lexer.token_t= self.consume_name_tok("Expected member name after '.'");
                if (self.match_tok(oparen)) {
                    // Method call: obj.method(args)
                    let mut callee: *expr_node= alloc_expr_node();
                    callee.kind = ek_member;
                    callee.line = (u64)mem_name.line;
                    callee.object = lhs;
                    callee.member_name = lexer.str_dup(mem_name.value);
                    let mut call_n: *expr_node= alloc_expr_node();
                    call_n.kind = ek_call;
                    call_n.line = (u64)mem_name.line;
                    call_n.callee = callee;
                    // Parse arguments
                    let mut args: expr_ptr_vec;
                    expr_ptr_vec_init(&args);
                    if (!self.check_tok(cparen)) {
                        let mut parsing_args: bool= true;
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
                    let mut n: *expr_node= alloc_expr_node();
                    n.kind = ek_member;
                    n.line = (u64)mem_name.line;
                    n.object = lhs;
                    n.member_name = lexer.str_dup(mem_name.value);
                    lhs = n;
                }
            } else if (self.check_tok(obracket)) {
                self.advance_tok();
                let mut idx: *expr_node= self.parse_expr();
                self.consume_tok(cbracket, "Expected ']'");
                let mut n: *expr_node= alloc_expr_node();
                n.kind  = ek_subscript;
                n.line  = (u64)self.prev_line();
                n.object = lhs;
                n.index  = idx;
                lhs = n;
            } else if (self.check_tok(oparen)) {
                // Postfix call: expr(args) — for function pointer / lambda invocation
                let mut call_ln: u64= (u64)self.peek_line();
                self.advance_tok(); // consume '('
                let mut call_n: *expr_node= alloc_expr_node();
                call_n.kind   = ek_call;
                call_n.line   = call_ln;
                call_n.callee = lhs;
                let mut call_args: expr_ptr_vec;
                expr_ptr_vec_init(&call_args);
                if (!self.check_tok(cparen)) {
                    let mut pa: bool= true;
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
                let mut ln: u64= (u64)self.advance_line_get();
                let mut n: *expr_node= alloc_expr_node();
                n.kind = ek_unary; n.line = ln; n.uop = uop_post_inc; n.operand = lhs;
                lhs = n;
            } else if (self.check_tok(dec)) {
                let mut ln: u64= (u64)self.advance_line_get();
                let mut n: *expr_node= alloc_expr_node();
                n.kind = ek_unary; n.line = ln; n.uop = uop_post_dec; n.operand = lhs;
                lhs = n;
            } else if (self.check_tok(kw_catch)) {
                self.advance_tok(); // consume 'catch'
                let mut handler_var: *i8= (i8*)0;
                if (self.check_tok(bit_or)) {
                    self.advance_tok(); // consume '|'
                    if (self.check_tok(id)) {
                        let mut evar_tok: lexer.token_t= self.advance_tok();
                        handler_var = lexer.str_dup(evar_tok.value);
                    }
                    self.consume_tok(bit_or, "Expected '|' after catch variable");
                }
                let mut handler_blk: *i8= (i8*)0;
                if (self.check_tok(obrace)) {
                    handler_blk = (i8*)self.parse_block();
                }
                let mut n: *expr_node= alloc_expr_node();
                n.kind = ek_except_expr;
                n.line = (u64)self.prev_line();
                n.object = lhs;
                n.member_name = handler_var;
                n.handler_block = handler_blk;
                lhs = n;
            } else if (self.check_tok(obrace) && self.peek_at_type(1) == dot) {
                // ADT named-struct constructor: expr { .field = val, ... }
                let mut brace_ln: u64= (u64)self.advance_line_get(); // consume '{'
                let mut n: *expr_node= alloc_expr_node();
                n.kind = ek_class_init; n.line = brace_ln;
                n.object = lhs; // base expression (e.g., event.key_press)
                let mut field_names: str_vec; str_vec_init(&field_names);
                let mut field_vals: expr_ptr_vec; expr_ptr_vec_init(&field_vals);
                while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                    self.consume_tok(dot, "Expected '.' in field init");
                    let mut fn2: lexer.token_t= self.consume_name_tok("Expected field name");
                    self.consume_tok(assign, "Expected '=' in field init");
                    let mut fv: *expr_node= self.parse_expr();
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
                let mut dot_ln: u64= (u64)self.advance_line_get(); // consume '.'
                self.advance_tok(); // consume '{'
                let mut n: *expr_node= alloc_expr_node();
                n.kind = ek_class_init; n.line = dot_ln;
                n.object = lhs;
                n.is_implicit_init = true;
                let mut field_names: str_vec; str_vec_init(&field_names);
                let mut field_vals: expr_ptr_vec; expr_ptr_vec_init(&field_vals);
                while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                    self.consume_tok(dot, "Expected '.' in field init");
                    let mut fn2: lexer.token_t= self.consume_name_tok("Expected field name");
                    self.consume_tok(assign, "Expected '=' in field init");
                    let mut fv: *expr_node= self.parse_expr();
                    str_vec_push(&field_names, lexer.str_dup(fn2.value));
                    expr_ptr_vec_push(&field_vals, fv);
                    self.match_tok(comma);
                }
                self.consume_tok(cbrace, "Expected '}' after field inits");
                n.field_names = field_names.data;
                n.field_vals  = field_vals.data;
                n.field_count = field_names.len;
                lhs = n;
            } else if (self.check_tok(kw_as)) {
                // expr as Type — safe explicit type cast
                let mut as_ln: u64= (u64)self.advance_line_get(); // consume 'as'
                let mut target_t: *parser.type_node= self.parse_type();
                let mut n: *expr_node= alloc_expr_node();
                n.kind = ek_cast_as;
                n.line = as_ln;
                n.operand   = lhs;
                n.cast_type = target_t;
                lhs = n;
            } else {
                running = false;
            }
        }
        return lhs;
    }

    // Lambda expression: [captures](params) RetType? { body }
    // Captures: [=] = all by value, [&] = all by ref, [=a,&b] = explicit
    fn parse_lambda_expr(self: *parser_t) *expr_node {
        let mut ln: u64= (u64)self.peek_line();
        self.advance_tok(); // consume '['

        // Parse capture list
        let mut cap_cap: i32= 8;
        let mut cap_names: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)cap_cap);
        let mut cap_byref: *i32= (i32*)arc_malloc(sizeof(i32) * (u64)cap_cap);
        let mut cap_len: i32= 0;
        let mut cap_all_val: bool= false;
        let mut cap_all_ref: bool= false;

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
                    let mut cn: lexer.token_t= self.advance_tok();
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
                    let mut cn: lexer.token_t= self.advance_tok();
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
                let mut cn: lexer.token_t= self.advance_tok();
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
        let mut param_cap: i32= 8;
        let mut param_types: **type_node= (type_node**)arc_malloc(sizeof(i8*) * (u64)param_cap);
        let mut param_names: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)param_cap);
        let mut param_len: i32= 0;
        while (!self.check_tok(cparen) && !self.is_at_end_p()) {
            if (self.check_tok(comma)) { self.advance_tok(); continue; }
            if (param_len >= param_cap) {
                param_cap = param_cap * 2;
                param_types = (type_node**)arc_realloc((i8*)param_types, sizeof(i8*) * (u64)param_cap);
                param_names = (i8**)arc_realloc((i8*)param_names, sizeof(i8*) * (u64)param_cap);
            }
            // Support both old-style (type name) and new-style (name: type) lambda params
            if (self.check_tok(id) && self.peek_at_type(1) == colon) {
                // New-style: name: type
                let mut pname_ns: *i8= lexer.str_dup(self.advance_value_get()); // consume name
                self.advance_tok(); // consume ':'
                let mut pt_ns: *type_node= self.parse_type();
                param_types[param_len] = pt_ns;
                param_names[param_len] = pname_ns;
            } else {
                // Old-style: type [name]
                let mut pt: *type_node= self.parse_type();
                param_types[param_len] = pt;
                if (self.check_tok(id)) {
                    param_names[param_len] = lexer.str_dup(self.advance_value_get());
                } else {
                    let mut pname: [32]i8;
                    afmt(pname, (u64)32, "__lp%d", .{ param_len });
                    param_names[param_len] = lexer.str_dup(pname);
                }
            }
            param_len = param_len + 1;
        }
        self.consume_tok(cparen, "Expected ')' after lambda parameters");

        // Optional return type (omit if next is '{')
        let mut ret_type: *type_node= (type_node*)0;
        if (!self.check_tok(obrace)) {
            ret_type = self.parse_type();
        }

        // Body
        let mut body: *block_stmt= self.parse_block();

        // Build the ek_lambda node
        let mut n: *expr_node= alloc_expr_node();
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
        let mut flags: *i8= (i8*)arc_malloc(3);
        flags[0] = cap_all_val ? 'v' : '_';
        flags[1] = cap_all_ref ? 'r' : '_';
        flags[2] = 0;
        n.str_val = flags;
        return n;
    }

    fn parse_primary(self: *parser_t) *expr_node {
        let mut tok: lexer.token_t= self.peek_tok();
        let mut tt: i32= tok.type;
        let mut ln: u64= (u64)tok.line;

        // match(...) { } used as an expression
        if (tt == kw_match) {
            let mut ms_node: *ast_node= self.parse_match_stmt();
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_match_expr; n.line = ln;
            n.match_stmt_ptr = (i8*)ms_node;
            return n;
        }

        if (tt == int_lit) {
            self.advance_tok();
            let mut n: *expr_node= alloc_expr_node();
            n.kind    = ek_int_lit;
            n.line    = ln;
            n.int_val = strtoll(tok.value, (i8**)0, 0);
            n.str_val = lexer.str_dup(tok.value);
            return n;
        }
        if (tt == float_lit) {
            self.advance_tok();
            let mut n: *expr_node= alloc_expr_node();
            n.kind    = ek_float_lit;
            n.line    = ln;
            n.flt_val = strtod(tok.value, (i8**)0);
            n.str_val = lexer.str_dup(tok.value);
            return n;
        }
        if (tt == string_lit) {
            self.advance_tok();
            let mut n: *expr_node= alloc_expr_node();
            n.kind    = ek_string_lit;
            n.line    = ln;
            n.str_val = lexer.str_dup(tok.value);
            return n;
        }
        if (tt == char_lit) {
            self.advance_tok();
            let mut n: *expr_node= alloc_expr_node();
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
            let mut n: *expr_node= alloc_expr_node();
            n.kind     = ek_bool_lit; n.line = ln; n.bool_val = true;
            return n;
        }
        if (tt == kw_false) {
            self.advance_tok();
            let mut n: *expr_node= alloc_expr_node();
            n.kind     = ek_bool_lit; n.line = ln; n.bool_val = false;
            return n;
        }
        if (tt == kw_null) {
            self.advance_tok();
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_null_lit; n.line = ln;
            return n;
        }
        // Anonymous struct literal: .{ .field = val, ... } or .{ val, ... }
        if (tt == dot && self.peek_at_type(1) == obrace) {
            self.advance_tok(); // consume '.'
            self.advance_tok(); // consume '{'
            let mut an: *expr_node= alloc_expr_node();
            an.kind = ek_anon_struct; an.line = ln;
            let mut af_names: str_vec; str_vec_init(&af_names);
            let mut af_vals: expr_ptr_vec; expr_ptr_vec_init(&af_vals);
            let mut af_idx: i32= 0;
            while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                if (self.check_tok(dot) && self.peek_at_type(1) == id) {
                    // Named field: .field = val
                    self.advance_tok(); // consume '.'
                    let mut afn: lexer.token_t= self.advance_tok(); // field name
                    self.consume_tok(assign, "Expected '=' after field name in anonymous struct");
                    let mut afv: *expr_node= self.parse_expr();
                    str_vec_push(&af_names, lexer.str_dup(afn.value));
                    expr_ptr_vec_push(&af_vals, afv);
                } else {
                    // Positional field: val — use "__N" as synthetic name
                    let mut pos_name: [32]i8;
                    afmt(pos_name, (u64)32, "__%d", .{ af_idx });
                    let mut afv2: *expr_node= self.parse_expr();
                    str_vec_push(&af_names, lexer.str_dup(pos_name));
                    expr_ptr_vec_push(&af_vals, afv2);
                }
                af_idx = af_idx + 1;
                self.match_tok(comma);
            }
            self.consume_tok(cbrace, "Expected '}' to close anonymous struct literal");
            an.field_names = af_names.data;
            an.field_vals  = af_vals.data;
            an.field_count = af_names.len;
            return an;
        }

        // ref expr — context-aware address-of (depth determined at IR emit time)
        if (tt == kw_ref) {
            self.advance_tok();
            let mut n: *expr_node= alloc_expr_node();
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
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_quote;
            n.line = ln;
            // Capture token text until matching '}'
            let mut depth_q: i32= 1;
            let mut buf_cap: i32= 256; let mut buf_len: i32= 0;
            let mut buf: *i8= (i8*)arc_malloc((u64)buf_cap);
            buf[0] = 0;
            while (depth_q > 0 && !self.is_at_end_p()) {
                let mut qt: lexer.token_t= self.advance_tok();
                if (qt.type == obrace) { depth_q = depth_q + 1; }
                if (qt.type == cbrace) { depth_q = depth_q - 1; if (depth_q == 0) { break; } }
                if (qt.value != (i8*)0) {
                    // ty_arb_* tokens store only the numeric suffix; prepend the type prefix
                    let mut qt_prefix: *i8= (i8*)0;
                    if      (qt.type == ty_arb_int)      { qt_prefix = "i"; }
                    else if (qt.type == ty_arb_uint)     { qt_prefix = "u"; }
                    else if (qt.type == ty_arb_float)    { qt_prefix = "f"; }
                    else if (qt.type == ty_arb_bool)     { qt_prefix = "b"; }
                    else if (qt.type == ty_arb_nat)      { qt_prefix = "n"; }
                    else if (qt.type == ty_arb_zint)     { qt_prefix = "z"; }
                    else if (qt.type == ty_arb_rational) { qt_prefix = "q"; }
                    else if (qt.type == ty_arb_real)     { qt_prefix = "r"; }
                    else if (qt.type == ty_arb_alg)      { qt_prefix = "a"; }
                    else if (qt.type == ty_arb_complex)  { qt_prefix = "c"; }
                    else if (qt.type == ty_arb_char_w)   { qt_prefix = "ch"; }
                    else if (qt.type == ty_arb_str_w)    { qt_prefix = "str"; }
                    let mut pfx_len: i32= qt_prefix != (i8*)0 ? (i32)strlen(qt_prefix) : 0;
                    let mut vlen: i32= (i32)strlen(qt.value);
                    while (buf_len + pfx_len + vlen + 2 >= buf_cap) {
                        buf_cap = buf_cap * 2;
                        buf = (i8*)arc_realloc(buf, (u64)buf_cap);
                    }
                    let mut ppi: i32= 0;
                    while (ppi < pfx_len) { buf[buf_len] = qt_prefix[ppi]; buf_len = buf_len + 1; ppi = ppi + 1; }
                    let mut vi: i32= 0;
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
                let mut annot: lexer.token_t= self.advance_tok();
                // @typeinfo(T) intrinsic — compile-time type reflection
                if (strcmp(annot.value, "typeinfo") == 0 && self.check_tok(oparen)) {
                    self.advance_tok(); // consume (
                    let mut ti_n: *expr_node= alloc_expr_node();
                    ti_n.kind = ek_typeinfo_e;
                    ti_n.line = ln;
                    ti_n.cast_type = self.parse_type();
                    self.consume_tok(cparen, "Expected ')' after @typeinfo argument");
                    return ti_n;
                }
                // @shcopy(x) — explicit shallow copy
                if (strcmp(annot.value, "shcopy") == 0 && self.check_tok(oparen)) {
                    self.advance_tok();
                    let mut n: *expr_node= alloc_expr_node(); n.kind = ek_shcopy; n.line = ln;
                    n.operand = self.parse_expr();
                    self.consume_tok(cparen, "Expected ')' after @shcopy argument");
                    return n;
                }
                // @decopy(x) — deep copy
                if (strcmp(annot.value, "decopy") == 0 && self.check_tok(oparen)) {
                    self.advance_tok();
                    let mut n: *expr_node= alloc_expr_node(); n.kind = ek_decopy; n.line = ln;
                    n.operand = self.parse_expr();
                    self.consume_tok(cparen, "Expected ')' after @decopy argument");
                    return n;
                }
                // @move(x) — move (transfer ownership, zero source)
                if (strcmp(annot.value, "move") == 0 && self.check_tok(oparen)) {
                    self.advance_tok();
                    let mut n: *expr_node= alloc_expr_node(); n.kind = ek_move_expr; n.line = ln;
                    n.operand = self.parse_expr();
                    self.consume_tok(cparen, "Expected ')' after @move argument");
                    return n;
                }
                // @cstype(T) — first-class type value for use with `type` variables
                if (strcmp(annot.value, "cstype") == 0 && self.check_tok(oparen)) {
                    self.advance_tok();
                    let mut n: *expr_node= alloc_expr_node(); n.kind = ek_cstype; n.line = ln;
                    n.cast_type = self.parse_type();
                    self.consume_tok(cparen, "Expected ')' after @cstype argument");
                    return n;
                }
                // @typeof(x) — comptime type of expression x
                if (strcmp(annot.value, "typeof") == 0 && self.check_tok(oparen)) {
                    self.advance_tok();
                    let mut n: *expr_node= alloc_expr_node(); n.kind = ek_typeof_e; n.line = ln;
                    n.operand = self.parse_expr();
                    self.consume_tok(cparen, "Expected ')' after @typeof argument");
                    return n;
                }
                // @alignof(T) — compile-time alignment of type T in bytes
                if (strcmp(annot.value, "alignof") == 0 && self.check_tok(oparen)) {
                    self.advance_tok();
                    let mut n: *expr_node= alloc_expr_node(); n.kind = ek_sizeof_e; n.line = ln;
                    n.str_val = lexer.str_dup("alignof");
                    // A bare id followed by ) or < is a user-defined type name, not a var
                    let mut ao_next: i32= self.peek_at_type(1);
                    let mut ao_is_type: bool= self.is_type_start() || self.check_tok(oparen) ||
                        self.check_tok(obracket) || self.check_tok(ast) ||
                        (self.check_tok(id) && (ao_next == cparen || ao_next == comma || ao_next == lt));
                    if (ao_is_type) {
                        n.cast_type = self.parse_type();
                    } else {
                        n.operand = self.parse_expr();
                    }
                    self.consume_tok(cparen, "Expected ')' after @alignof argument");
                    return n;
                }
                // @csizeof(T) — compile-time byte size of type T
                if (strcmp(annot.value, "csizeof") == 0 && self.check_tok(oparen)) {
                    self.advance_tok();
                    let mut n: *expr_node= alloc_expr_node(); n.kind = ek_sizeof_e; n.line = ln;
                    n.str_val = lexer.str_dup("csizeof");
                    let mut cs_next: i32= self.peek_at_type(1);
                    let mut cs_is_type: bool= self.is_type_start() || self.check_tok(oparen) ||
                        self.check_tok(obracket) || self.check_tok(ast) ||
                        (self.check_tok(id) && (cs_next == cparen || cs_next == comma || cs_next == lt));
                    if (cs_is_type) {
                        n.cast_type = self.parse_type();
                    } else {
                        n.operand = self.parse_expr();
                    }
                    self.consume_tok(cparen, "Expected ')' after @csizeof argument");
                    return n;
                }
                // @srsizeof(x) — shallow runtime byte size of value x
                if (strcmp(annot.value, "srsizeof") == 0 && self.check_tok(oparen)) {
                    self.advance_tok();
                    let mut n: *expr_node= alloc_expr_node(); n.kind = ek_sizeof_e; n.line = ln;
                    n.str_val = lexer.str_dup("srsizeof");
                    n.operand = self.parse_expr();
                    self.consume_tok(cparen, "Expected ')' after @srsizeof argument");
                    return n;
                }
                // @drsizeof(x) — deep recursive runtime byte size of value x
                if (strcmp(annot.value, "drsizeof") == 0 && self.check_tok(oparen)) {
                    self.advance_tok();
                    let mut n: *expr_node= alloc_expr_node(); n.kind = ek_sizeof_e; n.line = ln;
                    n.str_val = lexer.str_dup("drsizeof");
                    n.operand = self.parse_expr();
                    self.consume_tok(cparen, "Expected ')' after @drsizeof argument");
                    return n;
                }
                // @self() — pointer to the enclosing istruc/struct container
                if (strcmp(annot.value, "self") == 0 && self.check_tok(oparen)) {
                    self.advance_tok();
                    self.consume_tok(cparen, "Expected ')' after @self()");
                    let mut n: *expr_node= alloc_expr_node(); n.kind = ek_self_builtin; n.line = ln;
                    return n;
                }
                // @ifield() — metadata of the enclosing container
                if (strcmp(annot.value, "ifield") == 0 && self.check_tok(oparen)) {
                    self.advance_tok();
                    self.consume_tok(cparen, "Expected ')' after @ifield()");
                    let mut n: *expr_node= alloc_expr_node(); n.kind = ek_ifield; n.line = ln;
                    return n;
                }
                let mut n: *expr_node= alloc_expr_node();
                n.kind    = ek_annotation;
                n.line    = ln;
                n.str_val = lexer.str_dup(annot.value);
                return n;
            }
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_annotation; n.line = ln; n.str_val = lexer.str_dup("");
            return n;
        }

        if (tt == id) {
            self.advance_tok();
            let mut name: *i8= lexer.str_dup(tok.value);

            // Generic call: func<Type>(args) — parse and save type args
            let mut gen_ta_ptrs: **i8= (i8**)0;
            let mut gen_ta_len: i32= 0;
            if (self.check_tok(lt)) {
                let mut saved_g: i32= self.current;
                self.advance_tok(); // consume '<'
                let mut gen_ta_cap: i32= 4;
                gen_ta_ptrs = (i8**)arc_malloc(sizeof(i8*) * (u64)gen_ta_cap);
                let mut depth_gc: i32= 1;
                while (depth_gc > 0 && !self.is_at_end_p()) {
                    let mut tgc: i32= self.peek_type();
                    if (tgc == gt && depth_gc == 1) {
                        depth_gc = 0; self.advance_tok();
                    } else if (tgc == lt) { depth_gc = depth_gc + 1; self.advance_tok(); }
                    else if (tgc == gt)   { depth_gc = depth_gc - 1; self.advance_tok(); }
                    else if (tgc == right && depth_gc <= 2) { depth_gc = 0; self.advance_tok(); }
                    else if (tgc == comma) { self.advance_tok(); }
                    else if (tgc == question) { depth_gc = 0; } // ternary — not generic args
                    else if (tgc == cparen || tgc == cbrace || tgc == sm) { depth_gc = 0; } // not inside generic args
                    else if (self.is_type_start()) {
                        let mut gta: *type_node= self.parse_type();
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
                let mut mdef: *macro_def_t= self.find_macro(name);
                if (mdef != (macro_def_t*)0) {
                    return self.expand_macro_call(mdef);
                }
            }

            // Function call or identifier
            if (self.match_tok(oparen)) {
                let mut callee: *expr_node= alloc_expr_node();
                callee.kind    = ek_identifier;
                callee.line    = ln;
                callee.str_val = name;

                let mut call_n: *expr_node= alloc_expr_node();
                call_n.kind   = ek_call;
                call_n.line   = ln;
                call_n.callee = callee;

                let mut args: expr_ptr_vec;
                expr_ptr_vec_init(&args);
                if (!self.check_tok(cparen)) {
                    let mut parsing_a: bool= true;
                    while (parsing_a) {
                        // Detect type-as-argument for comptime type params:
                        // Only match unambiguous primitive type tokens to avoid treating
                        // plain identifiers (like variable names) as type args.
                        // Plain 'id' tokens are NOT matched here — they are always exprs.
                        let mut arg_is_type: bool= false;
                        let mut tt_arg: i32= self.peek_type();
                        // NOTE: ty_arb_bool excluded — bN tokens (b1,b2,b8...) look like variable
                        // names (e.g. b2 is a common builder var). Users can use @cstype(bN) instead.
                        let mut is_prim_type_tok: bool= (tt_arg == ty_arb_int || tt_arg == ty_arb_uint ||
                            tt_arg == ty_arb_float || tt_arg == ty_void || tt_arg == ty_char ||
                            tt_arg == kw_usize || tt_arg == kw_isize || tt_arg == kw_iofs ||
                            tt_arg == kw_anytype);
                        if (is_prim_type_tok) {
                            let mut saved_a: i32= self.current;
                            let mut ct_arg: *type_node= self.parse_type();
                            if (self.check_tok(cparen) || self.check_tok(comma)) {
                                // Successfully parsed a primitive type followed by ) or , — treat as type arg
                                let mut ct_node: *expr_node= alloc_expr_node();
                                ct_node.kind      = ek_cstype;
                                ct_node.line      = ln;
                                ct_node.cast_type = ct_arg;
                                expr_ptr_vec_push(&args, ct_node);
                                arg_is_type = true;
                            } else {
                                // Not a type arg — restore and parse as expression
                                self.current = saved_a;
                            }
                        }
                        if (!arg_is_type) {
                            expr_ptr_vec_push(&args, self.parse_expr());
                        }
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
                    let mut n: *expr_node= alloc_expr_node();
                    n.kind = ek_class_init;
                    n.line = ln;
                    let mut it: *type_node= alloc_type_node();
                    it.name = name;
                    n.init_type = it;

                    let mut field_names: str_vec;
                    str_vec_init(&field_names);
                    let mut field_vals: expr_ptr_vec;
                    expr_ptr_vec_init(&field_vals);

                    while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                        self.consume_tok(dot, "Expected '.' in field init");
                        let mut fn_ref: lexer.token_t= self.consume_name_tok("Expected field name");
                        self.consume_tok(assign, "Expected '=' in field init");
                        let mut fv: *expr_node= self.parse_expr();
                        str_vec_push(&field_names, lexer.str_dup(fn_ref.value));
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

            let mut n: *expr_node= alloc_expr_node();
            n.kind    = ek_identifier;
            n.line    = ln;
            n.str_val = name;
            return n;
        }

        if (tt == oparen) {
            self.advance_tok();
            let mut e: *expr_node= self.parse_expr();
            self.consume_tok(cparen, "Expected ')'");
            return e;
        }

        if (tt == dot && self.peek_at_type(1) == obrace) {
            // Implicit init: .{ .field = val }
            self.advance_tok();  // consume .
            self.advance_tok();  // consume {
            let mut n: *expr_node= alloc_expr_node();
            n.kind = ek_class_init;
            n.line = ln;
            n.is_implicit_init = true;

            let mut field_names: str_vec;
            str_vec_init(&field_names);
            let mut field_vals: expr_ptr_vec;
            expr_ptr_vec_init(&field_vals);

            while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                self.consume_tok(dot, "Expected '.' in field init");
                let mut fn_ref: lexer.token_t= self.consume_name_tok("Expected field name");
                self.consume_tok(assign, "Expected '=' in field init");
                let mut fv: *expr_node= self.parse_expr();
                str_vec_push(&field_names, lexer.str_dup(fn_ref.value));
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
            let mut n: *expr_node= alloc_expr_node();
            n.kind    = ek_identifier;
            n.line    = ln;
            n.str_val = lexer.str_dup(tok.value);
            return n;
        }

        // Error: unexpected token in expression
        {
            let mut tok_name: *i8= lexer.tok_type_name(tt);
            let mut tok_val: *i8= tok.value;
            if (tt == id && tok_val != (i8*)0 && tok_val[0] != 0) {
                aprint("error at line %d: unexpected %s '%s' in expression\n", .{ (i32)ln, tok_name, tok_val });
            } else {
                aprint("error at line %d: unexpected %s in expression\n", .{ (i32)ln, tok_name });
            }
        }
        self.had_parse_error = true;
        self.advance_tok();
        let mut n: *expr_node= alloc_expr_node();
        n.kind = ek_int_lit; n.line = ln; n.int_val = 0;
        return n;
    }

    // ---- Main parse entry point ----

    fn parse(self: *parser_t) *program_node {
        let mut prog: *program_node= (program_node*)arc_malloc(sizeof(parser__NS_program_node));
        memset((i8*)prog, 0, sizeof(parser__NS_program_node));
        prog.kind = nd_program;
        prog.decls_cap = 64;
        prog.decls = (ast_node**)arc_malloc(sizeof(i8*) * (u64)prog.decls_cap);

        while (!self.is_at_end_p()) {
            let mut decl: *ast_node= self.parse_top_level();
            if (decl != (ast_node*)0) {
                // Wildcard import: null-name namespace_decl — splice contents directly
                if (decl.kind == nd_namespace_decl) {
                    let mut splice_nd: *namespace_decl= (namespace_decl*)decl;
                    if (splice_nd.name == (i8*)0) {
                        let mut spi: i32= 0;
                        while (spi < splice_nd.decls_len) {
                            let mut sp_decl: *ast_node= splice_nd.decls[spi];
                            if (sp_decl != (ast_node*)0) {
                                if (prog.decls_len >= prog.decls_cap) {
                                    prog.decls_cap = prog.decls_cap * 2;
                                    prog.decls = (ast_node**)arc_realloc((i8*)prog.decls, sizeof(i8*) * (u64)prog.decls_cap);
                                }
                                prog.decls[prog.decls_len] = sp_decl;
                                prog.decls_len = prog.decls_len + 1;
                            }
                            spi = spi + 1;
                        }
                        arc_free((i8*)splice_nd);
                    } else {
                        if (prog.decls_len >= prog.decls_cap) {
                            prog.decls_cap = prog.decls_cap * 2;
                            prog.decls = (ast_node**)arc_realloc((i8*)prog.decls, sizeof(i8*) * (u64)prog.decls_cap);
                        }
                        prog.decls[prog.decls_len] = decl;
                        prog.decls_len = prog.decls_len + 1;
                    }
                } else {
                    if (prog.decls_len >= prog.decls_cap) {
                        prog.decls_cap = prog.decls_cap * 2;
                        prog.decls = (ast_node**)arc_realloc((i8*)prog.decls, sizeof(i8*) * (u64)prog.decls_cap);
                    }
                    prog.decls[prog.decls_len] = decl;
                    prog.decls_len = prog.decls_len + 1;
                }
            }
            // Emit any pending anonymous-istruc instance var queued by parse_istruc_decl
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
