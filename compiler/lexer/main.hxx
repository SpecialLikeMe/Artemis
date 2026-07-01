#pragma once
#include <string>
#include <vector>
#include <stdexcept>
#include <cctype>
#include <cstdint>
#include <unordered_map>

enum class token_type {
    //basics
    eof,
    num,        // (kept for compatibility; int_lit / float_lit used by lexer)
    id,
    newline,
    err,

    //syntax
    obrace,     // {
    cbrace,     // }
    oparen,     // (
    cparen,     // )
    sm,         // ;
    colon,      // :
    scope_res,  // ::
    question,   // ?

    //operators
    eq,         // ==
    ne,         // !=
    lt,         // <
    gt,         // >
    lte,        // <=
    gte,        // >=
    plus,       // +
    and_,       // &&
    or_,        // ||
    not_,       // !
    minus,      // -
    ast,        // *
    slash,      // /
    comma,      // ,
    dot,        // .
    obracket,   // [
    cbracket,   // ]
    at,         // @
    hash,       // #
    addr,       // &  (single &, also bitwise AND)
    assign,     // =

    // compound assignment
    plus_eq,    // +=
    minus_eq,   // -=
    star_eq,    // *=
    slash_eq,   // /=
    mod_eq,     // %=
    amp_eq,     // &=
    pipe_eq,    // |=
    caret_eq,   // ^=
    shl_eq,     // <<=
    shr_eq,     // >>=

    // arithmetic extras
    mod,        // %
    inc,        // ++
    dec,        // --

    //bitwise
    left,       // <<
    right,      // >>
    bit_or,     // |
    bit_xor,    // ^
    bit_not,    // ~

    //literals
    int_lit,
    float_lit,
    string_lit,
    char_lit,

    //keywords
    kw_if,
    kw_else,
    kw_while,
    kw_switch,
    kw_case,
    kw_default,
    kw_for,
    kw_return,
    kw_break,
    kw_continue,
    kw_signed,
    kw_unsigned,
    kw_const,
    kw_register,
    kw_extern,
    kw_extern_std,
    kw_inline,
    kw_sizeof,
    kw_true,
    kw_false,
    kw_volatile,
    kw_void,
    kw_null,

    //kw types
    kw_char,
    kw_i8, kw_i16, kw_i32, kw_i64, kw_i128, kw_i256, kw_i512,
    kw_u8, kw_u16, kw_u32, kw_u64, kw_u128, kw_u256, kw_u512,
    kw_f8, kw_f16, kw_f32, kw_f64, kw_f128, kw_f256, kw_f512,
    kw_bool /*an 8 bit bool*/, kw_b1 /*a 1 bit bool, kw b1*/, kw_b8, kw_b16, kw_b32, kw_b64, kw_b128, kw_b256, kw_b512,

    kw_struct,
    kw_enum,
    kw_union,
    kw_smem,
    kw_typedef,

    kw_asm,     // __asm__
    asm_body,   // raw { ... } body following __asm__

    // OOP / class keywords
    kw_istruc,      // istruc  (class)
    kw_interface,   // interface (contract declaration)
    kw_public,      // public
    kw_private,     // private
    kw_protected,   // protected
    kw_virtual,     // virtual
    kw_override,    // override
    kw_final,       // final
    kw_static,      // static
    kw_mandatory,   // mandatory (for mandatory virtual)
    kw_noexcept,    // noexcept
    kw_explicit,    // explicit
    kw_constexpr,   // constexpr
    kw_consteval,   // consteval — marks a var as manually-constructed
    kw_sta,         // sta (comptime type-erased param)
    kw_local,       // local (friend-like)
    kw_operator,    // operator
    kw_self,        // self
    kw_this,        // this (type alias for enclosing class in method params)

    // Misc
    kw_defer,       // defer
    kw_extern_c,    // extern "C"
    kw_namespace,   // namespace
    kw_try,         // try
    kw_except,      // except
    kw_throw,       // throw
    arrow,          // ->

