#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <string_view>
#include <fstream>
#include <sstream>
#include <vector>
#include <stdexcept>

// Compiler pipeline
#include "../compiler/lexer/main.hxx"
#include "../compiler/parser/main.hxx"
#include "../compiler/analysis/main.hxx"
#include "../compiler/ir/main.hxx"
#include "../compiler/diagnostics.hxx"

// LLVM
#include <llvm-c/Core.h>
#include <llvm-c/Analysis.h>
#include <llvm-c/Target.h>
#include <llvm-c/TargetMachine.h>
#include <llvm-c/BitWriter.h>
#include <llvm-c/Transforms/PassBuilder.h>

#ifdef _WIN32
#  include <io.h>
#else
#  include <unistd.h>
#endif

static constexpr std::string_view VERSION = "0.1.0";
static constexpr size_t MAX_INPUT_BYTES   = 1024 * 1024 * 1024; // 1024 MB

// ------------------------------------------------------------------ CLI

struct cli_opts {
    std::string  input;
    std::string  output;
    std::string  target_triple;
    int          opt_level    = 0;      // 0-3
    bool         emit_ir      = false;  // -S
    bool         emit_obj     = false;  // -c
    bool         emit_ast     = false;  // --emit-ast
    bool         verbose      = false;
    // Platform target flags (atc -l/-w/-m)
    bool         target_linux = false;
    bool         target_win   = false;
    bool         target_mac   = false;
};

static void print_usage(std::string_view prog) {
    fprintf(stdout,
        "Usage:\n"
        "  arc     <file.arc> [options]       Compile (standard alias)\n"
        "  arc run <file.arc>                 Compile and run immediately\n"
        "  arc     <file.arc> -o <output>     Compile to executable (auto target)\n"
        "  arc     <file.arc> -l <output>     Target Linux\n"
        "  arc     <file.arc> -w <output>     Target Windows\n"
        "  arc     <file.arc> -m <output>     Target macOS\n"
        "  artemis <file.arc> [options]       Full compiler (same as arc)\n"
        "  atc     <file.arc> -o <output>     Alias for arc -o\n"
        "  atc run <file.arc>                 Compile and run (alias for arc run)\n"
        "  atx run <file.arc>                 Alias for arc run\n"
        "\n"
        "Options:\n"
        "  -o <file>          Output file (default: a.out)\n"
        "  -S                 Emit LLVM IR (.ll) only\n"
        "  -c                 Emit object file (.o) only\n"
        "  --emit-ast         Print AST to stdout and exit\n"
        "  -O0/-O1/-O2/-O3    Optimisation level (default: -O0)\n"
        "  --target <triple>  LLVM target triple (default: host)\n"
        "  -v, --verbose      Verbose output\n"
        "  --version          Print version and exit\n"
        "  -h, --help         Print this message and exit\n",
        static_cast<int>(prog.size()), prog.data());
}

// Returns false and prints an error if parsing fails.
static bool parse_args(int argc, char** argv, cli_opts& opts,
                       bool is_atc, bool is_atx) {
    if (argc < 2) { print_usage(argv[0]); return false; }

    std::string_view a1 = argv[1];

    if (a1 == "--version") {
        fprintf(stdout, "artemis %.*s\n", static_cast<int>(VERSION.size()), VERSION.data());
        exit(0);
    }
    if (a1 == "-h" || a1 == "--help" || a1 == "help") {
        print_usage(argv[0]);
        exit(0);
    }

    // atx / arc run <file>
    if (is_atx) {
        if (argc < 3 || a1 != "run") {
            fprintf(stderr, "atx/arc: usage: atx run <file.arc>  (or: arc run <file.arc>)\n");
            return false;
        }
        opts.input  = argv[2];
        opts.output = "/tmp/atx_run_out";
        return true;
    }

    int i = 1;
    while (i < argc) {
        std::string_view arg = argv[i];
        if (arg[0] != '-') {
            if (opts.input.empty()) { opts.input = argv[i++]; continue; }
            fprintf(stderr, "Unexpected argument: %s\n", argv[i]);
            return false;
        }
        if (arg == "-o" && i + 1 < argc) { opts.output = argv[++i]; }
        else if (arg == "-S")            { opts.emit_ir  = true; }
        else if (arg == "-c")            { opts.emit_obj = true; }
        else if (arg == "--emit-ast")    { opts.emit_ast = true; }
        else if (arg == "-v" || arg == "--verbose") { opts.verbose = true; }
        else if (arg == "-O0") { opts.opt_level = 0; }
        else if (arg == "-O1") { opts.opt_level = 1; }
        else if (arg == "-O2") { opts.opt_level = 2; }
        else if (arg == "-O3") { opts.opt_level = 3; }
        else if (arg == "--target" && i + 1 < argc) { opts.target_triple = argv[++i]; }
        else if (is_atc && arg == "-l") { opts.target_linux = true; if (i+1<argc) opts.output = argv[++i]; }
        else if (is_atc && arg == "-w") { opts.target_win   = true; if (i+1<argc) opts.output = argv[++i]; }
        else if (is_atc && arg == "-m") { opts.target_mac   = true; if (i+1<argc) opts.output = argv[++i]; }
        else {
            fprintf(stderr, "Unknown flag: %.*s\n", static_cast<int>(arg.size()), arg.data());
            return false;
        }
        ++i;
    }

    if (opts.input.empty()) {
        fprintf(stderr, "No input file specified.\n");
        return false;
    }
    if (opts.output.empty()) {
        opts.output = opts.emit_ir ? "output.ll" : opts.emit_obj ? "output.o" : "a.out";
    }
    return true;
}

