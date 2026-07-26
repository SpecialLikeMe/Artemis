// compiler/ast/print.arc — Human-readable AST printer.
// Called by the compiler driver when --emit-ast is supplied.
// Output format: indented S-expression style, one node per line.

namespace ast {

fn print_indent(depth: i32) void {
    let mut i: i32= 0;
    while (i < depth) { printf("  "); i = i + 1; }
}

fn print_type(t: *parser.type_node) void {
    if (t == (parser.type_node*)0) { printf("<null-type>"); return; }
    if (t.is_const) { printf("const "); }
    if (t.is_volatile) { printf("volatile "); }
    if (t.is_static_kw) { printf("static "); }
    if (t.is_nullable) { printf("?"); }
    if (t.is_primitive) {
        if (t.prim == 5) { printf("void"); }
        else if (t.prim == 4) { printf("bool"); }
        else if (t.prim == 3) { printf("f%d", (i32)t.bit_width); }
        else if (t.is_signed) { printf("i%d", (i32)t.bit_width); }
        else { printf("u%d", (i32)t.bit_width); }
    } else if (t.is_func_ptr) {
        if (t.fp_ret != (i8*)0) { print_type((parser.type_node*)t.fp_ret); }
        else { printf("void"); }
        printf("(");
        let mut pi: i32= 0;
        while (pi < t.fp_params_len) {
            if (pi > 0) { printf(", "); }
            print_type((parser.type_node*)t.fp_params[pi]);
            pi = pi + 1;
        }
        if (t.fp_variadic) { if (t.fp_params_len > 0) { printf(", "); } printf("..."); }
        printf(")*");
    } else if (t.name != (i8*)0) {
        printf("%s", t.name);
        if (t.type_args_len > 0) {
            printf("<");
            let mut ti: i32= 0;
            while (ti < t.type_args_len) {
                if (ti > 0) { printf(","); }
                print_type((parser.type_node*)t.type_args[ti]);
                ti = ti + 1;
            }
            printf(">");
        }
    } else {
        printf("<type>");
    }
    let mut d: i32= 0;
    while (d < t.pointer_depth) { printf("*"); d = d + 1; }
}

fn print_expr(e: *parser.expr_node, depth: i32) void {
    if (e == (parser.expr_node*)0) { printf("<null-expr>"); return; }
    let mut k: i32= e.kind;
    if (k == 0) { printf("%ld", e.int_val); }
    else if (k == 1) { printf("%f", e.flt_val); }
    else if (k == 2) { printf("\"%s\"", e.str_val != (i8*)0 ? e.str_val : ""); }
    else if (k == 3) { printf("'%s'", e.str_val != (i8*)0 ? e.str_val : ""); }
    else if (k == 4) { printf("%s", e.int_val != 0 ? "true" : "false"); }
    else if (k == 5) { printf("%s", e.str_val != (i8*)0 ? e.str_val : "<id>"); }
    else if (k == 21) { printf("null"); }
    else if (k == 18) { printf("error.%s", e.str_val != (i8*)0 ? e.str_val : ""); }
    else if (k == 29) { printf("quote{%s}", e.str_val != (i8*)0 ? e.str_val : ""); }
    else if (k == 6) { // unary
        let mut uop: i32= e.uop;
        if (uop == 0) { printf("(neg "); }
        else if (uop == 3) { printf("(not "); }
        else if (uop == 8) { printf("(deref "); }
        else if (uop == 9) { printf("(addr "); }
        else { printf("(uop%d ", uop); }
        print_expr(e.operand, depth);
        printf(")");
    } else if (k == 7) { // binary
        printf("(");
        let mut bop: i32= e.bop;
        if (bop == 0) { printf("+"); }
        else if (bop == 1) { printf("-"); }
        else if (bop == 2) { printf("*"); }
        else if (bop == 3) { printf("/"); }
        else if (bop == 5) { printf("=="); }
        else if (bop == 6) { printf("!="); }
        else if (bop == 7) { printf("<"); }
        else if (bop == 8) { printf(">"); }
        else if (bop == 11) { printf("&&"); }
        else if (bop == 12) { printf("||"); }
        else if (bop == 18) { printf("="); }
        else { printf("bop%d", bop); }
        printf(" ");
        print_expr(e.lhs, depth);
        printf(" ");
        print_expr(e.rhs, depth);
        printf(")");
    } else if (k == 8) { // call
        print_expr(e.callee, depth);
        printf("(");
        let mut ai: i32= 0;
        while (ai < e.args_len) {
            if (ai > 0) { printf(", "); }
            print_expr(e.args[ai], depth);
            ai = ai + 1;
        }
        printf(")");
    } else if (k == 9) { // subscript
        print_expr(e.object, depth);
        printf("[");
        print_expr(e.index, depth);
        printf("]");
    } else if (k == 10) { // member
        print_expr(e.object, depth);
        printf(".%s", e.str_val != (i8*)0 ? e.str_val : "");
    } else if (k == 11 || k == 31) { // cast / cast_as
        printf("(%s)(", k == 31 ? "as" : "cast");
        print_type(e.cast_type);
        printf(")");
        print_expr(e.operand, depth);
    } else if (k == 33) { // range
        print_expr(e.lhs, depth);
        printf(e.int_val != 0 ? "..=" : "..");
        print_expr(e.rhs, depth);
    } else if (k == 34) { // cstype
        printf("@cstype(");
        print_type(e.cast_type);
        printf(")");
    } else if (k == 30) { // lambda
        printf("[lambda]");
    } else if (k == 17) { // class_init
        printf("%s{...}", e.str_val != (i8*)0 ? e.str_val : "");
    } else {
        printf("<expr-k%d>", k);
    }
}

fn print_stmt(node: *parser.ast_node, depth: i32) void;

fn print_block(blk: *parser.block_stmt, depth: i32) void {
    if (blk == (parser.block_stmt*)0) { return; }
    let mut i: i32= 0;
    while (i < blk.stmts_len) {
        print_stmt(blk.stmts[i], depth);
        i = i + 1;
    }
}

fn print_stmt(node: *parser.ast_node, depth: i32) void {
    if (node == (parser.ast_node*)0) { return; }
    print_indent(depth);
    let mut k: i32= node.kind;
    if (k == 0) { // block
        printf("(block\n");
        print_block((parser.block_stmt*)node, depth + 1);
        print_indent(depth); printf(")\n");
    } else if (k == 13) { // var_decl
        let mut vd: *parser.var_decl= (parser.var_decl*)node;
        printf("(var %s : ", vd.name != (i8*)0 ? vd.name : "_");
        print_type(vd.type);
        if (vd.has_init && vd.init != (parser.expr_node*)0) {
            printf(" = ");
            print_expr(vd.init, depth);
        }
        if (vd.attributes_len > 0) {
            let mut ai: i32= 0;
            while (ai < vd.attributes_len) {
                printf(" #[%s]", vd.attributes[ai].name != (i8*)0 ? vd.attributes[ai].name : "");
                ai = ai + 1;
            }
        }
        printf(")\n");
    } else if (k == 14) { // func_decl
        let mut fd: *parser.func_decl= (parser.func_decl*)node;
        if (fd.attributes_len > 0) {
            let mut ai: i32= 0;
            while (ai < fd.attributes_len) {
                print_indent(depth);
                printf("#[%s]\n", fd.attributes[ai].name != (i8*)0 ? fd.attributes[ai].name : "");
                ai = ai + 1;
            }
        }
        printf("(fn %s(", fd.name != (i8*)0 ? fd.name : "_");
        let mut pi: i32= 0;
        while (pi < fd.params_len) {
            if (pi > 0) { printf(", "); }
            printf("%s: ", fd.params[pi].name != (i8*)0 ? fd.params[pi].name : "_");
            print_type(fd.params[pi].type);
            pi = pi + 1;
        }
        if (fd.is_variadic) { if (fd.params_len > 0) { printf(", "); } printf("..."); }
        printf(") -> ");
        print_type(fd.ret_type);
        if (fd.has_body) {
            printf("\n");
            print_block((parser.block_stmt*)fd.body, depth + 1);
            print_indent(depth); printf(")\n");
        } else {
            printf(")  // extern\n");
        }
    } else if (k == 20) { // namespace_decl
        let mut nd: *parser.namespace_decl= (parser.namespace_decl*)node;
        printf("(namespace %s\n", nd.name != (i8*)0 ? nd.name : "_");
        let mut di: i32= 0;
        while (di < nd.decls_len) {
            print_stmt(nd.decls[di], depth + 1);
            di = di + 1;
        }
        print_indent(depth); printf(")\n");
    } else if (k == 15) { // struct_decl
        let mut sd: *parser.struct_decl= (parser.struct_decl*)node;
        printf("(struct %s\n", sd.name != (i8*)0 ? sd.name : "_");
        let mut fi: i32= 0;
        while (fi < sd.fields_len) {
            print_indent(depth + 1);
            let mut _f: *parser.var_decl= sd.fields[fi];
            printf("%s: ", _f.name != (i8*)0 ? _f.name : "_");
            print_type(_f.type);
            printf("\n");
            fi = fi + 1;
        }
        print_indent(depth); printf(")\n");
    } else if (k == 17) { // enum_decl
        let mut ed: *parser.enum_decl= (parser.enum_decl*)node;
        printf("(enum %s\n", ed.name != (i8*)0 ? ed.name : "_");
        let mut vi: i32= 0;
        while (vi < ed.variants_len) {
            print_indent(depth + 1);
            printf("%s", ed.variant_names[vi] != (i8*)0 ? ed.variant_names[vi] : "_");
            if (ed.variant_has_val[vi]) { printf(" = %ld", ed.variant_vals[vi]); }
            printf("\n");
            vi = vi + 1;
        }
        print_indent(depth); printf(")\n");
    } else if (k == 19) { // typedef_decl
        let mut td: *parser.typedef_decl= (parser.typedef_decl*)node;
        printf("(typedef %s = ", td.name != (i8*)0 ? td.name : "_");
        print_type(td.target);
        printf(")\n");
    } else {
        // Treat as expression statement
        let mut ne: *parser.expr_node= (parser.expr_node*)node;
        printf("(expr-stmt ");
        print_expr(ne, depth);
        printf(")\n");
    }
}

fn print_program(prog: *parser.program_node, out_path: *i8) void {
    let mut fp: *void= (void*)0;
    if (out_path != (i8*)0) {
        fp = fopen(out_path, "w");
    }
    // Use stdout if no output file or open failed
    let mut use_stdout: bool= (fp == (void*)0);
    if (!use_stdout) { fclose(fp); } // Close and reuse printf for simplicity

    // Note: we always write to stdout; file redirect can be done via shell.
    printf("; Artemis AST dump\n");
    printf("(program\n");
    let mut i: i32= 0;
    while (i < prog.decls_len) {
        print_stmt(prog.decls[i], 1);
        i = i + 1;
    }
    printf(")\n");
}

} // namespace ast