    // New features
    kw_auto,        // auto (type inference / trailing type placeholder)
    kw_using,       // using (contextual alias: using let = const auto;)
    kw_pragma,      // pragma (preprocessor hint: @pragma once)
    kw_derive,      // derive (proc macro marker)
    kw_attr,        // attr   (proc macro marker)
    kw_macro,       // macro  (proc macro marker)
    kw_verify,      // verify (proc macro syntax-check flag)
    kw_quote,       // quote  (tokenstream literal block)
    kw_const_resolve, // const_resolve (fn macro definition)
    kw_res,         // res    (error-handling resource block)
    kw_error,       // error  (error literal: error.Variant)
    kw_null_t,      // null_t (internal nullable wrapper — not a source keyword)
};

struct token_t {
    token_type  type;
    std::string value;
    int         line;
};

class lexer {
public:
    explicit lexer(std::string source) : src(std::move(source)), cursor(0), line(1) {}

    std::vector<token_t> tokenize() {
        std::vector<token_t> tokens;

        while (!is_at_end()) {
            skip_whitespace_and_comments(tokens);
            if (is_at_end()) break;

            char c = peek();

            if (c == '\n') {
                line++;
                advance();
                continue;
            }

            if (std::isalpha(c) || c == '_') {
                auto ident_tok = read_identifier_or_keyword();
                tokens.push_back(ident_tok);
                if (ident_tok.type == token_type::kw_asm) {
                    skip_to_brace();
                    if (!is_at_end() && peek() == '{')
                        tokens.push_back(read_asm_body());
                }
                continue;
            }

            if (std::isdigit(c) || (c == '.' && std::isdigit(peek_next()))) {
                tokens.push_back(read_number());
                continue;
            }

            if (c == '"') { tokens.push_back(read_string()); continue; }
            if (c == '\'') { tokens.push_back(read_char()); continue; }

            tokens.push_back(read_symbol());
        }

        tokens.push_back({token_type::eof, "", line});
        return tokens;
    }

private:
    // ------------------------------------------------------------------ helpers
    char peek() const          { return is_at_end() ? '\0' : src[cursor]; }
    char peek_next() const     { return (cursor + 1 >= src.size()) ? '\0' : src[cursor + 1]; }
    char peek_at(int n) const  { return (cursor + n >= src.size()) ? '\0' : src[cursor + n]; }
    char advance()             { return is_at_end() ? '\0' : src[cursor++]; }
    bool is_at_end() const     { return cursor >= src.size(); }

    void skip_whitespace_and_comments(std::vector<token_t>& /*tokens*/) {
        while (!is_at_end()) {
            char c = peek();
            if (c == ' ' || c == '\r' || c == '\t') { advance(); continue; }

            // single-line comment
            if (c == '/' && peek_next() == '/') {
                while (!is_at_end() && peek() != '\n') advance();
                continue;
            }
            // block comment
            if (c == '/' && peek_next() == '*') {
                advance(); advance(); // consume /*
                while (!is_at_end()) {
                    if (peek() == '\n') line++;
                    if (peek() == '*' && peek_next() == '/') { advance(); advance(); break; }
                    advance();
                }
                continue;
            }
            break;
        }
    }