// ------------------------------------------------------------------ file I/O

static std::string read_file(const std::string& path) {
    std::ifstream f(path, std::ios::binary | std::ios::ate);
    if (!f) throw std::runtime_error("Cannot open file: " + path);
    auto sz = static_cast<size_t>(f.tellg());
    if (sz > MAX_INPUT_BYTES)
        throw std::runtime_error("Input file too large (max 1024 MB): " + path);
    f.seekg(0);
    std::string src(sz, '\0');
    f.read(src.data(), static_cast<std::streamsize>(sz));
    return src;
}

// ------------------------------------------------------------------ AST printer (--emit-ast)

static void print_indent(int depth) {
    for (int i = 0; i < depth * 2; i++) fputc(' ', stdout);
}

static void print_type(const type_node* t) {
    if (!t) { fputs("<null-type>", stdout); return; }
    if (t->is_const)  fputs("const ", stdout);
    if (t->is_extern) fputs("extern ", stdout);
    if (t->is_primitive) {
        // Simple name via prim value index (just use the known mapping)
        fputs(t->prim ? "prim" : "void", stdout);
    } else {
        fputs(t->name.value_or("<unnamed>").c_str(), stdout);
    }
    for (int i = 0; i < t->pointer_depth; i++) fputc('*', stdout);
}

static void dump_expr(const expr_node* e, int depth);
static void dump_stmt(const ast_node* n, int depth);

static void dump_expr(const expr_node* e, int depth) {
    if (!e) return;
    print_indent(depth);
    switch (e->kind) {
        case expr_kind::int_lit:    fprintf(stdout, "IntLit(%lld)\n", (long long)e->int_val); break;
        case expr_kind::float_lit:  fprintf(stdout, "FloatLit(%g)\n", e->flt_val); break;
        case expr_kind::string_lit: fprintf(stdout, "StrLit(\"%s\")\n", e->str_val.c_str()); break;
        case expr_kind::char_lit:   fprintf(stdout, "CharLit('%s')\n", e->str_val.c_str()); break;
        case expr_kind::bool_lit:   fprintf(stdout, "BoolLit(%s)\n", e->bool_val ? "true" : "false"); break;
        case expr_kind::identifier: fprintf(stdout, "Id(%s)\n", e->str_val.c_str()); break;
        case expr_kind::annotation: fprintf(stdout, "Annotation(@%s)\n", e->str_val.c_str()); break;
        case expr_kind::unary:
            fprintf(stdout, "Unary(op=%d)\n", static_cast<int>(e->uop));
            dump_expr(e->operand, depth + 1);
            break;
        case expr_kind::binary:
            fprintf(stdout, "Binary(op=%d)\n", static_cast<int>(e->bop));
            dump_expr(e->lhs, depth + 1);
            dump_expr(e->rhs, depth + 1);
            break;
        case expr_kind::assign:
            fprintf(stdout, "Assign(op=%d)\n", static_cast<int>(e->bop));
            dump_expr(e->lhs, depth + 1);
            dump_expr(e->rhs, depth + 1);
            break;
        case expr_kind::call:
            fputs("Call\n", stdout);
            dump_expr(e->callee, depth + 1);
            for (auto* a : e->args) dump_expr(a, depth + 1);
            break;
        case expr_kind::subscript:
            fputs("Subscript\n", stdout);
            dump_expr(e->object, depth + 1);
            dump_expr(e->index, depth + 1);
            break;
        case expr_kind::member:
            fprintf(stdout, "Member(.%s)\n", e->member_name.c_str());
            dump_expr(e->object, depth + 1);
            break;
        case expr_kind::cast:
            fputs("Cast(", stdout); print_type(e->cast_type); fputs(")\n", stdout);
            dump_expr(e->operand, depth + 1);
            break;
        case expr_kind::sizeof_e:
            fputs("Sizeof\n", stdout);
            if (e->cast_type) { print_indent(depth + 1); print_type(e->cast_type); fputc('\n', stdout); }
            else dump_expr(e->operand, depth + 1);
            break;
        case expr_kind::ternary:
            fputs("Ternary\n", stdout);
            dump_expr(e->cond,   depth + 1);
            dump_expr(e->then_e, depth + 1);
            dump_expr(e->else_e, depth + 1);
            break;
        default:
            fprintf(stdout, "Expr(kind=%d)\n", static_cast<int>(e->kind));
    }
}

