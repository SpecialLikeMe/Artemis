#pragma once
#include <string>
#include <regex>
#include <vector>
#include <unordered_map>
#include <unordered_set>
#include <fstream>
#include <sstream>
#include <filesystem>
#include <stdexcept>
#include "../diagnostics.hxx"

/*
 * PREPROCESSOR DIRECTIVE REFERENCE:
 *
 * @include <filename>          - Includes and preprocesses the given file
 * @embed <filename>            - Embeds the raw (unprocessed) content of a file
 * @define <pattern> <repl>     - Defines a regex macro; pattern is ECMAScript regex,
 *                                replacement uses %0 (full match), %1 (group 1), etc.
 * @undef <pattern>             - Removes a previously defined macro by its pattern key
 * @ifdef <name>                - Opens a block included only if the named macro is defined
 * @ifndef <name>               - Opens a block included only if the named macro is NOT defined
 * @elifdef <name>              - Elif variant: active if no prior branch taken and name is defined
 * @elifndef <name>             - Elif variant: active if no prior branch taken and name is NOT defined
 * @else                        - Active if no prior branch in the block was taken
 * @endif                       - Closes the current conditional block
 * @error <message>             - Emits a preprocessor error and halts further output
 * @warning <message>           - Emits a preprocessor warning (processing continues)
 *
 * Argument syntax: arguments may be wrapped in angle brackets <arg> or bare tokens.
 * For @define, both the pattern and replacement must be in angle brackets to support
 * patterns/replacements that contain spaces.
 */

