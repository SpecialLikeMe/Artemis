#pragma once
#include "json.hxx"
#include <string>
#include <vector>
#include <sstream>
#include <cctype>

namespace toml {

using json = nlohmann::json;

inline void skip_ws(const std::string& s, size_t& pos) {
    while (pos < s.size() && (s[pos] == ' ' || s[pos] == '\t')) ++pos;
}

inline std::string parse_string(const std::string& line, size_t& pos) {
    char delim = line[pos++];
    std::string result;
    while (pos < line.size() && line[pos] != delim) {
        if (delim == '"' && line[pos] == '\\' && pos + 1 < line.size()) {
            ++pos;
            switch (line[pos]) {
                case 'n': result += '\n'; break;
                case 't': result += '\t'; break;
                case 'r': result += '\r'; break;
                case '"': result += '"'; break;
                case '\'': result += '\''; break;
                case '\\': result += '\\'; break;
                default: result += '\\'; result += line[pos]; break;
            }
        } else {
            result += line[pos];
        }
        ++pos;
    }
    if (pos < line.size()) ++pos;
    return result;
}

inline json parse_value(const std::string& line, size_t& pos);

inline json parse_array(const std::string& line, size_t& pos) {
    ++pos; // consume '['
    json arr = json::array();
    skip_ws(line, pos);
    while (pos < line.size() && line[pos] != ']') {
        if (line[pos] == '#') break;
        skip_ws(line, pos);
        if (pos < line.size() && line[pos] == ']') break;
        arr.push_back(parse_value(line, pos));
        skip_ws(line, pos);
        if (pos < line.size() && line[pos] == ',') ++pos;
        skip_ws(line, pos);
    }
    if (pos < line.size() && line[pos] == ']') ++pos;
    return arr;
}

inline json parse_inline_table(const std::string& line, size_t& pos) {
    ++pos; // consume '{'
    json obj = json::object();
    skip_ws(line, pos);
    while (pos < line.size() && line[pos] != '}') {
        skip_ws(line, pos);
        if (pos >= line.size() || line[pos] == '}') break;
        std::string key;
        if (line[pos] == '"' || line[pos] == '\'') {
            key = parse_string(line, pos);
        } else {
            size_t ks = pos;
            while (pos < line.size() && line[pos] != '=' && line[pos] != ' ' && line[pos] != '\t') ++pos;
            key = line.substr(ks, pos - ks);
        }
        skip_ws(line, pos);
        if (pos < line.size() && line[pos] == '=') ++pos;
        skip_ws(line, pos);
        obj[key] = parse_value(line, pos);
        skip_ws(line, pos);
        if (pos < line.size() && line[pos] == ',') ++pos;
        skip_ws(line, pos);
    }
    if (pos < line.size() && line[pos] == '}') ++pos;
    return obj;
}

inline json parse_value(const std::string& line, size_t& pos) {
    skip_ws(line, pos);
    if (pos >= line.size() || line[pos] == '#') return nullptr;

    char c = line[pos];
    if (c == '"' || c == '\'') return parse_string(line, pos);
    if (c == '[') return parse_array(line, pos);
    if (c == '{') return parse_inline_table(line, pos);
    if (line.substr(pos, 4) == "true")  { pos += 4; return true; }
    if (line.substr(pos, 5) == "false") { pos += 5; return false; }

    size_t start = pos;
    bool has_dot = false;
    if (c == '-' || c == '+') ++pos;
    while (pos < line.size() && (std::isdigit((unsigned char)line[pos]) || line[pos] == '.' || line[pos] == '_')) {
        if (line[pos] == '.') has_dot = true;
        ++pos;
    }
    if (pos > start) {
        std::string num = line.substr(start, pos - start);
        std::string clean;
        for (char ch : num) if (ch != '_') clean += ch;
        try {
            if (has_dot) return std::stod(clean);
            return static_cast<int64_t>(std::stoll(clean));
        } catch (...) {}
    }
    return nullptr;
}

inline json& navigate_to(json& root, const std::vector<std::string>& path) {
    json* cur = &root;
    for (const auto& key : path) {
        if (!cur->contains(key)) (*cur)[key] = json::object();
        cur = &(*cur)[key];
    }
    return *cur;
}

inline json& current_node(json& root, const std::vector<std::string>& sec_path, bool in_arr) {
    if (in_arr && !sec_path.empty()) {
        json* cur = &root;
        for (size_t i = 0; i + 1 < sec_path.size(); ++i) {
            if (!cur->contains(sec_path[i])) (*cur)[sec_path[i]] = json::object();
            cur = &(*cur)[sec_path[i]];
        }
        return (*cur)[sec_path.back()].back();
    }
    return navigate_to(root, sec_path);
}

inline json loads(const std::string& input) {
    json root = json::object();
    std::vector<std::string> sec_path;
    bool in_arr = false;

    std::istringstream ss(input);
    std::string line;

    while (std::getline(ss, line)) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        size_t pos = 0;
        skip_ws(line, pos);
        if (pos >= line.size() || line[pos] == '#') continue;

        if (line[pos] == '[') {
            ++pos;
            bool is_arr = (pos < line.size() && line[pos] == '[');
            if (is_arr) ++pos;

            std::vector<std::string> path;
            while (pos < line.size() && line[pos] != ']') {
                skip_ws(line, pos);
                std::string part;
                if (pos < line.size() && (line[pos] == '"' || line[pos] == '\''))
                    part = parse_string(line, pos);
                else {
                    size_t s = pos;
                    while (pos < line.size() && line[pos] != '.' && line[pos] != ']'
                           && line[pos] != ' ' && line[pos] != '\t') ++pos;
                    part = line.substr(s, pos - s);
                }
                if (!part.empty()) path.push_back(part);
                skip_ws(line, pos);
                if (pos < line.size() && line[pos] == '.') { ++pos; continue; }
                break;
            }
            if (pos < line.size()) ++pos; // ']'
            if (is_arr && pos < line.size() && line[pos] == ']') ++pos; // ']]'

            sec_path = path;
            in_arr = is_arr;

            if (is_arr) {
                json* node = &root;
                for (size_t i = 0; i + 1 < path.size(); ++i) {
                    if (!node->contains(path[i])) (*node)[path[i]] = json::object();
                    node = &(*node)[path[i]];
                }
                const auto& ak = path.back();
                if (!node->contains(ak) || !(*node)[ak].is_array())
                    (*node)[ak] = json::array();
                (*node)[ak].push_back(json::object());
            } else {
                navigate_to(root, path);
            }
            continue;
        }

        // Key-value pair
        std::vector<std::string> key_parts;
        while (pos < line.size() && line[pos] != '=') {
            skip_ws(line, pos);
            std::string part;
            if (pos < line.size() && (line[pos] == '"' || line[pos] == '\''))
                part = parse_string(line, pos);
            else {
                size_t s = pos;
                while (pos < line.size() && line[pos] != '=' && line[pos] != '.'
                       && line[pos] != ' ' && line[pos] != '\t') ++pos;
                part = line.substr(s, pos - s);
            }
            if (!part.empty()) key_parts.push_back(part);
            skip_ws(line, pos);
            if (pos < line.size() && line[pos] == '.') { ++pos; continue; }
            break;
        }
        if (pos >= line.size() || line[pos] != '=' || key_parts.empty()) continue;
        ++pos;
        skip_ws(line, pos);

        json val = parse_value(line, pos);
        json& node = current_node(root, sec_path, in_arr);
        json* cur = &node;
        for (size_t i = 0; i + 1 < key_parts.size(); ++i) {
            if (!cur->contains(key_parts[i])) (*cur)[key_parts[i]] = json::object();
            cur = &(*cur)[key_parts[i]];
        }
        (*cur)[key_parts.back()] = val;
    }
    return root;
}