static void dump_stmt(const ast_node* n, int depth) {
    if (!n) return;
    print_indent(depth);
    if (const auto* b = dynamic_cast<const block_stmt*>(n)) {
        fputs("Block\n", stdout);
        for (auto* s : b->stmts) dump_stmt(s, depth + 1);
    } else if (const auto* v = dynamic_cast<const var_decl*>(n)) {
        fprintf(stdout, "VarDecl(%s)\n", v->name.c_str());
        if (v->init.has_value()) dump_expr(v->init.value(), depth + 1);
    } else if (const auto* e = dynamic_cast<const expr_stmt*>(n)) {
        fputs("ExprStmt\n", stdout);
        dump_expr(e->expr, depth + 1);
    } else if (const auto* r = dynamic_cast<const return_stmt*>(n)) {
        fputs("Return\n", stdout);
        if (r->value.has_value()) dump_expr(r->value.value(), depth + 1);
    } else if (const auto* i = dynamic_cast<const if_stmt*>(n)) {
        fputs("If\n", stdout);
        dump_expr(i->cond,      depth + 1);
        dump_stmt(i->then_body, depth + 1);
        if (i->else_body) dump_stmt(i->else_body, depth + 1);
    } else if (const auto* w = dynamic_cast<const while_stmt*>(n)) {
        fputs("While\n", stdout);
        dump_expr(w->cond, depth + 1);
        dump_stmt(w->body, depth + 1);
    } else if (const auto* f = dynamic_cast<const for_stmt*>(n)) {
        fputs("For\n", stdout);
        if (f->init) dump_stmt(f->init, depth + 1);
        if (f->cond) dump_expr(f->cond, depth + 1);
        if (f->step) dump_expr(f->step, depth + 1);
        dump_stmt(f->body, depth + 1);
    } else if (const auto* sw = dynamic_cast<const switch_stmt*>(n)) {
        fputs("Switch\n", stdout);
        dump_expr(sw->subject, depth + 1);
        for (auto& [label, blk] : sw->cases) {
            print_indent(depth + 1);
            fputs(label.has_value() ? "Case\n" : "Default\n", stdout);
            if (label.has_value()) dump_expr(label.value(), depth + 2);
            dump_stmt(blk, depth + 2);
        }
    } else if (dynamic_cast<const break_stmt*>(n)) {
        fputs("Break\n", stdout);
    } else if (dynamic_cast<const continue_stmt*>(n)) {
        fputs("Continue\n", stdout);
    } else if (const auto* as = dynamic_cast<const asm_stmt*>(n)) {
        fputs("Asm\n", stdout);
        print_indent(depth + 1);
        fprintf(stdout, "instructions: %s\n", as->raw_instructions.c_str());
    } else if (const auto* fd = dynamic_cast<const func_decl*>(n)) {
        fprintf(stdout, "FuncDecl(%s)\n", fd->name.c_str());
        if (fd->body) dump_stmt(fd->body, depth + 1);
    } else if (const auto* sd = dynamic_cast<const struct_decl*>(n)) {
        fprintf(stdout, "StructDecl(%s)\n", sd->name.c_str());
    } else {
        fputs("Stmt(?)\n", stdout);
    }
}

static void dump_ast(const program_node* prog) {
    fputs("Program\n", stdout);
    for (const auto* d : prog->decls) dump_stmt(d, 1);
}

