#pragma once
// ============================================================
// const_resolve macro engine — Artemis macro_rules! analogue.
// Included by parser/main.hxx after the token_type enum.
// ============================================================
//
// Syntax:
//   const_resolve name {
//       (pattern) => { expansion },
//       [$syntax_pattern] => { expansion },
//       ...
//   }
//
// Invocation:
//   name(args)     — expression or statement invocation
//   name[args]     — expression or statement (same semantics)
//   name{args}     — block invocation
//   keyword stmt   — syntax-definition form ([] rules)
//
// Pattern fragments: $cap:expr  $cap:ident  $cap:literal  $cap:ty
//                    $cap:tt    $cap:stmt   $cap:block    $cap:path
// Variadic: $group($cap:kind)* / + / ?
// Literal matcher: "word" in a [] pattern

#include <string>
#include <vector>
#include <unordered_map>
#include <functional>
#include <algorithm>

// ---- pattern element ----------------------------------------
enum class macro_pat_kind {
    tok,       // match a specific token exactly
    capture,   // $name:type — capture a fragment
    str_match, // "word"     — match an identifier/keyword with that value (syntax form)
    variadic,  // $group(sub_pattern)* or + or ?
};

struct macro_pat_elem {
    macro_pat_kind kind = macro_pat_kind::tok;
    token_t        tok{};           // for kind==tok: exact token to match
    std::string    cap_name;        // for capture/variadic: name
    std::string    cap_type;        // for capture: "expr","ident","literal","tt","ty","stmt","block","path"
    char           rep_mod  = '*';  // for variadic: '*','+'or'?'
    std::vector<macro_pat_elem> sub; // for variadic: sub-pattern
};

// ---- rule ---------------------------------------------------
struct macro_rule {
    bool                       is_syntax = false; // true when pattern came from []
    std::vector<macro_pat_elem> pats;
    std::vector<token_t>        expansion; // raw expansion tokens; $name is dollar+id token
};

// ---- definition ---------------------------------------------
struct macro_def {
    std::string              name;
    std::vector<macro_rule>  rules;
};

// ============================================================
// Pattern parser (operates on a sub-vector of tokens)
// ============================================================

inline std::vector<macro_pat_elem>
parse_macro_pattern(const std::vector<token_t>& ts, size_t& pos);

// Parse a single pattern element starting at ts[pos].
// Returns false and leaves pos unchanged if nothing valid found.
static bool
parse_one_pat_elem(const std::vector<token_t>& ts, size_t& pos,
                   macro_pat_elem& out)
{
    if (pos >= ts.size()) return false;
    const token_t& cur = ts[pos];

    // $name:type  or  $group(sub)*
    if (cur.type == token_type::dollar && pos + 1 < ts.size()) {
        token_t next = ts[pos + 1];

        // $group(sub_pattern)*  or + or ?
        if (next.type == token_type::id && pos + 2 < ts.size() &&
            ts[pos + 2].type == token_type::oparen) {
            // peek ahead to see if after the closing ) there's */+/?
            // First collect sub-pattern tokens (balanced parens)
            size_t sub_start = pos + 3;
            size_t depth = 1;
            size_t sub_end = sub_start;
            while (sub_end < ts.size() && depth > 0) {
                if (ts[sub_end].type == token_type::oparen)  depth++;
                else if (ts[sub_end].type == token_type::cparen) depth--;
                if (depth > 0) sub_end++;
            }
            if (depth != 0) return false; // malformed
            char mod = '*';
            size_t after = sub_end + 1;
            if (after < ts.size()) {
                if (ts[after].value == "*" || ts[after].type == token_type::ast)
                    { mod = '*'; after++; }
                else if (ts[after].value == "+" || ts[after].type == token_type::plus)
                    { mod = '+'; after++; }
                else if (ts[after].type == token_type::question)
                    { mod = '?'; after++; }
            }
            std::vector<token_t> sub_ts(ts.begin() + sub_start, ts.begin() + sub_end);
            size_t sp = 0;
            out.kind     = macro_pat_kind::variadic;
            out.cap_name = next.value;
            out.rep_mod  = mod;
            out.sub      = parse_macro_pattern(sub_ts, sp);
            pos = after;
            return true;
        }

        // $name:kind — simple capture
        if (next.type == token_type::id && pos + 2 < ts.size() &&
            ts[pos + 2].type == token_type::colon) {
            if (pos + 3 < ts.size() && ts[pos + 3].type == token_type::id) {
                out.kind     = macro_pat_kind::capture;
                out.cap_name = next.value;
                out.cap_type = ts[pos + 3].value;
                pos += 4;
                return true;
            }
        }
    }

    // "word" — literal string match (syntax-definition form)
    if (cur.type == token_type::string_lit) {
        out.kind     = macro_pat_kind::str_match;
        out.cap_name = cur.value; // the required identifier value
        pos++;
        return true;
    }

    // Plain token — match exactly
    out.kind = macro_pat_kind::tok;
    out.tok  = cur;
    pos++;
    return true;
}