inline std::string escape_str(const std::string& s) {
    std::string r;
    for (char c : s) {
        if (c == '"')  { r += "\\\""; }
        else if (c == '\\') { r += "\\\\"; }
        else if (c == '\n') { r += "\\n"; }
        else if (c == '\t') { r += "\\t"; }
        else r += c;
    }
    return r;
}

inline std::string write_scalar(const json& v) {
    if (v.is_string())          return "\"" + escape_str(v.get<std::string>()) + "\"";
    if (v.is_boolean())         return v.get<bool>() ? "true" : "false";
    if (v.is_number_integer())  return std::to_string(v.get<int64_t>());
    if (v.is_number_float()) {
        std::ostringstream o; o << v.get<double>(); return o.str();
    }
    return v.dump();
}

inline bool needs_quotes(const std::string& k) {
    for (char c : k) if (!std::isalnum((unsigned char)c) && c != '_' && c != '-') return true;
    return false;
}

inline std::string write_key(const std::string& k) {
    return needs_quotes(k) ? "\"" + k + "\"" : k;
}

inline std::string write_inline_table(const json& obj);

inline std::string write_array(const json& arr) {
    std::ostringstream o;
    o << '[';
    bool first = true;
    for (const auto& e : arr) {
        if (!first) o << ", ";
        first = false;
        if (e.is_object()) o << write_inline_table(e);
        else               o << write_scalar(e);
    }
    o << ']';
    return o.str();
}

