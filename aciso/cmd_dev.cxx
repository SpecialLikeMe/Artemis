#include "aciso.hxx"
#include <sstream>

// ---- fmt ----

static std::string format_arc(const std::string& src) {
    // Basic formatter: strip trailing whitespace, normalise blank lines,
    // ensure final newline.
    std::istringstream ss(src);
    std::ostringstream out;
    std::string line;
    int blanks = 0;
    while (std::getline(ss, line)) {
        // strip \r
        if (!line.empty() && line.back() == '\r') line.pop_back();
        // strip trailing spaces/tabs
        while (!line.empty() && (line.back() == ' ' || line.back() == '\t')) line.pop_back();

        if (line.empty()) {
            ++blanks;
            if (blanks <= 1) out << '\n';
        } else {
            blanks = 0;
            out << line << '\n';
        }
    }
    return out.str();
}

static void fmt_file(const std::string& path) {
    std::string orig = read_file_str(path);
    std::string fmtd = format_arc(orig);
    if (fmtd == orig) { info("unchanged: " + path); return; }
    write_file_str(path, fmtd);
    ok("formatted: " + path);
}

void cmd_fmt(const std::string& path) {
    if (path.empty()) {
        // format whole workspace
        Config cfg;
        std::string src_dir = "src/";
        try {
            cfg = load_build_config();
            if (cfg.data.contains("build")) src_dir = cfg.data["build"].value("source_dir", src_dir);
        } catch (...) {}
        for (const auto& f : collect_ext(src_dir, ".arc")) fmt_file(f);
    } else if (fs::is_directory(path)) {
        for (const auto& f : collect_ext(path, ".arc")) fmt_file(f);
    } else {
        fmt_file(path);
    }
}

// ---- sta (static analysis) ----

static void sta_file(const std::string& path, const std::string& compiler,
                     const std::vector<std::string>& syms) {
    std::string flags = symbol_flags(syms);
    // Use --emit-ast to type-check without producing an object file.
    // This avoids Windows path-separator issues with -o and temp files.
    std::string cmd = "\"" + compiler + "\" \"" + path + "\" --emit-ast" + flags + " 2>&1 1>NUL";
    // Fallback: also try -c with a safe temp path
    fs::path tmp_dir = fs::temp_directory_path();
    std::string tmp = tmp_dir.string();
    // Normalize separators so shell doesn't choke
    for (char& c : tmp) if (c == '\\') c = '/';
    tmp += "/aciso_sta_tmp.o";
    std::string cmd2 = "\"" + compiler + "\" -c \"" + path + "\" -o \"" + tmp + "\"" + flags + " 2>&1";

    // Run check-only: use --emit-ast to just parse+analyze, discard output
    std::string check_cmd = "\"" + compiler + "\" \"" + path + "\"" + flags + " --emit-ast 2>&1";
    // Capture stderr (analysis errors) by running with analysis-only flag
    // Artemis writes errors to stderr; redirect stdout away, keep stderr
#ifdef _WIN32
    check_cmd = "\"" + compiler + "\" \"" + path + "\"" + flags + " --emit-ast 2>&1 | more +0";
    // Simpler: just compile to /dev/null equivalent
    check_cmd = "\"" + compiler + "\" \"" + path + "\"" + flags + " -c -o NUL 2>&1";
#else
    check_cmd = "\"" + compiler + "\" \"" + path + "\"" + flags + " -c -o /dev/null 2>&1";
#endif
    std::string output = capture_cmd(check_cmd);
    // Remove any empty lines for cleaner output
    std::string filtered;
    std::istringstream ss(output);
    std::string line;
    while (std::getline(ss, line)) {
        if (!line.empty() && line != "\r")
            filtered += line + "\n";
    }

    if (filtered.empty()) {
        ok("clean: " + path);
    } else {
        std::cout << "\033[31mERRORS\033[0m in \033[1m" << path << "\033[0m:\n" << filtered;
    }
}

void cmd_sta(const std::string& path) {
    Config cfg;
    std::vector<std::string> syms;
    std::string src_dir = "src/";
    std::string compiler = find_compiler();
    try {
        cfg = load_build_config();
        syms    = get_symbols(cfg);
        if (cfg.data.contains("build")) src_dir = cfg.data["build"].value("source_dir", src_dir);
    } catch (...) {}

    if (path.empty()) {
        for (const auto& f : collect_ext(src_dir, ".arc")) sta_file(f, compiler, syms);
    } else if (fs::is_directory(path)) {
        for (const auto& f : collect_ext(path, ".arc")) sta_file(f, compiler, syms);
    } else {
        sta_file(path, compiler, syms);
    }
}

// ---- test ----

void cmd_test() {
    auto files = collect_ext(".", ".arct");
    if (files.empty()) { info("no .arct test files found"); return; }

    std::string compiler = find_compiler();
    std::string tmp_base = (fs::temp_directory_path() / "aciso_test_").string();
    int passed = 0, failed = 0;

    for (const auto& f : files) {
        std::string exe = tmp_base + fs::path(f).stem().string();
#ifdef _WIN32
        exe += ".exe";
#endif
        std::string build_cmd = "\"" + compiler + "\" \"" + f + "\" -o \"" + exe + "\"";
        if (run_cmd(build_cmd) != 0) {
            err("test compile failed: " + f);
            ++failed;
            continue;
        }
        int rc = run_cmd("\"" + exe + "\"");
        fs::remove(exe);
        if (rc == 0) { ok("PASS: " + f); ++passed; }
        else         { err("FAIL: " + f + " (exit " + std::to_string(rc) + ")"); ++failed; }
    }

    std::cout << "\n" << passed << "/" << (passed+failed) << " tests passed\n";
}

// ---- bench ----

void cmd_bench() {
    auto files = collect_ext(".", ".arcb");
    if (files.empty()) { info("no .arcb bench files found"); return; }

    std::string compiler = find_compiler();
    std::string tmp_base = (fs::temp_directory_path() / "aciso_bench_").string();
    int passed = 0, failed = 0;

    for (const auto& f : files) {
        std::string exe = tmp_base + fs::path(f).stem().string();
#ifdef _WIN32
        exe += ".exe";
#endif
        std::string build_cmd = "\"" + compiler + "\" \"" + f + "\" -o \"" + exe + "\"";
        if (run_cmd(build_cmd) != 0) {
            err("bench compile failed: " + f);
            ++failed;
            continue;
        }
        auto t0 = std::chrono::steady_clock::now();
        int rc  = run_cmd("\"" + exe + "\"");
        double ms = elapsed_ms(t0);
        fs::remove(exe);

        if (rc == 0) {
            std::cout << "\033[32mOK:\033[0m    " << f << "  \033[36m" << ms << " ms\033[0m\n";
            ++passed;
        } else {
            std::cout << "\033[31mFAIL:\033[0m  " << f << "  (exit " << rc
                      << ")  " << ms << " ms\n";
            ++failed;
        }
    }

    std::cout << "\n" << passed << "/" << (passed+failed) << " benchmarks passed\n";
}
