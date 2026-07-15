// Minimal preprocessor for the Artemis self-hosting (boot) compiler.
// Handles: @define, @undef, @ifdef, @ifndef, @elifdef, @elifndef, @else, @endif,
//          @include, @embed, @error.
// Regex-pattern @define is NOT supported; <PATTERN> treated as a literal name.

namespace preproc {

// ---- dynamic string buffer ----

struct strbuf {
    i8* data;
    u64 len;
    u64 cap;
}

void strbuf_init(strbuf* b) {
    b.data = (i8*)malloc(1024u);
    b.len  = 0u;
    b.cap  = 1024u;
}

void strbuf_ensure(strbuf* b, u64 extra) {
    if (b.len + extra < b.cap) { return; }
    u64 nc = b.cap * 2u + extra + 1u;
    b.data = (i8*)realloc(b.data, nc);
    b.cap  = nc;
}

void strbuf_push(strbuf* b, i8 c) {
    strbuf_ensure(b, 1u);
    b.data[b.len] = c;
    b.len = b.len + 1u;
}

void strbuf_append(strbuf* b, i8* s, u64 n) {
    strbuf_ensure(b, n);
    u64 i = 0u;
    while (i < n) { b.data[b.len + i] = s[i]; i = i + 1u; }
    b.len = b.len + n;
}

void strbuf_append_cstr(strbuf* b, i8* s) {
    if (s == (i8*)0) { return; }
    u64 n = (u64)strlen(s);
    strbuf_append(b, s, n);
}

i8* strbuf_finish(strbuf* b) {
    strbuf_ensure(b, 1u);
    b.data[b.len] = 0;
    return b.data;
}

// ---- macro table (parallel arrays, avoids array-of-struct IR issues) ----

struct pp_table {
    i8* names[512];
    i8* values[512];
    i32 count;
}

void pp_table_init(pp_table* t) { t.count = 0; }

bool pp_defined(pp_table* t, i8* name) {
    i32 i = 0;
    while (i < t.count) {
        if (strcmp(t.names[i], name) == 0) { return true; }
        i = i + 1;
    }
    return false;
}

i8* pp_get(pp_table* t, i8* name) {
    i32 i = 0;
    while (i < t.count) {
        if (strcmp(t.names[i], name) == 0) { return t.values[i]; }
        i = i + 1;
    }
    return (i8*)0;
}

void pp_set(pp_table* t, i8* name, i8* value) {
    i32 i = 0;
    while (i < t.count) {
        if (strcmp(t.names[i], name) == 0) {
            t.values[i] = value;
            return;
        }
        i = i + 1;
    }
    if (t.count < 512) {
        t.names[t.count]  = name;
        t.values[t.count] = value;
        t.count = t.count + 1;
    }
}

void pp_undef(pp_table* t, i8* name) {
    i32 i = 0;
    while (i < t.count) {
        if (strcmp(t.names[i], name) == 0) {
            i32 last = t.count - 1;
            t.names[i]  = t.names[last];
            t.values[i] = t.values[last];
            t.count = t.count - 1;
            return;
        }
        i = i + 1;
    }
}

// ---- helpers ----

bool pp_is_id_start(i8 c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
}
bool pp_is_id_cont(i8 c) {
    return pp_is_id_start(c) || (c >= '0' && c <= '9');
}

i8* pp_substr_dup(i8* s, i32 len) {
    i8* r = (i8*)malloc((u64)(len + 1));
    i32 i = 0;
    while (i < len) { r[i] = s[i]; i = i + 1; }
    r[len] = 0;
    return r;
}

// Extract content inside <...>; returns pointer to inside, writes length.
i8* pp_extract_angle(i8* s, i32* out_len) {
    while (*s == ' ' || *s == '\t') { s = s + 1; }
    if (*s != '<') { *out_len = 0; return (i8*)0; }
    s = s + 1;
    i8* start = s;
    i32 depth = 1;
    i32 len = 0;
    while (*s != 0 && depth > 0) {
        if (*s == '<') { depth = depth + 1; }
        else if (*s == '>') { depth = depth - 1; }
        if (depth > 0) { len = len + 1; s = s + 1; }
    }
    *out_len = len;
    return start;
}

// Apply macro substitutions to one line (line_len bytes from line).
void pp_apply(pp_table* t, i8* line, i32 line_len, strbuf* out) {
    i32 i = 0;
    while (i < line_len) {
        i8 c = line[i];
        // Skip string literals
        if (c == '"') {
            strbuf_push(out, c); i = i + 1;
            while (i < line_len && line[i] != '"') {
                if (line[i] == '\\' && i + 1 < line_len) {
                    strbuf_push(out, line[i]); i = i + 1;
                }
                strbuf_push(out, line[i]); i = i + 1;
            }
            if (i < line_len) { strbuf_push(out, line[i]); i = i + 1; }
            continue;
        }
        // Skip // line comments — copy rest as-is
        if (c == '/' && i + 1 < line_len && line[i+1] == '/') {
            strbuf_append(out, line + i, (u64)(line_len - i));
            return;
        }
        // Identifier: try substitution
        if (pp_is_id_start(c)) {
            i32 j = i + 1;
            while (j < line_len && pp_is_id_cont(line[j])) { j = j + 1; }
            i8* id = pp_substr_dup(line + i, j - i);
            i8* repl = pp_get(t, id);
            free(id);
            if (repl != (i8*)0) {
                strbuf_append_cstr(out, repl);
            } else {
                strbuf_append(out, line + i, (u64)(j - i));
            }
            i = j;
            continue;
        }
        strbuf_push(out, c);
        i = i + 1;
    }
}

// ---- conditional stack (parallel arrays, avoids array-of-struct IR issues) ----

struct pp_stack {
    bool active[64];
    bool ever_active[64];
    bool done[64];
    i32  depth;
}

void pp_stack_init(pp_stack* s) { s.depth = 0; }

bool pp_all_active(pp_stack* s) {
    i32 i = 0;
    while (i < s.depth) {
        if (!s.active[i]) { return false; }
        i = i + 1;
    }
    return true;
}

bool pp_parents_active(pp_stack* s) {
    i32 i = 0;
    while (i < s.depth - 1) {
        if (!s.active[i]) { return false; }
        i = i + 1;
    }
    return true;
}

// ---- read a file ----
i8* pp_read_file(i8* path) {
    void* fp = fopen(path, "rb");
    if (fp == (void*)0) { return (i8*)0; }
    fseek(fp, (i64)0, 2);
    i64 sz = ftell(fp);
    fseek(fp, (i64)0, 0);
    if (sz < 0) { fclose(fp); return (i8*)0; }
    i8* buf = (i8*)malloc((u64)(sz + 1));
    u64 n   = fread(buf, 1u, (u64)sz, fp);
    buf[n]  = 0;
    fclose(fp);
    return buf;
}

// Forward declaration
i8* preprocess_inner(i8* src, i8* base_dir, pp_table* macros);

// ---- core pass ----
i8* preprocess_inner(i8* src, i8* base_dir, pp_table* macros) {
    strbuf  out;
    pp_stack cs;
    strbuf_init(&out);
    pp_stack_init(&cs);

    i32 pos = 0;

    while (src[pos] != 0) {
        i32 line_start = pos;
        while (src[pos] != 0 && src[pos] != '\n') { pos = pos + 1; }
        i32 line_end = pos;
        if (src[pos] == '\n') { pos = pos + 1; }
        // Strip trailing \r for Windows line endings
        if (line_end > line_start && src[line_end - 1] == '\r') { line_end = line_end - 1; }

        i8* line = src + line_start;
        i32 line_len = line_end - line_start;

        // Trim indent to find directive
        i32 ind = 0;
        while (ind < line_len && (line[ind] == ' ' || line[ind] == '\t')) { ind = ind + 1; }

        bool is_dir = (ind < line_len && line[ind] == '@');
        if (is_dir) {
            i32 ks = ind + 1;
            i32 ke = ks;
            while (ke < line_len && pp_is_id_cont(line[ke])) { ke = ke + 1; }
            i8* kw = pp_substr_dup(line + ks, ke - ks);
            i8* rest = line + ke;
            while (*rest == ' ' || *rest == '\t') { rest = rest + 1; }

            if (strcmp(kw, "define") == 0) {
                if (pp_all_active(&cs)) {
                    i32 plen = 0;
                    i8* pstart = pp_extract_angle(rest, &plen);
                    if (pstart != (i8*)0) {
                        i8* pat = pp_substr_dup(pstart, plen);
                        i8* after = pstart + plen + 1;
                        while (*after == ' ' || *after == '\t') { after = after + 1; }
                        i32 vlen = 0;
                        i8* vstart = pp_extract_angle(after, &vlen);
                        i8* val;
                        if (vstart != (i8*)0) {
                            val = pp_substr_dup(vstart, vlen);
                        } else {
                            val = (i8*)malloc(1u);
                            val[0] = 0;
                        }
                        pp_set(macros, pat, val);
                    }
                }
            } else if (strcmp(kw, "undef") == 0) {
                if (pp_all_active(&cs)) {
                    i32 nlen = 0;
                    i8* nstart = pp_extract_angle(rest, &nlen);
                    if (nstart != (i8*)0) {
                        i8* n = pp_substr_dup(nstart, nlen);
                        pp_undef(macros, n); free(n);
                    } else {
                        i32 j = 0;
                        while (rest[j] != 0 && rest[j] != ' ' && rest[j] != '\t' && rest[j] != '\r' && rest[j] != '\n') { j = j + 1; }
                        if (j > 0) { i8* n = pp_substr_dup(rest, j); pp_undef(macros, n); free(n); }
                    }
                }
            } else if (strcmp(kw, "ifdef") == 0 || strcmp(kw, "ifndef") == 0) {
                i32 nlen = 0;
                i8* nstart = pp_extract_angle(rest, &nlen);
                i8* name;
                if (nstart != (i8*)0) {
                    name = pp_substr_dup(nstart, nlen);
                } else {
                    i32 j = 0;
                    while (rest[j] != 0 && rest[j] != ' ' && rest[j] != '\t' && rest[j] != '\r' && rest[j] != '\n') { j = j + 1; }
                    name = pp_substr_dup(rest, j);
                }
                bool def = pp_defined(macros, name);
                free(name);
                bool cond;
                if (strcmp(kw, "ifdef") == 0) { cond = def; } else { cond = !def; }
                if (cs.depth < 64) {
                    cs.active[cs.depth]      = cond && pp_all_active(&cs);
                    cs.ever_active[cs.depth]  = cs.active[cs.depth];
                    cs.done[cs.depth]         = false;
                    cs.depth = cs.depth + 1;
                }
            } else if (strcmp(kw, "elifdef") == 0 || strcmp(kw, "elifndef") == 0) {
                if (cs.depth > 0) {
                    i32 ti = cs.depth - 1;
                    if (!cs.ever_active[ti] && !cs.done[ti]) {
                        i32 nlen = 0;
                        i8* nstart = pp_extract_angle(rest, &nlen);
                        i8* name;
                        if (nstart != (i8*)0) {
                            name = pp_substr_dup(nstart, nlen);
                        } else {
                            i32 j = 0;
                            while (rest[j] != 0 && rest[j] != ' ' && rest[j] != '\t' && rest[j] != '\r' && rest[j] != '\n') { j = j + 1; }
                            name = pp_substr_dup(rest, j);
                        }
                        bool def = pp_defined(macros, name);
                        free(name);
                        bool cond;
                        if (strcmp(kw, "elifdef") == 0) { cond = def; } else { cond = !def; }
                        cs.active[ti] = cond && pp_parents_active(&cs);
                        cs.ever_active[ti] = cs.ever_active[ti] || cs.active[ti];
                    } else {
                        cs.active[cs.depth - 1] = false;
                    }
                }
            } else if (strcmp(kw, "else") == 0) {
                if (cs.depth > 0) {
                    i32 ti = cs.depth - 1;
                    if (!cs.ever_active[ti] && !cs.done[ti]) {
                        cs.active[ti]      = pp_parents_active(&cs);
                        cs.ever_active[ti] = true;
                        cs.done[ti]        = true;
                    } else {
                        cs.active[ti] = false;
                        cs.done[ti]   = true;
                    }
                }
            } else if (strcmp(kw, "endif") == 0) {
                if (cs.depth > 0) { cs.depth = cs.depth - 1; }
            } else if (strcmp(kw, "include") == 0 || strcmp(kw, "embed") == 0) {
                if (pp_all_active(&cs) && base_dir != (i8*)0) {
                    i32 flen = 0;
                    i8* fstart = pp_extract_angle(rest, &flen);
                    if (fstart != (i8*)0) {
                        i8* fname = pp_substr_dup(fstart, flen);
                        i8 fpath[2048];
                        snprintf(fpath, 2048u, "%s/%s", base_dir, fname);
                        free(fname);
                        i8* inc = pp_read_file(fpath);
                        if (inc != (i8*)0) {
                            i8* expanded = preprocess_inner(inc, base_dir, macros);
                            strbuf_append_cstr(&out, expanded);
                            free(expanded);
                            free(inc);
                        }
                    }
                }
            } else if (strcmp(kw, "error") == 0) {
                if (pp_all_active(&cs)) {
                    printf("preprocessor error: %s\n", rest);
                }
            }
            // All directives become blank lines
            free(kw);
            strbuf_push(&out, '\n');
        } else {
            if (pp_all_active(&cs)) {
                pp_apply(macros, line, line_len, &out);
            }
            strbuf_push(&out, '\n');
        }
    }

    return strbuf_finish(&out);
}

// Public entry point.
i8* preprocess(i8* src, i8* src_path) {
    pp_table macros;
    pp_table_init(&macros);

    i8 base_dir[2048];
    base_dir[0] = 0;
    if (src_path != (i8*)0) {
        i32 i = 0;
        i32 last_sep = -1;
        while (src_path[i] != 0) {
            if (src_path[i] == '/' || src_path[i] == '\\') { last_sep = i; }
            i = i + 1;
        }
        if (last_sep >= 0) {
            i32 j = 0;
            while (j < last_sep) { base_dir[j] = src_path[j]; j = j + 1; }
            base_dir[last_sep] = 0;
        } else {
            base_dir[0] = '.'; base_dir[1] = 0;
        }
    }

    i8* bd = (base_dir[0] != 0) ? base_dir : (i8*)0;
    return preprocess_inner(src, bd, &macros);
}

} // namespace preproc
// Artemis lexer — tokenizes Artemis source code.

namespace lexer {

// ---- Token types ----
enum token_type {
    // basics
    eof_t      = 0,
    num_t      = 1,
    id         = 2,
    newline_t  = 3,
    err_t      = 4,

    // syntax
    obrace     = 5,   // {
    cbrace     = 6,   // }
    oparen     = 7,   // (
    cparen     = 8,   // )
    sm         = 9,   // ;
    colon      = 10,  // :
    scope_res  = 11,  // ::
    question   = 12,  // ?
    question_question = 13, // ??
    dollar     = 14,  // $

    // operators
    eq         = 15,  // ==
    ne         = 16,  // !=
    lt         = 17,  // <
    gt         = 18,  // >
    lte        = 19,  // <=
    gte        = 20,  // >=
    plus       = 21,  // +
    and_       = 22,  // &&
    or_        = 23,  // ||
    not_       = 24,  // !
    minus      = 25,  // -
    ast        = 26,  // *
    slash      = 27,  // /
    comma      = 28,  // ,
    dot        = 29,  // .
    obracket   = 30,  // [
    cbracket   = 31,  // ]
    at         = 32,  // @
    hash       = 33,  // #
    addr       = 34,  // &
    assign     = 35,  // =

    // compound assignment
    plus_eq    = 36,  // +=
    minus_eq   = 37,  // -=
    star_eq    = 38,  // *=
    slash_eq   = 39,  // /=
    mod_eq     = 40,  // %=
    amp_eq     = 41,  // &=
    pipe_eq    = 42,  // |=
    caret_eq   = 43,  // ^=
    shl_eq     = 44,  // <<=
    shr_eq     = 45,  // >>=

    // arithmetic extras
    mod        = 46,  // %
    inc        = 47,  // ++
    dec        = 48,  // --

    // bitwise
    left       = 49,  // <<
    right      = 50,  // >>
    bit_or     = 51,  // |
    bit_xor    = 52,  // ^
    bit_not    = 53,  // ~

    // literals
    int_lit    = 54,
    float_lit  = 55,
    string_lit = 56,
    char_lit   = 57,

    // keywords
    kw_if       = 58,
    kw_else     = 59,
    kw_while    = 60,
    kw_switch   = 61,
    kw_case     = 62,
    kw_default  = 63,
    kw_for      = 64,
    kw_return   = 65,
    kw_break    = 66,
    kw_continue = 67,
    kw_signed   = 68,
    kw_unsigned = 69,
    kw_const    = 70,
    kw_register = 71,
    kw_extern   = 72,
    kw_inline   = 73,
    kw_sizeof   = 74,
    kw_true     = 75,
    kw_false    = 76,
    kw_volatile = 77,
    kw_void     = 78,
    kw_null     = 79,

    // type keywords
    kw_char     = 80,
    kw_arb_int  = 81,  // iN — value = N as decimal string
    kw_arb_uint = 82,  // uN
    kw_arb_float= 83,  // fN
    kw_arb_bool = 84,  // bN

    kw_struct   = 85,
    kw_enum     = 86,
    kw_union    = 87,
    kw_smem     = 88,
    kw_typedef  = 89,

    kw_asm      = 90,
    asm_body    = 91,

    // OOP / class keywords
    kw_istruc   = 92,
    kw_interface= 93,
    kw_static   = 94,
    kw_noexcept = 95,
    kw_constexpr= 96,
    kw_consteval= 97,
    kw_sta      = 98,
    kw_operator = 99,

    // misc
    kw_defer    = 100,
    kw_errdefer = 101,
    kw_extern_c = 102,
    kw_namespace= 103,
    kw_try      = 104,
    kw_except   = 105,
    arrow       = 106,  // ->

