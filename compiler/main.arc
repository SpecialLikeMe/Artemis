// Artemis self-hosting compiler driver.
// This is the main entry point for the bootstrap compiler.
// It mirrors the existing C++ compiler driver in src/main.cpp.

@include <bind/llvm.arc>
@include <alloc.arc>
@include <preproc.arc>
@include <lexer/main.arc>
@include <parser/expr.arc>
@include <parser/main.arc>
@include <diagnostics.arc>
@include <analysis/scope.arc>
@include <analysis/types.arc>
@include <analysis/main.arc>
@include <smt/main.arc>
@include <ir/context.arc>
@include <ir/types.arc>
@include <ir/names.arc>
@include <ir/exprs.arc>
@include <ir/stmts.arc>
@include <ir/decls.arc>
@include <ir/main.arc>
@include <mir/main.arc>
@include <mir/lower.arc>
@include <lir/main.arc>
@include <lir/lower.arc>
@include <ast/print.arc>
@include <macro/exec.arc>

// ---- CLI options ----

struct cli_opts {
    let input: *i8;
    let output: *i8;
    let opt_level: i32;
    let emit_ir: bool;
    let emit_obj: bool;
    let emit_ast: bool;
    let emit_asm: bool;
    let no_link: bool;
    let verbose: bool;
    let use_mir: bool;
    let unsafe_unit: bool;  // --unsafe: whole TU is an unsafe context
    let emit_mir: bool;
    let emit_lir: bool;
    let stdlib_path: *i8;
    let target: *i8;
    let no_std: bool;
}

fn cli_opts_init(opts: *cli_opts) void {
    opts.input       = (i8*)0;
    opts.output      = (i8*)0;
    opts.opt_level   = 0;
    opts.emit_ir     = false;
    opts.emit_obj    = false;
    opts.emit_ast    = false;
    opts.emit_asm    = false;
    opts.no_link     = false;
    opts.verbose     = false;
    opts.use_mir     = false;
    opts.unsafe_unit = false;
    opts.emit_mir    = false;
    opts.emit_lir    = false;
    opts.stdlib_path = (i8*)0;
    opts.target      = (i8*)0;
    opts.no_std      = false;
}