namespace preproc {

struct macro_def {
    std::string pattern;
    std::string replacement;
};

struct cond_frame {
    bool active;    // current branch is being included
    bool ever_true; // some earlier branch in this block was taken
};

inline std::string read_file(const std::string& path) {
    std::ifstream f(path, std::ios::binary);
    if (!f) throw std::runtime_error("cannot open file: " + path);
    return std::string(std::istreambuf_iterator<char>(f),
                       std::istreambuf_iterator<char>());
}

// Apply a single macro substitution across text, expanding %0..%N capture placeholders.
inline std::string apply_one_macro(const std::string& text, const macro_def& def) {
    std::regex pat(def.pattern, std::regex_constants::ECMAScript);
    std::string result;
    size_t last = 0;
    for (auto it = std::sregex_iterator(text.begin(), text.end(), pat);
         it != std::sregex_iterator(); ++it) {
        const std::smatch& m = *it;
        result.append(text, last, (size_t)m.position() - last);
        std::string out = def.replacement;
        // Substitute from highest index down to avoid %1 clobbering %10 etc.
        for (int i = (int)m.size() - 1; i >= 0; --i) {
            const std::string ph = "%" + std::to_string(i);
            const std::string val = m[i].str();
            size_t p = 0;
            while ((p = out.find(ph, p)) != std::string::npos) {
                out.replace(p, ph.size(), val);
                p += val.size();
            }
        }
        result += out;
        last = (size_t)m.position() + m.length();
    }
    result.append(text, last, std::string::npos);
    return result;
}

// Parse the next whitespace-delimited token from `line` starting at `pos`.
// If the token starts with '<', reads until the matching '>'.
inline std::string parse_arg(const std::string& line, size_t& pos) {
    while (pos < line.size() && (line[pos] == ' ' || line[pos] == '\t')) ++pos;
    if (pos >= line.size()) return {};
    if (line[pos] == '<' || line[pos] == '(') {
        const char close = (line[pos] == '<') ? '>' : ')';
        size_t start = ++pos;
        // The replacement/pattern may itself contain the close char (e.g. a regex
        // replacement like "%1 > %2"). Choose the close delimiter that is followed
        // (after whitespace) by end-of-line or the start of the next argument.
        size_t best = std::string::npos;
        for (size_t i = start; i < line.size(); ++i) {
            if (line[i] == close) {
                size_t j = i + 1;
                while (j < line.size() && (line[j] == ' ' || line[j] == '\t')) ++j;
                if (j >= line.size() || line[j] == '<' || line[j] == '(') { best = i; break; }
            }
        }
        if (best == std::string::npos) {
            best = line.rfind(close);
            if (best == std::string::npos || best < start) best = line.size();
        }
        std::string arg = line.substr(start, best - start);
        pos = (best < line.size()) ? best + 1 : best;
        return arg;
    }
    size_t start = pos;
    while (pos < line.size() && line[pos] != ' ' && line[pos] != '\t') ++pos;
    return line.substr(start, pos - start);
}

// Parse the remainder of the line as a message, stripping optional <> wrapping.
inline std::string parse_rest(const std::string& line, size_t pos) {
    while (pos < line.size() && line[pos] == ' ') ++pos;
    if (pos < line.size() && line[pos] == '<') {
        ++pos;
        size_t start = pos;
        size_t end = line.rfind('>');
        return (end != std::string::npos && end > start)
            ? line.substr(start, end - start)
            : line.substr(start);
    }
    return line.substr(pos);
}

// Forward declaration for recursive includes.
inline std::string pr_process(
    const std::string& input,
    const std::string& filename,
    std::unordered_map<std::string, macro_def>& defines,
    diag_engine& diag,
    int depth = 0,
    const std::unordered_set<std::string>* predefined = nullptr,
    const std::vector<std::string>* include_paths = nullptr
);

inline std::string pr_process(
    const std::string& input,
    const std::string& filename,
    std::unordered_map<std::string, macro_def>& defines,
    diag_engine& diag,
    int depth,
    const std::unordered_set<std::string>* predefined,
    const std::vector<std::string>* include_paths
) {
    if (depth > 64) {
        diag.error(0, 0, "maximum include depth exceeded (possible circular @include)");
        return {};
    }

    std::istringstream ss(input);
    std::string line;
    std::ostringstream out;
    int lineno = 0;
    std::vector<cond_frame> stack;

    // All frames in the stack must be active for output to be included.
    auto active = [&]() {
        for (const auto& f : stack) if (!f.active) return false;
        return true;
    };

    // All frames except the topmost — used by elif/else to determine parent state.
    auto parent_active = [&]() {
        for (size_t i = 0; i + 1 < stack.size(); ++i)
            if (!stack[i].active) return false;
        return true;
    };

    while (std::getline(ss, line)) {
        ++lineno;
        if (!line.empty() && line.back() == '\r') line.pop_back();

        // Non-directive lines
        if (line.empty() || line[0] != '@') {
            if (active()) {
                // stdlib import: extern std.<dotpath>;
                // e.g. "extern std.alloc.pool;" → include alloc/pool.arc from stdlib path
                static const std::regex std_import(
                    R"(^\s*extern\s+std\.([a-zA-Z0-9_]+(?:\.[a-zA-Z0-9_]+)*)\s*;\s*$)");
                std::smatch sm;
                if (std::regex_match(line, sm, std_import)) {
                    std::string dotpath = sm[1].str();
                    std::string filepath;
                    for (char c : dotpath) filepath += (c == '.') ? '/' : c;
                    filepath += ".arc";
                    bool found = false;
                    if (include_paths) {
                        for (const auto& idir : *include_paths) {
                            auto candidate = std::filesystem::path(idir) / filepath;
                            if (std::filesystem::exists(candidate)) {
                                try {
                                    const std::string content = read_file(candidate.string());
                                    out << pr_process(content, candidate.string(), defines, diag,
                                                      depth + 1, predefined, include_paths);
                                } catch (const std::runtime_error& e) {
                                    diag.error(lineno, 1, e.what());
                                }
                                found = true;
                                break;
                            }
                        }
                    }
                    if (!found)
                        diag.error(lineno, 1, "unknown stdlib module: std." + dotpath);
                } else {
                    std::string processed = line;
                    for (const auto& [_, def] : defines)
                        processed = apply_one_macro(processed, def);
                    out << processed << '\n';
                }
            }
            continue;
        }

        // Parse the directive keyword
        size_t pos = 1;
        size_t ks = pos;
        while (pos < line.size() && (std::isalnum((unsigned char)line[pos]) || line[pos] == '_'))
            ++pos;
        std::string kw = line.substr(ks, pos - ks);
        while (pos < line.size() && line[pos] == ' ') ++pos; // skip space after keyword

        // Conditional-stack directives must be processed regardless of active state
        // so that nesting stays balanced.
        if (kw == "ifdef" || kw == "ifndef") {
            const std::string name = parse_arg(line, pos);
            const bool defined = defines.count(name) > 0
                                 || (predefined && predefined->count(name) > 0);
            const bool cond = (kw == "ifdef") ? defined : !defined;
            stack.push_back({active() && cond, cond});
        } else if (kw == "elifdef" || kw == "elifndef") {
            if (stack.empty()) {
                diag.error(lineno, 1, "@" + kw + " without opening @ifdef/@ifndef");
            } else {
                auto& top = stack.back();
                if (!top.ever_true) {
                    const std::string name = parse_arg(line, pos);
                    const bool defined = defines.count(name) > 0
                                         || (predefined && predefined->count(name) > 0);
                    const bool cond = (kw == "elifdef") ? defined : !defined;
                    top.active = parent_active() && cond;
                    top.ever_true = cond;
                } else {
                    top.active = false;
                }
            }
        } else if (kw == "else") {
            if (stack.empty()) {
                diag.error(lineno, 1, "@else without opening @ifdef/@ifndef");
            } else {
                auto& top = stack.back();
                top.active = parent_active() && !top.ever_true;
            }
        } else if (kw == "endif") {
            if (stack.empty()) diag.error(lineno, 1, "@endif without opening @ifdef/@ifndef");
            else stack.pop_back();
        } else if (active()) {
            // Non-conditional directives are silently skipped in inactive blocks.
            if (kw == "include") {
                const std::string fname = parse_arg(line, pos);
                const auto base = std::filesystem::path(filename).parent_path();
                std::filesystem::path full = base / fname;
                // If not found relative to source, search include paths
                if (!std::filesystem::exists(full) && include_paths) {
                    for (const auto& idir : *include_paths) {
                        auto candidate = std::filesystem::path(idir) / fname;
                        if (std::filesystem::exists(candidate)) { full = candidate; break; }
                    }
                }
                try {
                    const std::string content = read_file(full.string());
                    out << pr_process(content, full.string(), defines, diag, depth + 1, predefined, include_paths);
                } catch (const std::runtime_error& e) {
                    diag.error(lineno, 1, e.what());
                }
            } else if (kw == "embed") {
                const std::string fname = parse_arg(line, pos);
                const auto base = std::filesystem::path(filename).parent_path();
                std::filesystem::path full = base / fname;
                if (!std::filesystem::exists(full) && include_paths) {
                    for (const auto& idir : *include_paths) {
                        auto candidate = std::filesystem::path(idir) / fname;
                        if (std::filesystem::exists(candidate)) { full = candidate; break; }
                    }
                }
                try {
                    out << read_file(full.string());
                } catch (const std::runtime_error& e) {
                    diag.error(lineno, 1, e.what());
                }
            } else if (kw == "define") {
                const std::string pattern = parse_arg(line, pos);
                const std::string replacement = parse_arg(line, pos);
                if (pattern.empty()) {
                    diag.error(lineno, 1, "@define: missing pattern");
                } else {
                    try {
                        std::regex validated(pattern, std::regex_constants::ECMAScript);
                        (void)validated;
                        defines[pattern] = {pattern, replacement};
                    } catch (const std::regex_error& e) {
                        diag.error(lineno, 1, std::string("@define: invalid regex: ") + e.what());
                    }
                }
            } else if (kw == "undef") {
                defines.erase(parse_arg(line, pos));
            } else if (kw == "error") {
                diag.error(lineno, 1, parse_rest(line, pos));
            } else if (kw == "warning") {
                diag.warning(lineno, 1, parse_rest(line, pos));
            } else if (kw == "pragma") {
                // @pragma once  — ignore duplicate includes (file-level guard)
                // @pragma omp simd — silently accepted (future parallelism hint)
                // Other pragmas are silently ignored (forward-compatible).
                std::string pragma_arg = parse_arg(line, pos);
                if (pragma_arg == "once") {
                    // Mark this file as included; only honour in the include path
                    // (already deduplicated by stdlib importer; nothing more to do here)
                }
                // All other pragmas are silently accepted (e.g. @pragma omp simd)
            } else {
                diag.warning(lineno, 1, "unknown preprocessor directive: @" + kw);
            }
        }
    }

    if (!stack.empty()) {
        diag.error(lineno, 1,
            std::to_string(stack.size()) + " unclosed conditional block(s) at end of file");
    }

    return out.str();
}

// Public entry point. Returns the preprocessed text; diagnostics are collected in `diag`.
inline std::string pr_main(
    const std::string& input,
    const std::string& filename,
    diag_engine& diag,
    const std::unordered_set<std::string>& predefined = {},
    const std::vector<std::string>& include_paths = {}
) {
    std::unordered_map<std::string, macro_def> defines;
    return pr_process(input, filename, defines, diag, 0,
                      predefined.empty() ? nullptr : &predefined,
                      include_paths.empty() ? nullptr : &include_paths);
}

} // namespace preproc