    // newer features
    kw_auto     = 107,
    kw_using    = 108,
    kw_pragma   = 109,
    kw_const_resolve = 110,
    kw_res      = 111,
    kw_error    = 112,
    kw_null_t   = 113,
    kw_token_type = 114,
}

// ---- Token struct ----
struct token_t {
    i32  type;
    i8*  value;
    i32  line;
}

// ---- Dynamic token array ----
struct token_vec {
    token_t* data;
    i32      len;
    i32      cap;
}

void token_vec_init(token_vec* v) {
    v.data = (token_t*)0;
    v.len  = 0;
    v.cap  = 0;
}

void token_vec_push(token_vec* v, token_t t) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 64 : v.cap * 2;
        v.data = (token_t*)realloc((i8*)v.data, sizeof(lexer__NS_token_t) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = t;
    v.len = v.len + 1;
}

// ---- String allocation helpers ----

// Allocate a copy of a substring: src[start..start+len]
i8* str_dup_n(i8* src, i32 start, i32 len) {
    i8* buf = (i8*)malloc((u64)(len + 1));
    memcpy(buf, src + start, (u64)len);
    buf[len] = 0;
    return buf;
}

// Allocate a copy of a null-terminated string
i8* str_dup(i8* src) {
    i32 n = 0;
    while (src[n] != 0) { n = n + 1; }
    return str_dup_n(src, 0, n);
}

// Allocate a single-character string
i8* char_str(i8 c) {
    i8* buf = (i8*)malloc(2);
    buf[0] = c;
    buf[1] = 0;
    return buf;
}

// Allocate a two-character string
i8* char2_str(i8 a, i8 b) {
    i8* buf = (i8*)malloc(3);
    buf[0] = a;
    buf[1] = b;
    buf[2] = 0;
    return buf;
}

// ---- Lexer istruc ----

istruc lexer_t {
    i8*  src;
    u64  src_len;
    u64  pos;
    i32  line;

    void init(lexer_t* self, i8* source, u64 len) {
        self.src     = source;
        self.src_len = len;
        self.pos     = 0;
        self.line    = 1;
    }

    i8 peek_char(lexer_t* self) {
        if (self.pos >= self.src_len) { return 0; }
        return self.src[self.pos];
    }

    i8 peek_next_char(lexer_t* self) {
        if (self.pos + 1 >= self.src_len) { return 0; }
        return self.src[self.pos + 1];
    }

    i8 peek_at_n(lexer_t* self, u64 n) {
        if (self.pos + n >= self.src_len) { return 0; }
        return self.src[self.pos + n];
    }

    i8 advance_char(lexer_t* self) {
        if (self.pos >= self.src_len) { return 0; }
        i8 c = self.src[self.pos];
        self.pos = self.pos + 1;
        return c;
    }

    bool is_at_end(lexer_t* self) {
        return self.pos >= self.src_len;
    }

    bool match_next(lexer_t* self, i8 expected) {
        if (self.is_at_end()) { return false; }
        if (self.peek_char() != expected) { return false; }
        self.pos = self.pos + 1;
        return true;
    }

    // Skip whitespace (not newlines) and comments; updates self.line for newlines
    void skip_whitespace_and_comments(lexer_t* self) {
        bool cont = true;
        while (cont && !self.is_at_end()) {
            i8 c = self.peek_char();
            if (c == ' ' || c == '\r' || c == '\t') {
                self.advance_char();
            } else if (c == '/' && self.peek_next_char() == '/') {
                // single-line comment: skip to end of line
                self.skip_line_comment();
            } else if (c == '/' && self.peek_next_char() == '*') {
                // block comment
                self.skip_block_comment();
            } else {
                cont = false;
            }
        }
    }

    void skip_line_comment(lexer_t* self) {
        while (!self.is_at_end() && self.peek_char() != '\n') {
            self.advance_char();
        }
    }

    void skip_block_comment(lexer_t* self) {
        self.advance_char();
        self.advance_char();  // consume /*
        while (!self.is_at_end()) {
            i8 c = self.peek_char();
            if (c == '\n') { self.line = self.line + 1; }
            if (c == '*' && self.peek_next_char() == '/') {
                self.advance_char();
                self.advance_char();
                return;
            }
            self.advance_char();
        }
    }

    // Read escape sequence (after backslash)
    i8 read_escape(lexer_t* self) {
        self.advance_char();  // consume backslash
        i8 c = self.advance_char();
        if (c == 'n')  { return 10; }
        if (c == 't')  { return 9;  }
        if (c == 'r')  { return 13; }
        if (c == '\\') { return 92; }
        if (c == '\'') { return 39; }
        if (c == '"')  { return 34; }
        if (c == '0')  { return 0;  }
        return c;
    }

    // Read string literal (opening " already consumed)
    token_t read_string_lit(lexer_t* self, i32 tok_line) {
        // Collect string into a growable buffer
        i32  buf_cap = 64;
        i32  buf_len = 0;
        i8*  buf = (i8*)malloc((u64)buf_cap);

        bool running = true;
        while (running && !self.is_at_end() && self.peek_char() != '"') {
            i8 c;
            if (self.peek_char() == '\\') {
                c = self.read_escape();
            } else {
                if (self.peek_char() == '\n') { self.line = self.line + 1; }
                c = self.advance_char();
            }
            if (buf_len + 1 >= buf_cap) {
                buf_cap = buf_cap * 2;
                buf = (i8*)realloc(buf, (u64)buf_cap);
            }
            buf[buf_len] = c;
            buf_len = buf_len + 1;
        }
        if (!self.is_at_end()) { self.advance_char(); }  // closing "
        buf[buf_len] = 0;

        token_t tok;
        tok.type  = string_lit;
        tok.value = buf;
        tok.line  = tok_line;
        return tok;
    }

    // Read char literal (opening ' already consumed)
    token_t read_char_lit(lexer_t* self, i32 tok_line) {
        i8 c;
        if (self.peek_char() == '\\') {
            c = self.read_escape();
        } else {
            c = self.advance_char();
        }
        if (self.peek_char() == '\'') { self.advance_char(); }  // closing '

        token_t tok;
        tok.type  = char_lit;
        tok.value = char_str(c);
        tok.line  = tok_line;
        return tok;
    }

    // Check if a character is a digit
    bool is_digit_c(lexer_t* self, i8 c) {
        return c >= '0' && c <= '9';
    }

    bool is_hex_digit_c(lexer_t* self, i8 c) {
        if (c >= '0' && c <= '9') { return true; }
        if (c >= 'a' && c <= 'f') { return true; }
        if (c >= 'A' && c <= 'F') { return true; }
        return false;
    }

    bool is_alpha_c(lexer_t* self, i8 c) {
        if (c >= 'a' && c <= 'z') { return true; }
        if (c >= 'A' && c <= 'Z') { return true; }
        if (c == '_') { return true; }
        return false;
    }

    bool is_alnum_c(lexer_t* self, i8 c) {
        return self.is_alpha_c(c) || self.is_digit_c(c);
    }

    // Read a number literal
    token_t read_number(lexer_t* self) {
        i32 tok_line = self.line;
        u64 start    = self.pos;
        bool is_float_lit = false;

        // hex: 0x...
        if (self.peek_char() == '0' && (self.peek_next_char() == 'x' || self.peek_next_char() == 'X')) {
            self.advance_char();
            self.advance_char();
            while (!self.is_at_end() && self.is_hex_digit_c(self.peek_char())) {
                self.advance_char();
            }
            self.skip_int_suffix();
            i32 len = (i32)(self.pos - start);
            token_t tok;
            tok.type  = int_lit;
            tok.value = str_dup_n(self.src, (i32)start, len);
            tok.line  = tok_line;
            return tok;
        }

        // binary: 0b...
        if (self.peek_char() == '0' && (self.peek_next_char() == 'b' || self.peek_next_char() == 'B')) {
            self.advance_char();
            self.advance_char();
            while (!self.is_at_end() && (self.peek_char() == '0' || self.peek_char() == '1')) {
                self.advance_char();
            }
            self.skip_int_suffix();
            i32 len = (i32)(self.pos - start);
            token_t tok;
            tok.type  = int_lit;
            tok.value = str_dup_n(self.src, (i32)start, len);
            tok.line  = tok_line;
            return tok;
        }

        // decimal
        while (!self.is_at_end() && self.is_digit_c(self.peek_char())) {
            self.advance_char();
        }
        if (!self.is_at_end() && self.peek_char() == '.' && self.is_digit_c(self.peek_next_char())) {
            is_float_lit = true;
            self.advance_char();  // consume '.'
            while (!self.is_at_end() && self.is_digit_c(self.peek_char())) {
                self.advance_char();
            }
        }
        if (!self.is_at_end() && (self.peek_char() == 'e' || self.peek_char() == 'E')) {
            is_float_lit = true;
            self.advance_char();
            if (!self.is_at_end() && (self.peek_char() == '+' || self.peek_char() == '-')) {
                self.advance_char();
            }
            while (!self.is_at_end() && self.is_digit_c(self.peek_char())) {
                self.advance_char();
            }
        }
        self.skip_num_suffix();

        i32 len = (i32)(self.pos - start);
        token_t tok;
        tok.type  = is_float_lit ? float_lit : int_lit;
        tok.value = str_dup_n(self.src, (i32)start, len);
        tok.line  = tok_line;
        return tok;
    }

    void skip_int_suffix(lexer_t* self) {
        while (!self.is_at_end()) {
            i8 c = self.peek_char();
            if (c == 'u' || c == 'U' || c == 'l' || c == 'L') {
                self.advance_char();
            } else {
                return;
            }
        }
    }

    void skip_num_suffix(lexer_t* self) {
        while (!self.is_at_end()) {
            i8 c = self.peek_char();
            if (c == 'f' || c == 'F' || c == 'u' || c == 'U' || c == 'l' || c == 'L') {
                self.advance_char();
            } else {
                return;
            }
        }
    }

    // Keyword lookup - returns token_type or id if not found
    i32 lookup_keyword(lexer_t* self, i8* word) {
        if (strcmp(word, "if")        == 0) { return kw_if; }
        if (strcmp(word, "else")      == 0) { return kw_else; }
        if (strcmp(word, "while")     == 0) { return kw_while; }
        if (strcmp(word, "switch")    == 0) { return kw_switch; }
        if (strcmp(word, "case")      == 0) { return kw_case; }
        if (strcmp(word, "default")   == 0) { return kw_default; }
        if (strcmp(word, "for")       == 0) { return kw_for; }
        if (strcmp(word, "return")    == 0) { return kw_return; }
        if (strcmp(word, "break")     == 0) { return kw_break; }
        if (strcmp(word, "continue")  == 0) { return kw_continue; }
        if (strcmp(word, "signed")    == 0) { return kw_signed; }
        if (strcmp(word, "unsigned")  == 0) { return kw_unsigned; }
        if (strcmp(word, "const")     == 0) { return kw_const; }
        if (strcmp(word, "register")  == 0) { return kw_register; }
        if (strcmp(word, "extern")    == 0) { return kw_extern; }
        if (strcmp(word, "inline")    == 0) { return kw_inline; }
        if (strcmp(word, "sizeof")    == 0) { return kw_sizeof; }
        if (strcmp(word, "true")      == 0) { return kw_true; }
        if (strcmp(word, "false")     == 0) { return kw_false; }
        if (strcmp(word, "volatile")  == 0) { return kw_volatile; }
        if (strcmp(word, "void")      == 0) { return kw_void; }
        if (strcmp(word, "null")      == 0) { return kw_null; }
        if (strcmp(word, "char")      == 0) { return kw_char; }
        if (strcmp(word, "struct")    == 0) { return kw_struct; }
        if (strcmp(word, "enum")      == 0) { return kw_enum; }
        if (strcmp(word, "union")     == 0) { return kw_union; }
        if (strcmp(word, "memstr")    == 0) { return kw_smem; }
        if (strcmp(word, "typedef")   == 0) { return kw_typedef; }
        if (strcmp(word, "__asm__")   == 0) { return kw_asm; }
        if (strcmp(word, "istruc")    == 0) { return kw_istruc; }
        if (strcmp(word, "interface") == 0) { return kw_interface; }
        if (strcmp(word, "static")    == 0) { return kw_static; }
        if (strcmp(word, "noexcept")  == 0) { return kw_noexcept; }
        if (strcmp(word, "constexpr") == 0) { return kw_constexpr; }
        if (strcmp(word, "consteval") == 0) { return kw_consteval; }
        if (strcmp(word, "sta")       == 0) { return kw_sta; }
        if (strcmp(word, "operator")  == 0) { return kw_operator; }
        if (strcmp(word, "defer")     == 0) { return kw_defer; }
        if (strcmp(word, "errdefer")  == 0) { return kw_errdefer; }
        if (strcmp(word, "namespace") == 0) { return kw_namespace; }
        if (strcmp(word, "try")       == 0) { return kw_try; }
        if (strcmp(word, "except")    == 0) { return kw_except; }
        if (strcmp(word, "res")       == 0) { return kw_res; }
        if (strcmp(word, "error")     == 0) { return kw_error; }
        if (strcmp(word, "auto")      == 0) { return kw_auto; }
        if (strcmp(word, "using")     == 0) { return kw_using; }
        if (strcmp(word, "const_resolve") == 0) { return kw_const_resolve; }
        if (strcmp(word, "__token")   == 0) { return kw_token_type; }
        return id;
    }

    // Read identifier or keyword
    token_t read_identifier_or_keyword(lexer_t* self) {
        i32 tok_line = self.line;
        u64 start    = self.pos;

        while (!self.is_at_end() && self.is_alnum_c(self.peek_char())) {
            self.advance_char();
        }

        i32 len  = (i32)(self.pos - start);
        i8* word = str_dup_n(self.src, (i32)start, len);

        // Check for extern "C"
        if (strcmp(word, "extern") == 0) {
            u64 save_pos  = self.pos;
            i32 save_line = self.line;
            // skip spaces
            while (!self.is_at_end() && (self.peek_char() == ' ' || self.peek_char() == '\t')) {
                self.advance_char();
            }
            if (!self.is_at_end() && self.peek_char() == '"') {
                u64 q_save = self.pos;
                self.advance_char();  // consume "
                if (!self.is_at_end() && self.peek_char() == 'C') {
                    self.advance_char();  // consume C
                    if (!self.is_at_end() && self.peek_char() == '"') {
                        self.advance_char();  // consume "
                        token_t tok;
                        tok.type  = kw_extern_c;
                        tok.value = str_dup("extern \"C\"");
                        tok.line  = tok_line;
                        free(word);
                        return tok;
                    }
                }
                self.pos = q_save;
            }
            self.pos  = save_pos;
            self.line = save_line;
        }

        // Check arbitrary-width types: iN, uN, fN, bN
        if (len >= 2) {
            i8 pfx = word[0];
            if (pfx == 'i' || pfx == 'u' || pfx == 'f' || pfx == 'b') {
                bool all_digits = true;
                for (i32 k = 1; k < len; k = k + 1) {
                    if (word[k] < '0' || word[k] > '9') { all_digits = false; }
                }
                if (all_digits) {
                    i8* width_str = str_dup_n(word, 1, len - 1);
                    i32 tt;
                    if (pfx == 'i')      { tt = kw_arb_int; }
                    else if (pfx == 'u') { tt = kw_arb_uint; }
                    else if (pfx == 'f') { tt = kw_arb_float; }
                    else                 { tt = kw_arb_bool; }
                    token_t tok;
                    tok.type  = tt;
                    tok.value = width_str;
                    tok.line  = tok_line;
                    free(word);
                    return tok;
                }
            }
        }

        // Word aliases
        if (strcmp(word, "int")   == 0) {
            token_t tok; tok.type = kw_arb_int;   tok.value = str_dup("32"); tok.line = tok_line;
            free(word); return tok;
        }
        if (strcmp(word, "uint")  == 0) {
            token_t tok; tok.type = kw_arb_uint;  tok.value = str_dup("32"); tok.line = tok_line;
            free(word); return tok;
        }
        if (strcmp(word, "float") == 0) {
            token_t tok; tok.type = kw_arb_float; tok.value = str_dup("64"); tok.line = tok_line;
            free(word); return tok;
        }
        if (strcmp(word, "bool")  == 0) {
            token_t tok; tok.type = kw_arb_bool;  tok.value = str_dup("8");  tok.line = tok_line;
            free(word); return tok;
        }

        i32 ktype = self.lookup_keyword(word);
        token_t tok;
        tok.type  = ktype;
        tok.value = word;
        tok.line  = tok_line;
        return tok;
    }

    // Skip asm body { ... } (nested braces) and return the content
    void skip_to_brace(lexer_t* self) {
        while (!self.is_at_end()) {
            i8 c = self.peek_char();
            if (c == ' ' || c == '\t' || c == '\r') { self.advance_char(); }
            else if (c == '\n') { self.line = self.line + 1; self.advance_char(); }
            else { return; }
        }
    }

    token_t read_asm_body(lexer_t* self) {
        i32 tok_line = self.line;
        self.advance_char();  // consume '{'

        i32 buf_cap = 256;
        i32 buf_len = 0;
        i8* buf = (i8*)malloc((u64)buf_cap);
        i32 depth = 1;

        bool running = true;
        while (running && !self.is_at_end() && depth > 0) {
            i8 c = self.peek_char();
            if (c == '{') {
                depth = depth + 1;
                buf[buf_len] = c; buf_len = buf_len + 1;
                self.advance_char();
            } else if (c == '}') {
                depth = depth - 1;
                if (depth == 0) { self.advance_char(); running = false; }
                else { buf[buf_len] = c; buf_len = buf_len + 1; self.advance_char(); }
            } else {
                if (c == '\n') { self.line = self.line + 1; }
                buf[buf_len] = c; buf_len = buf_len + 1;
                self.advance_char();
            }
            if (buf_len + 2 >= buf_cap) {
                buf_cap = buf_cap * 2;
                buf = (i8*)realloc(buf, (u64)buf_cap);
            }
        }
        buf[buf_len] = 0;

        token_t tok;
        tok.type  = asm_body;
        tok.value = buf;
        tok.line  = tok_line;
        return tok;
    }

    // Read operator/symbol token
    token_t read_operator(lexer_t* self) {
        i32 tok_line = self.line;
        i8 c = self.advance_char();

        if (c == '{') { token_t t; t.type = obrace;    t.value = str_dup("{"); t.line = tok_line; return t; }
        if (c == '}') { token_t t; t.type = cbrace;    t.value = str_dup("}"); t.line = tok_line; return t; }
        if (c == '(') { token_t t; t.type = oparen;    t.value = str_dup("("); t.line = tok_line; return t; }
        if (c == ')') { token_t t; t.type = cparen;    t.value = str_dup(")"); t.line = tok_line; return t; }
        if (c == '[') { token_t t; t.type = obracket;  t.value = str_dup("["); t.line = tok_line; return t; }
        if (c == ']') { token_t t; t.type = cbracket;  t.value = str_dup("]"); t.line = tok_line; return t; }
        if (c == ';') { token_t t; t.type = sm;        t.value = str_dup(";"); t.line = tok_line; return t; }
        if (c == ',') { token_t t; t.type = comma;     t.value = str_dup(","); t.line = tok_line; return t; }
        if (c == '.') { token_t t; t.type = dot;       t.value = str_dup("."); t.line = tok_line; return t; }
        if (c == '@') { token_t t; t.type = at;        t.value = str_dup("@"); t.line = tok_line; return t; }
        if (c == '#') { token_t t; t.type = hash;      t.value = str_dup("#"); t.line = tok_line; return t; }
        if (c == '~') { token_t t; t.type = bit_not;   t.value = str_dup("~"); t.line = tok_line; return t; }
        if (c == '$') { token_t t; t.type = dollar;    t.value = str_dup("$"); t.line = tok_line; return t; }

        if (c == '^') {
            if (self.match_next('=')) { token_t t; t.type = caret_eq; t.value = str_dup("^="); t.line = tok_line; return t; }
            token_t t; t.type = bit_xor; t.value = str_dup("^"); t.line = tok_line; return t;
        }
        if (c == '?') {
            if (self.match_next('?')) { token_t t; t.type = question_question; t.value = str_dup("??"); t.line = tok_line; return t; }
            token_t t; t.type = question; t.value = str_dup("?"); t.line = tok_line; return t;
        }
        if (c == ':') {
            if (self.match_next(':')) { token_t t; t.type = scope_res; t.value = str_dup("::"); t.line = tok_line; return t; }
            token_t t; t.type = colon; t.value = str_dup(":"); t.line = tok_line; return t;
        }
        if (c == '%') {
            if (self.match_next('=')) { token_t t; t.type = mod_eq; t.value = str_dup("%="); t.line = tok_line; return t; }
            token_t t; t.type = mod; t.value = str_dup("%"); t.line = tok_line; return t;
        }
        if (c == '+') {
            if (self.match_next('+')) { token_t t; t.type = inc;     t.value = str_dup("++"); t.line = tok_line; return t; }
            if (self.match_next('=')) { token_t t; t.type = plus_eq; t.value = str_dup("+="); t.line = tok_line; return t; }
            token_t t; t.type = plus; t.value = str_dup("+"); t.line = tok_line; return t;
        }
        if (c == '-') {
            if (self.match_next('-')) { token_t t; t.type = dec;      t.value = str_dup("--"); t.line = tok_line; return t; }
            if (self.match_next('=')) { token_t t; t.type = minus_eq; t.value = str_dup("-="); t.line = tok_line; return t; }
            if (self.match_next('>')) { token_t t; t.type = arrow;    t.value = str_dup("->"); t.line = tok_line; return t; }
            token_t t; t.type = minus; t.value = str_dup("-"); t.line = tok_line; return t;
        }
        if (c == '*') {
            if (self.match_next('=')) { token_t t; t.type = star_eq; t.value = str_dup("*="); t.line = tok_line; return t; }
            token_t t; t.type = ast; t.value = str_dup("*"); t.line = tok_line; return t;
        }
        if (c == '/') {
            if (self.match_next('=')) { token_t t; t.type = slash_eq; t.value = str_dup("/="); t.line = tok_line; return t; }
            token_t t; t.type = slash; t.value = str_dup("/"); t.line = tok_line; return t;
        }
        if (c == '=') {
            if (self.match_next('=')) { token_t t; t.type = eq;     t.value = str_dup("=="); t.line = tok_line; return t; }
            token_t t; t.type = assign; t.value = str_dup("="); t.line = tok_line; return t;
        }
        if (c == '!') {
            if (self.match_next('=')) { token_t t; t.type = ne;   t.value = str_dup("!="); t.line = tok_line; return t; }
            token_t t; t.type = not_; t.value = str_dup("!"); t.line = tok_line; return t;
        }
        if (c == '<') {
            if (self.match_next('<')) {
                if (self.match_next('=')) { token_t t; t.type = shl_eq; t.value = str_dup("<<="); t.line = tok_line; return t; }
                token_t t; t.type = left; t.value = str_dup("<<"); t.line = tok_line; return t;
            }
            if (self.match_next('=')) { token_t t; t.type = lte; t.value = str_dup("<="); t.line = tok_line; return t; }
            token_t t; t.type = lt; t.value = str_dup("<"); t.line = tok_line; return t;
        }
        if (c == '>') {
            if (self.match_next('>')) {
                if (self.match_next('=')) { token_t t; t.type = shr_eq; t.value = str_dup(">>="); t.line = tok_line; return t; }
                token_t t; t.type = right; t.value = str_dup(">>"); t.line = tok_line; return t;
            }
            if (self.match_next('=')) { token_t t; t.type = gte; t.value = str_dup(">="); t.line = tok_line; return t; }
            token_t t; t.type = gt; t.value = str_dup(">"); t.line = tok_line; return t;
        }
        if (c == '&') {
            if (self.match_next('&')) { token_t t; t.type = and_;    t.value = str_dup("&&"); t.line = tok_line; return t; }
            if (self.match_next('=')) { token_t t; t.type = amp_eq;  t.value = str_dup("&="); t.line = tok_line; return t; }
            token_t t; t.type = addr; t.value = str_dup("&"); t.line = tok_line; return t;
        }
        if (c == '|') {
            if (self.match_next('|')) { token_t t; t.type = or_;    t.value = str_dup("||"); t.line = tok_line; return t; }
            if (self.match_next('=')) { token_t t; t.type = pipe_eq; t.value = str_dup("|="); t.line = tok_line; return t; }
            token_t t; t.type = bit_or; t.value = str_dup("|"); t.line = tok_line; return t;
        }

        // unknown
        token_t t;
        t.type  = err_t;
        t.value = char_str(c);
        t.line  = tok_line;
        return t;
    }

    // Main tokenize function
    token_vec tokenize(lexer_t* self) {
        token_vec tokens;
        token_vec_init(&tokens);

        bool running = true;
        while (running && !self.is_at_end()) {
            self.skip_whitespace_and_comments();
            if (self.is_at_end()) { running = false; }
            else {
                i8 c = self.peek_char();

                if (c == '\n') {
                    self.line = self.line + 1;
                    self.advance_char();
                } else if (self.is_alpha_c(c)) {
                    token_t tok = self.read_identifier_or_keyword();
                    token_vec_push(&tokens, tok);
                    if (tok.type == kw_asm) {
                        self.skip_to_brace();
                        if (!self.is_at_end() && self.peek_char() == '{') {
                            token_t abody = self.read_asm_body();
                            token_vec_push(&tokens, abody);
                        }
                    }
                } else if (self.is_digit_c(c) || (c == '.' && self.is_digit_c(self.peek_next_char()))) {
                    token_t tok = self.read_number();
                    token_vec_push(&tokens, tok);
                } else if (c == '"') {
                    self.advance_char();  // consume opening "
                    token_t tok = self.read_string_lit(self.line);
                    token_vec_push(&tokens, tok);
                } else if (c == '\'') {
                    self.advance_char();  // consume opening '
                    token_t tok = self.read_char_lit(self.line);
                    token_vec_push(&tokens, tok);
                } else {
                    token_t tok = self.read_operator();
                    token_vec_push(&tokens, tok);
                }
            }
        }

        token_t eof_tok;
        eof_tok.type  = eof_t;
        eof_tok.value = str_dup("");
        eof_tok.line  = self.line;
        token_vec_push(&tokens, eof_tok);
        return tokens;
    }
}

} // namespace lexer
// Expression and type AST node definitions for the Artemis self-hosting compiler.

namespace parser {

// ---- Primitive type enumeration ----
enum prim_type_t {
    char_t    = 0,
    arb_int   = 1,
    arb_uint  = 2,
    arb_float = 3,
    arb_bool  = 4,
    void_t    = 5,
}

// ---- Type node ----
struct type_node {
    bool is_primitive;
    bool is_const;
    bool is_signed;
    bool is_extern;
    bool is_inline;
    bool is_register;
    bool is_extern_c;
    bool has_prim;
    i32  prim;          // prim_type_t value
    i8*  name;          // user-defined type name (null for primitives)
    i32  pointer_depth;
    // array_size: if non-null, this is an array type
    // We use a forward-declared pointer - defined later
    i8*  array_size_ptr;   // actually expr_node* but using i8* for forward ref
    // type_args for generics
    i8** type_args;         // actually type_node**
    i32  type_args_len;
    // function pointer
    bool is_func_ptr;
    i8*  fp_ret;            // actually type_node*
    i8** fp_params;         // actually type_node**
    i32  fp_params_len;
    i8** fp_param_names;    // i8** (string array)
    i32  fp_param_names_len;
    bool fp_variadic;
    // misc flags
    bool is_self_ref;
    bool is_self_ref_const;
    bool is_self_type;
    bool ptr_data_const;
    bool is_memstr_ref;
    bool is_auto;
    bool is_nullable;
    bool is_null_literal;
    bool is_sta;
    u32  bit_width;
}

type_node* alloc_type_node() {
    type_node* t = (type_node*)malloc(sizeof(parser__NS_type_node));
    memset((i8*)t, 0, sizeof(parser__NS_type_node));
    t.is_signed = true;
    return t;
}

// ---- Expression kind enumeration ----
enum expr_kind {
    ek_int_lit      = 0,
    ek_float_lit    = 1,
    ek_string_lit   = 2,
    ek_char_lit     = 3,
    ek_bool_lit     = 4,
    ek_identifier   = 5,
    ek_unary        = 6,
    ek_binary       = 7,
    ek_call         = 8,
    ek_subscript    = 9,
    ek_member       = 10,
    ek_cast         = 11,
    ek_sizeof_e     = 12,
    ek_get_ifo_t_e  = 13,
    ek_assign       = 14,
    ek_ternary      = 15,
    ek_annotation   = 16,
    ek_class_init   = 17,
    ek_error_lit    = 18,
    ek_try_expr     = 19,
    ek_except_expr  = 20,
    ek_null_lit     = 21,
    ek_null_coal    = 22,
    ek_import_expr  = 23,
    ek_sta_type_expr= 24,
}

// ---- Unary operator enumeration ----
enum unary_op {
    uop_neg      = 0,
    uop_pos      = 1,
    uop_bit_not  = 2,
    uop_log_not  = 3,
    uop_pre_inc  = 4,
    uop_pre_dec  = 5,
    uop_post_inc = 6,
    uop_post_dec = 7,
    uop_deref    = 8,
    uop_addr_of  = 9,
}

// ---- Binary operator enumeration ----
enum binary_op {
    bop_add        = 0,
    bop_sub        = 1,
    bop_mul        = 2,
    bop_div        = 3,
    bop_mod        = 4,
    bop_eq         = 5,
    bop_ne         = 6,
    bop_lt         = 7,
    bop_gt         = 8,
    bop_lte        = 9,
    bop_gte        = 10,
    bop_log_and    = 11,
    bop_log_or     = 12,
    bop_bit_and    = 13,
    bop_bit_or     = 14,
    bop_bit_xor    = 15,
    bop_shl        = 16,
    bop_shr        = 17,
    bop_assign     = 18,
    bop_add_assign = 19,
    bop_sub_assign = 20,
    bop_mul_assign = 21,
    bop_div_assign = 22,
    bop_mod_assign = 23,
    bop_and_assign = 24,
    bop_or_assign  = 25,
    bop_xor_assign = 26,
    bop_shl_assign = 27,
    bop_shr_assign = 28,
}

// ---- Expression node ----
struct expr_node {
    i32  kind;          // expr_kind value
    u64  line;

    // literals
    i8*  str_val;
    i64  int_val;
    f64  flt_val;
    bool bool_val;

    // unary
    i32        uop;
    expr_node* operand;

    // binary / assign
    i32        bop;
    expr_node* lhs;
    expr_node* rhs;

    // call
    expr_node*  callee;
    expr_node** args;
    i32         args_len;
    i8*         func_resolved_name;

    // subscript / member
    expr_node*  object;
    expr_node*  index;
    i8*         member_name;

    // cast / sizeof
    type_node*  cast_type;

    // ternary
    expr_node*  cond;
    expr_node*  then_e;
    expr_node*  else_e;

    // class_init
    type_node*  init_type;
    i8**        field_names;
    expr_node** field_vals;
    i32         field_count;
    bool        is_implicit_init;

    // generic type args for calls
    type_node** type_args;
    i32         type_args_len;

    bool is_constexpr;

    // except handler block
    i8*  handler_block;  // actually block_stmt*
}

expr_node* alloc_expr_node() {
    expr_node* e = (expr_node*)malloc(sizeof(parser__NS_expr_node));
    memset((i8*)e, 0, sizeof(parser__NS_expr_node));
    return e;
}

// Dynamic array of expr_node pointers
struct expr_ptr_vec {
    expr_node** data;
    i32         len;
    i32         cap;
}

void expr_ptr_vec_init(expr_ptr_vec* v) {
    v.data = (expr_node**)0;
    v.len  = 0;
    v.cap  = 0;
}

void expr_ptr_vec_push(expr_ptr_vec* v, expr_node* e) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 8 : v.cap * 2;
        v.data = (expr_node**)realloc((i8*)v.data, (u64)(nc * (i32)sizeof(i8*)));
        v.cap  = nc;
    }
    v.data[v.len] = e;
    v.len = v.len + 1;
}

// Dynamic array of type_node pointers
struct type_ptr_vec {
    type_node** data;
    i32         len;
    i32         cap;
}

void type_ptr_vec_init(type_ptr_vec* v) {
    v.data = (type_node**)0;
    v.len  = 0;
    v.cap  = 0;
}

void type_ptr_vec_push(type_ptr_vec* v, type_node* t) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 8 : v.cap * 2;
        v.data = (type_node**)realloc((i8*)v.data, (u64)(nc * (i32)sizeof(i8*)));
        v.cap  = nc;
    }
    v.data[v.len] = t;
    v.len = v.len + 1;
}

// Dynamic array of strings
struct str_vec {
    i8** data;
    i32  len;
    i32  cap;
}

void str_vec_init(str_vec* v) {
    v.data = (i8**)0;
    v.len  = 0;
    v.cap  = 0;
}

void str_vec_push(str_vec* v, i8* s) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 8 : v.cap * 2;
        v.data = (i8**)realloc((i8*)v.data, (u64)(nc * (i32)sizeof(i8*)));
        v.cap  = nc;
    }
    v.data[v.len] = s;
    v.len = v.len + 1;
}

} // namespace parser
// Artemis recursive descent parser — builds the AST from a token stream.