// Parse command line arguments.
fn parse_args(opts: *cli_opts, argc: i32, argv: **i8) bool {
    let mut i: i32= 1;
    while (i < argc) {
        let mut arg: *i8= argv[i];
        if (strcmp(arg, "-o") == 0) {
            i = i + 1;
            if (i >= argc) {
                printf("error: -o requires an argument\n");
                return false;
            }
            opts.output = argv[i];
        } else if (strcmp(arg, "-S") == 0) {
            opts.emit_ir = true;
        } else if (strcmp(arg, "-c") == 0) {
            opts.emit_obj = true;
            opts.no_link  = true;
        } else if (strcmp(arg, "--emit-ir") == 0) {
            opts.emit_ir = true;
        } else if (strcmp(arg, "--emit-asm") == 0) {
            opts.emit_asm = true;
        } else if (strcmp(arg, "--emit-ast") == 0) {
            opts.emit_ast = true;
        } else if (strcmp(arg, "--target") == 0) {
            i = i + 1;
            if (i >= argc) {
                printf("error: --target requires an argument\n");
                return false;
            }
            opts.target = argv[i];
        } else if (strcmp(arg, "--no-std") == 0) {
            opts.no_std = true;
        } else if (strcmp(arg, "-O0") == 0) {
            opts.opt_level = 0;
        } else if (strcmp(arg, "-O1") == 0) {
            opts.opt_level = 1;
        } else if (strcmp(arg, "-O2") == 0) {
            opts.opt_level = 2;
        } else if (strcmp(arg, "-O3") == 0) {
            opts.opt_level = 3;
        } else if (strcmp(arg, "-v") == 0) {
            opts.verbose = true;
        } else if (strcmp(arg, "--unsafe") == 0) {
            // Treat the whole translation unit as an unsafe context, so calls to
            // @unsafe functions need no per-site annotation. Intended for low-level
            // code written directly against C/FFI — the compiler's own source is
            // built this way, since libc and the LLVM C API are its base vocabulary
            // and wrapping ~2600 call sites would obscure more than it documents.
            opts.unsafe_unit = true;
        } else if (strcmp(arg, "--use-mir") == 0) {
            opts.use_mir = true;
        } else if (strcmp(arg, "--emit-mir") == 0) {
            opts.use_mir = true; opts.emit_mir = true;
        } else if (strcmp(arg, "--emit-lir") == 0) {
            opts.use_mir = true; opts.emit_lir = true;
        } else if (strcmp(arg, "-I") == 0) {
            i = i + 1;
            if (i < argc && opts.stdlib_path == (i8*)0) {
                opts.stdlib_path = argv[i];
            }
        } else if (arg[0] == '-' && arg[1] == 'I') {
            if (opts.stdlib_path == (i8*)0) { opts.stdlib_path = arg + 2; }
        } else if (strcmp(arg, "--help") == 0 || strcmp(arg, "-h") == 0) {
            printf("Usage: artemis <input.arc> [options]\n");
            printf("\nOptions:\n");
            printf("  -o <file>        Set output file path\n");
            printf("  -S               Emit LLVM IR (.ll)\n");
            printf("  -c               Compile to object file (.o)\n");
            printf("  --emit-ir        Emit LLVM IR (.ll)\n");
            printf("  --emit-asm       Emit native assembly (.s)\n");
            printf("  --emit-ast       Emit AST text and stop\n");
            printf("  -O0/-O1/-O2/-O3  Set optimization level\n");
            printf("  -I <path>        Set stdlib include path\n");
            printf("  --no-std         Skip stdlib auto-detection\n");
            printf("  --unsafe         Treat the whole file as an unsafe context (FFI-heavy code)\n");
            printf("  --target <t>     Set target triple (e.g. x86_64-pc-linux-gnu)\n");
            printf("  -v               Verbose output\n");
            printf("  --use-mir        Run the MIR/LIR pipeline\n");
            printf("  --emit-mir       Emit MIR text and stop\n");
            printf("  --emit-lir       Emit LIR text and stop\n");
            printf("  --version        Print compiler version\n");
            printf("  --help           Print this help\n");
            return false;
        } else if (strcmp(arg, "--version") == 0) {
            printf("artemis 0.1.0 (self-hosted Arc compiler)\n");
            return false;
        } else if (arg[0] != '-') {
            // Input file
            if (opts.input != (i8*)0) {
                printf("error: multiple input files not supported\n");
                return false;
            }
            opts.input = arg;
        } else {
            printf("warning: unknown flag '%s' (ignored)\n", arg);
        }
        i = i + 1;
    }
    if (opts.input == (i8*)0) {
        printf("usage: artemis <input.arc> [-S] [-o <output>] [-O0..O3] [-I <stdlib>]\n");
        printf("       artemis --help  for full options\n");
        return false;
    }
    return true;
}

// Read a file into a heap-allocated buffer. Returns null on failure.
fn read_file(path: *i8, out_len: *u64) *i8 {
    let mut fp: *void= fopen(path, "rb");
    if (fp == (void*)0) {
        printf("error: cannot open '%s'\n", path);
        return (i8*)0;
    }
    fseek(fp, (i64)0, 2);
    let mut sz: i64= ftell(fp);
    fseek(fp, (i64)0, 0);
    if (sz < 0) {
        fclose(fp);
        return (i8*)0;
    }
    let mut buf: *i8= (i8*)arc_malloc((u64)(sz + 1));
    let mut n: u64= fread((void*)buf, (u64)1, (u64)sz, fp);
    buf[n]  = 0;
    fclose(fp);
    if (out_len != (u64*)0) { *out_len = n; }
    return buf;
}