    // ------------------------------------------------------------------ identifier / keyword
    static const std::unordered_map<std::string, token_type>& keyword_map() {
        static const std::unordered_map<std::string, token_type> m = {
            {"if",         token_type::kw_if},
            {"else",       token_type::kw_else},
            {"while",      token_type::kw_while},
            {"switch",     token_type::kw_switch},
            {"case",       token_type::kw_case},
            {"default",    token_type::kw_default},
            {"for",        token_type::kw_for},
            {"return",     token_type::kw_return},
            {"break",      token_type::kw_break},
            {"continue",   token_type::kw_continue},
            {"signed",     token_type::kw_signed},
            {"unsigned",   token_type::kw_unsigned},
            {"const",      token_type::kw_const},
            {"register",   token_type::kw_register},
            {"extern",     token_type::kw_extern},
            {"inline",     token_type::kw_inline},
            {"sizeof",     token_type::kw_sizeof},
            {"true",       token_type::kw_true},
            {"false",      token_type::kw_false},
            {"volatile",   token_type::kw_volatile},
            {"void",       token_type::kw_void},
            {"null",       token_type::kw_null},
            {"char",       token_type::kw_char},
            {"i8",         token_type::kw_i8},
            {"i16",        token_type::kw_i16},
            {"i32",        token_type::kw_i32},
            {"int",        token_type::kw_i32},
            {"i64",        token_type::kw_i64},
            {"i128",       token_type::kw_i128},
            {"i256",       token_type::kw_i256},
            {"i512",       token_type::kw_i512},
            {"u8",         token_type::kw_u8},
            {"u16",        token_type::kw_u16},
            {"u32",        token_type::kw_u32},
            {"uint",       token_type::kw_u32},
            {"u64",        token_type::kw_u64},
            {"u128",       token_type::kw_u128},
            {"u256",       token_type::kw_u256},
            {"u512",       token_type::kw_u512},
            {"f8",         token_type::kw_f8},
            {"f16",        token_type::kw_f16},
            {"f32",        token_type::kw_f32},
            {"f64",        token_type::kw_f64},
            {"float",      token_type::kw_f64},
            {"f128",       token_type::kw_f128},
            {"f256",       token_type::kw_f256},
            {"f512",       token_type::kw_f512},
            {"bool",       token_type::kw_bool},
            {"b1",         token_type::kw_b1},
            {"b8",         token_type::kw_b8},
            {"b16",        token_type::kw_b16},
            {"b32",        token_type::kw_b32},
            {"b64",        token_type::kw_b64},
            {"b128",       token_type::kw_b128},
            {"b256",       token_type::kw_b256},
            {"b512",       token_type::kw_b512},
            {"struct",     token_type::kw_struct},
            {"enum",       token_type::kw_enum},
            {"union",      token_type::kw_union},
            {"typedef",    token_type::kw_typedef},
            {"memstr",     token_type::kw_smem},
            {"__asm__",    token_type::kw_asm},
            {"istruc",     token_type::kw_istruc},
            {"interface",  token_type::kw_interface},
            {"public",     token_type::kw_public},
            {"private",    token_type::kw_private},
            {"protected",  token_type::kw_protected},
            {"virtual",    token_type::kw_virtual},
            {"override",   token_type::kw_override},
            {"final",      token_type::kw_final},
            {"static",     token_type::kw_static},
            {"mandatory",  token_type::kw_mandatory},
            {"noexcept",   token_type::kw_noexcept},
            {"constexpr",  token_type::kw_constexpr},
            {"consteval",  token_type::kw_consteval},
            {"sta",        token_type::kw_sta},
            {"local",      token_type::kw_local},
            {"operator",   token_type::kw_operator},
            {"self",       token_type::kw_self},
            {"this",       token_type::kw_this},
            {"defer",      token_type::kw_defer},
            {"namespace",  token_type::kw_namespace},
            {"try",            token_type::kw_try},
            {"except",         token_type::kw_except},
            {"throw",          token_type::kw_throw},
            {"explicit",       token_type::kw_explicit},
            {"auto",           token_type::kw_auto},
            {"using",          token_type::kw_using},
            {"const_resolve",  token_type::kw_const_resolve},
        };
        return m;
    }

    token_t read_identifier_or_keyword() {
        int tok_line = line;
        size_t start = cursor;
        while (!is_at_end() && (std::isalnum(peek()) || peek() == '_')) advance();
        std::string value = src.substr(start, cursor - start);

        // Check for "extern std" and extern "C"
        if (value == "extern") {
            size_t save = cursor;
            int    save_line = line;
            // skip whitespace
            while (!is_at_end() && (peek() == ' ' || peek() == '\t')) advance();
            // Check for extern "C"
            if (!is_at_end() && peek() == '"') {
                size_t q_save = cursor; int ql_save = line;
                advance(); // consume opening "
                if (!is_at_end() && peek() == 'C') {
                    advance(); // consume C
                    if (!is_at_end() && peek() == '"') {
                        advance(); // consume closing "
                        return {token_type::kw_extern_c, "extern \"C\"", tok_line};
                    }
                }
                cursor = q_save; line = ql_save; // roll back quote attempt
            }
            size_t id_start = cursor;
            while (!is_at_end() && (std::isalnum(peek()) || peek() == '_')) advance();
            std::string next = src.substr(id_start, cursor - id_start);
            if (next == "std") return {token_type::kw_extern_std, "extern std", tok_line};
            // roll back
            cursor = save;
            line   = save_line;
        }

        auto it = keyword_map().find(value);
        if (it != keyword_map().end()) return {it->second, value, tok_line};
        return {token_type::id, value, tok_line};
    }