// ------------------------------------------------------------------ optimisation

static void run_optimisation(LLVMModuleRef mod, LLVMTargetMachineRef tm, int level) {
    if (level == 0) return;

    const char* passes;
    switch (level) {
        case 1: passes = "default<O1>"; break;
        case 2: passes = "default<O2>"; break;
        default: passes = "default<O3>"; break;
    }

    LLVMPassBuilderOptionsRef opts = LLVMCreatePassBuilderOptions();
    LLVMErrorRef err = LLVMRunPasses(mod, passes, tm, opts);
    if (err) {
        char* msg = LLVMGetErrorMessage(err);
        fprintf(stderr, "Optimisation warning: %s\n", msg);
        LLVMDisposeErrorMessage(msg);
        LLVMConsumeError(err);
    }
    LLVMDisposePassBuilderOptions(opts);
}

// ------------------------------------------------------------------ emission

static int emit_output(LLVMModuleRef mod, const cli_opts& opts,
                        LLVMTargetMachineRef tm, bool verbose) {
    char* llvm_err = nullptr;

    // Verify module before emission.
    if (LLVMVerifyModule(mod, LLVMPrintMessageAction, &llvm_err)) {
        fprintf(stderr, "IR verification failed: %s\n", llvm_err ? llvm_err : "");
        LLVMDisposeMessage(llvm_err);
        return 1;
    }
    LLVMDisposeMessage(llvm_err);
    llvm_err = nullptr;

    if (opts.emit_ir) {
        if (LLVMPrintModuleToFile(mod, opts.output.c_str(), &llvm_err)) {
            fprintf(stderr, "Failed to write IR: %s\n", llvm_err);
            LLVMDisposeMessage(llvm_err);
            return 1;
        }
        if (verbose) fprintf(stdout, "Wrote LLVM IR to %s\n", opts.output.c_str());
        return 0;
    }

    // Emit object file.
    std::string obj_path = opts.emit_obj ? opts.output : opts.output + ".o";
    if (LLVMTargetMachineEmitToFile(tm, mod,
            const_cast<char*>(obj_path.c_str()),
            LLVMObjectFile, &llvm_err)) {
        fprintf(stderr, "Object emission failed: %s\n", llvm_err);
        LLVMDisposeMessage(llvm_err);
        return 1;
    }
    if (verbose) fprintf(stdout, "Wrote object file to %s\n", obj_path.c_str());
    if (opts.emit_obj) return 0;

    // Select linker based on output target.
    std::string linker;
    std::string extra_flags;
    if (opts.target_linux) {
        // Prefer a GNU cross-linker; fall back to clang with explicit target.
        linker      = "x86_64-linux-gnu-gcc";
        extra_flags = "-static-libgcc -static-libstdc++";
    } else if (opts.target_win) {
        linker      = "x86_64-w64-mingw32-gcc";
        extra_flags = "-static-libgcc -static-libstdc++ -static-libwinpthread";
    } else if (opts.target_mac) {
        // Requires osxcross or a macOS SDK with clang targeting apple-macosx.
        linker      = "x86_64-apple-darwin-clang";
        extra_flags = "";
        // Fall back to plain clang with --target if osxcross isn't available.
        if (system("which x86_64-apple-darwin-clang > /dev/null 2>&1") != 0) // NOLINT
            linker = "clang --target=x86_64-apple-macosx10.15";
    } else {
        linker = "cc";
    }

    std::string link_cmd = linker + " " + obj_path + " -o " + opts.output;
    if (!extra_flags.empty()) link_cmd += " " + extra_flags;
    if (verbose) fprintf(stdout, "Linking: %s\n", link_cmd.c_str());
    int rc = system(link_cmd.c_str()); // NOLINT
    if (rc != 0) {
        fprintf(stderr, "Linker failed (exit %d)\n", rc);
        return 1;
    }
    remove(obj_path.c_str());
    if (verbose) fprintf(stdout, "Executable: %s\n", opts.output.c_str());
    return 0;
}

// ------------------------------------------------------------------ main

