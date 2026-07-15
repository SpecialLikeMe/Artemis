#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <string_view>
#include <fstream>
#include <sstream>
#include <vector>
#include <unordered_set>
#include <stdexcept>
#include <filesystem>

// Compiler pipeline
#include "../compiler/preproc/main.hxx"
#include "../compiler/lexer/main.hxx"
#include "../compiler/parser/main.hxx"
#include "../compiler/analysis/main.hxx"
#include "../compiler/mir/mir.hxx"
#include "../compiler/lir/lir.hxx"
#include "../compiler/smt/smt.hxx"
#include "../compiler/smt/inject.hxx"
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
#  include <windows.h>
#else
#  include <unistd.h>
#endif

static constexpr std::string_view VERSION = "0.1.1";
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
    bool         unsafe      = false;  // --unsafe: skip heap allocator check
    // Preprocessor: -D SYMBOL defines, -I path include dirs
    std::unordered_set<std::string> defines;
    std::vector<std::string>        include_paths;
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
        "  -D <name>          Predefine symbol (for @ifdef/@ifndef)\n"
        "  -I <path>          Add directory to @include search path\n"
        "  -v, --verbose      Verbose output\n"
        "  --version          Print version and exit\n"
        "  -h, --help         Print this message and exit\n");
    (void)prog;
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
        else if (arg == "-D" && i + 1 < argc) { opts.defines.insert(argv[++i]); }
        else if (arg.size() > 2 && arg[0] == '-' && arg[1] == 'D') { opts.defines.insert(std::string(arg.substr(2))); }
        else if (arg == "-I" && i + 1 < argc) { opts.include_paths.push_back(argv[++i]); }
        else if (arg.size() > 2 && arg[0] == '-' && arg[1] == 'I') { opts.include_paths.push_back(std::string(arg.substr(2))); }
        else if (arg == "--unsafe")     { opts.unsafe = true; }
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

// ------------------------------------------------------------------ aciso package import expansion

namespace fs = std::filesystem;

// Scan source for `extern aciso.NAME;` lines; prepend package source files.
static std::string resolve_aciso_imports(const std::string& src) {
    std::string pkg_src;   // package sources to prepend
    std::string main_src;  // original source with imports replaced by comments

    std::istringstream ss(src);
    std::string line;
    while (std::getline(ss, line)) {
        // Trim leading whitespace for matching
        size_t first = line.find_first_not_of(" \t");
        std::string trimmed = (first == std::string::npos) ? "" : line.substr(first);
        // Strip trailing \r (Windows CRLF line endings)
        if (!trimmed.empty() && trimmed.back() == '\r') trimmed.pop_back();

        // Match: extern aciso.NAME;
        const std::string prefix = "extern aciso.";
        if (trimmed.size() > prefix.size() + 1 &&
            trimmed.substr(0, prefix.size()) == prefix &&
            trimmed.back() == ';') {
            std::string pkg_name = trimmed.substr(prefix.size(),
                                                  trimmed.size() - prefix.size() - 1);
            // Strip any trailing whitespace in pkg_name
            pkg_name.erase(pkg_name.find_last_not_of(" \t") + 1);

            fs::path pkg_dir = fs::path("modules") / pkg_name;
            if (!fs::exists(pkg_dir)) {
                fprintf(stderr, "error: Package '%s' not installed. "
                        "Run: aciso install %s <url>\n",
                        pkg_name.c_str(), pkg_name.c_str());
                std::exit(1);
            }
            // Read all .arc files in the package directory (sorted for determinism)
            std::vector<fs::path> arc_files;
            for (auto& entry : fs::directory_iterator(pkg_dir))
                if (entry.path().extension() == ".arc")
                    arc_files.push_back(entry.path());
            std::sort(arc_files.begin(), arc_files.end());
            for (auto& p : arc_files)
                pkg_src += read_file(p.string()) + "\n";

            main_src += "// aciso: imported " + pkg_name + "\n";
        } else {
            main_src += line + "\n";
        }
    }
    return pkg_src + main_src;
}

// ------------------------------------------------------------------ stdlib import expansion