inline std::string write_inline_table(const json& obj) {
    std::ostringstream o;
    o << '{';
    bool first = true;
    for (auto& [k, v] : obj.items()) {
        if (!first) o << ", ";
        first = false;
        o << write_key(k) << " = ";
        if (v.is_object()) o << write_inline_table(v);
        else if (v.is_array()) o << write_array(v);
        else o << write_scalar(v);
    }
    o << '}';
    return o.str();
}

// Forward declaration
inline std::string dumps(const json& j, const std::string& prefix = "");

inline std::string write_section_body(const json& obj) {
    std::ostringstream out;
    for (auto& [k, v] : obj.items()) {
        bool is_arr_tbl = v.is_array() && !v.empty() && v[0].is_object();
        if (is_arr_tbl) continue;
        out << write_key(k) << " = ";
        if (v.is_object())   out << write_inline_table(v);
        else if (v.is_array()) out << write_array(v);
        else                 out << write_scalar(v);
        out << '\n';
    }
    return out.str();
}

inline std::string dumps(const json& j, const std::string& prefix) {
    if (!j.is_object()) return "";
    std::ostringstream out;

    // scalars, arrays-of-scalars, inline-table values
    for (auto& [k, v] : j.items()) {
        bool is_tbl     = v.is_object();
        bool is_arr_tbl = v.is_array() && !v.empty() && v[0].is_object();
        if (!is_tbl && !is_arr_tbl) {
            out << write_key(k) << " = ";
            if (v.is_array()) out << write_array(v);
            else              out << write_scalar(v);
            out << '\n';
        }
    }

    // sub-tables → [section] headers, or inline tables for keys with special chars
    for (auto& [k, v] : j.items()) {
        if (!v.is_object()) continue;
        if (needs_quotes(k)) {
            // inline table avoids ambiguous multi-level quoted section headers
            out << write_key(k) << " = " << write_inline_table(v) << '\n';
        } else {
            std::string full = prefix.empty() ? k : prefix + "." + k;
            out << "\n[" << full << "]\n";
            out << dumps(v, full);
        }
    }

    // arrays of tables → [[section]] headers
    for (auto& [k, v] : j.items()) {
        if (!v.is_array() || v.empty() || !v[0].is_object()) continue;
        std::string full = prefix.empty() ? k : prefix + "." + k;
        for (const auto& elem : v) {
            out << "\n[[" << full << "]]\n";
            out << write_section_body(elem);
        }
    }

    return out.str();
}

} // namespace toml