inline std::vector<macro_pat_elem>
parse_macro_pattern(const std::vector<token_t>& ts, size_t& pos)
{
    std::vector<macro_pat_elem> result;
    while (pos < ts.size()) {
        macro_pat_elem elem;
        if (parse_one_pat_elem(ts, pos, elem))
            result.push_back(std::move(elem));
        else
            pos++; // skip unrecognised
    }
    return result;
}

// ============================================================
// Macro invocation matcher
// ============================================================

// Map: capture name → matched token sequence
using capture_map = std::unordered_map<std::string, std::vector<token_t>>;

// Forward declarations
static bool match_pattern(const std::vector<macro_pat_elem>& pats,
                          const std::vector<token_t>& ts, size_t& pos,
                          capture_map& caps);

// Consume a fragment of the given kind from ts starting at pos.
// Returns the consumed tokens and advances pos.
static bool consume_fragment(const std::string& kind,
                             const std::vector<token_t>& ts, size_t& pos,
                             std::vector<token_t>& out)
{
    if (pos >= ts.size()) return false;

    if (kind == "ident") {
        if (ts[pos].type == token_type::id || ts[pos].type == token_type::kw_auto) {
            out.push_back(ts[pos++]); return true;
        }
        return false;
    }

    if (kind == "literal") {
        auto tt = ts[pos].type;
        if (tt == token_type::int_lit || tt == token_type::float_lit ||
            tt == token_type::string_lit || tt == token_type::char_lit ||
            tt == token_type::kw_true || tt == token_type::kw_false) {
            out.push_back(ts[pos++]); return true;
        }
        return false;
    }

    if (kind == "tt") {
        // Single token tree: either a single token or a balanced ()/[]/{} group
        auto tt = ts[pos].type;
        if (tt == token_type::oparen || tt == token_type::obracket ||
            tt == token_type::obrace) {
            token_type close = (tt == token_type::oparen)   ? token_type::cparen :
                               (tt == token_type::obracket) ? token_type::cbracket :
                               token_type::cbrace;
            out.push_back(ts[pos++]);
            int depth = 1;
            while (pos < ts.size() && depth > 0) {
                if (ts[pos].type == tt)    depth++;
                if (ts[pos].type == close) depth--;
                out.push_back(ts[pos++]);
            }
        } else {
            out.push_back(ts[pos++]);
        }
        return true;
    }

    if (kind == "block") {
        if (ts[pos].type != token_type::obrace) return false;
        out.push_back(ts[pos++]);
        int depth = 1;
        while (pos < ts.size() && depth > 0) {
            if (ts[pos].type == token_type::obrace) depth++;
            if (ts[pos].type == token_type::cbrace) depth--;
            out.push_back(ts[pos++]);
        }
        return true;
    }

    if (kind == "path") {
        if (ts[pos].type != token_type::id) return false;
        out.push_back(ts[pos++]);
        while (pos + 1 < ts.size() &&
               ts[pos].type == token_type::scope_res &&
               ts[pos+1].type == token_type::id) {
            out.push_back(ts[pos++]);
            out.push_back(ts[pos++]);
        }
        return true;
    }

    if (kind == "ty") {
        // A type token or identifier (simplified)
        auto tt = ts[pos].type;
        if (tt == token_type::id || tt == token_type::kw_arb_int ||
            tt == token_type::kw_arb_uint || tt == token_type::kw_arb_float ||
            tt == token_type::kw_arb_bool || tt == token_type::kw_char ||
            tt == token_type::kw_void || tt == token_type::kw_auto) {
            out.push_back(ts[pos++]);
            while (pos < ts.size() && ts[pos].type == token_type::ast) {
                out.push_back(ts[pos++]); // pointer stars
            }
            return true;
        }
        return false;
    }

    // "expr" and "stmt" — consume until comma, closing paren/bracket, or semicolon
    // (context-dependent balanced scan)
    if (kind == "expr" || kind == "stmt") {
        if (pos >= ts.size()) return false;
        int depth = 0;
        bool got_any = false;
        while (pos < ts.size()) {
            auto tt = ts[pos].type;
            if (tt == token_type::oparen || tt == token_type::obracket ||
                tt == token_type::obrace) {
                depth++;
            } else if (tt == token_type::cparen || tt == token_type::cbracket ||
                       tt == token_type::cbrace) {
                if (depth == 0) break;
                depth--;
            } else if (depth == 0 &&
                       (tt == token_type::comma || tt == token_type::sm)) {
                break;
            }
            out.push_back(ts[pos++]);
            got_any = true;
        }
        if (kind == "stmt" && pos < ts.size() && ts[pos].type == token_type::sm)
            out.push_back(ts[pos++]);
        return got_any;
    }

    return false;
}

