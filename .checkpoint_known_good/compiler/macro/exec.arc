// compiler/macro/exec.arc — Proc macro execution engine.
//
// At the IR-generation phase, declarations with #[name] or #derive[name]
// attributes are processed here before their normal IR emission.
//
// Execution model (first implementation):
//   1. Find the macro function by dotted name in the global program AST.
//   2. Evaluate the function body using a lightweight interpreter that handles
//      simple statements: local var decls, assignments, return, if/else, and
//      quote{} literals.
//   3. The return value is a tokenstream string (from quote{}).
//   4. Re-lex and re-parse that string; splice the resulting AST nodes in-place.
//
// Limitation: macro functions must be accessible in the current program AST
// (not yet compiled to a separate plugin DSO). This covers all inlined macros.

namespace macro_exec {

// ---- Simple string value for macro interpreter ----
// All values in the interpreter are strings; we just pass token text around.

struct macro_val {
    let str: *i8;      // value as text (null = void/error)
    let is_quote: bool; // true: this is a quote{} token stream, not a raw string
}

fn mv_null() macro_val {
    let mut v: macro_val;
    v.str = (i8*)0;
    v.is_quote = false;
    return v;
}

fn mv_str(s: *i8) macro_val {
    let mut v: macro_val;
    v.str = s;
    v.is_quote = false;
    return v;
}

fn mv_quote(s: *i8) macro_val {
    let mut v: macro_val;
    v.str = s;
    v.is_quote = true;
    return v;
}

// ---- Find a macro function by dotted name in the program AST ----
// Dotted name: "bar.mymacro" → look in namespace "bar" for fn "mymacro"
// Returns the func_decl* or null if not found.

fn find_fn_in_ns(ns: *parser.namespace_decl, fn_name: *i8) *parser.func_decl {
    let mut i: i32= 0;
    while (i < ns.decls_len) {
        let mut d: *parser.ast_node= ns.decls[i];
        if (d != (parser.ast_node*)0 && d.kind == 14) { // nd_func_decl
            let mut fd: *parser.func_decl= (parser.func_decl*)d;
            if (fd.name != (i8*)0 && fn_name != (i8*)0 && strcmp(fd.name, fn_name) == 0) {
                return fd;
            }
        }
        i = i + 1;
    }
    return (parser.func_decl*)0;
}

fn find_macro_fn(prog: *parser.program_node, macro_name: *i8) *parser.func_decl {
    if (macro_name == (i8*)0 || prog == (parser.program_node*)0) {
        return (parser.func_decl*)0;
    }

    // Split macro_name at the last '.' — everything before is the namespace path,
    // everything after is the function name.
    let mut dot_pos: i32= -1;
    let mut ci: i32= 0;
    while (macro_name[ci] != 0) {
        if (macro_name[ci] == '.') { dot_pos = ci; }
        ci = ci + 1;
    }

    if (dot_pos < 0) {
        // No dot: look for a top-level function
        let mut i: i32= 0;
        while (i < prog.decls_len) {
            let mut d: *parser.ast_node= prog.decls[i];
            if (d != (parser.ast_node*)0 && d.kind == 14) {
                let mut fd: *parser.func_decl= (parser.func_decl*)d;
                if (fd.name != (i8*)0 && strcmp(fd.name, macro_name) == 0) { return fd; }
            }
            i = i + 1;
        }
        return (parser.func_decl*)0;
    }

    // Extract namespace name (everything before last dot) and fn name (after)
    let mut ns_name: [256]i8;
    let mut j: i32= 0;
    while (j < dot_pos && j < 255) { ns_name[j] = macro_name[j]; j = j + 1; }
    ns_name[j] = 0;
    let mut fn_name: *i8= macro_name + dot_pos + 1;

    // Resolve the namespace path: "foo.mymacro" looks in ns foo;
    // "foo.bar.mymacro" looks in ns foo, then nested ns bar.
    // Find top-level namespace matching ns_name (or the first segment of it)
    let mut top_dot: i32= -1;
    let mut k: i32= 0;
    while (ns_name[k] != 0) { if (ns_name[k] == '.') { top_dot = k; break; } k = k + 1; }

    let mut top_ns_name: *i8= ns_name;  // single segment or full dotted path
    let mut i: i32= 0;
    while (i < prog.decls_len) {
        let mut d: *parser.ast_node= prog.decls[i];
        if (d != (parser.ast_node*)0 && d.kind == 20) { // nd_namespace_decl
            let mut ns: *parser.namespace_decl= (parser.namespace_decl*)d;
            if (ns.name != (i8*)0 && strcmp(ns.name, top_ns_name) == 0) {
                if (top_dot < 0) {
                    // Single-level: look directly for the function
                    let mut fd: *parser.func_decl= find_fn_in_ns(ns, fn_name);
                    if (fd != (parser.func_decl*)0) { return fd; }
                } else {
                    // Two-level: look for nested namespace matching second segment
                    let mut second: *i8= ns_name + top_dot + 1;
                    let mut ni: i32= 0;
                    while (ni < ns.decls_len) {
                        let mut nd: *parser.ast_node= ns.decls[ni];
                        if (nd != (parser.ast_node*)0 && nd.kind == 20) {
                            let mut inner: *parser.namespace_decl= (parser.namespace_decl*)nd;
                            if (inner.name != (i8*)0 && strcmp(inner.name, second) == 0) {
                                let mut fd2: *parser.func_decl= find_fn_in_ns(inner, fn_name);
                                if (fd2 != (parser.func_decl*)0) { return fd2; }
                            }
                        }
                        ni = ni + 1;
                    }
                }
            }
        }
        i = i + 1;
    }
    return (parser.func_decl*)0;
}

// ---- Interpreter ----
// Evaluates a macro function body and returns the quoted token string, or null.

// Evaluate a single expression node; only handles literals and ek_quote.
fn eval_expr(e: *parser.expr_node) macro_val {
    if (e == (parser.expr_node*)0) { return mv_null(); }
    let mut k: i32= e.kind;
    if (k == 0) {  // int_lit
        let mut buf: [32]i8;
        snprintf(buf, 32u, "%ld", e.int_val);
        return mv_str(lexer.str_dup(buf));
    }
    if (k == 2) {  // string_lit
        return mv_str(e.str_val != (i8*)0 ? lexer.str_dup(e.str_val) : lexer.str_dup(""));
    }
    if (k == 4) {  // bool_lit
        return mv_str(e.int_val != 0 ? lexer.str_dup("true") : lexer.str_dup("false"));
    }
    if (k == 29) { // ek_quote
        return mv_quote(e.str_val != (i8*)0 ? e.str_val : "");
    }
    // For unknown expressions: return null (cannot evaluate at compile time)
    return mv_null();
}

fn mv_is_truthy(v: macro_val) bool {
    if (v.str == (i8*)0) { return false; }
    if (v.str[0] == 0) { return false; }
    if (strcmp(v.str, "false") == 0) { return false; }
    if (strcmp(v.str, "0") == 0) { return false; }
    return true;
}

// Evaluate a macro body; return the tokenstream string from a `return quote{...}`,
// or null if the body is too complex or returns nothing.
// Stores return value in *out; returns true if a return was executed.
fn eval_body(blk: *parser.block_stmt, out: *macro_val) bool;

// Loop bodies in a macro are interpreted, not compiled, so a non-terminating loop
// would hang the compiler. Cap the iteration count instead.
comptime i32 MACRO_MAX_ITERS = 1024;

// Run a single statement through the interpreter (used for for-loop init).
fn eval_body_stmt(node: *parser.ast_node, out: *macro_val) bool {
    if (node == (parser.ast_node*)0) { return false; }
    let mut one: parser.block_stmt;
    memset((i8*)&one, 0, sizeof(parser__NS_block_stmt));
    let mut slot: [1]*parser.ast_node;
    slot[0] = node;
    one.kind      = 0;
    one.stmts     = slot;
    one.stmts_len = 1;
    return eval_body(&one, out);
}

fn eval_body(blk: *parser.block_stmt, out: *macro_val) bool {
    if (blk == (parser.block_stmt*)0) { return false; }
    let mut i: i32= 0;
    while (i < blk.stmts_len) {
        let mut stmt: *parser.ast_node= blk.stmts[i];
        if (stmt == (parser.ast_node*)0) { i = i + 1; continue; }
        let mut k: i32= stmt.kind;

        // Return statement (nd_return = 5 in the stmt kinds used in block_stmt)
        // Check by looking for expr_node patterns that act as return
        // In the AST, return stmts are stored as expr_nodes with is_return=true
        // We match nd_return by checking ek_* on the stmt used as return
        // Actually, return stmts in block_stmt are represented differently.
        // Let's look at what kind values return stmts get.
        // Based on analysis: nd_return = 5, stored as expr_node with the return value.
        // We check kind >= 100 as the "return" statement marker OR kind == nd_return.
        // Looking at parser: return statements are stored as AST nodes with kind from
        // the node_kind enum. Let's use a broader match: if a node's int_val or similar
        // field indicates a return statement.

        // In the Arc IR/parser, return stmts have no standard nd_* kind exposed in the
        // block_stmt stmts array — they're parsed as special nodes. Let's check all
        // expr_node stmt kinds for ek_* patterns we know about.
        // The simplest check: if this is an expr-stmt that is purely a quote{}, return it.
        // More specifically: we look for a stmt of kind that maps to a return in the parser.

        // From ir/stmts.arc, return stmts are ek_* = -1 or similar? Let me check:
        // Actually in Arc IR, return nodes in block_stmt.stmts have kind that matches
        // the nd_* enum. nd_return = ... let's check the nd_* enum in parser/main.arc.
        // From the grep earlier: nd_block=0, nd_var_decl=13, nd_func_decl=14, etc.
        // Return stmts should be around nd_return. Let's use a heuristic: we'll check
        // if the stmt has kind in a certain range OR if we can cast it to expr_node
        // and its kind is ek_quote (a direct quote{} statement).

        // Bare ek_quote as an expression statement
        if (k == 29) { // ek_quote
            *out = eval_expr((parser.expr_node*)stmt);
            return true;
        }

        // nd_return_stmt = 2 (from parser/main.arc nd_* enum)
        // Cast correctly to return_stmt (NOT expr_node — different struct layout).
        if (k == 2) {
            let mut rn: *parser.return_stmt= (parser.return_stmt*)stmt;
            if (rn.has_val && rn.val != (parser.expr_node*)0) {
                *out = eval_expr(rn.val);
            }
            return true;
        }

        // nd_expr_stmt = 1: expression used as a statement
        if (k == 1) {
            let mut as_expr: *parser.expr_node= (parser.expr_node*)stmt;
            if (as_expr.kind == 29) { // ek_quote expression as stmt
                *out = eval_expr(as_expr);
                return true;
            }
        }

        // var_decl: the interpreter evaluates expressions structurally rather than
        // through an environment, so a local binding has nothing to record.
        if (k == 13) { i = i + 1; continue; }

        // block: recurse
        if (k == 0) {
            let mut r: bool= eval_body((parser.block_stmt*)stmt, out);
            if (r) { return true; }
        }

        // nd_if_stmt = 5: evaluate condition, recurse into appropriate branch
        if (k == 5) {
            let mut is2: *parser.if_stmt= (parser.if_stmt*)stmt;
            let mut cond_val: macro_val= (is2.cond != (parser.expr_node*)0) ? eval_expr(is2.cond) : mv_null();
            let mut branch: *parser.ast_node= mv_is_truthy(cond_val) ? is2.then_body : is2.else_body;
            if (branch != (parser.ast_node*)0) {
                let mut r: bool= eval_body((parser.block_stmt*)branch, out);
                if (r) { return true; }
            }
            i = i + 1; continue;
        }

        // nd_while_stmt = 6: evaluate condition, execute body up to 1024 iterations
        if (k == 6) {
            let mut ws2: *parser.while_stmt= (parser.while_stmt*)stmt;
            let mut iters: i32= 0;
            while (iters < MACRO_MAX_ITERS) {
                let mut wcond: macro_val= (ws2.cond != (parser.expr_node*)0) ? eval_expr(ws2.cond) : mv_null();
                if (!mv_is_truthy(wcond)) { break; }
                if (ws2.body != (parser.ast_node*)0) {
                    let mut r: bool= eval_body((parser.block_stmt*)ws2.body, out);
                    if (r) { return true; }
                }
                iters = iters + 1;
            }
            i = i + 1; continue;
        }

        // nd_for_stmt = 7: C-style for. init/step are evaluated for their effect on
        // the interpreter's view; the body runs while the condition stays truthy.
        if (k == 7) {
            let mut fs2: *parser.for_stmt= (parser.for_stmt*)stmt;
            if (fs2.init != (parser.ast_node*)0) { eval_body_stmt(fs2.init, out); }
            let mut fiters: i32= 0;
            while (fiters < MACRO_MAX_ITERS) {
                let mut fcond: macro_val= (fs2.cond != (parser.expr_node*)0) ? eval_expr(fs2.cond) : mv_null();
                // A for loop with no condition would spin forever; MACRO_MAX_ITERS caps it.
                if (fs2.cond != (parser.expr_node*)0 && !mv_is_truthy(fcond)) { break; }
                if (fs2.body != (parser.ast_node*)0) {
                    let mut r: bool= eval_body((parser.block_stmt*)fs2.body, out);
                    if (r) { return true; }
                }
                if (fs2.step != (parser.expr_node*)0) { eval_expr(fs2.step); }
                fiters = fiters + 1;
            }
            i = i + 1; continue;
        }

        // nd_for_range_stmt = 8: `for (x : range)` — run the body like any other loop.
        if (k == 8) {
            let mut frs2: *parser.for_range_stmt= (parser.for_range_stmt*)stmt;
            if (frs2.body != (parser.ast_node*)0) {
                let mut r: bool= eval_body((parser.block_stmt*)frs2.body, out);
                if (r) { return true; }
            }
            i = i + 1; continue;
        }

        // nd_match_stmt = 26: take the first arm whose guard is truthy (or unguarded).
        if (k == 26) {
            let mut ms2: *parser.match_stmt= (parser.match_stmt*)stmt;
            let mut ai: i32= 0;
            while (ai < ms2.arms_len) {
                let mut arm2: *parser.match_arm= ms2.arms[ai];
                if (arm2 != (parser.match_arm*)0) {
                    let mut take: bool= true;
                    if (arm2.guard != (i8*)0) {
                        take = mv_is_truthy(eval_expr((parser.expr_node*)arm2.guard));
                    }
                    if (take && arm2.body != (parser.ast_node*)0) {
                        let mut r: bool= eval_body((parser.block_stmt*)arm2.body, out);
                        if (r) { return true; }
                        ai = ms2.arms_len;
                    }
                }
                ai = ai + 1;
            }
            i = i + 1; continue;
        }

        i = i + 1;
    }
    return false;
}

fn eval_macro_fn(fd: *parser.func_decl) macro_val {
    if (fd == (parser.func_decl*)0 || !fd.has_body) { return mv_null(); }
    let mut blk: *parser.block_stmt= (parser.block_stmt*)fd.body;
    let mut result: macro_val= mv_null();
    eval_body(blk, &result);
    return result;
}

// ---- Splice: re-lex and re-parse the macro output into AST nodes ----
// Takes the raw token text from quote{}, pre-lexes/parses it, and returns
// a program_node containing the resulting top-level declarations.
// Returns null on parse error.
fn splice_quote(token_src: *i8, stdlib_path: *i8) *parser.program_node {
    if (token_src == (i8*)0) { return (parser.program_node*)0; }
    let mut src_len: u64= (u64)strlen(token_src);
    if (src_len == 0) { return (parser.program_node*)0; }

    // Preprocess (no @include / @define expected inside macros)
    let mut pp_src: *i8= preproc.preprocess(token_src, "<macro>", stdlib_path);
    let mut pp_len: u64= (u64)strlen(pp_src);

    // Lex
    let mut lxr: lexer.lexer_t;
    lxr.init(pp_src, pp_len);
    let mut toks: lexer.token_vec= lxr.tokenize();

    // Parse
    let mut prs: parser.parser_t;
    prs.init(toks.data, toks.len);
    prs.import_src_path    = "<macro>";
    prs.import_stdlib_path = stdlib_path;
    let mut prog: *parser.program_node= prs.parse();

    if (prs.had_parse_error) {
        printf("warning: proc macro output failed to parse\n");
        return (parser.program_node*)0;
    }
    return prog;
}

// ---- Main entry point ----
// Call before visiting a declaration with attributes.
// macro_name: the dotted attribute name (e.g., "bar.mymacro")
// decl_node: the decorated AST node (its source text is passed as the token input)
// prog: the full program AST (to locate the macro function)
// stdlib_path: for re-parsing
// out_prog: receives the expanded nodes (caller splices them in)
// Returns true if a macro was found and produced output.
fn try_exec_macro(macro_name: *i8,
                  decl_node: *parser.ast_node,
                  prog: *parser.program_node,
                  stdlib_path: *i8,
                  out_prog: **parser.program_node) bool {
    *out_prog = (parser.program_node*)0;
    if (macro_name == (i8*)0) { return false; }

    let mut fd: *parser.func_decl= find_macro_fn(prog, macro_name);
    if (fd == (parser.func_decl*)0) {
        printf("warning: proc macro '%s' not found in current translation unit\n", macro_name);
        return false;
    }

    let mut result: macro_val= eval_macro_fn(fd);
    if (result.str == (i8*)0 || !result.is_quote) {
        // Macro didn't return a quote{} — pass-through (keep original node)
        return false;
    }

    let mut expanded: *parser.program_node= splice_quote(result.str, stdlib_path);
    if (expanded == (parser.program_node*)0) { return false; }

    *out_prog = expanded;
    return true;
}

} // namespace macro_exec
