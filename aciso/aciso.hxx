#pragma once
#include "config.hxx"
#include "hash.hxx"
#include <iostream>
#include <string>
#include <vector>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <chrono>

namespace fs = std::filesystem;

#ifdef _WIN32
#  define ACISO_NULL   "NUL"
#  define ACISO_POPEN  _popen
#  define ACISO_PCLOSE _pclose
#else
#  define ACISO_NULL   "/dev/null"
#  define ACISO_POPEN  popen
#  define ACISO_PCLOSE pclose
#endif

inline void err(const std::string& msg)  { std::cerr << "\033[31mERROR:\033[0m aciso: " << msg << "\n"; }
inline void ok(const std::string& msg)   { std::cout << "\033[32mOK:\033[0m    " << msg << "\n"; }
inline void info(const std::string& msg) { std::cout << "\033[34mINFO:\033[0m  " << msg << "\n"; }
inline void warn(const std::string& msg) { std::cout << "\033[33mWARN:\033[0m  " << msg << "\n"; }

inline std::string find_compiler() {
    if (const char* h = std::getenv("ARTEMIS_HOME")) {
        fs::path p = fs::path(h) / "bin" / "artemis";
#ifdef _WIN32
        p += ".exe";
#endif
        if (fs::exists(p)) return p.string();
    }
    return "artemis";
}

inline int run_cmd(const std::string& cmd) {
    return std::system(cmd.c_str());
}

inline std::string capture_cmd(const std::string& cmd) {
    FILE* p = ACISO_POPEN(cmd.c_str(), "r");
    if (!p) return "";
    std::string out;
    char buf[512];
    while (fgets(buf, sizeof(buf), p)) out += buf;
    ACISO_PCLOSE(p);
    return out;
}

inline std::string read_file_str(const std::string& path) {
    std::ifstream f(path, std::ios::binary);
    if (!f) return "";
    return std::string((std::istreambuf_iterator<char>(f)),
                       std::istreambuf_iterator<char>());
}

inline void write_file_str(const std::string& path, const std::string& content) {
    std::ofstream f(path);
    f << content;
}

inline std::vector<std::string> collect_ext(const fs::path& root, const std::string& ext) {
    std::vector<std::string> out;
    if (!fs::exists(root)) return out;
    for (auto& e : fs::recursive_directory_iterator(root)) {
        if (e.is_regular_file() && e.path().extension() == ext)
            out.push_back(e.path().string());
    }
    return out;
}

inline std::string symbol_flags(const std::vector<std::string>& syms) {
    std::string r;
    for (const auto& s : syms) r += " -D " + s;
    return r;
}

inline std::vector<std::string> get_symbols(const Config& cfg) {
    std::vector<std::string> syms;
    if (cfg.data.contains("symbol") && cfg.data["symbol"].contains("defined_symbols")) {
        for (const auto& s : cfg.data["symbol"]["defined_symbols"])
            syms.push_back(s.get<std::string>());
    }
    return syms;
}

inline std::string output_ext(const std::string& type) {
    if (type == "exe" || type == "executable")            return ".exe";
    if (type == "elf")                                    return "";
    if (type == "mco")                                    return ".mco";
    if (type == "dll")                                    return ".dll";
    if (type == "so")                                     return ".so";
    if (type == "dylib")                                  return ".dylib";
    if (type == "static" || type == "a" || type == "lib") return ".a";
    if (type == "wasm")                                   return ".wasm";
    if (type == "wasi")                                   return ".wasi";
    if (type == "ll")                                     return ".ll";
    if (type == "bc")                                     return ".bc";
    if (type == "obj" || type == "o")                     return ".o";
    return "";
}

inline std::string type_from_filename(const std::string& name) {
    std::string ext = fs::path(name).extension().string();
    if (ext == ".exe")                return "exe";
    if (ext == ".mco")               return "mco";
    if (ext == ".dll")               return "dll";
    if (ext == ".so")                return "so";
    if (ext == ".dylib")             return "dylib";
    if (ext == ".a" || ext == ".lib") return "static";
    if (ext == ".wasm")              return "wasm";
    if (ext == ".wasi")              return "wasi";
    if (ext == ".ll")                return "ll";
    if (ext == ".bc")                return "bc";
    if (ext == ".o" || ext == ".obj") return "obj";
    return "exe";
}

inline double elapsed_ms(std::chrono::steady_clock::time_point start) {
    return std::chrono::duration<double, std::milli>(
        std::chrono::steady_clock::now() - start).count();
}

inline void ensure_dir(const std::string& d) {
    fs::create_directories(d);
}

static const std::string CACHE_DIR = ".aciso_cache";

inline std::string cache_key(const std::string& src, const std::string& type,
                              const std::vector<std::string>& syms) {
    std::string h = read_file_str(src) + type;
    for (const auto& s : syms) h += s;
    return sha256(h).substr(0, 16);
}

inline bool cache_hit(const std::string& key, const std::string& out_path) {
    fs::path entry = fs::path(CACHE_DIR) / key;
    if (!fs::exists(entry)) return false;
    // restore from cache
    fs::copy_file(entry, out_path, fs::copy_options::overwrite_existing);
    return true;
}

inline void cache_store(const std::string& key, const std::string& out_path) {
    if (!fs::exists(out_path)) return;
    ensure_dir(CACHE_DIR);
    fs::copy_file(out_path, fs::path(CACHE_DIR) / key,
                  fs::copy_options::overwrite_existing);
}
