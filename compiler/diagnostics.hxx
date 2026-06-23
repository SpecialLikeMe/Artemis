#pragma once
#include <string>
#include <string_view>
#include <vector>
#include <cstdio>
#include <stdexcept>

#ifdef _WIN32
#  include <io.h>
#  define isatty _isatty
#  define fileno _fileno
#else
#  include <unistd.h>
#endif

enum class diag_level { note, warning, error };

struct diagnostic {
    diag_level  level;
    std::string filename;
    int         line = 0;
    int         col  = 0;
    std::string message;
};

class diag_engine {
public:
    static constexpr int max_errors = 20;

    explicit diag_engine(std::string_view src_filename)
        : filename(src_filename)
        , use_color(isatty(fileno(stderr)) != 0) {}

    void error(int line, int col, std::string_view msg) {
        if (err_count >= max_errors) return;
        diags.push_back({diag_level::error, std::string(filename), line, col, std::string(msg)});
        ++err_count;
    }
    void warning(int line, int col, std::string_view msg) {
        diags.push_back({diag_level::warning, std::string(filename), line, col, std::string(msg)});
    }
    void note(int line, int col, std::string_view msg) {
        diags.push_back({diag_level::note, std::string(filename), line, col, std::string(msg)});
    }

    // Convert a caught std::runtime_error (from the lexer/parser/analyzer) into a diagnostic.
    void absorb(const std::runtime_error& e, int line = 0, int col = 0) {
        error(line, col, e.what());
    }

    bool has_errors()  const { return err_count > 0; }
    int  error_count() const { return err_count; }
    bool at_limit()    const { return err_count >= max_errors; }

    // Print all collected diagnostics to stderr.
    void flush() const {
        for (const auto& d : diags) print_one(d);
        if (err_count >= max_errors)
            fprintf(stderr, "%s: fatal: too many errors (%d), stopping.\n",
                    filename.c_str(), err_count);
    }

    // Flush and return true if there were any errors.
    bool finish() { flush(); return has_errors(); }

    const std::vector<diagnostic>& all() const { return diags; }
    void reset() { diags.clear(); err_count = 0; }

private:
    std::string             filename;
    std::vector<diagnostic> diags;
    int                     err_count = 0;
    bool                    use_color = false;

    void print_one(const diagnostic& d) const {
        const char *lvl, *c0 = "", *c1 = "";
        if (use_color) c1 = "\033[0m";
        switch (d.level) {
            case diag_level::error:
                lvl = "error";
                if (use_color) c0 = "\033[1;31m";
                break;
            case diag_level::warning:
                lvl = "warning";
                if (use_color) c0 = "\033[1;33m";
                break;
            default:
                lvl = "note";
                if (use_color) c0 = "\033[1;36m";
                break;
        }
        fprintf(stderr, "%s:%d:%d: %s%s%s: %s\n",
                d.filename.c_str(), d.line, d.col,
                c0, lvl, c1,
                d.message.c_str());
    }
};
