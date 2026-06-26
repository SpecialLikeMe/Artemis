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
    // Try to compile to a temp object; errors go to stderr naturally
    std::string tmp = (fs::temp_directory_path() / "aciso_sta_tmp.o").string();
    std::string cmd = "\"" + compiler + "\" -c \"" + path + "\" -o \"" + tmp + "\"" + flags + " 2>&1";
    std::string output = capture_cmd(cmd);
    fs::remove(tmp);
    if (output.empty()) {
        ok("clean: " + path);
    } else {
        std::cout << "\033[33mSTATIC ANALYSIS:\033[0m " << path << "\n" << output;
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