// Resolve `extern std.NAME;` or `extern std.NAME.SUB;` lines.
// Maps to compiler/std/<NAME>.arc or compiler/std/<NAME>/<SUB>.arc.
// The stdlib directory is located relative to the compiler executable.
static std::string resolve_std_imports(const std::string& src) {
    std::string pkg_src;
    std::string main_src;

    // Locate the stdlib directory. Priority order:
    //   1. Build-time embedded path (ARTEMIS_STDLIB_PATH, set by CMake)
    //   2. ARTEMIS_HOME env var (set by installer)
    //   3. Walk up from the compiler executable
    //   4. Walk up from CWD
    fs::path std_root;
#ifdef ARTEMIS_STDLIB_PATH
    {
        fs::path baked(ARTEMIS_STDLIB_PATH);
        if (fs::exists(baked)) std_root = baked;
    }
#endif
    if (std_root.empty()) {
        const char* home = std::getenv("ARTEMIS_HOME");
        if (home) {
            fs::path h(home);
            if (fs::exists(h / "std" / "include"))
                std_root = h / "std" / "include";
            else if (fs::exists(h / "compiler" / "std" / "include"))
                std_root = h / "compiler" / "std" / "include";
        }
    }
    if (std_root.empty()) {
        fs::path exe_dir;
#ifdef _WIN32
        char exe_path[4096] = {};
        GetModuleFileNameA(nullptr, exe_path, sizeof(exe_path));
        exe_dir = fs::path(exe_path).parent_path();
#else
        char exe_path[4096] = {};
        ssize_t nl = readlink("/proc/self/exe", exe_path, sizeof(exe_path) - 1);
        if (nl > 0) { exe_path[nl] = '\0'; exe_dir = fs::path(exe_path).parent_path(); }
#endif
        for (fs::path p = exe_dir; p.has_parent_path() && p != p.parent_path(); p = p.parent_path()) {
            if (fs::exists(p / "compiler" / "std" / "include")) {
                std_root = p / "compiler" / "std" / "include"; break;
            }
        }
    }
    if (std_root.empty()) {
        for (fs::path p = fs::current_path(); p.has_parent_path() && p != p.parent_path(); p = p.parent_path()) {
            if (fs::exists(p / "compiler" / "std" / "include")) {
                std_root = p / "compiler" / "std" / "include"; break;
            }
        }
    }
    if (std_root.empty()) {
        fprintf(stderr, "error: Cannot locate Artemis standard library.\n"
                "  Set ARTEMIS_HOME to the Artemis install directory, or rebuild from source.\n");
    }

    std::unordered_set<std::string> already_included;
    std::istringstream ss(src);
    std::string line;
    while (std::getline(ss, line)) {
        size_t first = line.find_first_not_of(" \t");
        std::string trimmed = (first == std::string::npos) ? "" : line.substr(first);
        // Strip trailing \r (Windows CRLF line endings)
        if (!trimmed.empty() && trimmed.back() == '\r') trimmed.pop_back();

        const std::string prefix = "extern std.";
        if (trimmed.size() > prefix.size() + 1 &&
            trimmed.substr(0, prefix.size()) == prefix &&
            trimmed.back() == ';') {
            // e.g. "extern std.math;" or "extern std.fmt.out.printf;"
            std::string spec = trimmed.substr(prefix.size(),
                                              trimmed.size() - prefix.size() - 1);
            spec.erase(spec.find_last_not_of(" \t") + 1);

            // The first component always maps to a file: std/NAME.arc or std/NAME/NAME.arc
            // We include at the package granularity (top-level name).
            std::string top = spec.substr(0, spec.find('.'));

            // Check for alloc sub-packages: std.alloc.bump → std/alloc/bump.arc
            fs::path arc_path;
            if (spec.find('.') != std::string::npos) {
                std::string sub = spec.substr(spec.find('.') + 1);
                // Replace remaining dots with path separators for deeper nesting
                std::string sub_path_str = sub;
                for (char& c : sub_path_str) if (c == '.') c = '/';
                // Try exact sub-path first
                fs::path candidate = std_root / top / (sub_path_str + ".arc");
                if (fs::exists(candidate)) arc_path = candidate;
            }
            if (arc_path.empty()) {
                // Top-level file: std/math.arc
                fs::path candidate = std_root / (top + ".arc");
                if (fs::exists(candidate)) arc_path = candidate;
            }

            if (arc_path.empty()) {
                fprintf(stderr, "error: Standard library package 'std.%s' not found.\n"
                                "       Expected: %s\n", spec.c_str(),
                        (std_root / (top + ".arc")).string().c_str());
                std::exit(1);
            }

            std::string key = arc_path.string();
            if (!already_included.count(key)) {
                already_included.insert(key);
                pkg_src += read_file(key) + "\n";
            }
            main_src += "// std: imported " + spec + "\n";
        } else {
            main_src += line + "\n";
        }
    }
    return pkg_src + main_src;
}

// ------------------------------------------------------------------ @import resolution