namespace parser {

// ---- AST node kinds ----
enum ast_kind {
    nd_block        = 0,
    nd_expr_stmt    = 1,
    nd_return_stmt  = 2,
    nd_break_stmt   = 3,
    nd_continue_stmt= 4,
    nd_if_stmt      = 5,
    nd_while_stmt   = 6,
    nd_for_stmt     = 7,
    nd_for_range_stmt = 8,
    nd_switch_stmt  = 9,
    nd_asm_stmt     = 10,
    nd_defer_stmt   = 11,
    nd_errdefer_stmt= 12,
    nd_var_decl     = 13,
    nd_func_decl    = 14,
    nd_struct_decl  = 15,
    nd_class_decl   = 16,
    nd_enum_decl    = 17,
    nd_union_decl   = 18,
    nd_typedef_decl = 19,
    nd_namespace_decl = 20,
    nd_using_decl   = 21,
    nd_extern_c_block = 22,
    nd_program      = 23,
    nd_try_expr_stmt= 24,
    nd_res_block    = 25,
}

// ---- Base AST node ----
struct ast_node {
    i32 kind;
    u64 line;
}

// Dynamic array of ast_node pointers
struct node_vec {
    ast_node** data;
    i32        len;
    i32        cap;
}

void node_vec_init(node_vec* v) {
    v.data = (ast_node**)0;
    v.len  = 0;
    v.cap  = 0;
}

void node_vec_push(node_vec* v, ast_node* n) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 16 : v.cap * 2;
        v.data = (ast_node**)realloc((i8*)v.data, sizeof(i8*) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = n;
    v.len = v.len + 1;
}

// ---- Statement nodes ----

struct block_stmt {
    i32        kind;
    u64        line;
    ast_node** stmts;
    i32        stmts_len;
}

struct expr_stmt {
    i32        kind;
    u64        line;
    expr_node* expr;
}

struct return_stmt {
    i32        kind;
    u64        line;
    expr_node* val;
    bool       has_val;
}

struct break_stmt {
    i32 kind;
    u64 line;
}

struct continue_stmt {
    i32 kind;
    u64 line;
}

struct if_stmt {
    i32        kind;
    u64        line;
    expr_node* cond;
    ast_node*  then_body;
    ast_node*  else_body;
    bool       is_constexpr;
    i8*        then_capture;
    i8*        else_capture;
}

struct while_stmt {
    i32        kind;
    u64        line;
    expr_node* cond;
    ast_node*  body;
}

struct for_stmt {
    i32        kind;
    u64        line;
    ast_node*  init;
    expr_node* cond;
    expr_node* step;
    ast_node*  body;
}

struct for_range_stmt {
    i32        kind;
    u64        line;
    type_node* var_type;
    i8*        var_name;
    expr_node* range;
    ast_node*  body;
}

// switch case entry
struct switch_case {
    expr_node** case_vals;   // array of case values (null entry = default)
    bool*       case_is_default;
    block_stmt** case_bodies;
    i32          cases_len;
}

struct switch_stmt {
    i32           kind;
    u64           line;
    expr_node*    val;
    expr_node***  case_vals;   // array of (expr_node*) or null for default
    block_stmt**  case_bodies;
    bool*         case_is_default;
    i32           cases_len;
    i32           cases_cap;
}

struct defer_stmt {
    i32        kind;
    u64        line;
    expr_node* expr;
    i8*        blk;   // actually block_stmt*
    bool       is_block;
}

struct asm_stmt {
    i32 kind;
    u64 line;
    i8* raw_instructions;
}

struct try_expr_stmt {
    i32        kind;
    u64        line;
    expr_node* expr;
}

struct res_block_stmt {
    i32   kind;
    u64   line;
    i8*   body;   // actually block_stmt*
}

// ---- Declaration nodes ----

struct param_decl {
    type_node* type;
    i8*        name;
    u64        line;
}

struct proc_attr {
    i8*  name;
    i8** args;
    i32  args_len;
}

struct var_decl {
    i32        kind;
    u64        line;
    type_node* type;
    i8*        name;
    expr_node* init;
    bool       has_init;
    bool       is_constexpr;
    bool       is_consteval;
    bool       is_sta;
    bool       has_ctor_parens;
    i8**       ctor_args;
    i32        ctor_args_len;
}

struct func_decl {
    i32         kind;
    u64         line;
    type_node*  ret_type;
    i8*         name;
    param_decl* params;
    i32         params_len;
    bool        is_variadic;
    i8*         body;        // actually block_stmt*
    bool        has_body;
    bool        is_extern_c;
    i8*         mangled_name;
    bool        is_overloaded;
    bool        is_noexcept;
    i8**        type_params;
    i32         type_params_len;
    bool        is_error_union;
    type_node*  err_type;
    proc_attr*  attributes;
    i32         attributes_len;
}

struct struct_decl {
    i32         kind;
    u64         line;
    i8*         name;
    var_decl**  fields;
    i32         fields_len;
    i32         fields_cap;
    bool        is_union;
}

struct enum_variant {
    i32         kind;
    u64         line;
    i8*         name;
    i32         variant_kind;  // 0=plain, 1=tuple, 2=named_struct
    expr_node*  plain_val;
    bool        has_plain_val;
}

struct enum_decl {
    i32           kind;
    u64           line;
    i8*           name;
    i8**          variant_names;
    i64*          variant_vals;
    bool*         variant_has_val;
    i32           variants_len;
    i32           variants_cap;
    bool          is_adt;
    // ADT variant payloads: flat arrays, stride=8 per variant
    // variant_kinds[i]: 0=plain, 1=tuple, 2=named_struct, 3=istruc_dot
    // variant_field_names_flat[i*8 + j], variant_field_type_flat[i*8 + j]
    i32*          variant_kinds;
    i32*          variant_field_counts;     // number of fields for each variant
    i8**          variant_field_names_flat; // flat: [vi*8+fi] = field name (i8*)
    i8**          variant_field_type_flat;  // flat: [vi*8+fi] = parser.type_node* as i8*
    // ADT variant methods: flat arrays, stride=8 per variant
    i8**          variant_method_flat;      // flat: [vi*8+mi] = func_decl* as i8*
    i32*          variant_method_counts;    // number of methods per variant
}

struct typedef_decl {
    i32        kind;
    u64        line;
    i8*        name;
    type_node* target;
}

struct namespace_decl {
    i32        kind;
    u64        line;
    i8*        name;
    ast_node** decls;
    i32        decls_len;
    i32        decls_cap;
}

struct extern_c_block {
    i32        kind;
    u64        line;
    ast_node** decls;
    i32        decls_len;
    i32        decls_cap;
}

struct program_node {
    i32        kind;
    u64        line;
    ast_node** decls;
    i32        decls_len;
    i32        decls_cap;
}

// ---- Allocation helpers ----

block_stmt* alloc_block_stmt() {
    block_stmt* n = (block_stmt*)malloc(sizeof(parser__NS_block_stmt));
    memset((i8*)n, 0, sizeof(parser__NS_block_stmt));
    n.kind = nd_block;
    return n;
}

void block_stmt_push(block_stmt* blk, ast_node* s) {
    // Always realloc with doubled size (simple growth strategy)
    i32 old_len = blk.stmts_len;
    i32 nc = old_len == 0 ? 16 : old_len * 2;
    if (old_len == 0) {
        blk.stmts = (ast_node**)malloc(sizeof(i8*) * (u64)nc);
    } else {
        blk.stmts = (ast_node**)realloc((i8*)blk.stmts, sizeof(i8*) * (u64)nc);
    }
    blk.stmts[blk.stmts_len] = s;
    blk.stmts_len = blk.stmts_len + 1;
}

// ---- Macro definition (const_resolve) ----

istruc macro_def_t {
    i8*  name;
    i8** param_names;
    i32  param_count;
    i8*  template_toks;   // lexer.token_t* stored as i8*
    i32  template_len;
}

// ---- Parser istruc ----

istruc parser_t {
    lexer.token_t* tokens;
    i32             tokens_len;
    i32             current;
    bool            had_parse_error;
    macro_def_t**  macros;
    i32             macros_len;
    i32             macros_cap;

    void init(parser_t* self, lexer.token_t* toks, i32 len) {
        self.tokens          = toks;
        self.tokens_len      = len;
        self.current         = 0;
        self.had_parse_error = false;
        self.macros_cap      = 8;
        self.macros_len      = 0;
        self.macros          = (macro_def_t**)malloc(sizeof(i8*) * (u64)8);
    }

    // ---- Token access helpers ----

    lexer.token_t peek_tok(parser_t* self) {
        if (self.current >= self.tokens_len) {
            lexer.token_t t;
            t.type  = eof_t;
            t.value = (i8*)0;
            t.line  = 0;
            return t;
        }
        return self.tokens[self.current];
    }

    lexer.token_t peek_at_tok(parser_t* self, i32 offset) {
        i32 idx = self.current + offset;
        if (idx >= self.tokens_len) {
            lexer.token_t t;
            t.type  = eof_t;
            t.value = (i8*)0;
            t.line  = 0;
            return t;
        }
        return self.tokens[idx];
    }

    lexer.token_t advance_tok(parser_t* self) {
        lexer.token_t t = self.peek_tok();
        if (self.current < self.tokens_len) {
            self.current = self.current + 1;
        }
        return t;
    }

    lexer.token_t previous_tok(parser_t* self) {
        if (self.current > 0) {
            return self.tokens[self.current - 1];
        }
        return self.peek_tok();
    }

    // ---- Field accessor helpers (avoid call().field lvalue issue) ----

    i32 peek_type(parser_t* self) {
        lexer.token_t _t = self.peek_tok();
        return _t.type;
    }

    u64 peek_line(parser_t* self) {
        lexer.token_t _t = self.peek_tok();
        return _t.line;
    }

    i32 peek_at_type(parser_t* self, i32 offset) {
        lexer.token_t _t = self.peek_at_tok(offset);
        return _t.type;
    }

    u64 advance_line_get(parser_t* self) {
        lexer.token_t _t = self.advance_tok();
        return _t.line;
    }

    i8* advance_value_get(parser_t* self) {
        lexer.token_t _t = self.advance_tok();
        return _t.value;
    }

    i32 prev_type(parser_t* self) {
        lexer.token_t _t = self.previous_tok();
        return _t.type;
    }

    u64 prev_line(parser_t* self) {
        lexer.token_t _t = self.previous_tok();
        return _t.line;
    }

    i8* consume_id_value(parser_t* self, i8* err_msg) {
        lexer.token_t _t = self.consume_tok(id, err_msg);
        return _t.value;
    }

    // ---- End helpers ----

    bool check_tok(parser_t* self, i32 type) {
        return self.peek_type() == type;
    }

    bool match_tok(parser_t* self, i32 type) {
        if (self.check_tok(type)) {
            self.advance_tok();
            return true;
        }
        return false;
    }

    bool is_at_end_p(parser_t* self) {
        return self.peek_type() == eof_t;
    }

    lexer.token_t consume_tok(parser_t* self, i32 type, i8* err_msg) {
        if (self.check_tok(type)) {
            return self.advance_tok();
        }
        // Error: print message and set error flag
        lexer.token_t cur = self.peek_tok();
        i8 errbuf[512];
        snprintf(errbuf, (u64)512, "Parse Error at line %d: %s (got token type %d)",
                 cur.line, err_msg, cur.type);
        printf("%s\n", errbuf);
        self.had_parse_error = true;
        return cur;
    }

    // ---- Error recovery ----

    void synchronize(parser_t* self) {
        self.advance_tok();
        while (!self.is_at_end_p()) {
            i32 prev = self.prev_type();
            if (prev == sm) { return; }
            i32 cur = self.peek_type();
            if (cur == kw_if     ||
                cur == kw_while  ||
                cur == kw_for    ||
                cur == kw_return ||
                cur == kw_struct ||
                cur == kw_enum   ||
                cur == cbrace) {
                return;
            }
            self.advance_tok();
        }
    }

    // ---- Macro helpers ----

    macro_def_t* find_macro(parser_t* self, i8* name) {
        i32 mi = 0;
        while (mi < self.macros_len) {
            macro_def_t* m = (macro_def_t*)self.macros[mi];
            if (strcmp(m.name, name) == 0) {
                return m;
            }
            mi = mi + 1;
        }
        return (macro_def_t*)0;
    }

    // Expand a macro call: consumes '(' args ')' from self, returns expanded expr
    expr_node* expand_macro_call(parser_t* self, macro_def_t* mdef) {
        // Collect argument tokens per arg
        i32 arg_buf_cap = 128;
        lexer.token_t* arg_buf = (lexer.token_t*)malloc(sizeof(lexer__NS_token_t) * (u64)arg_buf_cap);
        i32 arg_buf_len = 0;
        i32* arg_starts = (i32*)malloc(sizeof(i32) * (u64)16);
        i32* arg_lens   = (i32*)malloc(sizeof(i32) * (u64)16);
        i32 arg_count = 0;
        i32 cur_arg_start = 0;

        self.consume_tok(oparen, "Expected '(' for macro call");
        i32 depth_m = 0;
        while ((!self.check_tok(cparen) || depth_m > 0) && !self.is_at_end_p()) {
            lexer.token_t at = self.peek_tok();
            if (at.type == oparen) { depth_m = depth_m + 1; }
            else if (at.type == cparen) { depth_m = depth_m - 1; }
            else if (at.type == comma && depth_m == 0) {
                arg_starts[arg_count] = cur_arg_start;
                arg_lens[arg_count]   = arg_buf_len - cur_arg_start;
                arg_count = arg_count + 1;
                cur_arg_start = arg_buf_len;
                self.advance_tok();
                continue;
            }
            if (arg_buf_len >= arg_buf_cap) {
                arg_buf_cap = arg_buf_cap * 2;
                arg_buf = (lexer.token_t*)realloc((i8*)arg_buf, sizeof(lexer__NS_token_t) * (u64)arg_buf_cap);
            }
            arg_buf[arg_buf_len] = at;
            arg_buf_len = arg_buf_len + 1;
            self.advance_tok();
        }
        // last argument
        arg_starts[arg_count] = cur_arg_start;
        arg_lens[arg_count]   = arg_buf_len - cur_arg_start;
        if (arg_buf_len > cur_arg_start) { arg_count = arg_count + 1; }
        self.consume_tok(cparen, "Expected ')' after macro args");

        // Build expanded token list by substituting $param_name with arg tokens
        i32 exp_cap = 256;
        lexer.token_t* exp = (lexer.token_t*)malloc(sizeof(lexer__NS_token_t) * (u64)exp_cap);
        i32 exp_len = 0;
        lexer.token_t* tmpl = (lexer.token_t*)mdef.template_toks;

        i32 ti = 0;
        while (ti < mdef.template_len) {
            lexer.token_t tt = tmpl[ti];
            if (tt.type == dollar && ti + 1 < mdef.template_len) {
                lexer.token_t nt = tmpl[ti + 1];
                if (nt.type == id) {
                    i32 param_idx = -1;
                    i32 pi = 0;
                    while (pi < mdef.param_count) {
                        if (strcmp(mdef.param_names[pi], nt.value) == 0) {
                            param_idx = pi;
                            pi = mdef.param_count; // break
                        }
                        pi = pi + 1;
                    }
                    if (param_idx >= 0 && param_idx < arg_count) {
                        i32 em_s = arg_starts[param_idx];
                        i32 em_l = arg_lens[param_idx];
                        i32 ai = 0;
                        while (ai < em_l) {
                            if (exp_len >= exp_cap) {
                                exp_cap = exp_cap * 2;
                                exp = (lexer.token_t*)realloc((i8*)exp, sizeof(lexer__NS_token_t) * (u64)exp_cap);
                            }
                            exp[exp_len] = arg_buf[em_s + ai];
                            exp_len = exp_len + 1;
                            ai = ai + 1;
                        }
                    }
                    ti = ti + 2;
                    continue;
                }
            }
            if (exp_len >= exp_cap) {
                exp_cap = exp_cap * 2;
                exp = (lexer.token_t*)realloc((i8*)exp, sizeof(lexer__NS_token_t) * (u64)exp_cap);
            }
            exp[exp_len] = tt;
            exp_len = exp_len + 1;
            ti = ti + 1;
        }
        // append EOF
        if (exp_len >= exp_cap) {
            exp_cap = exp_cap + 1;
            exp = (lexer.token_t*)realloc((i8*)exp, sizeof(lexer__NS_token_t) * (u64)exp_cap);
        }
        lexer.token_t eoft;
        eoft.type  = eof_t;
        eoft.value = (i8*)0;
        eoft.line  = 0;
        exp[exp_len] = eoft;
        exp_len = exp_len + 1;

        // Parse expanded tokens with a sub-parser
        parser_t sub;
        sub.init(exp, exp_len);
        sub.macros     = self.macros;
        sub.macros_len = self.macros_len;
        sub.macros_cap = self.macros_cap;
        expr_node* result = sub.parse_expr();

        free((i8*)exp);
        free((i8*)arg_buf);
        free((i8*)arg_starts);
        free((i8*)arg_lens);
        return result;
    }

    // ---- Type start detection ----

    bool is_type_start(parser_t* self) {
        i32 tt = self.peek_type();
        if (tt == question) { return true; }
        if (tt == addr && self.peek_at_type(1) == kw_smem) { return true; }
        if (tt == kw_sta) { return true; }
        if (tt == kw_const)    { return true; }
        if (tt == kw_volatile) { return true; }
        if (tt == kw_signed)   { return true; }
        if (tt == kw_unsigned) { return true; }
        if (tt == kw_extern)   { return true; }
        if (tt == kw_extern_c) { return true; }
        if (tt == kw_inline)   { return true; }
        if (tt == kw_register) { return true; }
        if (tt == kw_auto)     { return true; }
        if (tt == kw_char)     { return true; }
        if (tt == kw_void)     { return true; }
        if (tt == kw_arb_int)  { return true; }
        if (tt == kw_arb_uint) { return true; }
        if (tt == kw_arb_float){ return true; }
        if (tt == kw_arb_bool) { return true; }
        if (tt == kw_struct)   { return true; }
        if (tt == kw_enum)     { return true; }
        if (tt == kw_union)    { return true; }
        if (tt == kw_smem)     { return true; }
        if (tt == kw_token_type) { return true; }
        // id followed by id = user-defined type
        if (tt == id && self.peek_at_type(1) == id) { return true; }
        // namespace.Type: id.id id or id.id*
        if (tt == id && self.peek_at_type(1) == dot) {
            if (self.peek_at_type(2) == id) {
                // Check what follows the qualified name
                i32 k = 3;
                // skip more dots
                bool searching = true;
                while (searching && self.peek_at_type(k) == dot
                       && self.peek_at_type(k + 1) == id) {
                    k = k + 2;
                }
                // skip stars
                while (self.peek_at_type(k) == ast) { k = k + 1; }
                i32 after = self.peek_at_type(k);
                if (after == id) { return true; }
            }
        }
        // id* id = pointer to user type
        if (tt == id) {
            i32 k = 1;
            while (self.peek_at_type(k) == ast) { k = k + 1; }
            if (k > 1 && self.peek_at_type(k) == id) { return true; }
        }
        // Generic type: id<...> id — scan past balanced <> to check for trailing id
        if (tt == id && self.peek_at_type(1) == lt) {
            i32 k2 = 2;
            i32 depth2 = 1;
            while (depth2 > 0 && self.peek_at_type(k2) != eof_t) {
                i32 t2 = self.peek_at_type(k2);
                if (t2 == lt)  { depth2 = depth2 + 1; }
                else if (t2 == gt)  { depth2 = depth2 - 1; }
                else if (t2 == right) { depth2 = depth2 - 2; }
                k2 = k2 + 1;
            }
            // After >, skip optional pointer stars
            while (self.peek_at_type(k2) == ast) { k2 = k2 + 1; }
            if (self.peek_at_type(k2) == id) { return true; }
        }
        return false;
    }

    // Like is_type_start() but also accepts id**) patterns for cast expressions, e.g. (T**)0
    bool is_cast_start(parser_t* self) {
        if (self.is_type_start()) { return true; }
        i32 tt = self.peek_type();
        if (tt == id) {
            i32 k = 1;
            // skip namespace qualifiers: ns.Type
            while (self.peek_at_type(k) == dot && self.peek_at_type(k + 1) == id) { k = k + 2; }
            // skip pointer stars
            while (self.peek_at_type(k) == ast) { k = k + 1; }
            if (k > 1 && self.peek_at_type(k) == cparen) { return true; }
        }
        return false;
    }

    // ---- Type parsing ----

    type_node* parse_type(parser_t* self) {
        type_node* t = alloc_type_node();

        // nullable: ?T
        if (self.check_tok(question)) {
            self.advance_tok();
            type_node* inner = self.parse_type();
            inner.is_nullable = true;
            free((i8*)t);
            return inner;
        }

        // C++ reference: &T — treat as T* for bootstrap
        if (self.check_tok(addr)) {
            self.advance_tok();
            type_node* inner = self.parse_type();
            inner.pointer_depth = inner.pointer_depth + 1;
            free((i8*)t);
            return inner;
        }

        // storage class
        bool parsing_storage = true;
        while (parsing_storage) {
            if (self.match_tok(kw_extern))   { t.is_extern = true; }
            else if (self.match_tok(kw_extern_c)) { t.is_extern = true; t.is_extern_c = true; }
            else if (self.match_tok(kw_inline))  { t.is_inline = true; }
            else if (self.match_tok(kw_register)){ t.is_register = true; }
            else { parsing_storage = false; }
        }

        // qualifiers
        bool parsing_qual = true;
        while (parsing_qual) {
            if (self.match_tok(kw_const))    { t.is_const = true; }
            else if (self.match_tok(kw_volatile)) { /* ignore volatile */ }
            else { parsing_qual = false; }
        }
        if (self.match_tok(kw_signed))   { t.is_signed = true; }
        if (self.match_tok(kw_unsigned)) { t.is_signed = false; }

        // sta
        if (self.check_tok(kw_sta)) {
            self.advance_tok();
            t.is_sta = true;
            t.is_primitive = false;
            t.name = lexer.str_dup("sta");
            return t;
        }

        // auto
        if (self.check_tok(kw_auto)) {
            self.advance_tok();
            t.is_auto = true;
            t.is_primitive = false;
            while (self.check_tok(ast)) {
                self.advance_tok();
                t.pointer_depth = t.pointer_depth + 1;
            }
            return t;
        }

        bool found = false;
        if (self.match_tok(kw_char)) {
            t.prim = char_t; t.bit_width = 8; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.match_tok(kw_void)) {
            t.prim = void_t; t.bit_width = 0; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(kw_arb_int)) {
            lexer.token_t w = self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_int; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(kw_arb_uint)) {
            lexer.token_t w = self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_uint; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(kw_arb_float)) {
            lexer.token_t w = self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_float; t.is_primitive = true; t.has_prim = true; found = true;
        } else if (self.check_tok(kw_arb_bool)) {
            lexer.token_t w = self.advance_tok();
            t.bit_width = (u32)atoi(w.value);
            t.prim = arb_bool; t.is_primitive = true; t.has_prim = true; found = true;
        }

        if (!found && self.check_tok(kw_smem)) {
            self.advance_tok();
            t.name = lexer.str_dup("memstr");
            found = true;
        }

        if (!found) {
            lexer.token_t name_tok = self.consume_tok(id, "Expected type name");
            t.name = lexer.str_dup(name_tok.value);

            // namespace-qualified: ns.Type
            bool ns_loop = true;
            while (ns_loop && self.check_tok(dot)) {
                i32 next_type = self.peek_at_type(1);
                if (next_type == id) {
                    self.advance_tok();  // consume dot
                    lexer.token_t sub = self.advance_tok();

                    // Build qualified name: old__NS_sub
                    i8 newname[1024];
                    snprintf(newname, (u64)1024, "%s__NS_%s", t.name, sub.value);
                    free(t.name);
                    t.name = lexer.str_dup(newname);
                } else {
                    ns_loop = false;
                }
            }

            // Generic type parameters: Type<A, B> — skip parameters, use base name
            if (self.check_tok(lt)) {
                i32 depth_g = 1;
                self.advance_tok(); // consume '<'
                while (depth_g > 0 && !self.is_at_end_p()) {
                    i32 tg = self.peek_type();
                    if (tg == lt)  { depth_g = depth_g + 1; self.advance_tok(); }
                    else if (tg == gt)  { depth_g = depth_g - 1; self.advance_tok(); }
                    else if (tg == right) { depth_g = depth_g - 2; self.advance_tok(); }
                    else { self.advance_tok(); }
                }
            }
        }

        // pointer stars
        while (self.check_tok(ast)) {
            self.advance_tok();
            t.pointer_depth = t.pointer_depth + 1;
        }

        // function pointer detection: type(params)*
        if (self.check_tok(oparen)) {
            i32 saved = self.current;
            self.advance_tok();  // consume (

            // Try to parse as function pointer params
            type_ptr_vec fp_params;
            type_ptr_vec_init(&fp_params);
            str_vec fp_names;
            str_vec_init(&fp_names);
            bool fp_variadic = false;
            bool ok = true;

            if (!self.check_tok(cparen)) {
                bool parsing_fp = true;
                while (ok && parsing_fp) {
                    if (self.check_tok(dot) &&
                        self.peek_at_type(1) == dot &&
                        self.peek_at_type(2) == dot) {
                        self.advance_tok(); self.advance_tok(); self.advance_tok();
                        fp_variadic = true;
                        parsing_fp = false;
                    } else if (self.is_type_start()) {
                        type_node* pt = self.parse_type();
                        type_ptr_vec_push(&fp_params, pt);
                        i8* pname = (i8*)0;
                        if (self.check_tok(id)) {
                            pname = lexer.str_dup(self.advance_value_get());
                        }
                        str_vec_push(&fp_names, pname);
                        if (!self.match_tok(comma)) {
                            parsing_fp = false;
                        }
                    } else {
                        ok = false;
                    }
                }
            }

            if (ok && self.check_tok(cparen)) {
                self.advance_tok();  // consume )
                if (self.check_tok(ast)) {
                    self.advance_tok();  // consume *
                    // This IS a function pointer type
                    type_node* fp_t = alloc_type_node();
                    fp_t.is_func_ptr     = true;
                    fp_t.fp_ret          = (i8*)t;
                    fp_t.fp_params       = (i8**)fp_params.data;
                    fp_t.fp_params_len   = fp_params.len;
                    fp_t.fp_param_names  = fp_names.data;
                    fp_t.fp_param_names_len = fp_names.len;
                    fp_t.fp_variadic     = fp_variadic;
                    fp_t.pointer_depth   = 1;
                    return fp_t;
                }
            }
            // Not a function pointer; restore
            self.current = saved;
        }

        // array brackets
        if (self.match_tok(obracket)) {
            if (!self.check_tok(cbracket)) {
                expr_node* sz = self.parse_expr();
                t.array_size_ptr = (i8*)sz;
            }
            self.consume_tok(cbracket, "Expected ']' after array size");
        }

        return t;
    }

    // ---- Variable body ----

    var_decl* parse_var_body(parser_t* self, type_node* ty, lexer.token_t name_tok) {
        var_decl* vd = (var_decl*)malloc(sizeof(parser__NS_var_decl));
        memset((i8*)vd, 0, sizeof(parser__NS_var_decl));
        vd.kind     = nd_var_decl;
        vd.line     = (u64)name_tok.line;
        vd.type     = ty;
        vd.name     = lexer.str_dup(name_tok.value);

        // Array size after name: int arr[10]
        if (self.match_tok(obracket)) {
            if (!self.check_tok(cbracket)) {
                ty.array_size_ptr = (i8*)self.parse_expr();
            }
            self.consume_tok(cbracket, "Expected ']' after array size");
        }
        // Constructor call: TypeName varname(args...)
        if (self.match_tok(oparen)) {
            vd.has_ctor_parens = true;
            i32 ctor_cap = 4;
            vd.ctor_args = (i8**)malloc(sizeof(i8*) * (u64)ctor_cap);
            vd.ctor_args_len = 0;
            if (!self.check_tok(cparen)) {
                bool p_ctor = true;
                while (p_ctor) {
                    if (vd.ctor_args_len >= ctor_cap) {
                        ctor_cap = ctor_cap * 2;
                        vd.ctor_args = (i8**)realloc((i8*)vd.ctor_args, sizeof(i8*) * (u64)ctor_cap);
                    }
                    vd.ctor_args[vd.ctor_args_len] = (i8*)self.parse_assignment();
                    vd.ctor_args_len = vd.ctor_args_len + 1;
                    if (!self.match_tok(comma)) { p_ctor = false; }
                }
            }
            self.consume_tok(cparen, "Expected ')' after constructor args");
        } else if (self.match_tok(obrace)) {
            // Brace constructor: TypeName varname{args...}
            vd.has_ctor_parens = true;
            i32 ctor_capB = 4;
            vd.ctor_args = (i8**)malloc(sizeof(i8*) * (u64)ctor_capB);
            vd.ctor_args_len = 0;
            if (!self.check_tok(cbrace)) {
                bool p_ctorB = true;
                while (p_ctorB) {
                    if (vd.ctor_args_len >= ctor_capB) {
                        ctor_capB = ctor_capB * 2;
                        vd.ctor_args = (i8**)realloc((i8*)vd.ctor_args, sizeof(i8*) * (u64)ctor_capB);
                    }
                    vd.ctor_args[vd.ctor_args_len] = (i8*)self.parse_assignment();
                    vd.ctor_args_len = vd.ctor_args_len + 1;
                    if (!self.match_tok(comma)) { p_ctorB = false; }
                }
            }
            self.consume_tok(cbrace, "Expected '}' after constructor args");
        } else if (self.match_tok(assign)) {
            vd.init     = self.parse_expr();
            vd.has_init = true;
        }
        self.consume_tok(sm, "Expected ';' after variable declaration");
        return vd;
    }

    // ---- Function body ----

    func_decl* parse_func_body(parser_t* self, type_node* ret, lexer.token_t name_tok, bool extern_c) {
        func_decl* fd = (func_decl*)malloc(sizeof(parser__NS_func_decl));
        memset((i8*)fd, 0, sizeof(parser__NS_func_decl));
        fd.kind        = nd_func_decl;
        fd.line        = (u64)name_tok.line;
        fd.ret_type    = ret;
        fd.name        = lexer.str_dup(name_tok.value);
        fd.is_extern_c = extern_c;
        if (ret != (type_node*)0 && (ret.is_extern_c || ret.is_extern)) {
            fd.is_extern_c = true;
        }

        // Parse parameters
        i32 params_cap = 8;
        fd.params     = (param_decl*)malloc(sizeof(parser__NS_param_decl) * (u64)params_cap);
        fd.params_len = 0;

        if (!self.check_tok(cparen)) {
            bool parsing_params = true;
            while (parsing_params) {
                if (self.check_tok(dot) &&
                    self.peek_at_type(1) == dot &&
                    self.peek_at_type(2) == dot) {
                    self.advance_tok(); self.advance_tok(); self.advance_tok();
                    fd.is_variadic = true;
                    parsing_params = false;
                } else {
                    if (fd.params_len >= params_cap) {
                        params_cap = params_cap * 2;
                        fd.params = (param_decl*)realloc((i8*)fd.params, sizeof(parser__NS_param_decl) * (u64)params_cap);
                    }
                    type_node* pt = self.parse_type();
                    i8* pname = (i8*)0;
                    if (self.check_tok(id)) {
                        pname = lexer.str_dup(self.advance_value_get());
                    }
                    param_decl p;
                    p.type = pt;
                    p.name = pname;
                    p.line = (u64)self.prev_line();
                    fd.params[fd.params_len] = p;
                    fd.params_len = fd.params_len + 1;

                    if (!self.match_tok(comma)) {
                        parsing_params = false;
                    }
                }
            }
        }
        self.consume_tok(cparen, "Expected ')' after parameters");

        // Optional qualifiers after )
        while (self.check_tok(kw_noexcept)) {
            self.advance_tok();
            fd.is_noexcept = true;
        }
        // Skip proc-macro / attribute markers: attr, derive, verify, etc.
        // If any are present, skip the entire body (bodies use quote{} which we don't parse)
        bool pm_skipped = false;
        while (self.check_tok(id)) {
            self.advance_tok();
            pm_skipped = true;
        }
        if (pm_skipped) {
            if (self.check_tok(obrace)) {
                i32 pm_depth = 1;
                self.advance_tok();
                while (pm_depth > 0 && !self.is_at_end_p()) {
                    if (self.check_tok(obrace)) { pm_depth = pm_depth + 1; }
                    else if (self.check_tok(cbrace)) { pm_depth = pm_depth - 1; }
                    self.advance_tok();
                }
            } else if (self.check_tok(sm)) { self.advance_tok(); }
            fd.body     = (i8*)0;
            fd.has_body = false;
            return fd;
        }

        // Trailing return type for auto
        if (ret != (type_node*)0 && ret.is_auto) {
            if (self.check_tok(not_)) {
                self.advance_tok();
                fd.ret_type        = self.parse_type();
                fd.is_error_union  = true;
                fd.err_type        = (type_node*)0;
            } else if (self.is_type_start()) {
                fd.ret_type = self.parse_type();
            }
        }

        // Parse optional C++ initializer list: : field(expr), field(expr)
        i8* init_self_name = (i8*)0;
        if (fd.params_len > 0 && fd.params[0].name != (i8*)0) {
            init_self_name = fd.params[0].name;
        } else {
            init_self_name = lexer.str_dup("self");
        }
        i32 init_cap  = 8;
        i8** init_fnames = (i8**)malloc(sizeof(i8*) * (u64)init_cap);
        i8** init_fexprs = (i8**)malloc(sizeof(i8*) * (u64)init_cap);
        i32 init_len  = 0;

        if (self.check_tok(colon)) {
            self.advance_tok(); // consume ':'
            bool p_init = true;
            while (p_init && !self.is_at_end_p() && self.check_tok(id)) {
                i8* fname = lexer.str_dup(self.advance_value_get());
                self.consume_tok(oparen, "Expected '(' in init list");
                expr_node* fval = self.parse_assignment();
                self.consume_tok(cparen, "Expected ')' in init list");
                if (init_len >= init_cap) {
                    init_cap = init_cap * 2;
                    init_fnames = (i8**)realloc((i8*)init_fnames, sizeof(i8*) * (u64)init_cap);
                    init_fexprs = (i8**)realloc((i8*)init_fexprs, sizeof(i8*) * (u64)init_cap);
                }
                init_fnames[init_len] = fname;
                init_fexprs[init_len] = (i8*)fval;
                init_len = init_len + 1;
                if (!self.match_tok(comma)) { p_init = false; }
            }
        }

        if (self.match_tok(sm)) {
            fd.body     = (i8*)0;
            fd.has_body = false;
        } else {
            block_stmt* blk_nd = self.parse_block();
            // Prepend init list as assignments: self.field = expr
            if (blk_nd != (block_stmt*)0 && init_len > 0) {
                i32 new_len = blk_nd.stmts_len + init_len;
                ast_node** new_stmts = (ast_node**)malloc(sizeof(i8*) * (u64)(new_len + 1));
                i32 ii = 0;
                while (ii < init_len) {
                    expr_node* self_id = (expr_node*)malloc(sizeof(parser__NS_expr_node));
                    memset((i8*)self_id, 0, sizeof(parser__NS_expr_node));
                    self_id.kind    = ek_identifier;
                    self_id.str_val = init_self_name;

                    expr_node* mem_e = (expr_node*)malloc(sizeof(parser__NS_expr_node));
                    memset((i8*)mem_e, 0, sizeof(parser__NS_expr_node));
                    mem_e.kind        = ek_member;
                    mem_e.object      = self_id;
                    mem_e.member_name = init_fnames[ii];

                    expr_node* asgn = (expr_node*)malloc(sizeof(parser__NS_expr_node));
                    memset((i8*)asgn, 0, sizeof(parser__NS_expr_node));
                    asgn.kind = ek_assign;
                    asgn.lhs  = mem_e;
                    asgn.rhs  = (expr_node*)init_fexprs[ii];

                    expr_stmt* es = (expr_stmt*)malloc(sizeof(parser__NS_expr_stmt));
                    memset((i8*)es, 0, sizeof(parser__NS_expr_stmt));
                    es.kind = nd_expr_stmt;
                    es.expr = asgn;
                    new_stmts[ii] = (ast_node*)es;
                    ii = ii + 1;
                }
                i32 si = 0;
                while (si < blk_nd.stmts_len) {
                    new_stmts[init_len + si] = blk_nd.stmts[si];
                    si = si + 1;
                }
                blk_nd.stmts     = new_stmts;
                blk_nd.stmts_len = new_len;
            }
            fd.body     = (i8*)blk_nd;
            fd.has_body = true;
        }
        free((i8*)init_fnames);
        free((i8*)init_fexprs);
        return fd;
    }

    // ---- Top-level declaration dispatch ----

    ast_node* parse_func_or_var_decl(parser_t* self) {
        bool is_cexpr = false;
        bool is_ceval = false;
        if (self.check_tok(kw_constexpr)) { self.advance_tok(); is_cexpr = true; }
        if (self.check_tok(kw_consteval)) { self.advance_tok(); is_ceval = true; }

        type_node* ret = self.parse_type();

        // Error union: !T or E!T
        bool is_err_union = false;
        type_node* err_type = (type_node*)0;
        if (self.check_tok(not_) && self.peek_at_type(1) != assign) {
            is_err_union = true;
            err_type     = ret;
            self.advance_tok();  // consume !
            ret = self.parse_type();
        }

        // Handle operator overloads: "RetType operator+(...)
        if (self.check_tok(kw_operator)) {
            self.advance_tok(); // consume 'operator'
            // Build operator name from the symbol that follows
            i8 op_name[64];
            i32 tt2 = self.peek_type();
            // Consume the operator symbol(s)
            lexer.token_t op_tok = self.advance_tok();
            // Handle two-character operators (==, !=, <=, >=, +=, etc.)
            i32 tt3 = self.peek_type();
            if ((tt2 == assign || tt2 == lt || tt2 == gt || tt2 == not_ || tt2 == plus || tt2 == minus || tt2 == ast || tt2 == slash) &&
                    (tt3 == assign)) {
                self.advance_tok();
                snprintf(op_name, (u64)64, "operator%s=", op_tok.value);
            } else if (tt2 == kw_arb_int) {
                snprintf(op_name, (u64)64, "operator_i%s", op_tok.value);
            } else if (tt2 == kw_arb_uint) {
                snprintf(op_name, (u64)64, "operator_u%s", op_tok.value);
            } else if (tt2 == kw_arb_float) {
                snprintf(op_name, (u64)64, "operator_f%s", op_tok.value);
            } else {
                snprintf(op_name, (u64)64, "operator%s", op_tok.value);
            }
            lexer.token_t name_tok2;
            name_tok2.type  = id;
            name_tok2.value = lexer.str_dup(op_name);
            name_tok2.line  = op_tok.line;
            self.consume_tok(oparen, "Expected '(' after operator name");
            func_decl* fd2 = self.parse_func_body(ret, name_tok2, false);
            if (is_err_union) { fd2.is_error_union = true; fd2.err_type = err_type; }
            return (ast_node*)fd2;
        }

        lexer.token_t name_tok = self.consume_tok(id, "Expected declaration name");

        // Parse generic type params: funcname<T, U>(...)
        i8** gtp_buf = (i8**)0;
        i32  gtp_len = 0;
        if (self.check_tok(lt)) {
            i32 gtp_cap = 4;
            gtp_buf = (i8**)malloc(sizeof(i8*) * (u64)gtp_cap);
            self.advance_tok(); // consume '<'
            i32 depth_gf = 1;
            while (depth_gf > 0 && !self.is_at_end_p()) {
                i32 tgf = self.peek_type();
                if (tgf == gt && depth_gf == 1) {
                    depth_gf = 0; self.advance_tok();
                } else if (tgf == lt) { depth_gf = depth_gf + 1; self.advance_tok(); }
                else if (tgf == gt)   { depth_gf = depth_gf - 1; self.advance_tok(); }
                else if (tgf == right && depth_gf <= 2) { depth_gf = 0; self.advance_tok(); }
                else if (tgf == id) {
                    lexer.token_t tp_tok = self.advance_tok();
                    if (gtp_len >= gtp_cap) {
                        gtp_cap = gtp_cap * 2;
                        gtp_buf = (i8**)realloc((i8*)gtp_buf, sizeof(i8*) * (u64)gtp_cap);
                    }
                    gtp_buf[gtp_len] = lexer.str_dup(tp_tok.value);
                    gtp_len = gtp_len + 1;
                } else { self.advance_tok(); }
            }
        }

        if (self.match_tok(oparen)) {
            func_decl* fd = self.parse_func_body(ret, name_tok, false);
            if (gtp_len > 0) {
                fd.type_params     = gtp_buf;
                fd.type_params_len = gtp_len;
            } else if (gtp_buf != (i8**)0) {
                free((i8*)gtp_buf);
            }
            if (is_err_union) { fd.is_error_union = true; fd.err_type = err_type; }
            return (ast_node*)fd;
        }
        if (gtp_buf != (i8**)0) { free((i8*)gtp_buf); }

        // Trailing type: auto name: type = expr;
        if (ret.is_auto && self.check_tok(colon)) {
            self.advance_tok();
            ret = self.parse_type();
        }
        var_decl* vd = self.parse_var_body(ret, name_tok);
        vd.is_constexpr = is_cexpr;
        vd.is_consteval = is_ceval;
        if (ret.is_sta) { vd.is_sta = true; }
        return (ast_node*)vd;
    }

    ast_node* parse_func_or_var_decl_extern_c(parser_t* self) {
        type_node* ret = self.parse_type();
        lexer.token_t name_tok = self.consume_tok(id, "Expected declaration name");
        if (self.match_tok(oparen)) {
            func_decl* fd = self.parse_func_body(ret, name_tok, true);
            fd.is_extern_c = true;
            return (ast_node*)fd;
        }
        return (ast_node*)self.parse_var_body(ret, name_tok);
    }

    struct_decl* parse_struct_decl(parser_t* self) {
        u64 ln = (u64)self.peek_line();
        self.advance_tok();  // consume 'struct'
        struct_decl* sd = (struct_decl*)malloc(sizeof(parser__NS_struct_decl));
        memset((i8*)sd, 0, sizeof(parser__NS_struct_decl));
        sd.kind = nd_struct_decl;
        sd.line = ln;
        sd.name = lexer.str_dup(self.consume_id_value("Expected struct name"));
        sd.fields_cap = 8;
        sd.fields = (var_decl**)malloc(sizeof(i8*) * (u64)sd.fields_cap);
        self.consume_tok(obrace, "Expected '{' after struct name");

        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            type_node* ft = self.parse_type();
            lexer.token_t fname = self.consume_tok(id, "Expected field name");
            var_decl* vd = (var_decl*)malloc(sizeof(parser__NS_var_decl));
            memset((i8*)vd, 0, sizeof(parser__NS_var_decl));
            vd.kind = nd_var_decl;
            vd.line = (u64)fname.line;
            vd.type = ft;
            vd.name = lexer.str_dup(fname.value);

            if (self.match_tok(obracket)) {
                if (!self.check_tok(cbracket)) {
                    ft.array_size_ptr = (i8*)self.parse_expr();
                }
                self.consume_tok(cbracket, "Expected ']' after array size");
            }
            self.consume_tok(sm, "Expected ';' after field");

            if (sd.fields_len >= sd.fields_cap) {
                sd.fields_cap = sd.fields_cap * 2;
                sd.fields = (var_decl**)realloc((i8*)sd.fields, sizeof(i8*) * (u64)sd.fields_cap);
            }
            sd.fields[sd.fields_len] = vd;
            sd.fields_len = sd.fields_len + 1;
        }
        self.consume_tok(cbrace, "Expected '}' after struct body");
        return sd;
    }

