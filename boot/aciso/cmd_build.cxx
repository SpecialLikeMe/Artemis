#include "aciso.hxx"

struct Target {
    std::string name;        // output filename (stem or full name)
    std::string source;      // .arc source file
    std::vector<std::string> types; // output type list
};

static std::vector<Target> parse_targets(const Config& cfg) {
    std::vector<Target> out;
    if (!cfg.data.contains("targets")) return out;

    std::string main_src;
    std::string proj_name = "out";
    if (cfg.data.contains("project")) {
        proj_name = cfg.data["project"].value("name", "out");
        main_src  = cfg.data["project"].value("main", "src/main.arc");
    }

    for (auto& [key, val] : cfg.data["targets"].items()) {
        Target t;
        if (key == "main_f") {
            // main_f = ["dll","exe","so","elf",...]
            t.name   = proj_name;
            t.source = main_src;
            if (val.is_array())
                for (const auto& ty : val) t.types.push_back(ty.get<std::string>());
            else
                t.types.push_back(val.get<std::string>());
        } else {
            // "output.exe" = { source = "...", type = "..." }
            t.name   = key;
            if (val.is_object()) {
                t.source = val.value("source", main_src);
                t.types.push_back(val.value("type", "exe"));
            } else if (val.is_string()) {
                t.source = main_src;
                t.types.push_back(val.get<std::string>());
            }
        }
        out.push_back(t);
    }
    return out;
}

static int compile_one(const std::string& compiler,
                       const std::string& src,
                       const std::string& out_path,
                       const std::string& type,
                       const std::vector<std::string>& syms,
                       bool release) {
    const std::string sym_str = release ? " -D __RELEASE" : symbol_flags(syms);
    ensure_dir(fs::path(out_path).parent_path().string());

    // Temp files sit next to the output so they're on the same filesystem.
    const std::string tmp_obj = out_path + ".tmp.o";
    const std::string tmp_ll  = out_path + ".tmp.ll";

    auto rm_tmps = [&] {
        for (const auto& f : {tmp_obj, tmp_ll})
            if (fs::exists(f)) fs::remove(f);
    };

    auto to_obj = [&]() -> bool {
        return run_cmd("\"" + compiler + "\" -c \"" + src +
                       "\" -o \"" + tmp_obj + "\"" + sym_str) == 0;
    };
    auto to_ll = [&]() -> bool {
        return run_cmd("\"" + compiler + "\" -S \"" + src +
                       "\" -o \"" + tmp_ll + "\"" + sym_str) == 0;
    };

    int ret = 1;

    // ---- native executables ----
    if (type == "exe" || type == "executable" || type == "elf") {
        return run_cmd("\"" + compiler + "\" \"" + src +
                       "\" -o \"" + out_path + "\"" + sym_str);
    }

    // Mach-O executable (.mco)
    // On macOS the native output is already Mach-O; elsewhere cross-compile
    // through LLVM IR and clang (requires osxcross / Apple SDK on PATH).
    if (type == "mco") {
#ifdef __APPLE__
        return run_cmd("\"" + compiler + "\" \"" + src +
                       "\" -o \"" + out_path + "\"" + sym_str);
#else
        if (!to_ll()) { rm_tmps(); return 1; }
        ret = run_cmd("clang --target=x86_64-apple-macosx10.15 "
                      "\"" + tmp_ll + "\" -o \"" + out_path + "\"");
        rm_tmps(); return ret;
#endif
    }

    // ---- IR / intermediate ----
    if (type == "ll") {
        return run_cmd("\"" + compiler + "\" -S \"" + src +
                       "\" -o \"" + out_path + "\"" + sym_str);
    }

    if (type == "bc") {
        // Emit LLVM IR then assemble to bitcode with llvm-as.
        if (!to_ll()) { rm_tmps(); return 1; }
        ret = run_cmd("llvm-as \"" + tmp_ll + "\" -o \"" + out_path + "\"");
        rm_tmps(); return ret;
    }

    if (type == "obj" || type == "o") {
        return run_cmd("\"" + compiler + "\" -c \"" + src +
                       "\" -o \"" + out_path + "\"" + sym_str);
    }

    // ---- shared libraries ----
    if (type == "dll" || type == "so" || type == "dylib") {
        if (!to_obj()) { rm_tmps(); return 1; }
        if (type == "dll")
            ret = run_cmd("clang -shared -o \"" + out_path + "\" \"" + tmp_obj + "\"");
        else if (type == "so")
            ret = run_cmd("clang -shared -fPIC -o \"" + out_path + "\" \"" + tmp_obj + "\"");
        else
            ret = run_cmd("clang -dynamiclib -o \"" + out_path + "\" \"" + tmp_obj + "\"");
        rm_tmps(); return ret;
    }

    // ---- static library ----
    if (type == "static" || type == "a" || type == "lib") {
        if (!to_obj()) { rm_tmps(); return 1; }
#ifdef _WIN32
        ret = run_cmd("lib /OUT:\"" + out_path + "\" \"" + tmp_obj + "\"");
#else
        ret = run_cmd("ar rcs \"" + out_path + "\" \"" + tmp_obj + "\"");
#endif
        rm_tmps(); return ret;
    }

    // ---- WebAssembly (bare) ----
    // Strategy: emit LLVM IR from artemis, then hand off to clang which
    // drives wasm-ld automatically.  This keeps the wasm pipeline self-
    // contained inside LLVM tooling without requiring artemis to know about
    // the wasm target directly.
    if (type == "wasm") {
        if (!to_ll()) { rm_tmps(); return 1; }
        ret = run_cmd(
            "clang --target=wasm32-unknown-unknown -nostdlib "
            "-Wl,--no-entry -Wl,--export-all "
            "-o \"" + out_path + "\" \"" + tmp_ll + "\"");
        rm_tmps(); return ret;
    }

    // ---- WebAssembly System Interface ----
    if (type == "wasi") {
        if (!to_ll()) { rm_tmps(); return 1; }
        ret = run_cmd(
            "clang --target=wasm32-wasi "
            "-o \"" + out_path + "\" \"" + tmp_ll + "\"");
        rm_tmps(); return ret;
    }

    err("unknown output type: " + type);
    return 1;
}

