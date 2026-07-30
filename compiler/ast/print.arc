// compiler/ast/print.arc — Human-readable AST printer.
// Called by the compiler driver when --emit-ast is supplied.
// Output format: indented S-expression style, one node per line.

namespace ast {

fn print_indent(depth: i32) void {
    let mut i: i32= 0;
    while (i < depth) { aprint("  ", .{}); i = i + 1; }
}

fn print_type(t: *parser.type_node) void {
    if (t == (parser.type_node*)0) { aprint("<null-type>", .{}); return; }
    if (t.is_const) { aprint("const ", .{}); }
    if (t.is_volatile) { aprint("volatile ", .{}); }
    if (t.is_static_kw) { aprint("static ", .{}); }
    if (t.is_nullable) { aprint("?", .{}); }
    if (t.is_primitive) {
        if (t.prim == 5) { aprint("void", .{}); }
        else if (t.prim == 4) { aprint("bool", .{}); }
        else if (t.prim == 3) { aprint("f%d", .{ (i32)t.bit_width }); }
        else if (t.is_signed) { aprint("i%d", .{ (i32)t.bit_width }); }
        else { aprint("u%d", .{ (i32)t.bit_width }); }
    } else if (t.is_func_ptr) {
        if (t.fp_ret != (i8*)0) { print_type((parser.type_node*)t.fp_ret); }
        else { aprint("void", .{}); }
        aprint("(", .{});
        let mut pi: i32= 0;
        while (pi < t.fp_params_len) {
            if (pi > 0) { aprint(", ", .{}); }
            print_type((parser.type_node*)t.fp_params[pi]);
            pi = pi + 1;
        }
        if (t.fp_variadic) { if (t.fp_params_len > 0) { aprint(", ", .{}); } aprint("...", .{}); }
        aprint(")*", .{});
    } else if (t.name != (i8*)0) {
        aprint("%s", .{ t.name });
        if (t.type_args_len > 0) {
            aprint("<", .{});
            let mut ti: i32= 0;
            while (ti < t.type_args_len) {
                if (ti > 0) { aprint(",", .{}); }
                print_type((parser.type_node*)t.type_args[ti]);
                ti = ti + 1;
            }
            aprint(">", .{});
        }
    } else {
        aprint("<type>", .{});
    }
    let mut d: i32= 0;
    while (d < t.pointer_depth) { aprint("*", .{}); d = d + 1; }
}

fn print_expr(e: *parser.expr_node, depth: i32) void {
    if (e == (parser.expr_node*)0) { aprint("<null-expr>", .{}); return; }
    let mut k: i32= e.kind;
    if (k == 0) { aprint("%ld", .{ e.int_val }); }
    else if (k == 1) { aprint("%f", .{ e.flt_val }); }
    else if (k == 2) { aprint("\"%s\"", .{ e.str_val != (i8*)0 ? e.str_val : "" }); }
    else if (k == 3) { aprint("'%s'", .{ e.str_val != (i8*)0 ? e.str_val : "" }); }
    else if (k == 4) { aprint("%s", .{ e.int_val != 0 ? "true" : "false" }); }
    else if (k == 5) { aprint("%s", .{ e.str_val != (i8*)0 ? e.str_val : "<id>" }); }
    else if (k == 21) { aprint("null", .{}); }
    else if (k == 18) { aprint("error.%s", .{ e.str_val != (i8*)0 ? e.str_val : "" }); }
    else if (k == 29) { aprint("quote{%s}", .{ e.str_val != (i8*)0 ? e.str_val : "" }); }
    else if (k == 6) { // unary
        let mut uop: i32= e.uop;
        if (uop == 0) { aprint("(neg ", .{}); }
        else if (uop == 3) { aprint("(not ", .{}); }
        else if (uop == 8) { aprint("(deref ", .{}); }
        else if (uop == 9) { aprint("(addr ", .{}); }
        else { aprint("(uop%d ", .{ uop }); }
        print_expr(e.operand, depth);
        aprint(")", .{});
    } else if (k == 7) { // binary
        aprint("(", .{});
        let mut bop: i32= e.bop;
        if (bop == 0) { aprint("+", .{}); }
        else if (bop == 1) { aprint("-", .{}); }
        else if (bop == 2) { aprint("*", .{}); }
        else if (bop == 3) { aprint("/", .{}); }
        else if (bop == 5) { aprint("==", .{}); }
        else if (bop == 6) { aprint("!=", .{}); }
        else if (bop == 7) { aprint("<", .{}); }
        else if (bop == 8) { aprint(">", .{}); }
        else if (bop == 11) { aprint("&&", .{}); }
        else if (bop == 12) { aprint("||", .{}); }
        else if (bop == 18) { aprint("=", .{}); }
        else { aprint("bop%d", .{ bop }); }
        aprint(" ", .{});
        print_expr(e.lhs, depth);
        aprint(" ", .{});
        print_expr(e.rhs, depth);
        aprint(")", .{});
    } else if (k == 8) { // call
        print_expr(e.callee, depth);
        aprint("(", .{});
        let mut ai: i32= 0;
        while (ai < e.args_len) {
            if (ai > 0) { aprint(", ", .{}); }
            print_expr(e.args[ai], depth);
            ai = ai + 1;
        }
        aprint(")", .{});
    } else if (k == 9) { // subscript
        print_expr(e.object, depth);
        aprint("[", .{});
        print_expr(e.index, depth);
        aprint("]", .{});
    } else if (k == 10) { // member
        print_expr(e.object, depth);
        aprint(".%s", .{ e.str_val != (i8*)0 ? e.str_val : "" });
    } else if (k == 11 || k == 31) { // cast / cast_as
        aprint("(%s)(", .{ k == 31 ? "as" : "cast" });
        print_type(e.cast_type);
        aprint(")", .{});
        print_expr(e.operand, depth);
    } else if (k == 33) { // range
        print_expr(e.lhs, depth);
        aprint(e.int_val != 0 ? "..=" : "..", .{});
        print_expr(e.rhs, depth);
    } else if (k == 34) { // cstype
        aprint("@cstype(", .{});
        print_type(e.cast_type);
        aprint(")", .{});
    } else if (k == 30) { // lambda
        aprint("[lambda]", .{});
    } else if (k == 17) { // class_init
        aprint("%s{...}", .{ e.str_val != (i8*)0 ? e.str_val : "" });
    } else {
        aprint("<expr-k%d>", .{ k });
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
        aprint("(block\n", .{});
        print_block((parser.block_stmt*)node, depth + 1);
        print_indent(depth); aprint(")\n", .{});
    } else if (k == 13) { // var_decl
    let mut vd: *parser.var_decl= (parser.var_decl*)node;
    aprint("(var %s : ", .{ vd.name != (i8*)0 ? vd.name : "_" });
    print_type(vd.type);
    if (vd.has_init && vd.init != (parser.expr_node*)0) {
        aprint(" = ", .{});
        print_expr(vd.init, depth);
    }
    if (vd.attributes_len > 0) {
        let mut ai: i32= 0;
        while (ai < vd.attributes_len) {
            aprint(" #[%s]", .{ vd.attributes[ai].name != (i8*)0 ? vd.attributes[ai].name : "" });
            ai = ai + 1;
        }
    }
    aprint(")\n", .{});
} else if (k == 14) { // func_decl
    let mut fd: *parser.func_decl= (parser.func_decl*)node;
    if (fd.attributes_len > 0) {
        let mut ai: i32= 0;
        while (ai < fd.attributes_len) {
            print_indent(depth);
            aprint("#[%s]\n", .{ fd.attributes[ai].name != (i8*)0 ? fd.attributes[ai].name : "" });
            ai = ai + 1;
        }
    }
    aprint("(fn %s(", .{ fd.name != (i8*)0 ? fd.name : "_" });
    let mut pi: i32= 0;
    while (pi < fd.params_len) {
        if (pi > 0) { aprint(", ", .{}); }
        aprint("%s: ", .{ fd.params[pi].name != (i8*)0 ? fd.params[pi].name : "_" });
        print_type(fd.params[pi].type);
        pi = pi + 1;
    }
    if (fd.is_variadic) { if (fd.params_len > 0) { aprint(", ", .{}); } aprint("...", .{}); }
    aprint(") -> ", .{});
    print_type(fd.ret_type);
    if (fd.has_body) {
        aprint("\n", .{});
        print_block((parser.block_stmt*)fd.body, depth + 1);
        print_indent(depth); aprint(")\n", .{});
    } else {
        aprint(")  // extern\n", .{});
    }
} else if (k == 20) { // namespace_decl
    let mut nd: *parser.namespace_decl= (parser.namespace_decl*)node;
    aprint("(namespace %s\n", .{ nd.name != (i8*)0 ? nd.name : "_" });
    let mut di: i32= 0;
    while (di < nd.decls_len) {
        print_stmt(nd.decls[di], depth + 1);
        di = di + 1;
    }
    print_indent(depth); aprint(")\n", .{});
} else if (k == 15) { // struct_decl
    let mut sd: *parser.struct_decl= (parser.struct_decl*)node;
    aprint("(struct %s\n", .{ sd.name != (i8*)0 ? sd.name : "_" });
    let mut fi: i32= 0;
    while (fi < sd.fields_len) {
        print_indent(depth + 1);
        let mut _f: *parser.var_decl= sd.fields[fi];
        aprint("%s: ", .{ _f.name != (i8*)0 ? _f.name : "_" });
        print_type(_f.type);
        aprint("\n", .{});
        fi = fi + 1;
    }
    print_indent(depth); aprint(")\n", .{});
} else if (k == 17) { // enum_decl
    let mut ed: *parser.enum_decl= (parser.enum_decl*)node;
    aprint("(enum %s\n", .{ ed.name != (i8*)0 ? ed.name : "_" });
    let mut vi: i32= 0;
    while (vi < ed.variants_len) {
        print_indent(depth + 1);
        aprint("%s", .{ ed.variant_names[vi] != (i8*)0 ? ed.variant_names[vi] : "_" });
        if (ed.variant_has_val[vi]) { aprint(" = %ld", .{ ed.variant_vals[vi] }); }
        aprint("\n", .{});
        vi = vi + 1;
    }
    print_indent(depth); aprint(")\n", .{});
} else if (k == 19) { // typedef_decl
    let mut td: *parser.typedef_decl= (parser.typedef_decl*)node;
    aprint("(typedef %s = ", .{ td.name != (i8*)0 ? td.name : "_" });
    print_type(td.target);
    aprint(")\n", .{});
} else {
        // Treat as expression statement
    let mut ne: *parser.expr_node= (parser.expr_node*)node;
    aprint("(expr-stmt ", .{});
    print_expr(ne, depth);
    aprint(")\n", .{});
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
aprint("; Artemis AST dump\n", .{});
aprint("(program\n", .{});
let mut i: i32= 0;
while (i < prog.decls_len) {
    print_stmt(prog.decls[i], 1);
    i = i + 1;
}
aprint(")\n", .{});
}

} // namespace ast