    enum_decl* parse_enum_decl(parser_t* self) {
        u64 ln = (u64)self.peek_line();
        self.advance_tok();  // consume 'enum'
        enum_decl* ed = (enum_decl*)malloc(sizeof(parser__NS_enum_decl));
        memset((i8*)ed, 0, sizeof(parser__NS_enum_decl));
        ed.kind = nd_enum_decl;
        ed.line = ln;
        ed.name = lexer.str_dup(self.consume_id_value("Expected enum name"));
        ed.variants_cap = 16;
        ed.variant_names        = (i8**)malloc(sizeof(i8*) * (u64)ed.variants_cap);
        ed.variant_vals         = (i64*)malloc(sizeof(i64) * (u64)ed.variants_cap);
        ed.variant_has_val      = (bool*)malloc(sizeof(bool) * (u64)ed.variants_cap);
        ed.variant_kinds        = (i32*)malloc(sizeof(i32) * (u64)ed.variants_cap);
        ed.variant_field_counts = (i32*)malloc(sizeof(i32) * (u64)ed.variants_cap);
        ed.variant_field_names_flat = (i8**)malloc(sizeof(i8*) * (u64)(ed.variants_cap * 8));
        ed.variant_field_type_flat  = (i8**)malloc(sizeof(i8*) * (u64)(ed.variants_cap * 8));
        ed.variant_method_flat      = (i8**)malloc(sizeof(i8*) * (u64)(ed.variants_cap * 8));
        ed.variant_method_counts    = (i32*)malloc(sizeof(i32) * (u64)ed.variants_cap);
        self.consume_tok(obrace, "Expected '{' after enum name");

        i64 next_val = 0;
        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            lexer.token_t var_name = self.consume_tok(id, "Expected variant name");

            // Grow if needed
            if (ed.variants_len >= ed.variants_cap) {
                ed.variants_cap = ed.variants_cap * 2;
                ed.variant_names        = (i8**)realloc((i8*)ed.variant_names,        sizeof(i8*) * (u64)ed.variants_cap);
                ed.variant_vals         = (i64*)realloc((i8*)ed.variant_vals,         sizeof(i64) * (u64)ed.variants_cap);
                ed.variant_has_val      = (bool*)realloc((i8*)ed.variant_has_val,      sizeof(bool) * (u64)ed.variants_cap);
                ed.variant_kinds        = (i32*)realloc((i8*)ed.variant_kinds,        sizeof(i32) * (u64)ed.variants_cap);
                ed.variant_field_counts = (i32*)realloc((i8*)ed.variant_field_counts, sizeof(i32) * (u64)ed.variants_cap);
                ed.variant_field_names_flat = (i8**)realloc((i8*)ed.variant_field_names_flat, sizeof(i8*) * (u64)(ed.variants_cap * 8));
                ed.variant_field_type_flat  = (i8**)realloc((i8*)ed.variant_field_type_flat,  sizeof(i8*) * (u64)(ed.variants_cap * 8));
                ed.variant_method_flat      = (i8**)realloc((i8*)ed.variant_method_flat,      sizeof(i8*) * (u64)(ed.variants_cap * 8));
                ed.variant_method_counts    = (i32*)realloc((i8*)ed.variant_method_counts,    sizeof(i32) * (u64)ed.variants_cap);
            }

            i32 vi = ed.variants_len;
            ed.variant_names[vi]          = lexer.str_dup(var_name.value);
            ed.variant_kinds[vi]          = 0; // plain by default
            ed.variant_field_counts[vi]   = 0;
            ed.variant_method_counts[vi]  = 0;
            // Init flat slots for this variant (stride 8)
            {
                i32 si = 0;
                while (si < 8) {
                    ed.variant_field_names_flat[vi * 8 + si] = (i8*)0;
                    ed.variant_field_type_flat[vi * 8 + si]  = (i8*)0;
                    ed.variant_method_flat[vi * 8 + si]      = (i8*)0;
                    si = si + 1;
                }
            }

            // ADT tuple variant: Variant(type1, type2, ...)
            if (self.check_tok(oparen)) {
                self.advance_tok(); // consume '('
                ed.variant_kinds[vi] = 1; // tuple
                ed.is_adt = true;
                i32 fc = 0;
                while (!self.check_tok(cparen) && !self.is_at_end_p() && fc < 8) {
                    type_node* ft = self.parse_type();
                    ed.variant_field_type_flat[vi * 8 + fc]  = (i8*)ft;
                    ed.variant_field_names_flat[vi * 8 + fc] = (i8*)0;
                    fc = fc + 1;
                    self.match_tok(comma);
                }
                self.consume_tok(cparen, "Expected ')' in tuple variant");
                ed.variant_field_counts[vi] = fc;
            }

            // ADT named struct / istruc variant: Variant { ... } or Variant .{ ... }
            bool has_dot_brace = self.check_tok(dot);
            if (has_dot_brace) { self.advance_tok(); } // consume optional '.'
            if (self.check_tok(obrace)) {
                self.advance_tok(); // consume '{'
                ed.is_adt = true;
                ed.variant_kinds[vi] = has_dot_brace ? 3 : 2; // 3=istruc_dot, 2=named_struct
                i32 fc = 0;
                i32 depth_vs = 1;
                while (depth_vs > 0 && !self.is_at_end_p()) {
                    if (self.check_tok(obrace)) {
                        depth_vs = depth_vs + 1; self.advance_tok();
                    } else if (self.check_tok(cbrace)) {
                        depth_vs = depth_vs - 1;
                        if (depth_vs > 0) { self.advance_tok(); } else { break; }
                    } else if (depth_vs == 1 && self.is_type_start() && !self.check_tok(kw_const)) {
                        i32 saved_pos = self.current;
                        type_node* ft = self.parse_type();
                        if (self.check_tok(id)) {
                            lexer.token_t fname = self.consume_tok(id, "field name");
                            if (self.check_tok(sm)) {
                                self.advance_tok();
                                if (fc < 8) {
                                    ed.variant_field_names_flat[vi * 8 + fc] = lexer.str_dup(fname.value);
                                    ed.variant_field_type_flat[vi * 8 + fc]  = (i8*)ft;
                                    fc = fc + 1;
                                }
                            } else if (self.check_tok(oparen)) {
                                self.advance_tok(); // consume '('
                                func_decl* mfd = self.parse_func_body(ft, fname, false);
                                if (mfd != (func_decl*)0) {
                                    i32 mc = ed.variant_method_counts[vi];
                                    if (mc < 8) {
                                        ed.variant_method_flat[vi * 8 + mc] = (i8*)mfd;
                                        ed.variant_method_counts[vi] = mc + 1;
                                    }
                                }
                            } else { self.current = saved_pos; self.advance_tok(); }
                        } else { self.current = saved_pos; self.advance_tok(); }
                    } else if (depth_vs == 1 && self.check_tok(kw_const) && self.peek_at_type(1) != kw_const) {
                        i32 saved_pos = self.current;
                        type_node* ft = self.parse_type();
                        if (self.check_tok(id)) {
                            lexer.token_t fname = self.consume_tok(id, "field name");
                            if (self.check_tok(sm)) {
                                self.advance_tok();
                                if (fc < 8) {
                                    ed.variant_field_names_flat[vi * 8 + fc] = lexer.str_dup(fname.value);
                                    ed.variant_field_type_flat[vi * 8 + fc]  = (i8*)ft;
                                    fc = fc + 1;
                                }
                            } else if (self.check_tok(oparen)) {
                                self.advance_tok(); // consume '('
                                func_decl* mfd = self.parse_func_body(ft, fname, false);
                                if (mfd != (func_decl*)0) {
                                    i32 mc = ed.variant_method_counts[vi];
                                    if (mc < 8) {
                                        ed.variant_method_flat[vi * 8 + mc] = (i8*)mfd;
                                        ed.variant_method_counts[vi] = mc + 1;
                                    }
                                }
                            } else { self.current = saved_pos; self.advance_tok(); }
                        } else { self.current = saved_pos; self.advance_tok(); }
                    } else { self.advance_tok(); }
                }
                self.consume_tok(cbrace, "Expected '}' after variant body");
                ed.variant_field_counts[vi] = fc;
            }

            if (self.match_tok(assign)) {
                expr_node* val_expr = self.parse_expr();
                if (val_expr.kind == ek_int_lit) { next_val = val_expr.int_val; }
                ed.variant_vals[vi]    = next_val;
                ed.variant_has_val[vi] = true;
            } else {
                ed.variant_vals[vi]    = next_val;
                ed.variant_has_val[vi] = false;
            }
            next_val = next_val + 1;
            ed.variants_len = ed.variants_len + 1;

            if (!self.check_tok(cbrace)) {
                self.consume_tok(comma, "Expected ',' between enum variants");
            }
        }
        self.consume_tok(cbrace, "Expected '}' after enum body");
        return ed;
    }

    typedef_decl* parse_typedef_decl(parser_t* self) {
        u64 ln = (u64)self.peek_line();
        self.advance_tok();  // consume 'typedef'
        typedef_decl* td = (typedef_decl*)malloc(sizeof(parser__NS_typedef_decl));
        memset((i8*)td, 0, sizeof(parser__NS_typedef_decl));
        td.kind = nd_typedef_decl;
        td.line = ln;

        if (self.check_tok(kw_auto)) {
            self.advance_tok();
            td.name = lexer.str_dup(self.consume_id_value("Expected typedef alias"));
            self.consume_tok(assign, "Expected '=' in typedef auto");
            td.target = self.parse_type();
        } else {
            td.target = self.parse_type();
            td.name   = lexer.str_dup(self.consume_id_value("Expected typedef alias"));
        }
        self.consume_tok(sm, "Expected ';' after typedef");
        return td;
    }

    namespace_decl* parse_namespace_decl(parser_t* self) {
        u64 ln = (u64)self.peek_line();
        self.advance_tok();  // consume 'namespace'
        namespace_decl* nd = (namespace_decl*)malloc(sizeof(parser__NS_namespace_decl));
        memset((i8*)nd, 0, sizeof(parser__NS_namespace_decl));
        nd.kind = nd_namespace_decl;
        nd.line = ln;
        nd.name = lexer.str_dup(self.consume_id_value("Expected namespace name"));
        nd.decls_cap = 16;
        nd.decls = (ast_node**)malloc(sizeof(i8*) * (u64)nd.decls_cap);
        self.consume_tok(obrace, "Expected '{' after namespace name");

        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            ast_node* decl = self.parse_top_level();
            if (decl != (ast_node*)0) {
                if (nd.decls_len >= nd.decls_cap) {
                    nd.decls_cap = nd.decls_cap * 2;
                    nd.decls = (ast_node**)realloc((i8*)nd.decls, sizeof(i8*) * (u64)nd.decls_cap);
                }
                nd.decls[nd.decls_len] = decl;
                nd.decls_len = nd.decls_len + 1;
            }
        }
        self.consume_tok(cbrace, "Expected '}' after namespace body");
        return nd;
    }

    extern_c_block* parse_extern_c_block(parser_t* self) {
        u64 ln = (u64)self.peek_line();
        self.advance_tok();  // consume 'extern "C"'
        extern_c_block* blk = (extern_c_block*)malloc(sizeof(parser__NS_extern_c_block));
        memset((i8*)blk, 0, sizeof(parser__NS_extern_c_block));
        blk.kind = nd_extern_c_block;
        blk.line = ln;
        blk.decls_cap = 16;
        blk.decls = (ast_node**)malloc(sizeof(i8*) * (u64)blk.decls_cap);

        if (self.match_tok(obrace)) {
            while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                ast_node* decl = self.parse_func_or_var_decl_extern_c();
                if (decl != (ast_node*)0) {
                    if (blk.decls_len >= blk.decls_cap) {
                        blk.decls_cap = blk.decls_cap * 2;
                        blk.decls = (ast_node**)realloc((i8*)blk.decls, sizeof(i8*) * (u64)blk.decls_cap);
                    }
                    blk.decls[blk.decls_len] = decl;
                    blk.decls_len = blk.decls_len + 1;
                }
            }
            self.consume_tok(cbrace, "Expected '}' after extern \"C\" block");
        } else {
            ast_node* decl = self.parse_func_or_var_decl_extern_c();
            blk.decls[0] = decl;
            blk.decls_len = 1;
        }
        return blk;
    }

    // Stub class_decl parser - we parse istruc bodies as namespace_decl for simplicity
    ast_node* parse_class_decl_stub(parser_t* self) {
        u64 ln = (u64)self.peek_line();
        self.advance_tok();  // consume 'istruc' or 'interface'
        lexer.token_t class_name = self.consume_tok(id, "Expected class name");

        // Skip optional type params: <T, U>
        if (self.check_tok(lt)) {
            i32 depth = 0;
            bool scanning = true;
            while (scanning && !self.is_at_end_p()) {
                if (self.check_tok(lt))  { depth = depth + 1; self.advance_tok(); }
                else if (self.check_tok(gt)) {
                    depth = depth - 1;
                    self.advance_tok();
                    if (depth <= 0) { scanning = false; }
                } else {
                    self.advance_tok();
                }
            }
        }

        // Skip optional : Interface list
        if (self.match_tok(colon)) {
            while (self.check_tok(id)) {
                self.advance_tok();
                if (!self.match_tok(comma)) { break; }
            }
        }

        // Parse body as a namespace for simplicity
        namespace_decl* nd = (namespace_decl*)malloc(sizeof(parser__NS_namespace_decl));
        memset((i8*)nd, 0, sizeof(parser__NS_namespace_decl));
        nd.kind = nd_namespace_decl;
        nd.line = ln;
        nd.name = lexer.str_dup(class_name.value);
        nd.decls_cap = 16;
        nd.decls = (ast_node**)malloc(sizeof(i8*) * (u64)nd.decls_cap);

        self.consume_tok(obrace, "Expected '{' after class name");
        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            // Skip modifiers: const, static, inline, virtual, override, noexcept, constexpr
            bool skip_mod = true;
            while (skip_mod) {
                i32 tt = self.peek_type();
                if (tt == kw_const || tt == kw_static || tt == kw_noexcept ||
                        tt == kw_constexpr || tt == kw_consteval) {
                    self.advance_tok();
                } else {
                    skip_mod = false;
                }
            }

            if (self.check_tok(cbrace)) { break; }

            // Conversion operator: operator TypeName(...) — no return type prefix
            if (self.check_tok(kw_operator)) {
                i32 op_nt = self.peek_at_type(1);
                if (op_nt == kw_arb_int || op_nt == kw_arb_uint || op_nt == kw_arb_float) {
                    self.advance_tok(); // consume 'operator'
                    i32 op_tt = self.peek_type();
                    type_node* conv_ret = self.parse_type();
                    i8 conv_name[64];
                    if (op_tt == kw_arb_int) {
                        snprintf(conv_name, (u64)64, "operator_i%d", (i32)conv_ret.bit_width);
                    } else if (op_tt == kw_arb_uint) {
                        snprintf(conv_name, (u64)64, "operator_u%d", (i32)conv_ret.bit_width);
                    } else {
                        snprintf(conv_name, (u64)64, "operator_f%d", (i32)conv_ret.bit_width);
                    }
                    lexer.token_t conv_nt;
                    conv_nt.type  = id;
                    conv_nt.value = lexer.str_dup(conv_name);
                    conv_nt.line  = 0;
                    self.consume_tok(oparen, "Expected '(' for conversion operator");
                    func_decl* conv_fd = self.parse_func_body(conv_ret, conv_nt, false);
                    if (conv_fd != (func_decl*)0) {
                        if (nd.decls_len >= nd.decls_cap) {
                            nd.decls_cap = nd.decls_cap * 2;
                            nd.decls = (ast_node**)realloc((i8*)nd.decls, sizeof(i8*) * (u64)nd.decls_cap);
                        }
                        nd.decls[nd.decls_len] = (ast_node*)conv_fd;
                        nd.decls_len = nd.decls_len + 1;
                    }
                    continue;
                }
            }

            ast_node* member = self.parse_func_or_var_decl();
            if (member != (ast_node*)0) {
                if (nd.decls_len >= nd.decls_cap) {
                    nd.decls_cap = nd.decls_cap * 2;
                    nd.decls = (ast_node**)realloc((i8*)nd.decls, sizeof(i8*) * (u64)nd.decls_cap);
                }
                nd.decls[nd.decls_len] = member;
                nd.decls_len = nd.decls_len + 1;
            }
        }
        self.consume_tok(cbrace, "Expected '}' after class body");
        self.match_tok(sm);

        // Post-process: split var_decl fields vs func_decl methods.
        // Build a struct_decl for the fields, then a namespace_decl with
        // the struct_decl first, followed by the method func_decls.
        struct_decl* sd = (struct_decl*)malloc(sizeof(parser__NS_struct_decl));
        memset((i8*)sd, 0, sizeof(parser__NS_struct_decl));
        sd.kind       = nd_struct_decl;
        sd.line       = ln;
        sd.name       = lexer.str_dup(nd.name);
        sd.fields_cap = 8;
        sd.fields     = (var_decl**)malloc(sizeof(i8*) * (u64)sd.fields_cap);
        sd.fields_len = 0;

        namespace_decl* out = (namespace_decl*)malloc(sizeof(parser__NS_namespace_decl));
        memset((i8*)out, 0, sizeof(parser__NS_namespace_decl));
        out.kind      = nd_namespace_decl;
        out.line      = ln;
        out.name      = nd.name;
        out.decls_cap = nd.decls_len + 4;
        out.decls     = (ast_node**)malloc(sizeof(i8*) * (u64)out.decls_cap);
        out.decls_len = 0;

        // Add struct_decl as first child (fields collected below)
        out.decls[0]  = (ast_node*)sd;
        out.decls_len = 1;

        // Pass: fields → struct, methods → namespace
        i32 pi = 0;
        while (pi < nd.decls_len) {
            ast_node* m = nd.decls[pi];
            if (m != (ast_node*)0 && m.kind == nd_var_decl) {
                if (sd.fields_len >= sd.fields_cap) {
                    sd.fields_cap = sd.fields_cap * 2;
                    sd.fields = (var_decl**)realloc((i8*)sd.fields, sizeof(i8*) * (u64)sd.fields_cap);
                }
                sd.fields[sd.fields_len] = (var_decl*)m;
                sd.fields_len = sd.fields_len + 1;
            } else if (m != (ast_node*)0) {
                if (out.decls_len >= out.decls_cap) {
                    out.decls_cap = out.decls_cap * 2;
                    out.decls = (ast_node**)realloc((i8*)out.decls, sizeof(i8*) * (u64)out.decls_cap);
                }
                out.decls[out.decls_len] = m;
                out.decls_len = out.decls_len + 1;
            }
            pi = pi + 1;
        }
        free((i8*)nd.decls);
        free((i8*)nd);
        return (ast_node*)out;
    }

    ast_node* parse_top_level(parser_t* self) {
        if (self.check_tok(kw_struct))     { return (ast_node*)self.parse_struct_decl(); }
        if (self.check_tok(kw_union))      {
            struct_decl* ud = self.parse_struct_decl();
            if (ud != (struct_decl*)0) { ud.is_union = true; }
            return (ast_node*)ud;
        }
        if (self.check_tok(kw_enum))       { return (ast_node*)self.parse_enum_decl(); }
        if (self.check_tok(kw_typedef))    { return (ast_node*)self.parse_typedef_decl(); }
        if (self.check_tok(kw_istruc))     { return self.parse_class_decl_stub(); }
        if (self.check_tok(kw_interface))  { return self.parse_class_decl_stub(); }
        if (self.check_tok(kw_extern_c))   { return (ast_node*)self.parse_extern_c_block(); }
        if (self.check_tok(kw_namespace))  { return (ast_node*)self.parse_namespace_decl(); }
        // skip hash/attribute markers for now
        if (self.check_tok(hash)) {
            while (!self.check_tok(cbracket) && !self.is_at_end_p()) {
                self.advance_tok();
            }
            if (!self.is_at_end_p()) { self.advance_tok(); } // consume ']'
            return self.parse_top_level();
        }
        if (self.check_tok(kw_smem)) { return self.parse_class_decl_stub(); }
        // using Alias = Type; — treat as typedef
        if (self.check_tok(kw_using)) {
            self.advance_tok(); // consume 'using'
            typedef_decl* td = (typedef_decl*)malloc(sizeof(parser__NS_typedef_decl));
            memset((i8*)td, 0, sizeof(parser__NS_typedef_decl));
            td.kind = nd_typedef_decl;
            td.name = lexer.str_dup(self.consume_id_value("Expected alias name after using"));
            self.consume_tok(assign, "Expected '=' in using declaration");
            td.target = self.parse_type();
            self.consume_tok(sm, "Expected ';' after using declaration");
            return (ast_node*)td;
        }
        // const_resolve macro definitions
        if (self.check_tok(kw_const_resolve)) {
            self.advance_tok(); // consume keyword
            i8* macro_name = (i8*)0;
            if (self.check_tok(id)) {
                lexer.token_t nm_tok = self.advance_tok();
                macro_name = lexer.str_dup(nm_tok.value);
            }
            if (macro_name == (i8*)0) { return (ast_node*)0; }
            self.consume_tok(obrace, "Expected '{' after const_resolve name");
            // Parse rules until '}'
            while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                i8* param_names_buf[16];
                i32 param_count = 0;
                // Pattern: (...) or [...]
                i32 pat_open  = self.check_tok(oparen)   ? oparen   : (self.check_tok(obracket) ? obracket : -1);
                i32 pat_close = (pat_open == oparen)      ? cparen   : (pat_open == obracket ? cbracket : -1);
                if (pat_open != -1) {
                    self.advance_tok(); // consume open
                    while (!self.check_tok(pat_close) && !self.is_at_end_p()) {
                        if (self.check_tok(dollar)) {
                            self.advance_tok(); // '$'
                            i8* pname = (i8*)0;
                            if (self.check_tok(id)) {
                                lexer.token_t pn_tok = self.advance_tok();
                                pname = lexer.str_dup(pn_tok.value);
                            }
                            if (self.check_tok(colon)) {
                                self.advance_tok(); // ':'
                                self.advance_tok(); // type fragment
                            }
                            if (pname != (i8*)0 && param_count < 16) {
                                param_names_buf[param_count] = pname;
                                param_count = param_count + 1;
                            }
                        } else {
                            self.advance_tok(); // skip literal match tokens
                        }
                        if (self.check_tok(comma) && !self.check_tok(pat_close)) { self.advance_tok(); }
                    }
                    self.consume_tok(pat_close, "Expected closing delimiter for macro pattern");
                }
                // Consume '=>'
                if (self.check_tok(assign)) { self.advance_tok(); }
                if (self.check_tok(gt))     { self.advance_tok(); }
                // Collect template tokens
                i32 tpl_cap = 64;
                lexer.token_t* tpl = (lexer.token_t*)malloc(sizeof(lexer__NS_token_t) * (u64)tpl_cap);
                i32 tpl_len = 0;
                if (self.check_tok(obrace)) {
                    self.advance_tok(); // consume '{'
                    i32 depth_t = 1;
                    while (depth_t > 0 && !self.is_at_end_p()) {
                        lexer.token_t cur = self.peek_tok();
                        if (cur.type == obrace) { depth_t = depth_t + 1; }
                        else if (cur.type == cbrace) {
                            depth_t = depth_t - 1;
                            if (depth_t == 0) { self.advance_tok(); break; }
                        }
                        if (tpl_len >= tpl_cap) {
                            tpl_cap = tpl_cap * 2;
                            tpl = (lexer.token_t*)realloc((i8*)tpl, sizeof(lexer__NS_token_t) * (u64)tpl_cap);
                        }
                        tpl[tpl_len] = cur;
                        tpl_len = tpl_len + 1;
                        self.advance_tok();
                    }
                }
                // Store macro definition
                macro_def_t* mdef = (macro_def_t*)malloc(sizeof(parser__NS_macro_def_t));
                mdef.name         = macro_name;
                mdef.param_count  = param_count;
                mdef.template_toks = (i8*)tpl;
                mdef.template_len  = tpl_len;
                mdef.param_names   = (i8**)malloc(sizeof(i8*) * (u64)(param_count + 1));
                i32 pi = 0;
                while (pi < param_count) {
                    mdef.param_names[pi] = param_names_buf[pi];
                    pi = pi + 1;
                }
                if (self.macros_len >= self.macros_cap) {
                    self.macros_cap = self.macros_cap * 2;
                    self.macros = (macro_def_t**)realloc((i8*)self.macros, sizeof(i8*) * (u64)self.macros_cap);
                }
                self.macros[self.macros_len] = mdef;
                self.macros_len = self.macros_len + 1;
                if (self.check_tok(comma)) { self.advance_tok(); }
            }
            self.consume_tok(cbrace, "Expected '}' after const_resolve body");
            return (ast_node*)0;
        }
        return self.parse_func_or_var_decl();
    }

    // ---- Block and statement parsing ----

    block_stmt* parse_block(parser_t* self) {
        u64 ln = (u64)self.peek_line();
        self.consume_tok(obrace, "Expected '{'");
        block_stmt* blk = (block_stmt*)malloc(sizeof(parser__NS_block_stmt));
        memset((i8*)blk, 0, sizeof(parser__NS_block_stmt));
        blk.kind = nd_block;
        blk.line = ln;

        i32 stmts_cap = 16;
        blk.stmts = (ast_node**)malloc(sizeof(i8*) * (u64)stmts_cap);
        blk.stmts_len = 0;

        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            ast_node* s = self.parse_stmt();
            if (s != (ast_node*)0) {
                if (blk.stmts_len >= stmts_cap) {
                    stmts_cap = stmts_cap * 2;
                    blk.stmts = (ast_node**)realloc((i8*)blk.stmts, sizeof(i8*) * (u64)stmts_cap);
                }
                blk.stmts[blk.stmts_len] = s;
                blk.stmts_len = blk.stmts_len + 1;
            }
        }
        self.consume_tok(cbrace, "Expected '}'");
        return blk;
    }

    var_decl* parse_local_var_decl(parser_t* self) {
        type_node* t = self.parse_type();
        if (!self.check_tok(id)) {
            printf("Parse Error at line %d: Expected variable name\n",
                    self.peek_line());
            self.had_parse_error = true;
        }
        lexer.token_t name_tok = self.advance_tok();
        // Trailing type: auto name: type
        if (t.is_auto && self.check_tok(colon)) {
            self.advance_tok();
            t = self.parse_type();
        }
        var_decl* vd = (var_decl*)malloc(sizeof(parser__NS_var_decl));
        memset((i8*)vd, 0, sizeof(parser__NS_var_decl));
        vd.kind    = nd_var_decl;
        vd.line    = (u64)name_tok.line;
        vd.type    = t;
        vd.name    = lexer.str_dup(name_tok.value);
        vd.is_sta  = t.is_sta;

        if (self.match_tok(obracket)) {
            if (!self.check_tok(cbracket)) {
                t.array_size_ptr = (i8*)self.parse_expr();
            }
            self.consume_tok(cbracket, "Expected ']' after array size");
        }
        // Constructor call: TypeName varname(args...)
        if (self.match_tok(oparen)) {
            vd.has_ctor_parens = true;
            i32 ctor_cap2 = 4;
            vd.ctor_args = (i8**)malloc(sizeof(i8*) * (u64)ctor_cap2);
            vd.ctor_args_len = 0;
            if (!self.check_tok(cparen)) {
                bool p_ctor2 = true;
                while (p_ctor2) {
                    if (vd.ctor_args_len >= ctor_cap2) {
                        ctor_cap2 = ctor_cap2 * 2;
                        vd.ctor_args = (i8**)realloc((i8*)vd.ctor_args, sizeof(i8*) * (u64)ctor_cap2);
                    }
                    vd.ctor_args[vd.ctor_args_len] = (i8*)self.parse_assignment();
                    vd.ctor_args_len = vd.ctor_args_len + 1;
                    if (!self.match_tok(comma)) { p_ctor2 = false; }
                }
            }
            self.consume_tok(cparen, "Expected ')' after constructor args");
        } else if (self.match_tok(obrace)) {
            // Brace constructor: TypeName varname{args...}
            vd.has_ctor_parens = true;
            i32 ctor_cap3 = 4;
            vd.ctor_args = (i8**)malloc(sizeof(i8*) * (u64)ctor_cap3);
            vd.ctor_args_len = 0;
            if (!self.check_tok(cbrace)) {
                bool p_ctor3 = true;
                while (p_ctor3) {
                    if (vd.ctor_args_len >= ctor_cap3) {
                        ctor_cap3 = ctor_cap3 * 2;
                        vd.ctor_args = (i8**)realloc((i8*)vd.ctor_args, sizeof(i8*) * (u64)ctor_cap3);
                    }
                    vd.ctor_args[vd.ctor_args_len] = (i8*)self.parse_assignment();
                    vd.ctor_args_len = vd.ctor_args_len + 1;
                    if (!self.match_tok(comma)) { p_ctor3 = false; }
                }
            }
            self.consume_tok(cbrace, "Expected '}' after constructor args");
        } else if (self.match_tok(assign)) {
            vd.init     = self.parse_expr();
            vd.has_init = true;
        }
        self.consume_tok(sm, "Expected ';' after variable declaration");
        return vd;
    }

    ast_node* parse_if_stmt(parser_t* self) {
        if_stmt* n = (if_stmt*)malloc(sizeof(parser__NS_if_stmt));
        memset((i8*)n, 0, sizeof(parser__NS_if_stmt));
        n.kind = nd_if_stmt;
        n.line = (u64)self.advance_line_get();  // consume 'if'

        if (self.check_tok(kw_constexpr)) { self.advance_tok(); n.is_constexpr = true; }
        bool has_parens = self.match_tok(oparen);
        n.cond = self.parse_expr();
        if (has_parens) { self.consume_tok(cparen, "Expected ')' after condition"); }

        // Optional |capture|
        if (self.match_tok(bit_or)) {
            n.then_capture = lexer.str_dup(self.consume_id_value("Expected identifier in capture"));
            self.consume_tok(bit_or, "Expected '|' after capture");
        }

        n.then_body = self.parse_stmt();
        if (self.match_tok(kw_else)) {
            if (self.match_tok(bit_or)) {
                n.else_capture = lexer.str_dup(self.consume_id_value("Expected identifier in capture"));
                self.consume_tok(bit_or, "Expected '|' after capture");
            }
            n.else_body = self.parse_stmt();
        }
        return (ast_node*)n;
    }

    ast_node* parse_while_stmt(parser_t* self) {
        while_stmt* n = (while_stmt*)malloc(sizeof(parser__NS_while_stmt));
        memset((i8*)n, 0, sizeof(parser__NS_while_stmt));
        n.kind = nd_while_stmt;
        n.line = (u64)self.advance_line_get();

        bool has_parens = self.match_tok(oparen);
        n.cond = self.parse_expr();
        if (has_parens) { self.consume_tok(cparen, "Expected ')' after condition"); }
        n.body = self.parse_stmt();
        return (ast_node*)n;
    }

    ast_node* parse_for_stmt(parser_t* self) {
        u64 ln = (u64)self.advance_line_get();  // consume 'for'
        bool has_parens = self.match_tok(oparen);

        for_stmt* n = (for_stmt*)malloc(sizeof(parser__NS_for_stmt));
        memset((i8*)n, 0, sizeof(parser__NS_for_stmt));
        n.kind = nd_for_stmt;
        n.line = ln;

        if (!self.check_tok(sm)) {
            if (self.is_type_start()) {
                n.init = (ast_node*)self.parse_local_var_decl();
            } else {
                expr_stmt* es = (expr_stmt*)malloc(sizeof(parser__NS_expr_stmt));
                memset((i8*)es, 0, sizeof(parser__NS_expr_stmt));
                es.kind = nd_expr_stmt;
                es.expr = self.parse_expr();
                self.consume_tok(sm, "Expected ';'");
                n.init = (ast_node*)es;
            }
        } else {
            self.advance_tok();  // consume ';'
        }

        if (!self.check_tok(sm)) {
            n.cond = self.parse_expr();
        }
        self.consume_tok(sm, "Expected ';' in for");

        bool no_step = has_parens ? self.check_tok(cparen) : self.check_tok(obrace);
        if (!no_step) {
            n.step = self.parse_expr();
        }
        if (has_parens) { self.consume_tok(cparen, "Expected ')' after for clauses"); }
        n.body = self.parse_stmt();
        return (ast_node*)n;
    }

    ast_node* parse_switch_stmt(parser_t* self) {
        switch_stmt* n = (switch_stmt*)malloc(sizeof(parser__NS_switch_stmt));
        memset((i8*)n, 0, sizeof(parser__NS_switch_stmt));
        n.kind = nd_switch_stmt;
        n.line = (u64)self.advance_line_get();

        bool has_parens = self.match_tok(oparen);
        n.val = self.parse_expr();
        if (has_parens) { self.consume_tok(cparen, "Expected ')'"); }
        self.consume_tok(obrace, "Expected '{'");

        i32 cases_cap = 8;
        n.case_vals       = (expr_node***)malloc(sizeof(i8*) * (u64)cases_cap);
        n.case_bodies     = (block_stmt**)malloc(sizeof(i8*) * (u64)cases_cap);
        n.case_is_default = (bool*)malloc(sizeof(bool) * (u64)cases_cap);
        n.cases_len = 0;
        n.cases_cap = cases_cap;

        while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
            bool is_default = false;
            expr_node* case_val = (expr_node*)0;

            if (self.match_tok(kw_case)) {
                case_val = self.parse_expr();
            } else {
                self.consume_tok(kw_default, "Expected 'case' or 'default'");
                is_default = true;
            }
            self.consume_tok(colon, "Expected ':' after case label");

            block_stmt* body = (block_stmt*)malloc(sizeof(parser__NS_block_stmt));
            memset((i8*)body, 0, sizeof(parser__NS_block_stmt));
            body.kind = nd_block;
            i32 body_cap = 8;
            body.stmts = (ast_node**)malloc(sizeof(i8*) * (u64)body_cap);

            while (!self.check_tok(kw_case) &&
                   !self.check_tok(kw_default) &&
                   !self.check_tok(cbrace) &&
                   !self.is_at_end_p()) {
                ast_node* s = self.parse_stmt();
                if (s != (ast_node*)0) {
                    if (body.stmts_len >= body_cap) {
                        body_cap = body_cap * 2;
                        body.stmts = (ast_node**)realloc((i8*)body.stmts, sizeof(i8*) * (u64)body_cap);
                    }
                    body.stmts[body.stmts_len] = s;
                    body.stmts_len = body.stmts_len + 1;
                }
            }

            if (n.cases_len >= n.cases_cap) {
                n.cases_cap = n.cases_cap * 2;
                n.case_vals       = (expr_node***)realloc((i8*)n.case_vals,       sizeof(i8*) * (u64)n.cases_cap);
                n.case_bodies     = (block_stmt**)realloc((i8*)n.case_bodies,     sizeof(i8*) * (u64)n.cases_cap);
                n.case_is_default = (bool*)realloc((i8*)n.case_is_default, sizeof(bool) * (u64)n.cases_cap);
            }
            n.case_vals[n.cases_len]       = (expr_node**)case_val;
            n.case_bodies[n.cases_len]     = body;
            n.case_is_default[n.cases_len] = is_default;
            n.cases_len = n.cases_len + 1;
        }
        self.consume_tok(cbrace, "Expected '}' after switch");
        return (ast_node*)n;
    }

    ast_node* parse_return_stmt(parser_t* self) {
        return_stmt* n = (return_stmt*)malloc(sizeof(parser__NS_return_stmt));
        memset((i8*)n, 0, sizeof(parser__NS_return_stmt));
        n.kind = nd_return_stmt;
        n.line = (u64)self.advance_line_get();
        if (!self.check_tok(sm)) {
            n.val     = self.parse_expr();
            n.has_val = true;
        }
        self.consume_tok(sm, "Expected ';' after return");
        return (ast_node*)n;
    }

    ast_node* parse_defer_stmt(parser_t* self) {
        defer_stmt* n = (defer_stmt*)malloc(sizeof(parser__NS_defer_stmt));
        memset((i8*)n, 0, sizeof(parser__NS_defer_stmt));
        n.kind = self.check_tok(kw_errdefer) ? nd_errdefer_stmt : nd_defer_stmt;
        n.line = (u64)self.advance_line_get();
        if (self.check_tok(obrace)) {
            n.blk      = (i8*)self.parse_block();
            n.is_block = true;
        } else {
            n.expr = self.parse_expr();
            self.consume_tok(sm, "Expected ';' after defer expression");
        }
        return (ast_node*)n;
    }

    ast_node* parse_stmt(parser_t* self) {
        // Empty statement
        if (self.check_tok(sm)) {
            block_stmt* blk = (block_stmt*)malloc(sizeof(parser__NS_block_stmt));
            memset((i8*)blk, 0, sizeof(parser__NS_block_stmt));
            blk.kind = nd_block;
            blk.line = (u64)self.advance_line_get();
            return (ast_node*)blk;
        }
        if (self.check_tok(obrace))      { return (ast_node*)self.parse_block(); }
        if (self.check_tok(kw_if))       { return self.parse_if_stmt(); }
        if (self.check_tok(kw_while))    { return self.parse_while_stmt(); }
        if (self.check_tok(kw_for))      { return self.parse_for_stmt(); }
        if (self.check_tok(kw_switch))   { return self.parse_switch_stmt(); }
        if (self.check_tok(kw_return))   { return self.parse_return_stmt(); }
        if (self.check_tok(kw_defer))    { return self.parse_defer_stmt(); }
        if (self.check_tok(kw_errdefer)) { return self.parse_defer_stmt(); }

        if (self.check_tok(kw_break)) {
            break_stmt* n = (break_stmt*)malloc(sizeof(parser__NS_break_stmt));
            memset((i8*)n, 0, sizeof(parser__NS_break_stmt));
            n.kind = nd_break_stmt;
            n.line = (u64)self.advance_line_get();
            self.consume_tok(sm, "Expected ';'");
            return (ast_node*)n;
        }
        if (self.check_tok(kw_continue)) {
            continue_stmt* n = (continue_stmt*)malloc(sizeof(parser__NS_continue_stmt));
            memset((i8*)n, 0, sizeof(parser__NS_continue_stmt));
            n.kind = nd_continue_stmt;
            n.line = (u64)self.advance_line_get();
            self.consume_tok(sm, "Expected ';'");
            return (ast_node*)n;
        }

        if (self.check_tok(kw_try)) {
            try_expr_stmt* n = (try_expr_stmt*)malloc(sizeof(parser__NS_try_expr_stmt));
            memset((i8*)n, 0, sizeof(parser__NS_try_expr_stmt));
            n.kind = nd_try_expr_stmt;
            n.line = (u64)self.advance_line_get();
            n.expr = self.parse_expr();
            self.consume_tok(sm, "Expected ';' after try expression");
            return (ast_node*)n;
        }

        if (self.check_tok(kw_constexpr)) {
            self.advance_tok();
            if (self.is_type_start()) {
                var_decl* vd = self.parse_local_var_decl();
                vd.is_constexpr = true;
                return (ast_node*)vd;
            }
            return self.parse_stmt();
        }
        if (self.check_tok(kw_consteval)) {
            self.advance_tok();
            var_decl* vd = self.parse_local_var_decl();
            vd.is_consteval = true;
            return (ast_node*)vd;
        }

        if (self.check_tok(kw_asm)) {
            asm_stmt* n = (asm_stmt*)malloc(sizeof(parser__NS_asm_stmt));
            memset((i8*)n, 0, sizeof(parser__NS_asm_stmt));
            n.kind = nd_asm_stmt;
            n.line = (u64)self.advance_line_get();
            lexer.token_t body_tok = self.consume_tok(asm_body, "Expected '{...}' after __asm__");
            n.raw_instructions = lexer.str_dup(body_tok.value);
            return (ast_node*)n;
        }

        if (self.is_type_start()) {
            return (ast_node*)self.parse_local_var_decl();
        }

        // Expression statement
        expr_stmt* es = (expr_stmt*)malloc(sizeof(parser__NS_expr_stmt));
        memset((i8*)es, 0, sizeof(parser__NS_expr_stmt));
        es.kind = nd_expr_stmt;
        es.line = (u64)self.peek_line();
        es.expr = self.parse_expr();
        if (es.expr != (expr_node*)0 && es.expr.kind == ek_except_expr) {
            self.match_tok(sm);
        } else {
            self.consume_tok(sm, "Expected ';' after expression");
        }
        return (ast_node*)es;
    }

    // ---- Expression parsing (Pratt precedence climbing) ----

    expr_node* parse_expr(parser_t* self) {
        return self.parse_assignment();
    }

    expr_node* parse_assignment(parser_t* self) {
        expr_node* lhs = self.parse_null_coal();

        i32 bop = -1;
        i32 tt  = self.peek_type();
        if (tt == assign)    { bop = bop_assign; }
        else if (tt == plus_eq)  { bop = bop_add_assign; }
        else if (tt == minus_eq) { bop = bop_sub_assign; }
        else if (tt == star_eq)  { bop = bop_mul_assign; }
        else if (tt == slash_eq) { bop = bop_div_assign; }
        else if (tt == mod_eq)   { bop = bop_mod_assign; }
        else if (tt == amp_eq)   { bop = bop_and_assign; }
        else if (tt == pipe_eq)  { bop = bop_or_assign; }
        else if (tt == caret_eq) { bop = bop_xor_assign; }
        else if (tt == shl_eq)   { bop = bop_shl_assign; }
        else if (tt == shr_eq)   { bop = bop_shr_assign; }

        if (bop >= 0) {
            u64 ln = (u64)self.advance_line_get();
            expr_node* rhs = self.parse_assignment();
            expr_node* n = alloc_expr_node();
            n.kind = ek_assign;
            n.line = ln;
            n.lhs  = lhs;
            n.rhs  = rhs;
            n.bop  = bop;
            return n;
        }
        return lhs;
    }

    expr_node* parse_null_coal(parser_t* self) {
        expr_node* lhs = self.parse_ternary();
        while (self.check_tok(question_question)) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_null_coal;
            n.line = (u64)self.prev_line();
            n.lhs  = lhs;
            if (self.check_tok(obrace)) {
                n.handler_block = (i8*)self.parse_block();
            } else {
                n.rhs = self.parse_ternary();
            }
            lhs = n;
        }
        return lhs;
    }

    expr_node* parse_ternary(parser_t* self) {
        expr_node* cond = self.parse_or();
        if (!self.match_tok(question)) { return cond; }
        expr_node* n = alloc_expr_node();
        n.kind  = ek_ternary;
        n.line  = (u64)self.prev_line();
        n.cond  = cond;
        n.then_e = self.parse_expr();
        self.consume_tok(colon, "Expected ':' in ternary");
        n.else_e = self.parse_ternary();
        return n;
    }

    expr_node* parse_or(parser_t* self) {
        expr_node* lhs = self.parse_and();
        while (self.check_tok(or_)) {
            u64 ln = (u64)self.advance_line_get();
            expr_node* n = alloc_expr_node();
            n.kind = ek_binary;
            n.line = ln;
            n.lhs  = lhs;
            n.bop  = bop_log_or;
            n.rhs  = self.parse_and();
            lhs = n;
        }
        return lhs;
    }

    expr_node* parse_and(parser_t* self) {
        expr_node* lhs = self.parse_bitor();
        while (self.check_tok(and_)) {
            u64 ln = (u64)self.advance_line_get();
            expr_node* n = alloc_expr_node();
            n.kind = ek_binary;
            n.line = ln;
            n.lhs  = lhs;
            n.bop  = bop_log_and;
            n.rhs  = self.parse_bitor();
            lhs = n;
        }
        return lhs;
    }

    expr_node* parse_bitor(parser_t* self) {
        expr_node* lhs = self.parse_bitxor();
        while (self.check_tok(bit_or)) {
            u64 ln = (u64)self.advance_line_get();
            expr_node* n = alloc_expr_node();
            n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop_bit_or;
            n.rhs = self.parse_bitxor();
            lhs = n;
        }
        return lhs;
    }

    expr_node* parse_bitxor(parser_t* self) {
        expr_node* lhs = self.parse_bitand();
        while (self.check_tok(bit_xor)) {
            u64 ln = (u64)self.advance_line_get();
            expr_node* n = alloc_expr_node();
            n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop_bit_xor;
            n.rhs = self.parse_bitand();
            lhs = n;
        }
        return lhs;
    }

    expr_node* parse_bitand(parser_t* self) {
        expr_node* lhs = self.parse_equality();
        while (self.check_tok(addr)) {
            u64 ln = (u64)self.advance_line_get();
            expr_node* n = alloc_expr_node();
            n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop_bit_and;
            n.rhs = self.parse_equality();
            lhs = n;
        }
        return lhs;
    }

    expr_node* parse_equality(parser_t* self) {
        expr_node* lhs = self.parse_compare();
        bool running = true;
        while (running) {
            i32 bop = -1;
            if (self.check_tok(eq)) { bop = bop_eq; }
            else if (self.check_tok(ne)) { bop = bop_ne; }
            if (bop < 0) { running = false; }
            else {
                u64 ln = (u64)self.advance_line_get();
                expr_node* n = alloc_expr_node();
                n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop;
                n.rhs = self.parse_compare();
                lhs = n;
            }
        }
        return lhs;
    }

    expr_node* parse_compare(parser_t* self) {
        expr_node* lhs = self.parse_shift();
        bool running = true;
        while (running) {
            i32 bop = -1;
            if (self.check_tok(lt))  { bop = bop_lt; }
            else if (self.check_tok(gt))  { bop = bop_gt; }
            else if (self.check_tok(lte)) { bop = bop_lte; }
            else if (self.check_tok(gte)) { bop = bop_gte; }
            if (bop < 0) { running = false; }
            else {
                u64 ln = (u64)self.advance_line_get();
                expr_node* n = alloc_expr_node();
                n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop;
                n.rhs = self.parse_shift();
                lhs = n;
            }
        }
        return lhs;
    }

    expr_node* parse_shift(parser_t* self) {
        expr_node* lhs = self.parse_add();
        bool running = true;
        while (running) {
            i32 bop = -1;
            if (self.check_tok(left))  { bop = bop_shl; }
            else if (self.check_tok(right)) { bop = bop_shr; }
            if (bop < 0) { running = false; }
            else {
                u64 ln = (u64)self.advance_line_get();
                expr_node* n = alloc_expr_node();
                n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop;
                n.rhs = self.parse_add();
                lhs = n;
            }
        }
        return lhs;
    }

    expr_node* parse_add(parser_t* self) {
        expr_node* lhs = self.parse_mul();
        bool running = true;
        while (running) {
            i32 bop = -1;
            if (self.check_tok(plus))  { bop = bop_add; }
            else if (self.check_tok(minus)) { bop = bop_sub; }
            if (bop < 0) { running = false; }
            else {
                u64 ln = (u64)self.advance_line_get();
                expr_node* n = alloc_expr_node();
                n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop;
                n.rhs = self.parse_mul();
                lhs = n;
            }
        }
        return lhs;
    }

    expr_node* parse_mul(parser_t* self) {
        expr_node* lhs = self.parse_unary();
        bool running = true;
        while (running) {
            i32 bop = -1;
            if (self.check_tok(ast))   { bop = bop_mul; }
            else if (self.check_tok(slash)) { bop = bop_div; }
            else if (self.check_tok(mod))   { bop = bop_mod; }
            if (bop < 0) { running = false; }
            else {
                u64 ln = (u64)self.advance_line_get();
                expr_node* n = alloc_expr_node();
                n.kind = ek_binary; n.line = ln; n.lhs = lhs; n.bop = bop;
                n.rhs = self.parse_unary();
                lhs = n;
            }
        }
        return lhs;
    }

    expr_node* parse_unary(parser_t* self) {
        i32 tt = self.peek_type();
        u64 ln = (u64)self.peek_line();

        if (tt == minus) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_neg;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == plus) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_pos;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == bit_not) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_bit_not;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == not_) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_log_not;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == inc) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_pre_inc;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == dec) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_pre_dec;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == ast) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_deref;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == addr) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_unary; n.line = ln; n.uop = uop_addr_of;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == kw_noexcept) {
            // noexcept(expr) — always evaluates to true (1) in this compiler
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_int_lit; n.line = ln; n.int_val = 1;
            if (self.check_tok(oparen)) {
                self.advance_tok();
                self.parse_expr(); // consume but discard the expression
                self.consume_tok(cparen, "Expected ')' after noexcept argument");
            }
            return n;
        }
        if (tt == kw_try) {
            // try expr — propagates error upward; yields value on success
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_try_expr;
            n.line = ln;
            n.operand = self.parse_unary();
            return n;
        }
        if (tt == kw_error) {
            // error.Variant or error.Variant(payload) — return -1 sentinel
            self.advance_tok(); // consume 'error'
            expr_node* payload_expr = (expr_node*)0;
            if (self.check_tok(dot)) {
                self.advance_tok(); // consume '.'
                if (self.check_tok(id)) { self.advance_tok(); } // consume variant name
                // Optional payload: error.Variant(expr)
                if (self.check_tok(oparen)) {
                    self.advance_tok(); // consume '('
                    if (!self.check_tok(cparen)) { payload_expr = self.parse_expr(); }
                    self.consume_tok(cparen, "Expected ')' after error payload");
                }
            }
            expr_node* n = alloc_expr_node();
            n.kind    = ek_error_lit;
            n.line    = ln;
            n.operand = payload_expr;
            return n;
        }
        if (tt == kw_sizeof) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_sizeof_e; n.line = ln;
            self.consume_tok(oparen, "Expected '(' after sizeof");
            if (self.is_type_start()) {
                n.cast_type = self.parse_type();
            } else {
                n.operand = self.parse_expr();
            }
            self.consume_tok(cparen, "Expected ')' after sizeof argument");
            return n;
        }

        // Cast: (type)expr — check if next is ( followed by a type
        if (tt == oparen) {
            i32 saved = self.current;
            self.advance_tok();  // consume (
            if (self.is_cast_start()) {
                type_node* ct = self.parse_type();
                if (self.check_tok(cparen)) {
                    self.advance_tok();  // consume )
                    expr_node* n = alloc_expr_node();
                    n.kind = ek_cast; n.line = ln;
                    n.cast_type = ct;
                    n.operand = self.parse_unary();
                    return n;
                }
            }
            self.current = saved;
        }

        return self.parse_postfix();
    }

    expr_node* parse_postfix(parser_t* self) {
        expr_node* lhs = self.parse_primary();

        bool running = true;
        while (running) {
            if (self.check_tok(dot) && self.peek_at_type(1) != obrace) {
                self.advance_tok();
                lexer.token_t mem_name = self.consume_tok(id, "Expected member name after '.'");
                if (self.match_tok(oparen)) {
                    // Method call: obj.method(args)
                    expr_node* callee = alloc_expr_node();
                    callee.kind = ek_member;
                    callee.line = (u64)mem_name.line;
                    callee.object = lhs;
                    callee.member_name = lexer.str_dup(mem_name.value);
                    expr_node* call_n = alloc_expr_node();
                    call_n.kind = ek_call;
                    call_n.line = (u64)mem_name.line;
                    call_n.callee = callee;
                    // Parse arguments
                    expr_ptr_vec args;
                    expr_ptr_vec_init(&args);
                    if (!self.check_tok(cparen)) {
                        bool parsing_args = true;
                        while (parsing_args) {
                            expr_ptr_vec_push(&args, self.parse_expr());
                            if (!self.match_tok(comma)) { parsing_args = false; }
                        }
                    }
                    self.consume_tok(cparen, "Expected ')' after arguments");
                    call_n.args     = args.data;
                    call_n.args_len = args.len;
                    lhs = call_n;
                } else {
                    expr_node* n = alloc_expr_node();
                    n.kind = ek_member;
                    n.line = (u64)mem_name.line;
                    n.object = lhs;
                    n.member_name = lexer.str_dup(mem_name.value);
                    lhs = n;
                }
            } else if (self.check_tok(obracket)) {
                self.advance_tok();
                expr_node* idx = self.parse_expr();
                self.consume_tok(cbracket, "Expected ']'");
                expr_node* n = alloc_expr_node();
                n.kind  = ek_subscript;
                n.line  = (u64)self.prev_line();
                n.object = lhs;
                n.index  = idx;
                lhs = n;
            } else if (self.check_tok(inc)) {
                u64 ln = (u64)self.advance_line_get();
                expr_node* n = alloc_expr_node();
                n.kind = ek_unary; n.line = ln; n.uop = uop_post_inc; n.operand = lhs;
                lhs = n;
            } else if (self.check_tok(dec)) {
                u64 ln = (u64)self.advance_line_get();
                expr_node* n = alloc_expr_node();
                n.kind = ek_unary; n.line = ln; n.uop = uop_post_dec; n.operand = lhs;
                lhs = n;
            } else if (self.check_tok(kw_except)) {
                self.advance_tok(); // consume 'except'
                i8* handler_var = (i8*)0;
                if (self.check_tok(bit_or)) {
                    self.advance_tok(); // consume '|'
                    if (self.check_tok(id)) {
                        lexer.token_t evar_tok = self.advance_tok();
                        handler_var = lexer.str_dup(evar_tok.value);
                    }
                    self.consume_tok(bit_or, "Expected '|' after except variable");
                }
                i8* handler_blk = (i8*)0;
                if (self.check_tok(obrace)) {
                    handler_blk = (i8*)self.parse_block();
                }
                expr_node* n = alloc_expr_node();
                n.kind = ek_except_expr;
                n.line = (u64)self.prev_line();
                n.object = lhs;
                n.member_name = handler_var;
                n.handler_block = handler_blk;
                lhs = n;
            } else if (self.check_tok(obrace) && self.peek_at_type(1) == dot) {
                // ADT named-struct constructor: expr { .field = val, ... }
                u64 brace_ln = (u64)self.advance_line_get(); // consume '{'
                expr_node* n = alloc_expr_node();
                n.kind = ek_class_init; n.line = brace_ln;
                n.object = lhs; // base expression (e.g., event.key_press)
                str_vec field_names; str_vec_init(&field_names);
                expr_ptr_vec field_vals; expr_ptr_vec_init(&field_vals);
                while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                    self.consume_tok(dot, "Expected '.' in field init");
                    lexer.token_t fn2 = self.consume_tok(id, "Expected field name");
                    self.consume_tok(assign, "Expected '=' in field init");
                    expr_node* fv = self.parse_expr();
                    str_vec_push(&field_names, lexer.str_dup(fn2.value));
                    expr_ptr_vec_push(&field_vals, fv);
                    self.match_tok(comma);
                }
                self.consume_tok(cbrace, "Expected '}' after field inits");
                n.field_names = field_names.data;
                n.field_vals  = field_vals.data;
                n.field_count = field_names.len;
                lhs = n;
            } else if (self.check_tok(dot) && self.peek_at_type(1) == obrace) {
                // ADT istruc constructor: expr .{ .field = val, ... }
                u64 dot_ln = (u64)self.advance_line_get(); // consume '.'
                self.advance_tok(); // consume '{'
                expr_node* n = alloc_expr_node();
                n.kind = ek_class_init; n.line = dot_ln;
                n.object = lhs;
                n.is_implicit_init = true;
                str_vec field_names; str_vec_init(&field_names);
                expr_ptr_vec field_vals; expr_ptr_vec_init(&field_vals);
                while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                    self.consume_tok(dot, "Expected '.' in field init");
                    lexer.token_t fn2 = self.consume_tok(id, "Expected field name");
                    self.consume_tok(assign, "Expected '=' in field init");
                    expr_node* fv = self.parse_expr();
                    str_vec_push(&field_names, lexer.str_dup(fn2.value));
                    expr_ptr_vec_push(&field_vals, fv);
                    self.match_tok(comma);
                }
                self.consume_tok(cbrace, "Expected '}' after field inits");
                n.field_names = field_names.data;
                n.field_vals  = field_vals.data;
                n.field_count = field_names.len;
                lhs = n;
            } else {
                running = false;
            }
        }
        return lhs;
    }

    expr_node* parse_primary(parser_t* self) {
        lexer.token_t tok = self.peek_tok();
        i32 tt  = tok.type;
        u64 ln  = (u64)tok.line;

        if (tt == int_lit) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind    = ek_int_lit;
            n.line    = ln;
            n.int_val = strtoll(tok.value, (i8**)0, 0);
            n.str_val = lexer.str_dup(tok.value);
            return n;
        }
        if (tt == float_lit) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind    = ek_float_lit;
            n.line    = ln;
            n.flt_val = strtod(tok.value, (i8**)0);
            n.str_val = lexer.str_dup(tok.value);
            return n;
        }
        if (tt == string_lit) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind    = ek_string_lit;
            n.line    = ln;
            n.str_val = lexer.str_dup(tok.value);
            return n;
        }
        if (tt == char_lit) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind    = ek_char_lit;
            n.line    = ln;
            n.str_val = lexer.str_dup(tok.value);
            if (tok.value != (i8*)0 && tok.value[0] != 0) {
                n.int_val = (i64)tok.value[0];
            }
            return n;
        }
        if (tt == kw_true) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind     = ek_bool_lit; n.line = ln; n.bool_val = true;
            return n;
        }
        if (tt == kw_false) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind     = ek_bool_lit; n.line = ln; n.bool_val = false;
            return n;
        }
        if (tt == kw_null) {
            self.advance_tok();
            expr_node* n = alloc_expr_node();
            n.kind = ek_null_lit; n.line = ln;
            return n;
        }

        if (tt == at) {
            self.advance_tok();
            if (self.check_tok(id)) {
                lexer.token_t annot = self.advance_tok();
                expr_node* n = alloc_expr_node();
                n.kind    = ek_annotation;
                n.line    = ln;
                n.str_val = lexer.str_dup(annot.value);
                return n;
            }
            expr_node* n = alloc_expr_node();
            n.kind = ek_annotation; n.line = ln; n.str_val = lexer.str_dup("");
            return n;
        }

        if (tt == id) {
            self.advance_tok();
            i8* name = lexer.str_dup(tok.value);

            // Generic call: func<Type>(args) — parse and save type args
            i8** gen_ta_ptrs = (i8**)0;
            i32 gen_ta_len   = 0;
            if (self.check_tok(lt)) {
                i32 saved_g = self.current;
                self.advance_tok(); // consume '<'
                i32 gen_ta_cap = 4;
                gen_ta_ptrs = (i8**)malloc(sizeof(i8*) * (u64)gen_ta_cap);
                i32 depth_gc = 1;
                while (depth_gc > 0 && !self.is_at_end_p()) {
                    i32 tgc = self.peek_type();
                    if (tgc == gt && depth_gc == 1) {
                        depth_gc = 0; self.advance_tok();
                    } else if (tgc == lt) { depth_gc = depth_gc + 1; self.advance_tok(); }
                    else if (tgc == gt)   { depth_gc = depth_gc - 1; self.advance_tok(); }
                    else if (tgc == right && depth_gc <= 2) { depth_gc = 0; self.advance_tok(); }
                    else if (tgc == comma) { self.advance_tok(); }
                    else if (tgc == question) { depth_gc = 0; } // ternary — not generic args
                    else if (tgc == cparen || tgc == cbrace || tgc == sm) { depth_gc = 0; } // not inside generic args
                    else if (self.is_type_start()) {
                        type_node* gta = self.parse_type();
                        if (gen_ta_len >= gen_ta_cap) {
                            gen_ta_cap = gen_ta_cap * 2;
                            gen_ta_ptrs = (i8**)realloc((i8*)gen_ta_ptrs, sizeof(i8*) * (u64)gen_ta_cap);
                        }
                        gen_ta_ptrs[gen_ta_len] = (i8*)gta;
                        gen_ta_len = gen_ta_len + 1;
                    } else { self.advance_tok(); }
                }
                // Only treat as generic if followed by '('
                if (!self.check_tok(oparen)) {
                    self.current = saved_g;
                    free((i8*)gen_ta_ptrs);
                    gen_ta_ptrs = (i8**)0;
                    gen_ta_len  = 0;
                }
            }

            // Macro expansion: check if name is a const_resolve macro
            if (self.check_tok(oparen)) {
                macro_def_t* mdef = self.find_macro(name);
                if (mdef != (macro_def_t*)0) {
                    return self.expand_macro_call(mdef);
                }
            }

            // Function call or identifier
            if (self.match_tok(oparen)) {
                expr_node* callee = alloc_expr_node();
                callee.kind    = ek_identifier;
                callee.line    = ln;
                callee.str_val = name;

                expr_node* call_n = alloc_expr_node();
                call_n.kind   = ek_call;
                call_n.line   = ln;
                call_n.callee = callee;

                expr_ptr_vec args;
                expr_ptr_vec_init(&args);
                if (!self.check_tok(cparen)) {
                    bool parsing_a = true;
                    while (parsing_a) {
                        expr_ptr_vec_push(&args, self.parse_expr());
                        if (!self.match_tok(comma)) { parsing_a = false; }
                    }
                }
                self.consume_tok(cparen, "Expected ')' after arguments");
                call_n.args          = args.data;
                call_n.args_len      = args.len;
                call_n.type_args     = (type_node**)gen_ta_ptrs;
                call_n.type_args_len = gen_ta_len;
                return call_n;
            }

            // Struct/class init: Name { .field = val, ... }
            if (self.check_tok(obrace)) {
                // Quick check: look ahead to see if first token is '.'
                if (self.peek_at_type(1) == dot) {
                    self.advance_tok();  // consume {
                    expr_node* n = alloc_expr_node();
                    n.kind = ek_class_init;
                    n.line = ln;
                    type_node* it = alloc_type_node();
                    it.name = name;
                    n.init_type = it;

                    str_vec field_names;
                    str_vec_init(&field_names);
                    expr_ptr_vec field_vals;
                    expr_ptr_vec_init(&field_vals);

                    while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                        self.consume_tok(dot, "Expected '.' in field init");
                        lexer.token_t fn = self.consume_tok(id, "Expected field name");
                        self.consume_tok(assign, "Expected '=' in field init");
                        expr_node* fv = self.parse_expr();
                        str_vec_push(&field_names, lexer.str_dup(fn.value));
                        expr_ptr_vec_push(&field_vals, fv);
                        self.match_tok(comma);
                    }
                    self.consume_tok(cbrace, "Expected '}' after field inits");
                    n.field_names  = field_names.data;
                    n.field_vals   = field_vals.data;
                    n.field_count  = field_names.len;
                    return n;
                }
            }

            expr_node* n = alloc_expr_node();
            n.kind    = ek_identifier;
            n.line    = ln;
            n.str_val = name;
            return n;
        }

        if (tt == oparen) {
            self.advance_tok();
            expr_node* e = self.parse_expr();
            self.consume_tok(cparen, "Expected ')'");
            return e;
        }

        if (tt == dot && self.peek_at_type(1) == obrace) {
            // Implicit init: .{ .field = val }
            self.advance_tok();  // consume .
            self.advance_tok();  // consume {
            expr_node* n = alloc_expr_node();
            n.kind = ek_class_init;
            n.line = ln;
            n.is_implicit_init = true;

            str_vec field_names;
            str_vec_init(&field_names);
            expr_ptr_vec field_vals;
            expr_ptr_vec_init(&field_vals);

            while (!self.check_tok(cbrace) && !self.is_at_end_p()) {
                self.consume_tok(dot, "Expected '.' in field init");
                lexer.token_t fn = self.consume_tok(id, "Expected field name");
                self.consume_tok(assign, "Expected '=' in field init");
                expr_node* fv = self.parse_expr();
                str_vec_push(&field_names, lexer.str_dup(fn.value));
                expr_ptr_vec_push(&field_vals, fv);
                self.match_tok(comma);
            }
            self.consume_tok(cbrace, "Expected '}' after field inits");
            n.field_names = field_names.data;
            n.field_vals  = field_vals.data;
            n.field_count = field_names.len;
            return n;
        }

        // Error: unexpected token in expression
        printf("Parse Error at line %d: Unexpected token type %d in expression\n",
                (i32)ln, tt);
        self.had_parse_error = true;
        self.advance_tok();
        expr_node* n = alloc_expr_node();
        n.kind = ek_int_lit; n.line = ln; n.int_val = 0;
        return n;
    }

    // ---- Main parse entry point ----

    program_node* parse(parser_t* self) {
        program_node* prog = (program_node*)malloc(sizeof(parser__NS_program_node));
        memset((i8*)prog, 0, sizeof(parser__NS_program_node));
        prog.kind = nd_program;
        prog.decls_cap = 64;
        prog.decls = (ast_node**)malloc(sizeof(i8*) * (u64)prog.decls_cap);

        while (!self.is_at_end_p()) {
            ast_node* decl = self.parse_top_level();
            if (decl != (ast_node*)0) {
                if (prog.decls_len >= prog.decls_cap) {
                    prog.decls_cap = prog.decls_cap * 2;
                    prog.decls = (ast_node**)realloc((i8*)prog.decls, sizeof(i8*) * (u64)prog.decls_cap);
                }
                prog.decls[prog.decls_len] = decl;
                prog.decls_len = prog.decls_len + 1;
            }
        }
        return prog;
    }
}

} // namespace parser
// Diagnostics module for the Artemis self-hosting compiler.