    // ------------------------------------------------------------------ numbers
    token_t read_number() {
        int tok_line = line;
        size_t start = cursor;
        bool is_float = false;

        // hex
        if (peek() == '0' && (peek_next() == 'x' || peek_next() == 'X')) {
            advance(); advance();
            while (!is_at_end() && std::isxdigit(peek())) advance();
            // consume optional u/U/l/L/ull/etc. suffix (strip, same as decimal)
            while (!is_at_end() && (peek() == 'u' || peek() == 'U' ||
                                    peek() == 'l' || peek() == 'L')) advance();
            return {token_type::int_lit, src.substr(start, cursor - start), tok_line};
        }
        // binary prefix
        if (peek() == '0' && (peek_next() == 'b' || peek_next() == 'B')) {
            advance(); advance();
            while (!is_at_end() && (peek() == '0' || peek() == '1')) advance();
            while (!is_at_end() && (peek() == 'u' || peek() == 'U' ||
                                    peek() == 'l' || peek() == 'L')) advance();
            return {token_type::int_lit, src.substr(start, cursor - start), tok_line};
        }

        while (!is_at_end() && std::isdigit(peek())) advance();
        if (!is_at_end() && peek() == '.' && std::isdigit(peek_next())) {
            is_float = true;
            advance();
            while (!is_at_end() && std::isdigit(peek())) advance();
        }
        if (!is_at_end() && (peek() == 'e' || peek() == 'E')) {
            is_float = true;
            advance();
            if (!is_at_end() && (peek() == '+' || peek() == '-')) advance();
            while (!is_at_end() && std::isdigit(peek())) advance();
        }
        // optional suffix: f, u, l, ul, ll, ull
        while (!is_at_end() && (peek() == 'f' || peek() == 'F' ||
                                 peek() == 'u' || peek() == 'U' ||
                                 peek() == 'l' || peek() == 'L')) {
            advance();
        }
        std::string val = src.substr(start, cursor - start);
        return {is_float ? token_type::float_lit : token_type::int_lit, val, tok_line};
    }

    // ------------------------------------------------------------------ string
    token_t read_string() {
        int tok_line = line;
        advance(); // opening "
        std::string result;
        while (!is_at_end() && peek() != '"') {
            if (peek() == '\\') { result += read_escape(); }
            else                { if (peek() == '\n') line++; result += advance(); }
        }
        if (is_at_end()) throw std::runtime_error("Lexer Error: unterminated string at line " + std::to_string(tok_line));
        advance(); // closing "
        return {token_type::string_lit, result, tok_line};
    }

    token_t read_char() {
        int tok_line = line;
        advance(); // opening '
        std::string result;
        if (peek() == '\\') result += read_escape();
        else                result += advance();
        if (peek() != '\'') throw std::runtime_error("Lexer Error: unterminated char literal at line " + std::to_string(tok_line));
        advance(); // closing '
        return {token_type::char_lit, result, tok_line};
    }

    char read_escape() {
        advance(); // consume backslash
        char c = advance();
        switch (c) {
            case 'n':  return '\n';
            case 't':  return '\t';
            case 'r':  return '\r';
            case '\\': return '\\';
            case '\'': return '\'';
            case '"':  return '"';
            case '0':  return '\0';
            default:   return c;
        }
    }