static bool match_pattern(const std::vector<macro_pat_elem>& pats,
                          const std::vector<token_t>& ts, size_t& pos,
                          capture_map& caps)
{
    for (size_t pi = 0; pi < pats.size(); pi++) {
        const auto& p = pats[pi];
        if (pos > ts.size()) return false;

        switch (p.kind) {
        case macro_pat_kind::str_match: {
            // Match an identifier or keyword whose value == p.cap_name
            if (pos >= ts.size()) return false;
            const auto& t = ts[pos];
            bool ok = (t.type == token_type::id && t.value == p.cap_name);
            // Also allow keyword tokens whose value matches
            if (!ok) {
                // Check if it's any token type whose text is the string
                ok = (t.value == p.cap_name);
            }
            if (!ok) return false;
            pos++;
            break;
        }
        case macro_pat_kind::tok: {
            if (pos >= ts.size()) return false;
            // Match token type (and for identifiers/keywords, also the value)
            const auto& t = ts[pos];
            if (t.type != p.tok.type) return false;
            if (p.tok.type == token_type::id && !p.tok.value.empty() &&
                t.value != p.tok.value) return false;
            pos++;
            break;
        }
        case macro_pat_kind::capture: {
            std::vector<token_t> captured;
            if (!consume_fragment(p.cap_type, ts, pos, captured)) return false;
            caps[p.cap_name] = std::move(captured);
            break;
        }
        case macro_pat_kind::variadic: {
            // Collect zero or more repetitions of sub-pattern
            std::vector<std::vector<token_t>> reps;
            size_t saved = pos;
            while (pos < ts.size()) {
                capture_map sub_caps;
                size_t try_pos = pos;
                bool matched = match_pattern(p.sub, ts, try_pos, sub_caps);
                if (!matched) break;
                // Check separator (comma between repetitions)
                if (!reps.empty() && try_pos < ts.size() &&
                    ts[try_pos].type == token_type::comma)
                    try_pos++; // consume the separator between reps
                pos = try_pos;
                // Merge sub_caps into a combined token sequence per name
                for (auto& [k, v] : sub_caps) {
                    for (auto& tok : v) caps[p.cap_name + "/" + k].push_back(tok);
                    // Also accumulate all as a flat sequence under cap_name
                    for (auto& tok : v) caps[p.cap_name].push_back(tok);
                }
                // Collect a flat token sequence for the whole rep
                std::vector<token_t> rep_flat;
                for (auto& [k, v] : sub_caps)
                    for (auto& tok : v) rep_flat.push_back(tok);
                reps.push_back(std::move(rep_flat));
                if (p.rep_mod == '?') break; // at most one
            }
            if (p.rep_mod == '+' && reps.empty()) {
                pos = saved; return false; // need at least one
            }
            break;
        }
        }
    }
    return true;
}