namespace diagnostics {

// Diagnostic level constants
enum diag_level_t {
    DIAG_NOTE    = 0,
    DIAG_WARNING = 1,
    DIAG_ERROR   = 2,
}

struct diagnostic_t {
    i32  level;
    i8*  filename;
    i32  line;
    i32  col;
    i8*  message;
}

// Dynamic array of diagnostics
struct diag_vec {
    diagnostic_t* data;
    i32           len;
    i32           cap;
}

void diag_vec_push(diag_vec* v, diagnostic_t d) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 16 : v.cap * 2;
        v.data = (diagnostic_t*)realloc((i8*)v.data, sizeof(diagnostics__NS_diagnostic_t) * (u64)nc);
        v.cap = nc;
    }
    v.data[v.len] = d;
    v.len = v.len + 1;
}

// ---- Diagnostic engine ----

istruc diag_engine {
    i8*       filename;
    diag_vec  diags;
    i32       err_count;
    i32       max_errors;

    void init(diag_engine* self, i8* fname) {
        self.filename   = fname;
        self.err_count  = 0;
        self.max_errors = 20;
        self.diags.data = (diagnostic_t*)0;
        self.diags.len  = 0;
        self.diags.cap  = 0;
    }

    void emit_error(diag_engine* self, i32 line, i32 col, i8* msg) {
        if (self.err_count >= self.max_errors) { return; }
        diagnostic_t d;
        d.level    = DIAG_ERROR;
        d.filename = self.filename;
        d.line     = line;
        d.col      = col;
        d.message  = msg;
        diag_vec_push(&self.diags, d);
        self.err_count = self.err_count + 1;
    }

    void emit_warning(diag_engine* self, i32 line, i32 col, i8* msg) {
        diagnostic_t d;
        d.level    = DIAG_WARNING;
        d.filename = self.filename;
        d.line     = line;
        d.col      = col;
        d.message  = msg;
        diag_vec_push(&self.diags, d);
    }

    void absorb(diag_engine* self, i8* msg) {
        self.emit_error(0, 0, msg);
    }

    bool has_errors(diag_engine* self) {
        return self.err_count > 0;
    }

    void flush(diag_engine* self) {
        for (i32 i = 0; i < self.diags.len; i = i + 1) {
            diagnostic_t d = self.diags.data[i];
            i8* lvl = "note";
            if (d.level == DIAG_ERROR)   { lvl = "error"; }
            if (d.level == DIAG_WARNING) { lvl = "warning"; }
            printf("%s:%d:%d: %s: %s\n",
                    d.filename, d.line, d.col, lvl, d.message);
        }
        if (self.err_count >= self.max_errors) {
            printf("%s: fatal: too many errors (%d), stopping.\n",
                    self.filename, self.err_count);
        }
    }

    bool finish(diag_engine* self) {
        self.flush();
        return self.has_errors();
    }
}

} // namespace diagnostics
// Scope management for the Artemis self-hosting compiler analyzer.
// Uses linear-search symbol tables (no hash maps needed for bootstrap).