int main(int argc, char** argv) {
    // Detect invocation alias: arc / atc / atx (arc is the standard alias).
    std::string prog = argv[0];
    bool is_arc = prog.find("arc") != std::string::npos;
    bool is_atc = prog.find("atc") != std::string::npos;
    bool is_atx = prog.find("atx") != std::string::npos;

    // arc run <file>  → behaves as atx; arc <file> [opts]  → behaves as atc
    if (is_arc) {
        bool run_mode = (argc >= 2 && std::string_view(argv[1]) == "run");
        is_atx = run_mode;
        is_atc = !run_mode;
    }
    // atc run <file>  → same as atx run
    if (is_atc && argc >= 2 && std::string_view(argv[1]) == "run") {
        is_atx = true;
        is_atc = false;
    }

    cli_opts opts;
    if (!parse_args(argc, argv, opts, is_atc, is_atx))
        return 1;

    // ---- read source ----
    std::string src;
    try {
        src = read_file(opts.input);
    } catch (const std::exception& e) {
        fprintf(stderr, "%s\n", e.what());
        return 1;
    }

    diag_engine diag(opts.input);

    // ---- lex ----
    std::vector<token_t> tokens;
    try {
        lexer lex(src);
        tokens = lex.tokenize();
    } catch (const std::runtime_error& e) {
        diag.absorb(e);
        diag.finish();
        return 1;
    }

    // ---- parse ----
    // The parser owns all AST node arenas; it must outlive every subsequent
    // stage (analysis, IR gen, AST dump) that holds raw pointers into those arenas.
    parser par(std::move(tokens));
    program_node* prog_ast = nullptr;
    try {
        prog_ast = par.parse();
    } catch (const std::runtime_error& e) {
        diag.absorb(e);
        diag.finish();
        return 1;
    }

    // ---- emit-ast ----
    if (opts.emit_ast) {
        dump_ast(prog_ast);
        return 0;
    }

    // ---- analyse ----
    try {
        analyze(prog_ast);
    } catch (const std::runtime_error& e) {
        diag.absorb(e);
        diag.finish();
        return 1;
    }

    // ---- IR generation ----
    LLVMInitializeNativeTarget();
    LLVMInitializeNativeAsmPrinter();
    LLVMInitializeNativeAsmParser();

    std::string triple;
    if (!opts.target_triple.empty()) {
        triple = opts.target_triple;
    } else if (opts.target_linux) {
        triple = "x86_64-pc-linux-gnu";
    } else if (opts.target_win) {
        triple = "x86_64-pc-windows-msvc";
    } else if (opts.target_mac) {
        triple = "x86_64-apple-macosx10.15.0";
    } else {
        char* def = LLVMGetDefaultTargetTriple();
        triple = def;
        LLVMDisposeMessage(def);
    }

    LLVMTargetRef target_ref;
    char* target_err = nullptr;
    if (LLVMGetTargetFromTriple(triple.c_str(), &target_ref, &target_err)) {
        fprintf(stderr, "Unknown target triple '%s': %s\n", triple.c_str(), target_err);
        LLVMDisposeMessage(target_err);
        return 1;
    }

    LLVMCodeGenOptLevel cg_level;
    switch (opts.opt_level) {
        case 1: cg_level = LLVMCodeGenLevelLess; break;
        case 2: cg_level = LLVMCodeGenLevelDefault; break;
        case 3: cg_level = LLVMCodeGenLevelAggressive; break;
        default: cg_level = LLVMCodeGenLevelNone; break;
    }

    LLVMTargetMachineRef tm = LLVMCreateTargetMachine(
        target_ref, triple.c_str(), "", "",
        cg_level, LLVMRelocPIC, LLVMCodeModelDefault);

    LLVMModuleRef mod;
    try {
        mod = ir_main(prog_ast, opts.input.c_str());
    } catch (const std::runtime_error& e) {
        diag.absorb(e);
        diag.finish();
        LLVMDisposeTargetMachine(tm);
        return 1;
    }

    LLVMSetTarget(mod, triple.c_str());

    // Set data layout from target machine.
    LLVMTargetDataRef dl = LLVMCreateTargetDataLayout(tm);
    char* dl_str = LLVMCopyStringRepOfTargetData(dl);
    LLVMSetDataLayout(mod, dl_str);
    LLVMDisposeMessage(dl_str);
    LLVMDisposeTargetData(dl);

    // ---- optimise ----
    run_optimisation(mod, tm, opts.opt_level);

    // ---- emit ----
    int ret = emit_output(mod, opts, tm, opts.verbose);

    LLVMDisposeModule(mod);
    LLVMDisposeTargetMachine(tm);

    // atx run: execute the output binary.
    if (is_atx && ret == 0) {
        std::string run_cmd = opts.output;
        ret = system(run_cmd.c_str()); // NOLINT
    }

    return ret;
}
