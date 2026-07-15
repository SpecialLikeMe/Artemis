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

// ---- CLI options ----

struct cli_opts {
    i8*  input;
    i8*  output;
    i32  opt_level;
    bool emit_ir;
    bool emit_obj;
    bool emit_ast;
    bool emit_asm;
    bool no_link;
    bool verbose;
    bool is_unsafe;
    bool use_mir;
    i8*  stdlib_path;
}

void cli_opts_init(cli_opts* opts) {
    opts.input       = (i8*)0;
    opts.output      = (i8*)0;
    opts.opt_level   = 0;
    opts.emit_ir     = false;
    opts.emit_obj    = false;
    opts.emit_ast    = false;
    opts.emit_asm    = false;
    opts.no_link     = false;
    opts.verbose     = false;
    opts.is_unsafe   = false;
    opts.use_mir     = false;
    opts.stdlib_path = (i8*)0;
}

// Parse command line arguments.
bool parse_args(cli_opts* opts, i32 argc, i8** argv) {
    i32 i = 1;
    while (i < argc) {
        i8* arg = argv[i];
        if (strcmp(arg, "-o") == 0) {
            i = i + 1;
            if (i >= argc) {
                printf("error: -o requires an argument\n");
                return false;
            }
            opts.output = argv[i];
        } else if (strcmp(arg, "-S") == 0) {
            opts.emit_ir  = true;
            opts.emit_asm = true;
        } else if (strcmp(arg, "-c") == 0) {
            opts.emit_obj = true;
            opts.no_link  = true;
        } else if (strcmp(arg, "--emit-ir") == 0) {
            opts.emit_ir = true;
        } else if (strcmp(arg, "--emit-ast") == 0) {
            opts.emit_ast = true;
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
            opts.is_unsafe = true;
        } else if (strcmp(arg, "--use-mir") == 0) {
            opts.use_mir = true;
        } else if (strcmp(arg, "-I") == 0) {
            i = i + 1;
            if (i < argc && opts.stdlib_path == (i8*)0) {
                opts.stdlib_path = argv[i];
            }
        } else if (arg[0] == '-' && arg[1] == 'I') {
            if (opts.stdlib_path == (i8*)0) { opts.stdlib_path = arg + 2; }
        } else if (arg[0] != '-') {
            // Input file
            if (opts.input != (i8*)0) {
                printf("error: multiple input files not supported\n");
                return false;
            }
            opts.input = arg;
        } else {
            // Unknown flag: skip
        }
        i = i + 1;
    }
    if (opts.input == (i8*)0) {
        printf("usage: artemis_boot <input.arc> [-S] [-o <output>] [-O0..O3]\n");
        return false;
    }
    return true;
}

// Read a file into a heap-allocated buffer. Returns null on failure.
i8* read_file(i8* path, u64* out_len) {
    void* fp = fopen(path, "rb");
    if (fp == (void*)0) {
        printf("error: cannot open '%s'\n", path);
        return (i8*)0;
    }
    fseek(fp, (i64)0, 2);
    i64 sz = ftell(fp);
    fseek(fp, (i64)0, 0);
    if (sz < 0) {
        fclose(fp);
        return (i8*)0;
    }
    i8* buf = (i8*)arc_malloc((u64)(sz + 1));
    u64 n   = fread((void*)buf, (u64)1, (u64)sz, fp);
    buf[n]  = 0;
    fclose(fp);
    if (out_len != (u64*)0) { *out_len = n; }
    return buf;
}

// Build default output path from input path, replacing extension.
i8* default_output_path(i8* input, i8* ext) {
    i8 buf[1024];
    i32 last_dot = -1;
    i32 i = 0;
    while (input[i] != 0) {
        if (input[i] == '.') { last_dot = i; }
        i = i + 1;
    }
    if (last_dot < 0) { last_dot = i; }
    i32 j = 0;
    while (j < last_dot) {
        buf[j] = input[j];
        j = j + 1;
    }
    buf[j] = 0;
    i8 result[1024];
    snprintf(result, (u64)1024, "%s%s", buf, ext);
    return lexer.str_dup(result);
}

// Run LLVM optimizations using PassBuilder.
void run_opt_passes(i8* llvm_mod, i8* tm, i32 opt_level) {
    if (opt_level <= 0) { return; }

    i8* opts = LLVMCreatePassBuilderOptions();
    i8 pass_name[32];
    if (opt_level == 1) { snprintf(pass_name, (u64)32, "O1"); }
    else if (opt_level == 2) { snprintf(pass_name, (u64)32, "O2"); }
    else { snprintf(pass_name, (u64)32, "O3"); }

    i8* err = LLVMRunPasses(llvm_mod, pass_name, tm, opts);
    if (err != (i8*)0) {
        i8* msg = LLVMGetErrorMessage(err);
        printf("warning: optimization failed: %s\n", msg);
        LLVMDisposeErrorMessage(msg);
        LLVMConsumeError(err);
    }
    LLVMDisposePassBuilderOptions(opts);
}