namespace analysis {

// ---- Symbol kinds ----
enum sym_kind {
    sym_var    = 0,
    sym_func   = 1,
    sym_type   = 2,
    sym_enum   = 3,
}

struct sym_entry {
    i8*  name;
    i32  kind;   // sym_kind
    i8*  type_ptr;   // parser::type_node* as i8*
    i32  scope_depth;
}

struct sym_table {
    sym_entry* entries;
    i32        len;
    i32        cap;
}

void sym_table_init(sym_table* t) {
    t.entries = (sym_entry*)0;
    t.len     = 0;
    t.cap     = 0;
}

void sym_table_push(sym_table* t, sym_entry e) {
    if (t.len >= t.cap) {
        i32 nc = t.cap == 0 ? 32 : t.cap * 2;
        t.entries = (sym_entry*)realloc((i8*)t.entries, sizeof(analysis__NS_sym_entry) * (u64)nc);
        t.cap = nc;
    }
    t.entries[t.len] = e;
    t.len = t.len + 1;
}

// ---- Struct registry ----
struct struct_entry {
    i8*  name;
    i8*  decl_ptr;   // parser::struct_decl* as i8*
}

struct struct_table {
    struct_entry* entries;
    i32           len;
    i32           cap;
}

void struct_table_init(struct_table* t) {
    t.entries = (struct_entry*)0;
    t.len     = 0;
    t.cap     = 0;
}

void struct_table_push(struct_table* t, struct_entry e) {
    if (t.len >= t.cap) {
        i32 nc = t.cap == 0 ? 16 : t.cap * 2;
        t.entries = (struct_entry*)realloc((i8*)t.entries, sizeof(analysis__NS_struct_entry) * (u64)nc);
        t.cap = nc;
    }
    t.entries[t.len] = e;
    t.len = t.len + 1;
}

// ---- Scope manager ----

istruc scope_manager {
    sym_table    syms;
    struct_table structs;
    i32          depth;

    void init(scope_manager* self) {
        sym_table_init(&self.syms);
        struct_table_init(&self.structs);
        self.depth = 0;
    }

    void push_scope(scope_manager* self) {
        self.depth = self.depth + 1;
    }

    void pop_scope(scope_manager* self) {
        // Remove all entries at the current depth
        i32 new_len = 0;
        i32 i = 0;
        while (i < self.syms.len) {
            if (self.syms.entries[i].scope_depth < self.depth) {
                self.syms.entries[new_len] = self.syms.entries[i];
                new_len = new_len + 1;
            }
            i = i + 1;
        }
        self.syms.len = new_len;
        self.depth = self.depth - 1;
    }

    void declare(scope_manager* self, i8* name, i32 kind, i8* type_ptr) {
        sym_entry e;
        e.name        = name;
        e.kind        = kind;
        e.type_ptr    = type_ptr;
        e.scope_depth = self.depth;
        sym_table_push(&self.syms, e);
    }

    void declare_struct(scope_manager* self, i8* name, i8* decl_ptr) {
        struct_entry e;
        e.name     = name;
        e.decl_ptr = decl_ptr;
        struct_table_push(&self.structs, e);
    }

    // Lookup: search from innermost scope outward
    i8* lookup(scope_manager* self, i8* name) {
        i32 i = self.syms.len - 1;
        while (i >= 0) {
            if (strcmp(self.syms.entries[i].name, name) == 0) {
                return self.syms.entries[i].type_ptr;
            }
            i = i - 1;
        }
        return (i8*)0;
    }

    i8* lookup_struct(scope_manager* self, i8* name) {
        i32 i = self.structs.len - 1;
        while (i >= 0) {
            if (strcmp(self.structs.entries[i].name, name) == 0) {
                return self.structs.entries[i].decl_ptr;
            }
            i = i - 1;
        }
        return (i8*)0;
    }
}

} // namespace analysis
// Type utilities for the Artemis self-hosting compiler analyzer.