// Build default output path from input path, replacing extension.
fn default_output_path(input: *i8, ext: *i8) *i8 {
    let mut buf: [1024]i8;
    let mut last_dot: i32= -1;
    let mut i: i32= 0;
    while (input[i] != 0) {
        if (input[i] == '.') { last_dot = i; }
        i = i + 1;
    }
    if (last_dot < 0) { last_dot = i; }
    let mut j: i32= 0;
    while (j < last_dot) {
        buf[j] = input[j];
        j = j + 1;
    }
    buf[j] = 0;
    let mut result: [1024]i8;
    snprintf(result, (u64)1024, "%s%s", buf, ext);
    return lexer.str_dup(result);
}

// Run LLVM optimizations using PassBuilder.
fn run_opt_passes(llvm_mod: *i8, tm: *i8, opt_level: i32) void {
    if (opt_level <= 0) { return; }

    let mut opts: *i8= LLVMCreatePassBuilderOptions();
    let mut pass_name: [32]i8;
    if (opt_level == 1) { snprintf(pass_name, (u64)32, "O1"); }
    else if (opt_level == 2) { snprintf(pass_name, (u64)32, "O2"); }
    else { snprintf(pass_name, (u64)32, "O3"); }

    let mut err: *i8= LLVMRunPasses(llvm_mod, pass_name, tm, opts);
    if (err != (i8*)0) {
        let mut msg: *i8= LLVMGetErrorMessage(err);
        printf("warning: optimization failed: %s\n", msg);
        LLVMDisposeErrorMessage(msg);
        LLVMConsumeError(err);
    }
    LLVMDisposePassBuilderOptions(opts);
}