// ============================================================
// Expansion: substitute $name references in expansion template
// ============================================================

static std::vector<token_t>
expand_macro(const std::vector<token_t>& templ, const capture_map& caps,
             uint64_t invoc_line)
{
    std::vector<token_t> result;
    size_t i = 0;
    while (i < templ.size()) {
        // $name — substitute captured tokens
        if (templ[i].type == token_type::dollar && i + 1 < templ.size() &&
            templ[i+1].type == token_type::id) {
            std::string name = templ[i+1].value;
            // $name? — optional (emit only if present)
            bool optional = (i + 2 < templ.size() &&
                             templ[i+2].type == token_type::question);
            auto it = caps.find(name);
            if (it != caps.end()) {
                for (auto tok : it->second) {
                    tok.line = invoc_line;
                    result.push_back(tok);
                }
            }
            i += optional ? 3 : 2;
            continue;
        }
        auto tok = templ[i];
        tok.line = invoc_line;
        result.push_back(tok);
        i++;
    }
    return result;
}

// ============================================================
// Rule body parser: parse { rules } from a token sub-sequence
// Expects tokens extracted from inside the outer { } of the definition.
// ============================================================

// Parse expansion tokens from inside a { } block: returns everything between { and }
static std::vector<token_t>
collect_balanced_braces(const std::vector<token_t>& ts, size_t& pos)
{
    std::vector<token_t> out;
    if (pos >= ts.size() || ts[pos].type != token_type::obrace) return out;
    pos++; // skip {
    int depth = 1;
    while (pos < ts.size() && depth > 0) {
        if (ts[pos].type == token_type::obrace)  depth++;
        if (ts[pos].type == token_type::cbrace) { depth--; if (depth == 0) { pos++; break; } }
        out.push_back(ts[pos++]);
    }
    return out;
}

// Parse pattern tokens from inside ( ) or [ ]
static std::vector<token_t>
collect_balanced(const std::vector<token_t>& ts, size_t& pos,
                 token_type open, token_type close)
{
    std::vector<token_t> out;
    if (pos >= ts.size() || ts[pos].type != open) return out;
    pos++; // skip open
    int depth = 1;
    while (pos < ts.size() && depth > 0) {
        if (ts[pos].type == open)  depth++;
        if (ts[pos].type == close) { depth--; if (depth == 0) { pos++; break; } }
        if (depth > 0) out.push_back(ts[pos]);
        pos++;
    }
    return out;
}

static macro_def parse_macro_def(const std::string& name,
                                  const std::vector<token_t>& body_tokens)
{
    macro_def def;
    def.name = name;

    size_t pos = 0;
    while (pos < body_tokens.size()) {
        // Skip commas between rules
        while (pos < body_tokens.size() && body_tokens[pos].type == token_type::comma)
            pos++;
        if (pos >= body_tokens.size()) break;

        macro_rule rule;

        // Pattern: ( ... ) or [ ... ]
        if (body_tokens[pos].type == token_type::oparen) {
            auto pat_ts = collect_balanced(body_tokens, pos, token_type::oparen, token_type::cparen);
            size_t pp = 0;
            rule.pats = parse_macro_pattern(pat_ts, pp);
            rule.is_syntax = false;
        } else if (body_tokens[pos].type == token_type::obracket) {
            auto pat_ts = collect_balanced(body_tokens, pos, token_type::obracket, token_type::cbracket);
            // In [] syntax rules, commas are pattern separators, not literal tokens to match.
            pat_ts.erase(std::remove_if(pat_ts.begin(), pat_ts.end(),
                [](const token_t& t) { return t.type == token_type::comma; }), pat_ts.end());
            size_t pp = 0;
            rule.pats = parse_macro_pattern(pat_ts, pp);
            rule.is_syntax = true;
        } else {
            pos++; continue; // unexpected
        }

        // =>
        if (pos < body_tokens.size() && body_tokens[pos].type == token_type::assign) pos++;
        if (pos < body_tokens.size() && body_tokens[pos].type == token_type::gt)     pos++;

        // { expansion }
        rule.expansion = collect_balanced_braces(body_tokens, pos);

        def.rules.push_back(std::move(rule));
    }
    return def;
}