namespace analysis {

// Convert a prim_type_t value to a display string.
i8* prim_to_str(i32 prim, u32 bit_width) {
    if (prim == char_t)    { return "i8"; }
    if (prim == void_t)    { return "void"; }
    if (prim == arb_bool)  { return "bool"; }
    if (prim == arb_float) {
        if (bit_width == 32) { return "f32"; }
        if (bit_width == 64) { return "f64"; }
        return "f64";
    }
    if (prim == arb_uint) {
        if (bit_width == 8)  { return "u8"; }
        if (bit_width == 16) { return "u16"; }
        if (bit_width == 32) { return "u32"; }
        if (bit_width == 64) { return "u64"; }
        return "uN";
    }
    // arb_int
    if (bit_width == 8)  { return "i8"; }
    if (bit_width == 16) { return "i16"; }
    if (bit_width == 32) { return "i32"; }
    if (bit_width == 64) { return "i64"; }
    return "iN";
}

// Convert a type_node to a display string (heap-allocated).
i8* type_to_str(parser.type_node* t) {
    if (t == (parser.type_node*)0) { return "void"; }
    i8 buf[256];
    if (t.is_primitive && t.has_prim) {
        i8* base = prim_to_str(t.prim, (u32)t.bit_width);
        i32 depth = t.pointer_depth;
        if (depth == 0) {
            return lexer.str_dup(base);
        }
        snprintf(buf, (u64)256, "%s", base);
        i32 i = 0;
        while (i < depth) {
            i8 tmp[256];
            snprintf(tmp, (u64)256, "%s*", buf);
            snprintf(buf, (u64)256, "%s", tmp);
            i = i + 1;
        }
        return lexer.str_dup(buf);
    }
    if (t.name != (i8*)0) {
        snprintf(buf, (u64)256, "%s", t.name);
        i32 i = 0;
        while (i < t.pointer_depth) {
            i8 tmp[256];
            snprintf(tmp, (u64)256, "%s*", buf);
            snprintf(buf, (u64)256, "%s", tmp);
            i = i + 1;
        }
        return lexer.str_dup(buf);
    }
    return "unknown";
}

// Return true if a prim type is an integer (not float, not void).
bool is_int_prim(i32 prim) {
    if (prim == char_t)   { return true; }
    if (prim == arb_int)  { return true; }
    if (prim == arb_uint) { return true; }
    if (prim == arb_bool) { return true; }
    return false;
}

// Return true if a prim type is floating point.
bool is_float_prim(i32 prim) {
    return prim == arb_float;
}

// Return true if a type_node is a pointer (pointer_depth > 0).
bool is_pointer_type(parser.type_node* t) {
    if (t == (parser.type_node*)0) { return false; }
    return t.pointer_depth > 0;
}

// Return true if a type_node is unsigned.
bool is_unsigned_type(parser.type_node* t) {
    if (t == (parser.type_node*)0) { return false; }
    if (!t.is_primitive) { return false; }
    if (t.pointer_depth > 0) { return false; }
    return t.prim == arb_uint || t.prim == arb_bool;
}

// Return true if two type_nodes are equal (shallow).
bool types_equal(parser.type_node* a, parser.type_node* b) {
    if (a == (parser.type_node*)0 && b == (parser.type_node*)0) { return true; }
    if (a == (parser.type_node*)0 || b == (parser.type_node*)0) { return false; }
    if (a.is_primitive != b.is_primitive) { return false; }
    if (a.pointer_depth != b.pointer_depth) { return false; }
    if (a.is_primitive) {
        if (a.prim != b.prim) { return false; }
        if (a.bit_width != b.bit_width) { return false; }
        return true;
    }
    if (a.name != (i8*)0 && b.name != (i8*)0) {
        return strcmp(a.name, b.name) == 0;
    }
    return false;
}

} // namespace analysis
// Analysis pass for the Artemis self-hosting compiler.
// This is a lightweight stub — the bootstrap compiler skips full type-checking
// and relies on the existing C++ compiler's semantics for correctness.

namespace analysis {

// Stub: walk the program and register top-level names.
// Full type inference and error checking is deferred to future phases.
void analyze(parser.program_node* prog) {
    // No-op for bootstrap: the C++ compiler already validates the source.
    // In the self-hosted version, this will perform full semantic analysis.
    if (prog == (parser.program_node*)0) { return; }
}

} // namespace analysis
// IR context for the Artemis self-hosting compiler.
// Uses linear-search tables instead of hash maps for simplicity.

namespace ir {

// ---- String -> Value linear map ----
struct sv_entry {
    i8*  key;
    i8*  val;   // LLVMValueRef as i8*
}

struct sv_map {
    sv_entry* data;
    i32       len;
    i32       cap;
}

void sv_map_init(sv_map* m) {
    m.data = (sv_entry*)0;
    m.len  = 0;
    m.cap  = 0;
}

void sv_map_set(sv_map* m, i8* key, i8* val) {
    // Update existing key
    i32 i = 0;
    while (i < m.len) {
        if (strcmp(m.data[i].key, key) == 0) {
            m.data[i].val = val;
            return;
        }
        i = i + 1;
    }
    // Insert new
    if (m.len >= m.cap) {
        i32 nc = m.cap == 0 ? 32 : m.cap * 2;
        m.data = (sv_entry*)realloc((i8*)m.data, sizeof(ir__NS_sv_entry) * (u64)nc);
        m.cap  = nc;
    }
    m.data[m.len].key = key;
    m.data[m.len].val = val;
    m.len = m.len + 1;
}

i8* sv_map_get(sv_map* m, i8* key) {
    i32 i = m.len - 1;
    while (i >= 0) {
        if (strcmp(m.data[i].key, key) == 0) {
            return m.data[i].val;
        }
        i = i - 1;
    }
    return (i8*)0;
}

bool sv_map_has(sv_map* m, i8* key) {
    return sv_map_get(m, key) != (i8*)0;
}

// ---- String -> Type linear map ----
struct st_entry {
    i8* key;
    i8* type;  // LLVMTypeRef as i8*
}

struct st_map {
    st_entry* data;
    i32       len;
    i32       cap;
}

void st_map_init(st_map* m) {
    m.data = (st_entry*)0;
    m.len  = 0;
    m.cap  = 0;
}

void st_map_set(st_map* m, i8* key, i8* type) {
    i32 i = 0;
    while (i < m.len) {
        if (strcmp(m.data[i].key, key) == 0) {
            m.data[i].type = type;
            return;
        }
        i = i + 1;
    }
    if (m.len >= m.cap) {
        i32 nc = m.cap == 0 ? 32 : m.cap * 2;
        m.data = (st_entry*)realloc((i8*)m.data, sizeof(ir__NS_st_entry) * (u64)nc);
        m.cap  = nc;
    }
    m.data[m.len].key  = key;
    m.data[m.len].type = type;
    m.len = m.len + 1;
}

i8* st_map_get(st_map* m, i8* key) {
    i32 i = m.len - 1;
    while (i >= 0) {
        if (strcmp(m.data[i].key, key) == 0) {
            return m.data[i].type;
        }
        i = i - 1;
    }
    return (i8*)0;
}

bool st_map_has(st_map* m, i8* key) {
    return st_map_get(m, key) != (i8*)0;
}

// ---- String -> bool map ----
struct sb_entry {
    i8*  key;
    bool val;
}

struct sb_map {
    sb_entry* data;
    i32       len;
    i32       cap;
}

void sb_map_init(sb_map* m) {
    m.data = (sb_entry*)0;
    m.len  = 0;
    m.cap  = 0;
}

void sb_map_set(sb_map* m, i8* key, bool val) {
    i32 i = 0;
    while (i < m.len) {
        if (strcmp(m.data[i].key, key) == 0) {
            m.data[i].val = val;
            return;
        }
        i = i + 1;
    }
    if (m.len >= m.cap) {
        i32 nc = m.cap == 0 ? 16 : m.cap * 2;
        m.data = (sb_entry*)realloc((i8*)m.data, sizeof(ir__NS_sb_entry) * (u64)nc);
        m.cap  = nc;
    }
    m.data[m.len].key = key;
    m.data[m.len].val = val;
    m.len = m.len + 1;
}

bool sb_map_get(sb_map* m, i8* key) {
    i32 i = m.len - 1;
    while (i >= 0) {
        if (strcmp(m.data[i].key, key) == 0) {
            return m.data[i].val;
        }
        i = i - 1;
    }
    return false;
}

// ---- String names (parallel arrays for struct fields) ----
struct name_list {
    i8** data;
    i32  len;
    i32  cap;
}

void name_list_init(name_list* v) {
    v.data = (i8**)0;
    v.len  = 0;
    v.cap  = 0;
}

void name_list_push(name_list* v, i8* s) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 8 : v.cap * 2;
        v.data = (i8**)realloc((i8*)v.data, sizeof(i8*) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = s;
    v.len = v.len + 1;
}

// ---- Type lists for struct fields ----
struct type_list {
    i8** data;   // LLVMTypeRef*
    i32  len;
    i32  cap;
}

void type_list_init(type_list* v) {
    v.data = (i8**)0;
    v.len  = 0;
    v.cap  = 0;
}

void type_list_push(type_list* v, i8* t) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 8 : v.cap * 2;
        v.data = (i8**)realloc((i8*)v.data, sizeof(i8*) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = t;
    v.len = v.len + 1;
}

// ---- Bool lists for unsigned tracking ----
struct bool_list {
    bool* data;
    i32   len;
    i32   cap;
}

void bool_list_init(bool_list* v) {
    v.data = (bool*)0;
    v.len  = 0;
    v.cap  = 0;
}

void bool_list_push(bool_list* v, bool b) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 8 : v.cap * 2;
        v.data = (bool*)realloc((i8*)v.data, sizeof(bool) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = b;
    v.len = v.len + 1;
}

// ---- Struct field metadata (parallel arrays per struct) ----
struct struct_meta {
    i8*        name;        // struct name
    name_list  field_names;
    type_list  field_types;   // LLVMTypeRef*
    bool_list  field_unsigned;
    type_list  field_pointee; // pointee types for pointer fields (null for non-pointers)
    bool       is_union;    // true if declared as 'union' rather than 'struct'
}

struct struct_meta_vec {
    struct_meta* data;
    i32          len;
    i32          cap;
}

void struct_meta_vec_init(struct_meta_vec* v) {
    v.data = (struct_meta*)0;
    v.len  = 0;
    v.cap  = 0;
}

void struct_meta_vec_push(struct_meta_vec* v, struct_meta m) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 16 : v.cap * 2;
        v.data = (struct_meta*)realloc((i8*)v.data, sizeof(ir__NS_struct_meta) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = m;
    v.len = v.len + 1;
}

struct_meta* struct_meta_find(struct_meta_vec* v, i8* name) {
    i32 i = 0;
    while (i < v.len) {
        if (strcmp(v.data[i].name, name) == 0) {
            return &v.data[i];
        }
        i = i + 1;
    }
    return (struct_meta*)0;
}

bool ctx_is_union(ir_context* ctx, i8* struct_name) {
    struct_meta* sm = struct_meta_find(&ctx.struct_meta_tbl, struct_name);
    if (sm == (struct_meta*)0) { return false; }
    return sm.is_union;
}

// ---- typedef alias entry ----
struct typedef_entry {
    i8*  name;
    i8*  type_node_ptr;   // parser::type_node* as i8*
}

struct typedef_map {
    typedef_entry* data;
    i32            len;
    i32            cap;
}

void typedef_map_init(typedef_map* m) {
    m.data = (typedef_entry*)0;
    m.len  = 0;
    m.cap  = 0;
}

void typedef_map_set(typedef_map* m, i8* name, i8* tn_ptr) {
    i32 i = 0;
    while (i < m.len) {
        if (strcmp(m.data[i].name, name) == 0) {
            m.data[i].type_node_ptr = tn_ptr;
            return;
        }
        i = i + 1;
    }
    if (m.len >= m.cap) {
        i32 nc = m.cap == 0 ? 16 : m.cap * 2;
        m.data = (typedef_entry*)realloc((i8*)m.data, sizeof(ir__NS_typedef_entry) * (u64)nc);
        m.cap  = nc;
    }
    m.data[m.len].name         = name;
    m.data[m.len].type_node_ptr = tn_ptr;
    m.len = m.len + 1;
}

i8* typedef_map_get(typedef_map* m, i8* name) {
    i32 i = 0;
    while (i < m.len) {
        if (strcmp(m.data[i].name, name) == 0) {
            return m.data[i].type_node_ptr;
        }
        i = i + 1;
    }
    return (i8*)0;
}

// ---- IR scope frame ----
struct ir_scope_frame {
    sv_map alloca_ptrs;     // name -> LLVMValueRef (alloca)
    st_map alloca_types;    // name -> LLVMTypeRef (element type)
    st_map deref_types;     // name -> LLVMTypeRef (pointed-to type)
    sb_map alloca_unsigned; // name -> bool
    st_map local_func_types;// name -> LLVMTypeRef (function type for func-ptr locals)
}

struct scope_frame_vec {
    ir_scope_frame* data;
    i32             len;
    i32             cap;
}

void scope_frame_vec_init(scope_frame_vec* v) {
    v.data = (ir_scope_frame*)0;
    v.len  = 0;
    v.cap  = 0;
}

void scope_frame_vec_push(scope_frame_vec* v, ir_scope_frame f) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 8 : v.cap * 2;
        v.data = (ir_scope_frame*)realloc((i8*)v.data, sizeof(ir__NS_ir_scope_frame) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = f;
    v.len = v.len + 1;
}

// ---- Loop control-flow info ----
struct ir_loop_info {
    i8* break_block;    // LLVMBasicBlockRef
    i8* continue_block; // LLVMBasicBlockRef
}

struct loop_stack {
    ir_loop_info* data;
    i32           len;
    i32           cap;
}

void loop_stack_init(loop_stack* v) {
    v.data = (ir_loop_info*)0;
    v.len  = 0;
    v.cap  = 0;
}

void loop_stack_push(loop_stack* v, ir_loop_info info) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 8 : v.cap * 2;
        v.data = (ir_loop_info*)realloc((i8*)v.data, sizeof(ir__NS_ir_loop_info) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = info;
    v.len = v.len + 1;
}

// ---- Defer item ----
struct defer_item {
    i8*  ptr;      // expr_node* or block_stmt*
    bool is_block; // true = block_stmt, false = expr_node
}

struct defer_scope {
    defer_item* data;
    i32         len;
    i32         cap;
}

void defer_scope_init(defer_scope* v) {
    v.data = (defer_item*)0;
    v.len  = 0;
    v.cap  = 0;
}

void defer_scope_push(defer_scope* v, defer_item d) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 8 : v.cap * 2;
        v.data = (defer_item*)realloc((i8*)v.data, sizeof(ir__NS_defer_item) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = d;
    v.len = v.len + 1;
}

struct defer_stack {
    defer_scope* data;
    i32          len;
    i32          cap;
}

void defer_stack_init(defer_stack* v) {
    v.data = (defer_scope*)0;
    v.len  = 0;
    v.cap  = 0;
}

void defer_stack_push_scope(defer_stack* v) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 8 : v.cap * 2;
        v.data = (defer_scope*)realloc((i8*)v.data, sizeof(ir__NS_defer_scope) * (u64)nc);
        v.cap  = nc;
    }
    defer_scope_init(&v.data[v.len]);
    v.len = v.len + 1;
}