// Main entry point.
pub fn main(argc: i32, argv: **i8) i32 {
    let mut opts: cli_opts;
    cli_opts_init(&opts);

    if (!parse_args(&opts, argc, argv)) {
        return 1;
    }

    // Auto-detect stdlib path when -I was not provided (unless --no-std).
    if (opts.stdlib_path == (i8*)0 && !opts.no_std) {
        let mut exe_buf: [2048]i8;
        let mut auto_found: bool= false;
        // On Windows use GetModuleFileNameA to find the exe directory.
        let mut exe_n: i32= GetModuleFileNameA((void*)0, exe_buf, 2047u);
        if (exe_n > 0) {
            // Strip filename, leaving directory with trailing separator
            let mut ei: i32= exe_n - 1;
            while (ei >= 0 && exe_buf[ei] != '/' && exe_buf[ei] != '\\') { ei = ei - 1; }
            if (ei >= 0) {
                // Probe a known file inside the candidate directory (fopen on a directory fails on Windows).
                // Try <exedir>/../compiler/std/include (dev build: exe in build/, stdlib in compiler/)
                let mut try1: [2048]i8;
                snprintf(try1, 2048u, "%.*s/../compiler/std/include", ei, exe_buf);
                let mut try1_probe: [2048]i8;
                snprintf(try1_probe, 2048u, "%s/fmt.arc", try1);
                let mut fp1: *void= fopen(try1_probe, "r");
                if (fp1 != (void*)0) { fclose(fp1); opts.stdlib_path = lexer.str_dup(try1); auto_found = true; }
                if (!auto_found) {
                    // Try <exedir>/std/include (installed build)
                    let mut try2: [2048]i8;
                    snprintf(try2, 2048u, "%.*s/std/include", ei, exe_buf);
                    let mut try2_probe: [2048]i8;
                    snprintf(try2_probe, 2048u, "%s/fmt.arc", try2);
                    let mut fp2: *void= fopen(try2_probe, "r");
                    if (fp2 != (void*)0) { fclose(fp2); opts.stdlib_path = lexer.str_dup(try2); auto_found = true; }
                }
            }
        }
        if (!auto_found) {
            // Fallback: try compiler/std/include relative to CWD
            let mut fp3: *void= fopen("compiler/std/include/fmt.arc", "r");
            if (fp3 != (void*)0) { fclose(fp3); opts.stdlib_path = "compiler/std/include"; }
        }
    }

    // Read the input file
    let mut src_len: u64= 0;
    let mut src: *i8= read_file(opts.input, &src_len);
    if (src == (i8*)0) {
        return 1;
    }

    if (opts.verbose) {
        printf("artemis_boot: compiling '%s'\n", opts.input);
    }

    // Inject compiler/builtin/struct.arc as a preamble so builtin types
    // (type_info, __vtable__, memstr, …) are visible to the parser and analyzer
    // without any @include.
    if (!opts.no_std) {
        let mut bsrc: *i8= (i8*)0;
        let mut blen: u64= 0;
        if (opts.stdlib_path != (i8*)0) {
            let mut bpath: [2048]i8;
            snprintf(bpath, 2048u, "%s/../../builtin/struct.arc", opts.stdlib_path);
            bsrc = read_file(bpath, &blen);
        }
        if (bsrc == (i8*)0) {
            bsrc = read_file("compiler/builtin/struct.arc", &blen);
        }
        if (bsrc != (i8*)0) {
            let mut clen: u64= blen + (u64)1 + src_len;
            let mut combined: *i8= (i8*)arc_malloc(clen + (u64)1);
            memcpy(combined, bsrc, blen);
            combined[blen] = '\n';
            memcpy(combined + blen + (u64)1, src, src_len);
            combined[clen] = 0;
            arc_free(bsrc);
            arc_free(src);
            src = combined;
            src_len = clen;
        }
    }

    // Preprocess
    let mut pp_src: *i8= preproc.preprocess(src, opts.input, opts.stdlib_path);

    // Lex
    let mut lxr: lexer.lexer_t;
    let mut pp_len: u64= (u64)strlen(pp_src);
    lxr.init(pp_src, pp_len);
    let mut toks: lexer.token_vec= lxr.tokenize();

    // Parse
    let mut prs: parser.parser_t;
    prs.init(toks.data, toks.len);
    prs.import_src_path    = opts.input;
    prs.import_stdlib_path = opts.stdlib_path;
    let mut prog: *parser.program_node= prs.parse();

    if (prs.had_parse_error) {
        printf("error: parsing failed\n");
        arc_free(src);
        return 1;
    }

    // Proc macro expansion pre-pass: expand #[name] and #derive[name] attributes.
    // Must run before analysis so that injected declarations are visible to the analyzer.
    let mut macro_new_decls: **parser.ast_node= (parser.ast_node**)arc_malloc(sizeof(i8*) * (u64)256);
    let mut macro_new_len: i32= 0;
    let mut mpi: i32= 0;
    while (mpi < prog.decls_len) {
        let mut mpd: *parser.ast_node= prog.decls[mpi];
        let mut mp_attrs: *parser.proc_attr= (parser.proc_attr*)0;
        let mut mp_attrs_len: i32= 0;
        if (mpd != (parser.ast_node*)0) {
            if (mpd.kind == 14) { // nd_func_decl
                let mut mpfd: *parser.func_decl= (parser.func_decl*)mpd;
                mp_attrs = mpfd.attributes;
                mp_attrs_len = mpfd.attributes_len;
            } else if (mpd.kind == 20) { // nd_namespace_decl
                let mut mpns: *parser.namespace_decl= (parser.namespace_decl*)mpd;
                mp_attrs = mpns.attributes;
                mp_attrs_len = mpns.attributes_len;
            } else if (mpd.kind == 13) { // nd_var_decl
                let mut mpvd: *parser.var_decl= (parser.var_decl*)mpd;
                mp_attrs = mpvd.attributes;
                mp_attrs_len = mpvd.attributes_len;
            }
        }
        let mut mai: i32= 0;
        while (mai < mp_attrs_len && mp_attrs != (parser.proc_attr*)0) {
            let mut mattr: *parser.proc_attr= &mp_attrs[mai];
            if (mattr.name != (i8*)0) {
                let mut expanded_prog: *parser.program_node= (parser.program_node*)0;
                let mut ok: bool= macro_exec.try_exec_macro(mattr.name, mpd, prog,
                                                             opts.stdlib_path, &expanded_prog);
                if (ok && expanded_prog != (parser.program_node*)0 && macro_new_len < 256) {
                    let mut ei: i32= 0;
                    while (ei < expanded_prog.decls_len && macro_new_len < 256) {
                        macro_new_decls[macro_new_len] = expanded_prog.decls[ei];
                        macro_new_len = macro_new_len + 1;
                        ei = ei + 1;
                    }
                }
            }
            mai = mai + 1;
        }
        mpi = mpi + 1;
    }
    if (macro_new_len > 0) {
        let mut old_len: i32= prog.decls_len;
        let mut new_cap: i32= old_len + macro_new_len;
        let mut new_decls: **parser.ast_node= (parser.ast_node**)arc_malloc(sizeof(i8*) * (u64)new_cap);
        let mut ci: i32= 0;
        while (ci < old_len) { new_decls[ci] = prog.decls[ci]; ci = ci + 1; }
        let mut cj: i32= 0;
        while (cj < macro_new_len) { new_decls[old_len + cj] = macro_new_decls[cj]; cj = cj + 1; }
        prog.decls = new_decls;
        prog.decls_len = new_cap;
    }
    arc_free((i8*)macro_new_decls);

    // Analysis (runs after macro expansion so injected decls are visible)
    let mut ana_errs: i32= analysis.analyze_unsafe(prog, opts.unsafe_unit);
    let mut smt_errs: i32= smt.smt_analyze(prog);
    if (ana_errs > 0 || smt_errs > 0) {
        arc_free(src);
        return 1;
    }

    // --emit-ast: print AST and exit
    if (opts.emit_ast) {
        ast.print_program(prog, opts.output);
        arc_free(src);
        return 0;
    }

    // Optional MIR → LIR pipeline (gated behind --use-mir)
    if (opts.use_mir) {
        let mut mir_mod: *mir.mir_module= mir.lower_program((i8*)prog);
        let mut lir_mod: *lir.lir_module= lir.lower_mir(mir_mod);
        if (opts.emit_mir) {
            let mut mfp: *void= (opts.output != (i8*)0) ? fopen(opts.output, "w") : (void*)0;
            mir.mir_print_module(mir_mod, mfp != (void*)0 ? mfp : stdout_file());
            if (mfp != (void*)0) { fclose(mfp); }
        }
        if (opts.emit_lir) {
            let mut lfp: *void= (opts.output != (i8*)0) ? fopen(opts.output, "w") : (void*)0;
            lir.lir_print_module(lir_mod, lfp != (void*)0 ? lfp : stdout_file());
            if (lfp != (void*)0) { fclose(lfp); }
        }
        mir.mir_module_free(mir_mod);
        lir.lir_module_free(lir_mod);
        if (opts.emit_mir || opts.emit_lir) {
            arc_free(src);
            return 0;
        }
    }

    // IR generation
    let mut module_name: *i8= opts.input != (i8*)0 ? opts.input : "artemis_boot";
    let mut llvm_mod: *i8= ir.ir_main(prog, module_name);
    if (llvm_mod == (i8*)0) {
        printf("error: IR generation failed\n");
        arc_free(src);
        return 1;
    }

    // Determine output path
    let mut output: *i8= opts.output;
    if (output == (i8*)0) {
        if (opts.emit_ir) {
            output = default_output_path(opts.input, ".ll");
        } else if (opts.emit_asm) {
            output = default_output_path(opts.input, ".s");
        } else if (opts.emit_obj) {
            output = default_output_path(opts.input, ".o");
        } else {
            output = default_output_path(opts.input, "");
        }
    }

    // Initialize LLVM targets (via shim functions in llvm_init.c)
    LLVMInitializeAllTargetInfos_shim();
    LLVMInitializeAllTargets_shim();
    LLVMInitializeAllTargetMCs_shim();
    LLVMInitializeAllAsmPrinters_shim();
    LLVMInitializeAllAsmParsers_shim();

    // Get target triple (use --target override if provided)
    let mut triple: *i8;
    let mut triple_needs_free: bool= false;
    if (opts.target != (i8*)0) {
        triple = opts.target;
    } else {
        triple = LLVMGetDefaultTargetTriple();
        triple_needs_free = true;
    }
    LLVMSetTarget(llvm_mod, triple);

    // Create target machine
    let mut target_ref: *i8= (i8*)0;
    let mut err_msg: *i8= (i8*)0;
    let mut rc: i32= LLVMGetTargetFromTriple(triple, &target_ref, &err_msg);
    if (rc != 0) {
        printf("error: cannot find target for '%s': %s\n", triple, err_msg);
        LLVMDisposeMessage(err_msg);
        if (triple_needs_free) { LLVMDisposeMessage(triple); }
        LLVMDisposeModule(llvm_mod);
        arc_free(src);
        return 1;
    }

    let mut opt_lvl: i32= LLVMCodeGenLevelNone;
    if (opts.opt_level == 1) { opt_lvl = LLVMCodeGenLevelLess; }
    if (opts.opt_level == 2) { opt_lvl = LLVMCodeGenLevelDefault; }
    if (opts.opt_level >= 3) { opt_lvl = LLVMCodeGenLevelAggressive; }

    // Use host CPU name and features so target-specific instructions (e.g. F16C
    // for half-precision float) are available when compiling for the native host.
    let mut host_cpu: *i8= LLVMGetHostCPUName();
    let mut host_features: *i8= LLVMGetHostCPUFeatures();
    let mut tm: *i8= LLVMCreateTargetMachine(target_ref, triple,
                                     host_cpu != (i8*)0 ? host_cpu : "",
                                     host_features != (i8*)0 ? host_features : "",
                                     opt_lvl, LLVMRelocDefault, 0);
    if (host_cpu != (i8*)0) { LLVMDisposeMessage(host_cpu); }
    if (host_features != (i8*)0) { LLVMDisposeMessage(host_features); }
    if (triple_needs_free) { LLVMDisposeMessage(triple); }

    if (tm != (i8*)0) {
        let mut td: *i8= LLVMCreateTargetDataLayout(tm);
        if (td != (i8*)0) {
            let mut dl_str: *i8= LLVMCopyStringRepOfTargetData(td);
            if (dl_str != (i8*)0) {
                LLVMSetDataLayout(llvm_mod, dl_str);
                LLVMDisposeMessage(dl_str);
            }
            LLVMDisposeTargetData(td);
        }

        // Optimize
        if (opts.opt_level > 0) {
            run_opt_passes(llvm_mod, tm, opts.opt_level);
        }
    }

    // Verify module — hard error: malformed IR must not be codegen'd
    let mut verify_err: *i8= (i8*)0;
    let mut verify_rc: i32= LLVMVerifyModule(llvm_mod, LLVMReturnStatusAction, &verify_err);
    if (verify_rc != 0) {
        if (verify_err != (i8*)0) {
            printf("error: module verification failed:\n%s\n", verify_err);
            LLVMDisposeMessage(verify_err);
        } else {
            printf("error: module verification failed (no details)\n");
        }
        if (tm != (i8*)0) { LLVMDisposeTargetMachine(tm); }
        LLVMDisposeModule(llvm_mod);
        arc_free(src);
        return 1;
    }

    // Emit output
    if (opts.emit_ir) {
        // Write LLVM IR text
        let mut write_err: *i8= (i8*)0;
        let mut write_rc: i32= LLVMPrintModuleToFile(llvm_mod, output, &write_err);
        if (write_rc != 0) {
            printf("error: cannot write IR to '%s': %s\n", output, write_err);
            LLVMDisposeMessage(write_err);
            if (tm != (i8*)0) { LLVMDisposeTargetMachine(tm); }
            LLVMDisposeModule(llvm_mod);
            arc_free(src);
            return 1;
        }
    } else if (opts.emit_asm) {
        // Write native assembly
        if (tm == (i8*)0) {
            printf("error: cannot emit assembly: no target machine\n");
            LLVMDisposeModule(llvm_mod);
            arc_free(src);
            return 1;
        }
        let mut emit_err: *i8= (i8*)0;
        let mut emit_rc: i32= LLVMTargetMachineEmitToFile(tm, llvm_mod, output,
                                                    LLVMAssemblyFile, &emit_err);
        if (emit_rc != 0) {
            printf("error: cannot emit assembly to '%s': %s\n", output, emit_err);
            LLVMDisposeMessage(emit_err);
            LLVMDisposeTargetMachine(tm);
            LLVMDisposeModule(llvm_mod);
            arc_free(src);
            return 1;
        }
    } else if (opts.emit_obj) {
        if (tm == (i8*)0) {
            printf("error: cannot emit object file: no target machine\n");
            LLVMDisposeModule(llvm_mod);
            arc_free(src);
            return 1;
        }
        let mut emit_err: *i8= (i8*)0;
        let mut emit_rc: i32= LLVMTargetMachineEmitToFile(tm, llvm_mod, output,
                                                    LLVMObjectFile, &emit_err);
        if (emit_rc != 0) {
            printf("error: cannot emit object to '%s': %s\n", output, emit_err);
            LLVMDisposeMessage(emit_err);
            LLVMDisposeTargetMachine(tm);
            LLVMDisposeModule(llvm_mod);
            arc_free(src);
            return 1;
        }
    } else {
        // Default: compile to object then link into executable.
        if (tm == (i8*)0) {
            printf("error: cannot link: no target machine\n");
            LLVMDisposeModule(llvm_mod);
            arc_free(src);
            return 1;
        }
        // Build temp object path alongside the output.
        let mut tmp_obj: [2048]i8;
        snprintf(tmp_obj, (u64)2048, "%s.tmp.o", output);

        let mut emit_err: *i8= (i8*)0;
        let mut emit_rc: i32= LLVMTargetMachineEmitToFile(tm, llvm_mod,
                                                    tmp_obj,
                                                    LLVMObjectFile, &emit_err);
        if (emit_rc != 0) {
            printf("error: cannot emit object to '%s': %s\n", tmp_obj, emit_err);
            LLVMDisposeMessage(emit_err);
            if (tm != (i8*)0) { LLVMDisposeTargetMachine(tm); }
            LLVMDisposeModule(llvm_mod);
            arc_free(src);
            return 1;
        }

        // Invoke system linker.  Use g++ as the driver so it pulls in CRT.
        // On Windows: if output has no .exe extension, append it so the binary is findable.
        let mut link_out: [2048]i8;
        snprintf(link_out, (u64)2048, "%s", output);
@ifdef _WIN32
        let mut out_len: i32= (i32)strlen(link_out);
        let mut has_exe: bool= false;
        if (out_len >= 4) {
            if (link_out[out_len-4] == '.' && (link_out[out_len-3] == 'e' || link_out[out_len-3] == 'E') &&
                (link_out[out_len-2] == 'x' || link_out[out_len-2] == 'X') &&
                (link_out[out_len-1] == 'e' || link_out[out_len-1] == 'E')) {
                has_exe = true;
            }
        }
        if (!has_exe) { snprintf(link_out, (u64)2048, "%s.exe", output); }
@endif
        let mut link_cmd: [4096]i8;
        snprintf(link_cmd, (u64)4096, "g++ \"%s\" -o \"%s\" -lm", tmp_obj, link_out);
        if (opts.verbose) { printf("Link: %s\n", link_cmd); }
        let mut link_rc: i32= system(link_cmd);
        remove(tmp_obj);
        if (link_rc != 0) {
            printf("error: linker failed (exit %d)\n", link_rc);
            if (tm != (i8*)0) { LLVMDisposeTargetMachine(tm); }
            LLVMDisposeModule(llvm_mod);
            arc_free(src);
            return 1;
        }
    }

    if (opts.verbose) {
        printf("artemis_boot: output written to '%s'\n", output);
    }

    // Cleanup
    if (tm != (i8*)0) { LLVMDisposeTargetMachine(tm); }
    LLVMDisposeModule(llvm_mod);
    arc_free(src);

    return 0;
}