// Expand `const sta X = @import("Y");` into `namespace X { <file contents> }` before parsing.
// For directory imports, looks for Y/import.arc (like Rust's mod.rs).
static std::string resolve_import_stmts(const std::string& src, const std::string& src_path) {
    fs::path src_dir = fs::path(src_path).parent_path();
    if (src_dir.empty()) src_dir = fs::current_path();

    std::string result;
    std::istringstream iss(src);
    std::string line;
    while (std::getline(iss, line)) {
        std::string trimmed = line;
        size_t first = trimmed.find_first_not_of(" \t");
        std::string t = (first == std::string::npos) ? "" : trimmed.substr(first);
        if (!t.empty() && t.back() == '\r') t.pop_back();

        // Match: const [sta] NAME = @import("PATH");
        std::string ns_name, import_path_str;
        bool matched = [&]() -> bool {
            size_t p = 0;
            if (t.substr(p, 5) != "const") return false;
            p += 5;
            while (p < t.size() && (t[p] == ' ' || t[p] == '\t')) p++;
            if (p + 3 <= t.size() && t.substr(p, 3) == "sta") {
                p += 3;
                while (p < t.size() && (t[p] == ' ' || t[p] == '\t')) p++;
            }
            size_t n0 = p;
            while (p < t.size() && (std::isalnum((unsigned char)t[p]) || t[p] == '_')) p++;
            if (p == n0) return false;
            ns_name = t.substr(n0, p - n0);
            while (p < t.size() && (t[p] == ' ' || t[p] == '\t')) p++;
            if (p >= t.size() || t[p] != '=') return false;
            p++;
            while (p < t.size() && (t[p] == ' ' || t[p] == '\t')) p++;
            const std::string prefix = "@import(";
            if (t.substr(p, prefix.size()) != prefix) return false;
            p += prefix.size();
            char q = '"';
            if (p < t.size() && (t[p] == '"' || t[p] == '\'')) { q = t[p]; p++; }
            size_t ps = p;
            while (p < t.size() && t[p] != q && t[p] != ')') p++;
            import_path_str = t.substr(ps, p - ps);
            return !import_path_str.empty();
        }();

        if (matched) {
            fs::path import_path = src_dir / import_path_str;
            std::string file_content;

            if (fs::exists(import_path) && !fs::is_directory(import_path)) {
                file_content = read_file(import_path.string());
            } else if (fs::is_directory(import_path)) {
                fs::path entry = import_path / "import.arc";
                if (!fs::exists(entry))
                    throw std::runtime_error("@import: directory '" + import_path.string() +
                                             "' has no import.arc entry point");
                file_content = read_file(entry.string());
            } else {
                fs::path with_ext = fs::path(import_path.string() + ".arc");
                if (fs::exists(with_ext)) {
                    file_content = read_file(with_ext.string());
                } else {
                    fs::path dir_entry = import_path / "import.arc";
                    if (fs::exists(dir_entry)) {
                        file_content = read_file(dir_entry.string());
                    } else {
                        throw std::runtime_error("@import: cannot find '" + import_path_str +
                                                 "' (tried " + with_ext.string() +
                                                 " and " + dir_entry.string() + ")");
                    }
                }
            }

            result += "namespace " + ns_name + " {\n" + file_content + "\n} // end @import " + ns_name + "\n";
        } else {
            result += line + "\n";
        }
    }
    return result;
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
        src = resolve_import_stmts(src, opts.input);  // @import → namespace wrapping
        src = resolve_aciso_imports(src);
        src = resolve_std_imports(src);
    } catch (const std::exception& e) {
        fprintf(stderr, "%s\n", e.what());
        return 1;
    }

    diag_engine diag(opts.input);

    // ---- preprocess ----
    src = preproc::pr_main(src, opts.input, diag, opts.defines, opts.include_paths);
    if (diag.has_errors()) { diag.finish(); return 1; }

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
    if (par.had_parse_error) {
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
        analyze(prog_ast, opts.unsafe);
    } catch (const std::runtime_error& e) {
        diag.absorb(e);
        diag.finish();
        return 1;
    }

    // ---- safety analysis (MIR → LIR → SMT → inject) ----
    std::unordered_map<expr_node*, check_kind> unsafe_ops;
    try {
        mir_module mir_mod = lower_to_mir(prog_ast);
        lower_to_lir(mir_mod);
        smt_result smt = analyze_module(mir_mod);
        // Temporary ir_context just to receive unsafe_ops; real one is created by ir_main below.
        ir_context tmp_ctx;
        inject_result inj = inject_checks(smt, &tmp_ctx);
        if (!inj.ok) {
            for (auto& err : inj.errors)
                fprintf(stderr, "%s\n", err.message.c_str());
            return 1;
        }
        unsafe_ops = std::move(tmp_ctx.unsafe_ops);
    } catch (const std::exception& ex) {
        // Safety pipeline failure is non-fatal: fall back to unchecked IR generation
        if (opts.verbose)
            fprintf(stderr, "Warning: safety pipeline failed (%s); proceeding without checks\n", ex.what());
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
        mod = ir_main(prog_ast, opts.input.c_str(), &unsafe_ops);
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