    // ------------------------------------------------------------------ symbols
    token_t read_symbol() {
        int tok_line = line;
        char c = advance();
        switch (c) {
            case '{': return {token_type::obrace,    "{", tok_line};
            case '}': return {token_type::cbrace,    "}", tok_line};
            case '(': return {token_type::oparen,    "(", tok_line};
            case ')': return {token_type::cparen,    ")", tok_line};
            case '[': return {token_type::obracket,  "[", tok_line};
            case ']': return {token_type::cbracket,  "]", tok_line};
            case ';': return {token_type::sm,        ";", tok_line};
            case ',': return {token_type::comma,     ",", tok_line};
            case '.': return {token_type::dot,       ".", tok_line};
            case '@': return {token_type::at,        "@", tok_line};
            case '#': return {token_type::hash,      "#", tok_line};
            case '~': return {token_type::bit_not,   "~", tok_line};
            case '^': return match_next('=') ? token_t{token_type::caret_eq,  "^=", tok_line}
                                             : token_t{token_type::bit_xor,  "^",  tok_line};
            case '?': return {token_type::question,  "?", tok_line};
            case ':': return match_next(':') ? token_t{token_type::scope_res, "::", tok_line}
                                           : token_t{token_type::colon,     ":",  tok_line};
            case '%': return match_next('=') ? token_t{token_type::mod_eq,   "%=", tok_line}
                                             : token_t{token_type::mod,      "%",  tok_line};
            case '+':
                if (match_next('+')) return {token_type::inc,      "++", tok_line};
                if (match_next('=')) return {token_type::plus_eq,  "+=", tok_line};
                return {token_type::plus, "+", tok_line};
            case '-':
                if (match_next('-')) return {token_type::dec,      "--", tok_line};
                if (match_next('=')) return {token_type::minus_eq, "-=", tok_line};
                if (match_next('>')) return {token_type::arrow,    "->", tok_line};
                return {token_type::minus, "-", tok_line};
            case '*':
                return match_next('=') ? token_t{token_type::star_eq,  "*=", tok_line}
                                       : token_t{token_type::ast,      "*",  tok_line};
            case '/':
                return match_next('=') ? token_t{token_type::slash_eq, "/=", tok_line}
                                       : token_t{token_type::slash,    "/",  tok_line};
            case '=':
                return match_next('=') ? token_t{token_type::eq,     "==", tok_line}
                                       : token_t{token_type::assign,  "=",  tok_line};
            case '!':
                return match_next('=') ? token_t{token_type::ne,    "!=", tok_line}
                                       : token_t{token_type::not_,   "!",  tok_line};
            case '<':
                if (match_next('<')) {
                    return match_next('=') ? token_t{token_type::shl_eq, "<<=", tok_line}
                                           : token_t{token_type::left,   "<<",  tok_line};
                }
                return match_next('=') ? token_t{token_type::lte, "<=", tok_line}
                                       : token_t{token_type::lt,  "<",  tok_line};
            case '>':
                if (match_next('>')) {
                    return match_next('=') ? token_t{token_type::shr_eq, ">>=", tok_line}
                                           : token_t{token_type::right,  ">>",  tok_line};
                }
                return match_next('=') ? token_t{token_type::gte, ">=", tok_line}
                                       : token_t{token_type::gt,  ">",  tok_line};
            case '&':
                if (match_next('&')) return {token_type::and_,   "&&", tok_line};
                if (match_next('=')) return {token_type::amp_eq, "&=", tok_line};
                return {token_type::addr, "&", tok_line};
            case '|':
                if (match_next('|')) return {token_type::or_,   "||", tok_line};
                if (match_next('=')) return {token_type::pipe_eq, "|=", tok_line};
                return {token_type::bit_or, "|", tok_line};
            default:
                return {token_type::err, std::string(1, c), tok_line};
        }
    }

    // Peek at current char; if it matches, consume and return true.
    bool match_next(char expected) {
        if (is_at_end() || peek() != expected) return false;
        advance();
        return true;
    }

    // Skip spaces, tabs, \r, and \n (including line counting) until a non-whitespace char.
    void skip_to_brace() {
        while (!is_at_end()) {
            char c = peek();
            if (c == ' ' || c == '\t' || c == '\r') { advance(); continue; }
            if (c == '\n') { line++; advance(); continue; }
            break;
        }
    }

    // Read the body of __asm__ { ... } as a single token.
    // The opening '{' must be the current character when called.
    token_t read_asm_body() {
        int tok_line = line;
        advance(); // consume '{'
        std::string body;
        int depth = 1;
        while (!is_at_end() && depth > 0) {
            char c = peek();
            if (c == '{') {
                depth++;
                body += c;
                advance();
            } else if (c == '}') {
                depth--;
                if (depth == 0) { advance(); break; } // consume closing '}', done
                body += c;
                advance();
            } else {
                if (c == '\n') line++;
                body += c;
                advance();
            }
        }
        return {token_type::asm_body, body, tok_line};
    }

    std::string src;
    size_t      cursor;
    int         line;
};