static bool do_build_target(const Target& t, const Config& cfg,
                            const std::string& compiler,
                            const std::vector<std::string>& syms,
                            bool release) {
    std::string out_dir = "build/";
    if (cfg.data.contains("build"))
        out_dir = cfg.data["build"].value("output_dir", "build/");
    ensure_dir(out_dir);

    bool any_fail = false;
    for (const auto& type : t.types) {
        std::string out_name = t.name + output_ext(type);
        // if t.name already has an extension (explicit target), use as-is
        if (fs::path(t.name).has_extension() && t.types.size() == 1)
            out_name = t.name;
        std::string out_path = out_dir + out_name;

        // check cache
        std::string key = cache_key(t.source, type, syms);
        if (!key.empty() && cache_hit(key, out_path)) {
            info("cached: " + out_path);
            continue;
        }

        info("building " + out_path + " [" + type + "] from " + t.source);
        int rc = compile_one(compiler, t.source, out_path, type, syms, release);
        if (rc != 0) {
            err("build failed for " + out_path + " (exit " + std::to_string(rc) + ")");
            any_fail = true;
        } else {
            cache_store(key, out_path);
            ok("built " + out_path);
        }
    }
    return !any_fail;
}

void cmd_build(bool release) {
    Config cfg;
    try { cfg = load_build_config(); } catch (const std::exception& e) { err(e.what()); return; }

    std::string compiler = find_compiler();
    std::vector<std::string> syms = get_symbols(cfg);
    auto targets = parse_targets(cfg);

    if (targets.empty()) {
        // default: build main file to dll, so, dylib
        std::string main_src = "src/main.arc";
        std::string name     = "out";
        if (cfg.data.contains("project")) {
            main_src = cfg.data["project"].value("main", main_src);
            name     = cfg.data["project"].value("name", name);
        }
        Target t; t.name = name; t.source = main_src;
        t.types = {"dll", "so", "dylib"};
        targets.push_back(t);
    }

    bool all_ok = true;
    for (const auto& t : targets)
        if (!do_build_target(t, cfg, compiler, syms, release)) all_ok = false;

    if (all_ok) ok("build complete");
    else        err("build finished with errors");
}

void cmd_sbuild(const std::string& target_name) {
    Config cfg;
    try { cfg = load_build_config(); } catch (const std::exception& e) { err(e.what()); return; }

    auto targets = parse_targets(cfg);
    for (const auto& t : targets) {
        if (t.name == target_name || target_name == t.name + output_ext(t.types.empty()?"":t.types[0])) {
            std::string compiler = find_compiler();
            std::vector<std::string> syms = get_symbols(cfg);
            do_build_target(t, cfg, compiler, syms, false);
            return;
        }
    }
    err("target not found: " + target_name);
}

void cmd_run() {
    Config cfg;
    try { cfg = load_build_config(); } catch (const std::exception& e) { err(e.what()); return; }

    std::string main_src = "src/main.arc";
    std::string name     = "out";
    if (cfg.data.contains("project")) {
        main_src = cfg.data["project"].value("main", main_src);
        name     = cfg.data["project"].value("name", name);
    }

    std::string compiler = find_compiler();
    std::string syms_str = symbol_flags(get_symbols(cfg));
    std::string out_dir  = "build/";
    if (cfg.data.contains("build")) out_dir = cfg.data["build"].value("output_dir", out_dir);
    ensure_dir(out_dir);

#ifdef _WIN32
    std::string exe = out_dir + name + ".exe";
#else
    std::string exe = out_dir + name;
#endif
    std::string build_cmd = "\"" + compiler + "\" \"" + main_src + "\" -o \"" + exe + "\"" + syms_str;
    if (run_cmd(build_cmd) != 0) { err("build failed"); return; }
    ok("built " + exe + ", running...");
    run_cmd("\"" + exe + "\"");
}

void cmd_clean() {
    Config cfg;
    std::string out_dir = "build/";
    try {
        cfg = load_build_config();
        if (cfg.data.contains("build")) out_dir = cfg.data["build"].value("output_dir", out_dir);
    } catch (...) {}

    if (fs::exists(out_dir)) { fs::remove_all(out_dir); ok("removed " + out_dir); }
    else warn("build directory not found: " + out_dir);
}

void cmd_cache() {
    ensure_dir(CACHE_DIR);
    ok("cache directory ready: " + CACHE_DIR);
    info("build targets will be cached automatically on next build");
}

void cmd_uncache() {
    if (fs::exists(CACHE_DIR)) { fs::remove_all(CACHE_DIR); ok("cache cleared"); }
    else warn("no cache found");
}