// ---- IR context ----

struct ir_context {
    i8* llvm_ctx;      // LLVMContextRef
    i8* llvm_mod;      // LLVMModuleRef
    i8* llvm_builder;  // LLVMBuilderRef

    i8* current_func;      // LLVMValueRef
    i8* current_func_type; // LLVMTypeRef
    i8* current_ret_type;  // LLVMTypeRef
    bool current_func_is_error_union;
    i8*  current_error_union_type;  // LLVMTypeRef

    scope_frame_vec scopes;
    loop_stack      loops;

    // Global function/variable tables
    sv_map global_funcs;
    st_map global_func_types;
    sb_map global_func_ret_unsigned;
    sv_map global_vars;
    sb_map global_var_unsigned;

    // Struct type registry: name -> LLVMTypeRef
    st_map struct_types;

    // Struct field metadata
    struct_meta_vec struct_meta_tbl;

    // Set of union names (stored as name -> true in a sb_map)
    sb_map union_names;

    // Non-struct typedef aliases
    typedef_map typedef_aliases;

    // Current class and namespace context
    i8* current_class_name;
    i8* current_namespace;

    // Defer stacks
    defer_stack defers;
    defer_stack errdefers;

    // constexpr integer values: name -> i64
    sv_map constexpr_int_vals_map;

    // Error union type (memstr fat type, etc.)
    i8* memstr_fat_type;

    // Generic function support
    sv_map generic_funcs;       // name -> func_decl* (i8*)
    st_map type_param_bindings; // type param name -> LLVMTypeRef

    // ADT enum support: enum name -> enum_decl* (i8*)
    sv_map adt_enum_decls;
}

// Allocate and initialize an ir_context.
ir_context* make_ir_context(i8* module_name) {
    ir_context* ctx = (ir_context*)malloc(sizeof(ir__NS_ir_context));
    memset((i8*)ctx, 0, sizeof(ir__NS_ir_context));

    ctx.llvm_ctx     = LLVMContextCreate();
    ctx.llvm_mod     = LLVMModuleCreateWithNameInContext(module_name, ctx.llvm_ctx);
    ctx.llvm_builder = LLVMCreateBuilderInContext(ctx.llvm_ctx);

    sv_map_init(&ctx.global_funcs);
    st_map_init(&ctx.global_func_types);
    sb_map_init(&ctx.global_func_ret_unsigned);
    sv_map_init(&ctx.global_vars);
    sb_map_init(&ctx.global_var_unsigned);
    st_map_init(&ctx.struct_types);
    struct_meta_vec_init(&ctx.struct_meta_tbl);
    sb_map_init(&ctx.union_names);
    typedef_map_init(&ctx.typedef_aliases);
    scope_frame_vec_init(&ctx.scopes);
    loop_stack_init(&ctx.loops);
    defer_stack_init(&ctx.defers);
    defer_stack_init(&ctx.errdefers);
    sv_map_init(&ctx.constexpr_int_vals_map);
    sv_map_init(&ctx.generic_funcs);
    st_map_init(&ctx.type_param_bindings);
    sv_map_init(&ctx.adt_enum_decls);

    ctx.current_class_name = (i8*)0;
    ctx.current_namespace  = (i8*)0;
    ctx.memstr_fat_type    = (i8*)0;

    return ctx;
}

void destroy_ir_context(ir_context* ctx) {
    if (ctx == (ir_context*)0) { return; }
    if (ctx.llvm_builder != (i8*)0) { LLVMDisposeBuilder(ctx.llvm_builder); }
    if (ctx.llvm_mod     != (i8*)0) { LLVMDisposeModule(ctx.llvm_mod); }
    if (ctx.llvm_ctx     != (i8*)0) { LLVMContextDispose(ctx.llvm_ctx); }
    free((i8*)ctx);
}

// ---- Scope helpers ----

void ctx_push_scope(ir_context* ctx) {
    ir_scope_frame f;
    sv_map_init(&f.alloca_ptrs);
    st_map_init(&f.alloca_types);
    st_map_init(&f.deref_types);
    sb_map_init(&f.alloca_unsigned);
    st_map_init(&f.local_func_types);
    scope_frame_vec_push(&ctx.scopes, f);
}

void ctx_pop_scope(ir_context* ctx) {
    if (ctx.scopes.len > 0) {
        ctx.scopes.len = ctx.scopes.len - 1;
    }
}

void ctx_declare_local(ir_context* ctx, i8* name, i8* alloca_ptr,
                       i8* elem_type, i8* deref_type, bool is_unsigned) {
    if (ctx.scopes.len == 0) { ctx_push_scope(ctx); }
    i32 idx = ctx.scopes.len - 1;
    sv_map_set(&ctx.scopes.data[idx].alloca_ptrs,     name, alloca_ptr);
    st_map_set(&ctx.scopes.data[idx].alloca_types,    name, elem_type);
    if (deref_type != (i8*)0) {
        st_map_set(&ctx.scopes.data[idx].deref_types, name, deref_type);
    }
    if (is_unsigned) {
        sb_map_set(&ctx.scopes.data[idx].alloca_unsigned, name, true);
    }
}

i8* ctx_lookup_local(ir_context* ctx, i8* name) {
    i32 i = ctx.scopes.len - 1;
    while (i >= 0) {
        i8* v = sv_map_get(&ctx.scopes.data[i].alloca_ptrs, name);
        if (v != (i8*)0) { return v; }
        i = i - 1;
    }
    return (i8*)0;
}

i8* ctx_lookup_local_type(ir_context* ctx, i8* name) {
    i32 i = ctx.scopes.len - 1;
    while (i >= 0) {
        i8* v = st_map_get(&ctx.scopes.data[i].alloca_types, name);
        if (v != (i8*)0) { return v; }
        i = i - 1;
    }
    return (i8*)0;
}

i8* ctx_lookup_deref_type(ir_context* ctx, i8* name) {
    i32 i = ctx.scopes.len - 1;
    while (i >= 0) {
        i8* v = st_map_get(&ctx.scopes.data[i].deref_types, name);
        if (v != (i8*)0) { return v; }
        i = i - 1;
    }
    return (i8*)0;
}

void ctx_declare_local_func_type(ir_context* ctx, i8* name, i8* fn_type) {
    if (ctx.scopes.len == 0) { ctx_push_scope(ctx); }
    i32 idx = ctx.scopes.len - 1;
    st_map_set(&ctx.scopes.data[idx].local_func_types, name, fn_type);
}

i8* ctx_lookup_local_func_type(ir_context* ctx, i8* name) {
    i32 i = ctx.scopes.len - 1;
    while (i >= 0) {
        i8* v = st_map_get(&ctx.scopes.data[i].local_func_types, name);
        if (v != (i8*)0) { return v; }
        i = i - 1;
    }
    return (i8*)0;
}

bool ctx_lookup_local_unsigned(ir_context* ctx, i8* name) {
    i32 i = ctx.scopes.len - 1;
    while (i >= 0) {
        bool v = sb_map_get(&ctx.scopes.data[i].alloca_unsigned, name);
        if (v) { return true; }
        i = i - 1;
    }
    return false;
}

// ---- Loop helpers ----

void ctx_push_loop(ir_context* ctx, i8* break_bb, i8* continue_bb) {
    ir_loop_info info;
    info.break_block    = break_bb;
    info.continue_block = continue_bb;
    loop_stack_push(&ctx.loops, info);
}

void ctx_pop_loop(ir_context* ctx) {
    if (ctx.loops.len > 0) {
        ctx.loops.len = ctx.loops.len - 1;
    }
}

i8* ctx_current_break(ir_context* ctx) {
    if (ctx.loops.len == 0) { return (i8*)0; }
    return ctx.loops.data[ctx.loops.len - 1].break_block;
}

i8* ctx_current_continue(ir_context* ctx) {
    if (ctx.loops.len == 0) { return (i8*)0; }
    return ctx.loops.data[ctx.loops.len - 1].continue_block;
}

// ---- Terminator check ----

bool ctx_is_terminated(ir_context* ctx) {
    i8* bb = LLVMGetInsertBlock(ctx.llvm_builder);
    if (bb == (i8*)0) { return false; }
    return LLVMGetBasicBlockTerminator(bb) != (i8*)0;
}

// ---- Defer helpers ----

void ctx_push_defer_scope(ir_context* ctx) {
    defer_stack_push_scope(&ctx.defers);
}

void ctx_push_errdefer_scope(ir_context* ctx) {
    defer_stack_push_scope(&ctx.errdefers);
}

void ctx_add_defer(ir_context* ctx, i8* ptr, bool is_block) {
    if (ctx.defers.len == 0) { return; }
    defer_item di;
    di.ptr      = ptr;
    di.is_block = is_block;
    defer_scope_push(&ctx.defers.data[ctx.defers.len - 1], di);
}

void ctx_add_errdefer(ir_context* ctx, i8* ptr, bool is_block) {
    if (ctx.errdefers.len == 0) { return; }
    defer_item di;
    di.ptr      = ptr;
    di.is_block = is_block;
    defer_scope_push(&ctx.errdefers.data[ctx.errdefers.len - 1], di);
}

void ctx_pop_errdefer_scope(ir_context* ctx) {
    if (ctx.errdefers.len > 0) {
        ctx.errdefers.len = ctx.errdefers.len - 1;
    }
}

defer_scope ctx_pop_errdefer_scope_get(ir_context* ctx) {
    defer_scope empty;
    defer_scope_init(&empty);
    if (ctx.errdefers.len == 0) { return empty; }
    defer_scope s = ctx.errdefers.data[ctx.errdefers.len - 1];
    ctx.errdefers.len = ctx.errdefers.len - 1;
    return s;
}

// Pop and return the defer scope (caller emits in reverse order).
defer_scope ctx_pop_defer_scope(ir_context* ctx) {
    defer_scope empty;
    defer_scope_init(&empty);
    if (ctx.defers.len == 0) { return empty; }
    defer_scope s = ctx.defers.data[ctx.defers.len - 1];
    ctx.defers.len = ctx.defers.len - 1;
    return s;
}

// ---- Field index lookup ----

i32 ctx_field_index(ir_context* ctx, i8* struct_name, i8* field_name) {
    struct_meta* m = struct_meta_find(&ctx.struct_meta_tbl, struct_name);
    if (m == (struct_meta*)0) { return -1; }
    i32 i = 0;
    while (i < m.field_names.len) {
        if (strcmp(m.field_names.data[i], field_name) == 0) {
            return i;
        }
        i = i + 1;
    }
    return -1;
}

i8* ctx_field_type(ir_context* ctx, i8* struct_name, i32 idx) {
    struct_meta* m = struct_meta_find(&ctx.struct_meta_tbl, struct_name);
    if (m == (struct_meta*)0) { return (i8*)0; }
    if (idx < 0 || idx >= m.field_types.len) { return (i8*)0; }
    return m.field_types.data[idx];
}

bool ctx_field_unsigned(ir_context* ctx, i8* struct_name, i8* field_name) {
    struct_meta* m = struct_meta_find(&ctx.struct_meta_tbl, struct_name);
    if (m == (struct_meta*)0) { return false; }
    i32 i = 0;
    while (i < m.field_names.len) {
        if (strcmp(m.field_names.data[i], field_name) == 0) {
            if (i < m.field_unsigned.len) {
                return m.field_unsigned.data[i];
            }
            return false;
        }
        i = i + 1;
    }
    return false;
}

} // namespace ir
// Type lowering: AST type_node -> LLVMTypeRef for the Artemis self-hosting compiler.

namespace ir {

// Compute byte size of an LLVM type without requiring data layout.
u64 llvm_type_byte_size(i8* ty) {
    if (ty == (i8*)0) { return 8; }
    i32 k = LLVMGetTypeKind(ty);
    if (k == LLVMIntegerTypeKind) {
        u32 bits = LLVMGetIntTypeWidth(ty);
        return (u64)((bits + 7) / 8);
    }
    if (k == LLVMFloatTypeKind)  { return 4; }
    if (k == LLVMDoubleTypeKind) { return 8; }
    if (k == LLVMX86_FP80TypeKind) { return 10; }
    if (k == LLVMPointerTypeKind) { return 8; }
    if (k == LLVMArrayTypeKind) {
        i8* elem_t = LLVMGetElementType(ty);
        u64 elem_sz = llvm_type_byte_size(elem_t);
        u32 cnt = LLVMGetArrayLength(ty);
        return elem_sz * (u64)cnt;
    }
    if (k == LLVMStructTypeKind) {
        // Sum field sizes (conservative: no padding)
        u32 nf = LLVMCountStructElementTypes(ty);
        u64 total = 0;
        u32 fi = 0;
        while (fi < nf) {
            i8* ft = LLVMStructGetTypeAtIndex(ty, fi);
            total = total + llvm_type_byte_size(ft);
            fi = fi + 1;
        }
        return total;
    }
    return 8;
}

// Returns true if the type_node is an unsigned integer primitive.
bool is_unsigned_type_node(parser.type_node* t) {
    if (t == (parser.type_node*)0) { return false; }
    if (!t.is_primitive) { return false; }
    if (t.pointer_depth > 0) { return false; }
    if (!t.has_prim) { return false; }
    return t.prim == arb_uint || t.prim == arb_bool;
}

// Map a floating-point bit-width to the nearest LLVM float type.
i8* llvm_float_for_width(u32 bw, i8* llvm_ctx) {
    if (bw <= 16) { return LLVMHalfTypeInContext(llvm_ctx); }
    if (bw <= 32) { return LLVMFloatTypeInContext(llvm_ctx); }
    if (bw <= 64) { return LLVMDoubleTypeInContext(llvm_ctx); }
    if (bw <= 80) { return LLVMX86FP80TypeInContext(llvm_ctx); }
    return LLVMFP128TypeInContext(llvm_ctx);
}

// Map a primitive type + bit-width to an LLVMTypeRef.
i8* llvm_type_of_prim(i32 prim, u32 bw, i8* llvm_ctx) {
    if (prim == char_t)    { return LLVMInt8TypeInContext(llvm_ctx); }
    if (prim == void_t)    { return LLVMVoidTypeInContext(llvm_ctx); }
    if (prim == arb_float) { return llvm_float_for_width(bw == 0 ? (u32)64 : bw, llvm_ctx); }
    // arb_int, arb_uint, arb_bool: integer type
    u32 width = bw == 0 ? (u32)32 : bw;
    return LLVMIntTypeInContext(llvm_ctx, (i32)width);
}

// Forward declaration (resolve_typedef_alias is defined below).
i8* resolve_typedef_alias(parser.type_node* t, ir_context* ctx);

// Convert a full type_node* (including pointer depth) to an LLVMTypeRef.
i8* llvm_type_of(parser.type_node* t, ir_context* ctx) {
    if (t == (parser.type_node*)0) {
        return LLVMVoidTypeInContext(ctx.llvm_ctx);
    }

    // Function pointer: returntype(params)*
    if (t.is_func_ptr && t.fp_ret != (i8*)0) {
        i8* ret_t = llvm_type_of((parser.type_node*)t.fp_ret, ctx);

        // Build parameter type array
        i32 nparams = t.fp_params_len;
        i8** param_ts = (i8**)0;
        if (nparams > 0) {
            param_ts = (i8**)malloc(sizeof(i8*) * (u64)nparams);
            i32 pi = 0;
            while (pi < nparams) {
                parser.type_node* pt = (parser.type_node*)t.fp_params[pi];
                param_ts[pi] = llvm_type_of(pt, ctx);
                pi = pi + 1;
            }
        }
        i32 variadic = t.fp_variadic ? 1 : 0;
        i8* fn_t = LLVMFunctionType(ret_t, param_ts, nparams, variadic);
        if (param_ts != (i8**)0) { free((i8*)param_ts); }
        return LLVMPointerType(fn_t, 0);
    }

    i8* base = (i8*)0;
    if (t.is_primitive && t.has_prim) {
        base = llvm_type_of_prim(t.prim, (u32)t.bit_width, ctx.llvm_ctx);
    } else {
        i8* name = t.name;
        if (name == (i8*)0) {
            return LLVMVoidTypeInContext(ctx.llvm_ctx);
        }

        // Check struct types first
        i8* found_struct = st_map_get(&ctx.struct_types, name);
        if (found_struct != (i8*)0) {
            base = found_struct;
        } else {
            // Check typedef aliases
            i8* alias_tn = typedef_map_get(&ctx.typedef_aliases, name);
            if (alias_tn != (i8*)0) {
                parser.type_node* resolved_tn = (parser.type_node*)alias_tn;
                i8* resolved = llvm_type_of(resolved_tn, ctx);
                // Apply pointer depth on top of resolved
                i32 pi = 0;
                while (pi < t.pointer_depth) {
                    resolved = LLVMPointerType(resolved, 0);
                    pi = pi + 1;
                }
                return resolved;
            }
            // Try namespace-qualified lookup
            if (ctx.current_namespace != (i8*)0) {
                i8 ns_name[512];
                snprintf(ns_name, (u64)512, "%s__NS_%s", ctx.current_namespace, name);
                found_struct = st_map_get(&ctx.struct_types, ns_name);
                if (found_struct != (i8*)0) {
                    base = found_struct;
                }
            }
            if (base == (i8*)0) {
                // Check type parameter bindings (for generic instantiation)
                i8* tp_t = st_map_get(&ctx.type_param_bindings, name);
                if (tp_t != (i8*)0) {
                    base = tp_t;
                } else {
                    // Fallback to i8* (opaque pointer)
                    base = LLVMInt8TypeInContext(ctx.llvm_ctx);
                }
            }
        }
    }

    // Apply pointer depth
    i32 pi = 0;
    while (pi < t.pointer_depth) {
        base = LLVMPointerType(base, 0);
        pi = pi + 1;
    }

    // Array type
    if (t.array_size_ptr != (i8*)0) {
        parser.expr_node* sz_expr = (parser.expr_node*)t.array_size_ptr;
        u64 n = 0;
        if (sz_expr.kind == ek_int_lit) {
            n = (u64)sz_expr.int_val;
        } else if (sz_expr.kind == ek_identifier && sz_expr.str_val != (i8*)0) {
            // Try to look up constexpr value
            i8* cv = sv_map_get(&ctx.constexpr_int_vals_map, sz_expr.str_val);
            if (cv != (i8*)0) {
                n = (u64)(i64)cv;
            }
        }
        return LLVMArrayType(base, (i32)n);
    }

    return base;
}

// Returns the bare LLVMFunctionType for a func-ptr type node (no pointer wrapper).
// Used to store the function type for indirect-call resolution in opaque-pointer mode.
i8* llvm_func_type_of(parser.type_node* t, ir_context* ctx) {
    if (t == (parser.type_node*)0) { return (i8*)0; }
    if (!t.is_func_ptr || t.fp_ret == (i8*)0) { return (i8*)0; }
    i8* ret_t = llvm_type_of((parser.type_node*)t.fp_ret, ctx);
    i32 nparams = t.fp_params_len;
    i8** param_ts = (i8**)0;
    if (nparams > 0) {
        param_ts = (i8**)malloc(sizeof(i8*) * (u64)nparams);
        i32 pi = 0;
        while (pi < nparams) {
            parser.type_node* pt = (parser.type_node*)t.fp_params[pi];
            param_ts[pi] = llvm_type_of(pt, ctx);
            pi = pi + 1;
        }
    }
    i32 variadic = t.fp_variadic ? 1 : 0;
    i8* fn_t = LLVMFunctionType(ret_t, param_ts, nparams, variadic);
    if (param_ts != (i8**)0) { free((i8*)param_ts); }
    return fn_t;
}

// Resolve typedef alias: returns the underlying type_node.
parser.type_node* resolve_typedef_alias_node(parser.type_node* t, ir_context* ctx) {
    if (t == (parser.type_node*)0) { return (parser.type_node*)0; }
    if (t.is_primitive) { return t; }
    if (t.pointer_depth > 0) { return t; }
    if (t.name == (i8*)0) { return t; }
    i8* alias_tn = typedef_map_get(&ctx.typedef_aliases, t.name);
    if (alias_tn == (i8*)0) { return t; }
    return resolve_typedef_alias_node((parser.type_node*)alias_tn, ctx);
}

// Returns true when an LLVM type is a floating-point kind.
bool llvm_is_float(i8* t) {
    i32 k = LLVMGetTypeKind(t);
    return k == LLVMHalfTypeKind   || k == LLVMBFloatTypeKind  ||
           k == LLVMFloatTypeKind  || k == LLVMDoubleTypeKind  ||
           k == LLVMX86_FP80TypeKind || k == LLVMFP128TypeKind;
}

} // namespace ir
// Name mangling for the Artemis self-hosting compiler.

namespace ir {

// Encode a single type_node into a short string for name mangling.
// Returns a heap-allocated string.
i8* mangle_type(parser.type_node* t) {
    if (t == (parser.type_node*)0) { return lexer.str_dup("v"); }
    if (t.is_func_ptr) { return lexer.str_dup("FP"); }

    i8 buf[256];
    buf[0] = 0;

    // Pointer prefix
    i32 pi = 0;
    while (pi < t.pointer_depth) {
        i8 tmp[256];
        snprintf(tmp, (u64)256, "P%s", buf);
        snprintf(buf, (u64)256, "%s", tmp);
        pi = pi + 1;
    }

    if (t.is_primitive && t.has_prim) {
        i8 suffix[64];
        if (t.prim == void_t)    { snprintf(suffix, (u64)64, "v"); }
        else if (t.prim == char_t)    { snprintf(suffix, (u64)64, "c"); }
        else if (t.prim == arb_int)   { snprintf(suffix, (u64)64, "i%d", (i32)t.bit_width); }
        else if (t.prim == arb_uint)  { snprintf(suffix, (u64)64, "u%d", (i32)t.bit_width); }
        else if (t.prim == arb_float) { snprintf(suffix, (u64)64, "f%d", (i32)t.bit_width); }
        else if (t.prim == arb_bool)  { snprintf(suffix, (u64)64, "b%d", (i32)t.bit_width); }
        else { snprintf(suffix, (u64)64, "?"); }
        i8 full[256];
        snprintf(full, (u64)256, "%s%s", buf, suffix);
        return lexer.str_dup(full);
    }

    if (t.name != (i8*)0) {
        i8 full[256];
        snprintf(full, (u64)256, "%s%s", buf, t.name);
        return lexer.str_dup(full);
    }

    i8 full[256];
    snprintf(full, (u64)256, "%s?", buf);
    return lexer.str_dup(full);
}

// Build the mangled name for an overloaded function: funcname__type1_type2_...
// Returns a heap-allocated string.
i8* build_mangled_name(i8* base, parser.param_decl* params, i32 params_len) {
    i8 buf[1024];
    snprintf(buf, (u64)1024, "%s__", base);

    i32 i = 0;
    while (i < params_len) {
        if (i > 0) {
            i8 tmp[1024];
            snprintf(tmp, (u64)1024, "%s_", buf);
            snprintf(buf, (u64)1024, "%s", tmp);
        }
        i8* mt = mangle_type(params[i].type);
        i8 tmp[1024];
        snprintf(tmp, (u64)1024, "%s%s", buf, mt);
        snprintf(buf, (u64)1024, "%s", tmp);
        free(mt);
        i = i + 1;
    }
    return lexer.str_dup(buf);
}

// Get the IR name for a func_decl.
i8* ir_func_name(parser.func_decl* fd) {
    if (fd.is_extern_c) { return fd.name; }
    if (fd.mangled_name != (i8*)0) { return fd.mangled_name; }
    if (fd.is_overloaded) {
        return build_mangled_name(fd.name, fd.params, fd.params_len);
    }
    return fd.name;
}

} // namespace ir