// Main entry point.
i32 main(i32 argc, i8** argv) {
    cli_opts opts;
    cli_opts_init(&opts);

    if (!parse_args(&opts, argc, argv)) {
        return 1;
    }

    // Read the input file
    u64 src_len = 0;
    i8* src = read_file(opts.input, &src_len);
    if (src == (i8*)0) {
        return 1;
    }

    if (opts.verbose) {
        printf("artemis_boot: compiling '%s'\n", opts.input);
    }

    // Preprocess
    i8* pp_src = preproc.preprocess(src, opts.input, opts.stdlib_path);

    // Lex
    lexer.lexer_t lxr;
    u64 pp_len = (u64)strlen(pp_src);
    lxr.init(pp_src, pp_len);
    lexer.token_vec toks = lxr.tokenize();

    // Parse
    parser.parser_t prs;
    prs.init(toks.data, toks.len);
    parser.program_node* prog = prs.parse();

    if (prs.had_parse_error) {
        printf("error: parsing failed\n");
        arc_free(src);
        return 1;
    }

    // Analysis
    i32 ana_errs = analysis.analyze_unsafe(prog, opts.is_unsafe);
    i32 smt_errs = smt.smt_analyze(prog);
    if (ana_errs > 0 || smt_errs > 0) {
        arc_free(src);
        return 1;
    }

    // Optional MIR → LIR pipeline (gated behind --use-mir)
    if (opts.use_mir) {
        mir.mir_module* mir_mod = mir.lower_program((i8*)prog);
        lir.lir_module* lir_mod = lir.lower_mir(mir_mod);
        mir.mir_module_free(mir_mod);
        lir.lir_module_free(lir_mod);
    }

    // IR generation
    i8* module_name = opts.input != (i8*)0 ? opts.input : "artemis_boot";
    i8* llvm_mod = ir.ir_main(prog, module_name);
    if (llvm_mod == (i8*)0) {
        printf("error: IR generation failed\n");
        arc_free(src);
        return 1;
    }

    // Determine output path
    i8* output = opts.output;
    if (output == (i8*)0) {
        if (opts.emit_ir || opts.emit_asm) {
            output = default_output_path(opts.input, ".ll");
        } else if (opts.emit_obj) {
            output = default_output_path(opts.input, ".o");
        } else {
            output = default_output_path(opts.input, ".ll");
        }
    }

    // Initialize LLVM targets (via shim functions in llvm_init.c)
    LLVMInitializeAllTargetInfos_shim();
    LLVMInitializeAllTargets_shim();
    LLVMInitializeAllTargetMCs_shim();
    LLVMInitializeAllAsmPrinters_shim();
    LLVMInitializeAllAsmParsers_shim();

    // Get target triple
    i8* triple = LLVMGetDefaultTargetTriple();
    LLVMSetTarget(llvm_mod, triple);

    // Create target machine
    i8* target_ref = (i8*)0;
    i8* err_msg    = (i8*)0;
    i32 rc = LLVMGetTargetFromTriple(triple, &target_ref, &err_msg);
    if (rc != 0) {
        printf("error: cannot find target for '%s': %s\n", triple, err_msg);
        LLVMDisposeMessage(err_msg);
        LLVMDisposeMessage(triple);
        LLVMDisposeModule(llvm_mod);
        arc_free(src);
        return 1;
    }

    i32 opt_lvl = LLVMCodeGenLevelNone;
    if (opts.opt_level == 1) { opt_lvl = LLVMCodeGenLevelLess; }
    if (opts.opt_level == 2) { opt_lvl = LLVMCodeGenLevelDefault; }
    if (opts.opt_level >= 3) { opt_lvl = LLVMCodeGenLevelAggressive; }

    i8* tm = LLVMCreateTargetMachine(target_ref, triple, "", "",
                                     opt_lvl, LLVMRelocDefault, 0);
    LLVMDisposeMessage(triple);

    if (tm != (i8*)0) {
        i8* td = LLVMCreateTargetDataLayout(tm);
        if (td != (i8*)0) {
            i8* dl_str = LLVMCopyStringRepOfTargetData(td);
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

    // Verify module
    i8* verify_err = (i8*)0;
    i32 verify_rc = LLVMVerifyModule(llvm_mod, LLVMReturnStatusAction, &verify_err);
    if (verify_rc != 0 && verify_err != (i8*)0) {
        printf("warning: module verification: %s\n", verify_err);
        LLVMDisposeMessage(verify_err);
    }

    // Emit output
    if (opts.emit_ir || opts.emit_asm) {
        // Write LLVM IR text
        i8* write_err = (i8*)0;
        i32 write_rc  = LLVMPrintModuleToFile(llvm_mod, output, &write_err);
        if (write_rc != 0) {
            printf("error: cannot write IR to '%s': %s\n", output, write_err);
            LLVMDisposeMessage(write_err);
            if (tm != (i8*)0) { LLVMDisposeTargetMachine(tm); }
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
        i8* emit_err = (i8*)0;
        i32 emit_rc  = LLVMTargetMachineEmitToFile(tm, llvm_mod, output,
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
        i8 tmp_obj[2048];
        snprintf(tmp_obj, (u64)2048, "%s.tmp.o", output);

        i8* emit_err = (i8*)0;
        i32 emit_rc  = LLVMTargetMachineEmitToFile(tm, llvm_mod,
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

        // Invoke system linker.  Use gcc as the driver so it pulls in CRT.
        i8 link_cmd[4096];
        snprintf(link_cmd, (u64)4096, "gcc \"%s\" -o \"%s\" -lm", tmp_obj, output);
        if (opts.verbose) { printf("Link: %s\n", link_cmd); }
        i32 link_rc = system(link_cmd);
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
