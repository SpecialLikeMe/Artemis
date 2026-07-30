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
    kw_extern   = 72,
    kw_inline   = 73,
    kw_sizeof   = 74,
    kw_true     = 75,
    kw_false    = 76,
    kw_volatile = 77,
    ty_void     = 78,
    kw_null     = 79,

    // type keywords
    ty_char     = 80,
    ty_arb_int  = 81,  // iN — value = N as decimal string
    ty_arb_uint = 82,  // uN
    ty_arb_float= 83,  // fN
    ty_arb_bool = 84,  // bN

    kw_struct   = 85,
    kw_enum     = 86,
    kw_union    = 87,
    kw_smem     = 88,

    kw_asm      = 90,
    asm_body    = 91,

    // OOP / class keywords
    kw_istruc   = 92,
    kw_interface= 93,
    kw_static   = 94,
    kw_comptime = 96,
    kw_type     = 98,
    kw_operator = 99,

    // misc
    kw_defer    = 100,
    kw_errdefer = 101,
    kw_extern_c = 102,
    kw_namespace= 103,
    kw_try      = 104,
    kw_catch    = 105,
    arrow       = 106,  // ->

    // newer features
    kw_auto     = 107,
    kw_using    = 108,
    kw_pragma   = 109,
    kw_const_resolve = 110,
    kw_error    = 112,
    kw_null_t   = 113,
    kw_token_type = 114,

    // new number-type prefixes
    ty_arb_rational = 115, // qN  — rational number { iN num; iN den; }
    ty_arb_complex  = 116, // cN  — complex number  { fN re;  fN im; }
    ty_arb_char_w   = 117, // chN — N-bit character (unsigned alias)
    ty_arb_str_w    = 118, // strN — string of N-bit chars
    ty_arb_nat      = 123, // nN  — natural number (≥0, distinct from uN)
    ty_arb_zint     = 124, // zN  — integer ring (distinct from iN)
    ty_arb_real     = 125, // rN  — real number (distinct from fN)
    ty_arb_alg      = 126, // aN  — algebraic number (always f64 at runtime)

    // new language keywords
    kw_ref    = 119, // ref — context-aware address-of
    kw_attr   = 120, // attr — proc macro attribute marker
    kw_derive = 121, // derive — proc macro derive marker
    kw_quote  = 122, // quote{} — tokenstream literal

    // trailing-type syntax keywords
    kw_let    = 127, // let  — runtime binding (immutable by default)
    kw_fn     = 128, // fn   — function declaration
    kw_mut    = 129, // mut  — mutable modifier (used after let)
    kw_pub    = 130, // pub  — public visibility
    kw_priv   = 131, // priv — private visibility
    fn_import = 132, // import — used in @import("path") builtin

    // match / ranges
    dotdot    = 141, // ..   — exclusive range / rest pattern (was 132, collided with fn_import)
    dotdot_eq = 142, // ..=  — inclusive range
    fat_arrow = 134, // =>   — match arm arrow
    kw_match  = 135, // match

    // safe cast and unsafe block
    kw_as     = 136, // as   — explicit type conversion  (expr as Type)

    // architecture-sized integer types
    kw_anytype = 137, // anytype — accepts any type (generic parameter, like Zig's anytype)
    kw_usize   = 138, // usize   — pointer-sized unsigned (u64 on x64)
    kw_isize   = 139, // isize   — pointer-sized signed (i64 on x64)
    kw_iofs    = 140, // iofs    — signed ptr_bits+1 offset (i65 on x64)
}

// ---- Token name helper (for diagnostic messages) ----
fn tok_type_name(tt: i32) *i8 {
    if (tt == eof_t)           { return "end of file"; }
    if (tt == id)              { return "identifier"; }
    if (tt == num_t)           { return "number"; }
    if (tt == int_lit)         { return "integer literal"; }
    if (tt == float_lit)       { return "float literal"; }
    if (tt == string_lit)      { return "string literal"; }
    if (tt == char_lit)        { return "char literal"; }
    if (tt == obrace)          { return "'{'"; }
    if (tt == cbrace)          { return "'}'"; }
    if (tt == oparen)          { return "'('"; }
    if (tt == cparen)          { return "')'"; }
    if (tt == obracket)        { return "'['"; }
    if (tt == cbracket)        { return "']'"; }
    if (tt == sm)              { return "';'"; }
    if (tt == colon)           { return "':'"; }
    if (tt == question)        { return "'?'"; }
    if (tt == dollar)          { return "'$'"; }
    if (tt == comma)           { return "','"; }
    if (tt == dot)             { return "'.'"; }
    if (tt == at)              { return "'@'"; }
    if (tt == hash)            { return "'#'"; }
    if (tt == addr)            { return "'&'"; }
    if (tt == assign)          { return "'='"; }
    if (tt == eq)              { return "'=='"; }
    if (tt == ne)              { return "'!='"; }
    if (tt == lt)              { return "'<'"; }
    if (tt == gt)              { return "'>'"; }
    if (tt == lte)             { return "'<='"; }
    if (tt == gte)             { return "'>='"; }
    if (tt == plus)            { return "'+'"; }
    if (tt == minus)           { return "'-'"; }
    if (tt == ast)             { return "'*'"; }
    if (tt == slash)           { return "'/'"; }
    if (tt == mod)             { return "'%'"; }
    if (tt == inc)             { return "'++'"; }
    if (tt == dec)             { return "'--'"; }
    if (tt == and_)            { return "'&&'"; }
    if (tt == or_)             { return "'||'"; }
    if (tt == not_)            { return "'!'"; }
    if (tt == bit_or)          { return "'|'"; }
    if (tt == bit_xor)         { return "'^'"; }
    if (tt == bit_not)         { return "'~'"; }
    if (tt == left)            { return "'<<'"; }
    if (tt == right)           { return "'>>'"; }
    if (tt == arrow)           { return "'->'"; }
    if (tt == plus_eq)         { return "'+='"; }
    if (tt == minus_eq)        { return "'-='"; }
    if (tt == star_eq)         { return "'*='"; }
    if (tt == slash_eq)        { return "'/='"; }
    if (tt == mod_eq)          { return "'%='"; }
    if (tt == amp_eq)          { return "'&='"; }
    if (tt == pipe_eq)         { return "'|='"; }
    if (tt == question_question){ return "'??'"; }
    if (tt == kw_if)           { return "'if'"; }
    if (tt == kw_else)         { return "'else'"; }
    if (tt == kw_while)        { return "'while'"; }
    if (tt == kw_for)          { return "'for'"; }
    if (tt == kw_return)       { return "'return'"; }
    if (tt == kw_break)        { return "'break'"; }
    if (tt == kw_continue)     { return "'continue'"; }
    if (tt == kw_switch)       { return "'switch'"; }
    if (tt == kw_case)         { return "'case'"; }
    if (tt == kw_default)      { return "'default'"; }
    if (tt == kw_const)        { return "'const'"; }
    if (tt == kw_extern)       { return "'extern'"; }
    if (tt == kw_extern_c)     { return "'extern \"C\"'"; }
    if (tt == kw_inline)       { return "'inline'"; }
    if (tt == kw_signed)       { return "'signed'"; }
    if (tt == kw_unsigned)     { return "'unsigned'"; }
    if (tt == kw_volatile)     { return "'volatile'"; }
    if (tt == kw_sizeof)       { return "'sizeof'"; }
    if (tt == kw_true)         { return "'true'"; }
    if (tt == kw_false)        { return "'false'"; }
    if (tt == ty_void)         { return "'void'"; }
    if (tt == kw_null)         { return "'null'"; }
    if (tt == kw_null_t)       { return "'null_t'"; }
    if (tt == ty_char)         { return "'char'"; }
    if (tt == ty_arb_int)      { return "integer type (iN)"; }
    if (tt == ty_arb_uint)     { return "unsigned type (uN)"; }
    if (tt == ty_arb_float)    { return "float type (fN)"; }
    if (tt == ty_arb_bool)     { return "bool type (bN)"; }
    if (tt == ty_arb_nat)      { return "natural type (nN)"; }
    if (tt == ty_arb_zint)     { return "integer-ring type (zN)"; }
    if (tt == ty_arb_real)     { return "real type (rN)"; }
    if (tt == ty_arb_alg)      { return "algebraic type (aN)"; }
    if (tt == kw_struct)       { return "'struct'"; }
    if (tt == kw_enum)         { return "'enum'"; }
    if (tt == kw_union)        { return "'union'"; }
    if (tt == kw_smem)         { return "'memstr'"; }
    if (tt == kw_asm)          { return "'__asm__'"; }
    if (tt == kw_istruc)       { return "'istruc'"; }
    if (tt == kw_interface)    { return "'interface'"; }
    if (tt == kw_static)       { return "'static'"; }
    if (tt == kw_comptime)     { return "'comptime'"; }
    if (tt == kw_type)         { return "'type'"; }
    if (tt == kw_operator)     { return "'operator'"; }
    if (tt == kw_defer)        { return "'defer'"; }
    if (tt == kw_errdefer)     { return "'errdefer'"; }
    if (tt == kw_namespace)    { return "'namespace'"; }
    if (tt == kw_try)          { return "'try'"; }
    if (tt == kw_catch)        { return "'catch'"; }
    if (tt == kw_error)        { return "'error'"; }
    if (tt == kw_auto)         { return "'auto'"; }
    if (tt == kw_using)        { return "'using'"; }
    if (tt == kw_ref)          { return "'ref'"; }
    if (tt == kw_attr)         { return "'attr'"; }
    if (tt == kw_derive)       { return "'derive'"; }
    if (tt == kw_quote)        { return "'quote'"; }
    if (tt == kw_let)          { return "'let'"; }
    if (tt == kw_fn)           { return "'fn'"; }
    if (tt == kw_mut)          { return "'mut'"; }
    if (tt == kw_pub)          { return "'pub'"; }
    if (tt == kw_priv)         { return "'priv'"; }
    if (tt == dotdot)          { return "'..'"; }
    if (tt == dotdot_eq)       { return "'..='"; }
    if (tt == fat_arrow)       { return "'=>'"; }
    if (tt == kw_match)        { return "'match'"; }
    if (tt == kw_as)           { return "'as'"; }
    if (tt == kw_anytype)      { return "'anytype'"; }
    if (tt == kw_usize)        { return "'usize'"; }
    if (tt == kw_isize)        { return "'isize'"; }
    if (tt == kw_iofs)         { return "'iofs'"; }
    return "unknown token";
}

// ---- Token struct ----
struct token_t {
    let type: i32;
    let value: *i8;
    let line: i32;
}

// ---- Dynamic token array ----
struct token_vec {
    let data: *token_t;
    let len: i32;
    let cap: i32;
}

fn token_vec_init(v: *token_vec) void {
    v.data = (token_t*)0;
    v.len  = 0;
    v.cap  = 0;
}

fn token_vec_push(v: *token_vec, t: token_t) void {
    if (v.len >= v.cap) {
        let mut nc: i32= v.cap == 0 ? 64 : v.cap * 2;
        v.data = (token_t*)arc_realloc((i8*)v.data, sizeof(lexer__NS_token_t) * (u64)nc);
        v.cap  = nc;
    }
    v.data[v.len] = t;
    v.len = v.len + 1;
}

// ---- String allocation helpers ----

// Allocate a copy of a substring: src[start..start+len]
fn str_dup_n(src: *i8, start: i32, len: i32) *i8 {
    let mut buf: *i8= (i8*)arc_malloc((u64)(len + 1));
    memcpy(buf, src + start, (u64)len);
    buf[len] = 0;
    return buf;
}

// Allocate a copy of a null-terminated string
fn str_dup(src: *i8) *i8 {
    let mut n: i32= 0;
    while (src[n] != 0) { n = n + 1; }
    return str_dup_n(src, 0, n);
}

// Allocate a single-character string
fn char_str(c: i8) *i8 {
    let mut buf: *i8= (i8*)arc_malloc(2);
    buf[0] = c;
    buf[1] = 0;
    return buf;
}

// Allocate a two-character string
fn char2_str(a: i8, b: i8) *i8 {
    let mut buf: *i8= (i8*)arc_malloc(3);
    buf[0] = a;
    buf[1] = b;
    buf[2] = 0;
    return buf;
}

// ---- Lexer istruc ----

istruc lexer_t {
    let mut src: *i8;
    let mut src_len: u64;
    let mut pos: u64;
    let mut line: i32;

    fn init(self: *lexer_t, source: *i8, len: u64) void {
        self.src     = source;
        self.src_len = len;
        self.pos     = 0;
        self.line    = 1;
    }

    fn peek_char(self: *lexer_t) i8 {
        if (self.pos >= self.src_len) { return 0; }
        return self.src[self.pos];
    }

    fn peek_next_char(self: *lexer_t) i8 {
        if (self.pos + 1 >= self.src_len) { return 0; }
        return self.src[self.pos + 1];
    }

    fn peek_at_n(self: *lexer_t, n: u64) i8 {
        if (self.pos + n >= self.src_len) { return 0; }
        return self.src[self.pos + n];
    }

    fn advance_char(self: *lexer_t) i8 {
        if (self.pos >= self.src_len) { return 0; }
        let mut c: i8= self.src[self.pos];
        self.pos = self.pos + 1;
        return c;
    }

    fn is_at_end(self: *lexer_t) bool {
        return self.pos >= self.src_len;
    }

    fn match_next(self: *lexer_t, expected: i8) bool {
        if (self.is_at_end()) { return false; }
        if (self.peek_char() != expected) { return false; }
        self.pos = self.pos + 1;
        return true;
    }

    // Skip whitespace (not newlines) and comments; updates self.line for newlines
    fn skip_whitespace_and_comments(self: *lexer_t) void {
        let mut cont: bool= true;
        while (cont && !self.is_at_end()) {
            let mut c: i8= self.peek_char();
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

    fn skip_line_comment(self: *lexer_t) void {
        while (!self.is_at_end() && self.peek_char() != '\n') {
            self.advance_char();
        }
    }

    fn skip_block_comment(self: *lexer_t) void {
        let mut start_line: i32= self.line;
        self.advance_char();
        self.advance_char();  // consume /*
        while (!self.is_at_end()) {
            let mut c: i8= self.peek_char();
            if (c == '\n') { self.line = self.line + 1; }
            if (c == '*' && self.peek_next_char() == '/') {
                self.advance_char();
                self.advance_char();
                return;
            }
            self.advance_char();
        }
        aprint("error at line %d: unterminated block comment (opened here)\n", .{ start_line });
    }

    // Read escape sequence (after backslash)
    fn read_escape(self: *lexer_t) i8 {
        self.advance_char();  // consume backslash
        let mut c: i8= self.advance_char();
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
    fn read_string_lit(self: *lexer_t, tok_line: i32) token_t {
        // Collect string into a growable buffer
        let mut buf_cap: i32= 64;
        let mut buf_len: i32= 0;
        let mut buf: *i8= (i8*)arc_malloc((u64)buf_cap);

        let mut running: bool= true;
        while (running && !self.is_at_end() && self.peek_char() != '"') {
            let mut c: i8;
            if (self.peek_char() == '\\') {
                c = self.read_escape();
            } else {
                if (self.peek_char() == '\n') { self.line = self.line + 1; }
                c = self.advance_char();
            }
            if (buf_len + 1 >= buf_cap) {
                buf_cap = buf_cap * 2;
                buf = (i8*)arc_realloc(buf, (u64)buf_cap);
            }
            buf[buf_len] = c;
            buf_len = buf_len + 1;
        }
        if (!self.is_at_end()) { self.advance_char(); }  // closing "
        buf[buf_len] = 0;

        let mut tok: token_t;
        tok.type  = string_lit;
        tok.value = buf;
        tok.line  = tok_line;
        return tok;
    }

    // Read char literal (opening ' already consumed)
    fn read_char_lit(self: *lexer_t, tok_line: i32) token_t {
        let mut c: i8;
        if (self.peek_char() == '\\') {
            c = self.read_escape();
        } else {
            c = self.advance_char();
        }
        if (self.peek_char() == '\'') { self.advance_char(); }  // closing '

        let mut tok: token_t;
        tok.type  = char_lit;
        tok.value = char_str(c);
        tok.line  = tok_line;
        return tok;
    }

    // Check if a character is a digit
    fn is_digit_c(self: *lexer_t, c: i8) bool {
        return c >= '0' && c <= '9';
    }

    fn is_hex_digit_c(self: *lexer_t, c: i8) bool {
        if (c >= '0' && c <= '9') { return true; }
        if (c >= 'a' && c <= 'f') { return true; }
        if (c >= 'A' && c <= 'F') { return true; }
        return false;
    }

    fn is_alpha_c(self: *lexer_t, c: i8) bool {
        if (c >= 'a' && c <= 'z') { return true; }
        if (c >= 'A' && c <= 'Z') { return true; }
        if (c == '_') { return true; }
        return false;
    }

    fn is_alnum_c(self: *lexer_t, c: i8) bool {
        return self.is_alpha_c(c) || self.is_digit_c(c);
    }

    // Read a number literal
    fn read_number(self: *lexer_t) token_t {
        let mut tok_line: i32= self.line;
        let mut start: u64= self.pos;
        let mut is_float_lit: bool= false;

        // hex: 0x...
        if (self.peek_char() == '0' && (self.peek_next_char() == 'x' || self.peek_next_char() == 'X')) {
            self.advance_char();
            self.advance_char();
            while (!self.is_at_end() && self.is_hex_digit_c(self.peek_char())) {
                self.advance_char();
            }
            self.skip_int_suffix();
            let mut len: i32= (i32)(self.pos - start);
            let mut tok: token_t;
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
            let mut len: i32= (i32)(self.pos - start);
            let mut tok: token_t;
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

        let mut len: i32= (i32)(self.pos - start);
        let mut tok: token_t;
        tok.type  = is_float_lit ? float_lit : int_lit;
        tok.value = str_dup_n(self.src, (i32)start, len);
        tok.line  = tok_line;
        return tok;
    }

    fn skip_int_suffix(self: *lexer_t) void {
        while (!self.is_at_end()) {
            let mut c: i8= self.peek_char();
            if (c == 'u' || c == 'U' || c == 'l' || c == 'L') {
                self.advance_char();
            } else {
                return;
            }
        }
    }

    fn skip_num_suffix(self: *lexer_t) void {
        while (!self.is_at_end()) {
            let mut c: i8= self.peek_char();
            if (c == 'f' || c == 'F' || c == 'u' || c == 'U' || c == 'l' || c == 'L') {
                self.advance_char();
            } else {
                return;
            }
        }
    }

    // Keyword lookup - returns token_type or id if not found
    fn lookup_keyword(self: *lexer_t, word: *i8) i32 {
        if (strcmp(word, "if")        == 0) { return kw_if; }
        if (strcmp(word, "else")      == 0) { return kw_else; }
        if (strcmp(word, "while")     == 0) { return kw_while; }
        if (strcmp(word, "switch")    == 0) { return kw_switch; }
        if (strcmp(word, "match")     == 0) { return kw_match; }
        if (strcmp(word, "as")        == 0) { return kw_as; }
        if (strcmp(word, "case")      == 0) { return kw_case; }
        if (strcmp(word, "default")   == 0) { return kw_default; }
        if (strcmp(word, "for")       == 0) { return kw_for; }
        if (strcmp(word, "return")    == 0) { return kw_return; }
        if (strcmp(word, "break")     == 0) { return kw_break; }
        if (strcmp(word, "continue")  == 0) { return kw_continue; }
        if (strcmp(word, "signed")    == 0) { return kw_signed; }
        if (strcmp(word, "unsigned")  == 0) { return kw_unsigned; }
        if (strcmp(word, "const")     == 0) { return kw_const; }
        if (strcmp(word, "extern")    == 0) { return kw_extern; }
        if (strcmp(word, "inline")    == 0) { return kw_inline; }
        if (strcmp(word, "sizeof")    == 0) { return kw_sizeof; }
        if (strcmp(word, "true")      == 0) { return kw_true; }
        if (strcmp(word, "false")     == 0) { return kw_false; }
        if (strcmp(word, "volatile")  == 0) { return kw_volatile; }
        if (strcmp(word, "void")      == 0) { return ty_void; }
        if (strcmp(word, "null")      == 0) { return kw_null; }
        if (strcmp(word, "char")      == 0) { return ty_char; }
        if (strcmp(word, "struct")    == 0) { return kw_struct; }
        if (strcmp(word, "enum")      == 0) { return kw_enum; }
        if (strcmp(word, "union")     == 0) { return kw_union; }
        // "memstr" is a builtin type name, not a reserved keyword — falls through to id
        if (strcmp(word, "__asm__")   == 0) { return kw_asm; }
        if (strcmp(word, "istruc")    == 0) { return kw_istruc; }
        if (strcmp(word, "interface") == 0) { return kw_interface; }
        if (strcmp(word, "static")    == 0) { return kw_static; }
        if (strcmp(word, "comptime")  == 0) { return kw_comptime; }
        if (strcmp(word, "type")      == 0) { return kw_type; }
        if (strcmp(word, "operator")  == 0) { return kw_operator; }
        if (strcmp(word, "defer")     == 0) { return kw_defer; }
        if (strcmp(word, "errdefer")  == 0) { return kw_errdefer; }
        if (strcmp(word, "namespace") == 0) { return kw_namespace; }
        if (strcmp(word, "try")       == 0) { return kw_try; }
        if (strcmp(word, "catch")     == 0) { return kw_catch; }
        if (strcmp(word, "error")     == 0) { return kw_error; }
        if (strcmp(word, "auto")      == 0) { return kw_auto; }
        if (strcmp(word, "using")     == 0) { return kw_using; }
        if (strcmp(word, "const_resolve") == 0) { return kw_const_resolve; }
        if (strcmp(word, "__token")   == 0) { return kw_token_type; }
        if (strcmp(word, "ref")       == 0) { return kw_ref; }
        if (strcmp(word, "attr")      == 0) { return kw_attr; }
        if (strcmp(word, "derive")    == 0) { return kw_derive; }
        if (strcmp(word, "quote")     == 0) { return kw_quote; }
        if (strcmp(word, "let")       == 0) { return kw_let; }
        if (strcmp(word, "fn")        == 0) { return kw_fn; }
        if (strcmp(word, "import")    == 0) { return fn_import; }
        if (strcmp(word, "mut")       == 0) { return kw_mut; }
        if (strcmp(word, "pub")       == 0) { return kw_pub; }
        if (strcmp(word, "priv")      == 0) { return kw_priv; }
        if (strcmp(word, "anytype")   == 0) { return kw_anytype; }
        if (strcmp(word, "usize")     == 0) { return kw_usize; }
        if (strcmp(word, "isize")     == 0) { return kw_isize; }
        if (strcmp(word, "iofs")      == 0) { return kw_iofs; }
        return id;
    }

    // Read identifier or keyword
    fn read_identifier_or_keyword(self: *lexer_t) token_t {
        let mut tok_line: i32= self.line;
        let mut start: u64= self.pos;

        while (!self.is_at_end() && self.is_alnum_c(self.peek_char())) {
            self.advance_char();
        }
        // Check for T[_] infinite-width suffix: e.g. i[_], u[_], f[_], z[_], r[_], etc.
        // Only consume [_] if the word so far is a known type prefix (1-3 chars, alphanumeric only).
        if (!self.is_at_end() && self.peek_char() == '[') {
            let mut saved_pos: u64= self.pos;
            self.advance_char();  // consume '['
            if (!self.is_at_end() && self.peek_char() == '_') {
                self.advance_char();  // consume '_'
                if (!self.is_at_end() && self.peek_char() == ']') {
                    self.advance_char();  // consume ']'
                    // Keep the extended word including [_]
                } else {
                    self.pos = saved_pos;  // rollback
                }
            } else {
                self.pos = saved_pos;  // rollback
            }
        }

        let mut len: i32= (i32)(self.pos - start);
        let mut word: *i8= str_dup_n(self.src, (i32)start, len);

        // Check for extern "C"
        if (strcmp(word, "extern") == 0) {
            let mut save_pos: u64= self.pos;
            let mut save_line: i32= self.line;
            // skip spaces
            while (!self.is_at_end() && (self.peek_char() == ' ' || self.peek_char() == '\t')) {
                self.advance_char();
            }
            if (!self.is_at_end() && self.peek_char() == '"') {
                let mut q_save: u64= self.pos;
                self.advance_char();  // consume "
                if (!self.is_at_end() && self.peek_char() == 'C') {
                    self.advance_char();  // consume C
                    if (!self.is_at_end() && self.peek_char() == '"') {
                        self.advance_char();  // consume "
                        let mut tok: token_t;
                        tok.type  = kw_extern_c;
                        tok.value = str_dup("extern \"C\"");
                        tok.line  = tok_line;
                        arc_free(word);
                        return tok;
                    }
                }
                self.pos = q_save;
            }
            self.pos  = save_pos;
            self.line = save_line;
        }

        // Check arbitrary-width types: iN, uN, fN, bN, nN, zN, qN, cN, rN, aN, chN, strN
        // Also handles T[_] infinite width (stored as width "0").
        if (len >= 2) {
            // Multi-char prefixes first (ch, str)
            let mut is_ch: bool= (len >= 3 && word[0]=='c' && word[1]=='h');
            let mut is_str: bool= (len >= 4 && word[0]=='s' && word[1]=='t' && word[2]=='r');
            let mut pfx_len: i32= is_str ? 3 : (is_ch ? 2 : 1);
            let mut pfx1: i8= word[0];
            let mut single_pfx: bool= !is_ch && !is_str &&
                (pfx1=='i' || pfx1=='u' || pfx1=='f' || pfx1=='b' ||
                 pfx1=='n' || pfx1=='z' || pfx1=='q' || pfx1=='c' ||
                 pfx1=='r' || pfx1=='a');

            let mut check_arb: bool= is_ch || is_str || single_pfx;
            if (check_arb) {
                // Check suffix: digits OR [_] for infinite width
                let mut all_digits: bool= true;
                let mut infinite: bool= false;
                let mut k: i32= pfx_len;
                if (k < len && word[k] == '[' && k+2 < len && word[k+1] == '_' && word[k+2] == ']') {
                    infinite = true;
                } else {
                    while (k < len) {
                        if (word[k] < '0' || word[k] > '9') { all_digits = false; }
                        k = k + 1;
                    }
                }
                // New single-char prefixes (n,z,q,r,a,c) require at least 2-digit suffix
                // to avoid tokenizing common identifiers like r1, r2, c3, n5, z2, q7.
                // Multi-char prefixes (ch, str) and classic prefixes (i,u,f,b) are unchanged.
                let mut needs_min2: bool= single_pfx && (pfx1=='n' || pfx1=='z' || pfx1=='q' ||
                                                 pfx1=='r' || pfx1=='a' || pfx1=='c');
                let mut suffix_len: i32= len - pfx_len;
                if ((all_digits && (!needs_min2 || suffix_len >= 2)) || infinite) {
                    let mut width_str: *i8;
                    if (infinite) { width_str = str_dup("0"); }
                    else          { width_str = str_dup_n(word, pfx_len, len - pfx_len); }
                    let mut tt: i32;
                    if (is_str)          { tt = ty_arb_str_w; }
                    else if (is_ch)      { tt = ty_arb_char_w; }
                    else if (pfx1=='i')  { tt = ty_arb_int; }
                    else if (pfx1=='u')  { tt = ty_arb_uint; }
                    else if (pfx1=='f')  { tt = ty_arb_float; }
                    else if (pfx1=='b')  { tt = ty_arb_bool; }
                    else if (pfx1=='n')  { tt = ty_arb_nat; }      // natural number (≥0)
                    else if (pfx1=='z')  { tt = ty_arb_zint; }    // integer ring ℤ
                    else if (pfx1=='q')  { tt = ty_arb_rational; } // rational number ℚ
                    else if (pfx1=='r')  { tt = ty_arb_real; }    // real number ℝ
                    else if (pfx1=='a')  { tt = ty_arb_alg; }     // algebraic number
                    else                 { tt = ty_arb_complex; }  // complex number ℂ
                    let mut tok: token_t;
                    tok.type  = tt;
                    tok.value = width_str;
                    tok.line  = tok_line;
                    arc_free(word);
                    return tok;
                }
            }
        }

        // Word aliases
        if (strcmp(word, "int")   == 0) {
            let mut tok: token_t; tok.type = ty_arb_int;   tok.value = str_dup("32"); tok.line = tok_line;
            arc_free(word); return tok;
        }
        if (strcmp(word, "uint")  == 0) {
            let mut tok: token_t; tok.type = ty_arb_uint;  tok.value = str_dup("32"); tok.line = tok_line;
            arc_free(word); return tok;
        }
        if (strcmp(word, "float") == 0) {
            let mut tok: token_t; tok.type = ty_arb_float; tok.value = str_dup("64"); tok.line = tok_line;
            arc_free(word); return tok;
        }
        if (strcmp(word, "bool")  == 0) {
            let mut tok: token_t; tok.type = ty_arb_bool;  tok.value = str_dup("8");  tok.line = tok_line;
            arc_free(word); return tok;
        }

        let mut ktype: i32= self.lookup_keyword(word);
        let mut tok: token_t;
        tok.type  = ktype;
        tok.value = word;
        tok.line  = tok_line;
        return tok;
    }

    // Skip asm body { ... } (nested braces) and return the content
    fn skip_to_brace(self: *lexer_t) void {
        while (!self.is_at_end()) {
            let mut c: i8= self.peek_char();
            if (c == ' ' || c == '\t' || c == '\r') { self.advance_char(); }
            else if (c == '\n') { self.line = self.line + 1; self.advance_char(); }
            else { return; }
        }
    }

    fn read_asm_body(self: *lexer_t) token_t {
        let mut tok_line: i32= self.line;
        self.advance_char();  // consume '{'

        let mut buf_cap: i32= 256;
        let mut buf_len: i32= 0;
        let mut buf: *i8= (i8*)arc_malloc((u64)buf_cap);
        let mut depth: i32= 1;

        let mut running: bool= true;
        while (running && !self.is_at_end() && depth > 0) {
            let mut c: i8= self.peek_char();
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
                buf = (i8*)arc_realloc(buf, (u64)buf_cap);
            }
        }
        buf[buf_len] = 0;

        let mut tok: token_t;
        tok.type  = asm_body;
        tok.value = buf;
        tok.line  = tok_line;
        return tok;
    }

    // Read operator/symbol token
    fn read_operator(self: *lexer_t) token_t {
        let mut tok_line: i32= self.line;
        let mut c: i8= self.advance_char();

        if (c == '{') { let mut t: token_t; t.type = obrace;    t.value = str_dup("{"); t.line = tok_line; return t; }
        if (c == '}') { let mut t: token_t; t.type = cbrace;    t.value = str_dup("}"); t.line = tok_line; return t; }
        if (c == '(') { let mut t: token_t; t.type = oparen;    t.value = str_dup("("); t.line = tok_line; return t; }
        if (c == ')') { let mut t: token_t; t.type = cparen;    t.value = str_dup(")"); t.line = tok_line; return t; }
        if (c == '[') { let mut t: token_t; t.type = obracket;  t.value = str_dup("["); t.line = tok_line; return t; }
        if (c == ']') { let mut t: token_t; t.type = cbracket;  t.value = str_dup("]"); t.line = tok_line; return t; }
        if (c == ';') { let mut t: token_t; t.type = sm;        t.value = str_dup(";"); t.line = tok_line; return t; }
        if (c == ',') { let mut t: token_t; t.type = comma;     t.value = str_dup(","); t.line = tok_line; return t; }
        if (c == '.') {
            if (self.match_next('.')) {
                if (self.match_next('=')) { let mut t: token_t; t.type = dotdot_eq; t.value = str_dup("..="); t.line = tok_line; return t; }
                let mut t: token_t; t.type = dotdot; t.value = str_dup(".."); t.line = tok_line; return t;
            }
            let mut t: token_t; t.type = dot; t.value = str_dup("."); t.line = tok_line; return t;
        }
        if (c == '@') { let mut t: token_t; t.type = at;        t.value = str_dup("@"); t.line = tok_line; return t; }
        if (c == '#') { let mut t: token_t; t.type = hash;      t.value = str_dup("#"); t.line = tok_line; return t; }
        if (c == '~') { let mut t: token_t; t.type = bit_not;   t.value = str_dup("~"); t.line = tok_line; return t; }
        if (c == '$') { let mut t: token_t; t.type = dollar;    t.value = str_dup("$"); t.line = tok_line; return t; }

        if (c == '^') {
            if (self.match_next('=')) { let mut t: token_t; t.type = caret_eq; t.value = str_dup("^="); t.line = tok_line; return t; }
            let mut t: token_t; t.type = bit_xor; t.value = str_dup("^"); t.line = tok_line; return t;
        }
        if (c == '?') {
            if (self.match_next('?')) { let mut t: token_t; t.type = question_question; t.value = str_dup("??"); t.line = tok_line; return t; }
            let mut t: token_t; t.type = question; t.value = str_dup("?"); t.line = tok_line; return t;
        }
        if (c == ':') {
            let mut t: token_t; t.type = colon; t.value = str_dup(":"); t.line = tok_line; return t;
        }
        if (c == '%') {
            if (self.match_next('=')) { let mut t: token_t; t.type = mod_eq; t.value = str_dup("%="); t.line = tok_line; return t; }
            let mut t: token_t; t.type = mod; t.value = str_dup("%"); t.line = tok_line; return t;
        }
        if (c == '+') {
            if (self.match_next('+')) { let mut t: token_t; t.type = inc;     t.value = str_dup("++"); t.line = tok_line; return t; }
            if (self.match_next('=')) { let mut t: token_t; t.type = plus_eq; t.value = str_dup("+="); t.line = tok_line; return t; }
            let mut t: token_t; t.type = plus; t.value = str_dup("+"); t.line = tok_line; return t;
        }
        if (c == '-') {
            if (self.match_next('-')) { let mut t: token_t; t.type = dec;      t.value = str_dup("--"); t.line = tok_line; return t; }
            if (self.match_next('=')) { let mut t: token_t; t.type = minus_eq; t.value = str_dup("-="); t.line = tok_line; return t; }
            if (self.match_next('>')) { let mut t: token_t; t.type = arrow;    t.value = str_dup("->"); t.line = tok_line; return t; }
            let mut t: token_t; t.type = minus; t.value = str_dup("-"); t.line = tok_line; return t;
        }
        if (c == '*') {
            if (self.match_next('=')) { let mut t: token_t; t.type = star_eq; t.value = str_dup("*="); t.line = tok_line; return t; }
            let mut t: token_t; t.type = ast; t.value = str_dup("*"); t.line = tok_line; return t;
        }
        if (c == '/') {
            if (self.match_next('=')) { let mut t: token_t; t.type = slash_eq; t.value = str_dup("/="); t.line = tok_line; return t; }
            let mut t: token_t; t.type = slash; t.value = str_dup("/"); t.line = tok_line; return t;
        }
        if (c == '=') {
            if (self.match_next('=')) { let mut t: token_t; t.type = eq;        t.value = str_dup("==");  t.line = tok_line; return t; }
            if (self.match_next('>')) { let mut t: token_t; t.type = fat_arrow; t.value = str_dup("=>"); t.line = tok_line; return t; }
            let mut t: token_t; t.type = assign; t.value = str_dup("="); t.line = tok_line; return t;
        }
        if (c == '!') {
            if (self.match_next('=')) { let mut t: token_t; t.type = ne;   t.value = str_dup("!="); t.line = tok_line; return t; }
            let mut t: token_t; t.type = not_; t.value = str_dup("!"); t.line = tok_line; return t;
        }
        if (c == '<') {
            if (self.match_next('<')) {
                if (self.match_next('=')) { let mut t: token_t; t.type = shl_eq; t.value = str_dup("<<="); t.line = tok_line; return t; }
                let mut t: token_t; t.type = left; t.value = str_dup("<<"); t.line = tok_line; return t;
            }
            if (self.match_next('=')) { let mut t: token_t; t.type = lte; t.value = str_dup("<="); t.line = tok_line; return t; }
            let mut t: token_t; t.type = lt; t.value = str_dup("<"); t.line = tok_line; return t;
        }
        if (c == '>') {
            if (self.match_next('>')) {
                if (self.match_next('=')) { let mut t: token_t; t.type = shr_eq; t.value = str_dup(">>="); t.line = tok_line; return t; }
                let mut t: token_t; t.type = right; t.value = str_dup(">>"); t.line = tok_line; return t;
            }
            if (self.match_next('=')) { let mut t: token_t; t.type = gte; t.value = str_dup(">="); t.line = tok_line; return t; }
            let mut t: token_t; t.type = gt; t.value = str_dup(">"); t.line = tok_line; return t;
        }
        if (c == '&') {
            if (self.match_next('&')) { let mut t: token_t; t.type = and_;    t.value = str_dup("&&"); t.line = tok_line; return t; }
            if (self.match_next('=')) { let mut t: token_t; t.type = amp_eq;  t.value = str_dup("&="); t.line = tok_line; return t; }
            let mut t: token_t; t.type = addr; t.value = str_dup("&"); t.line = tok_line; return t;
        }
        if (c == '|') {
            if (self.match_next('|')) { let mut t: token_t; t.type = or_;    t.value = str_dup("||"); t.line = tok_line; return t; }
            if (self.match_next('=')) { let mut t: token_t; t.type = pipe_eq; t.value = str_dup("|="); t.line = tok_line; return t; }
            let mut t: token_t; t.type = bit_or; t.value = str_dup("|"); t.line = tok_line; return t;
        }

        // unknown
        let mut t: token_t;
        t.type  = err_t;
        t.value = char_str(c);
        t.line  = tok_line;
        return t;
    }

    // Main tokenize function
    fn tokenize(self: *lexer_t) token_vec {
        let mut tokens: token_vec;
        token_vec_init(&tokens);

        let mut running: bool= true;
        while (running && !self.is_at_end()) {
            self.skip_whitespace_and_comments();
            if (self.is_at_end()) { running = false; }
            else {
                let mut c: i8= self.peek_char();

                if (c == '\n') {
                    self.line = self.line + 1;
                    self.advance_char();
                } else if (self.is_alpha_c(c)) {
                    let mut tok: token_t= self.read_identifier_or_keyword();
                    token_vec_push(&tokens, tok);
                    if (tok.type == kw_asm) {
                        self.skip_to_brace();
                        if (!self.is_at_end() && self.peek_char() == '{') {
                            let mut abody: token_t= self.read_asm_body();
                            token_vec_push(&tokens, abody);
                        }
                    }
                } else if (self.is_digit_c(c) || (c == '.' && self.is_digit_c(self.peek_next_char()))) {
                    let mut tok: token_t= self.read_number();
                    token_vec_push(&tokens, tok);
                } else if (c == '"') {
                    self.advance_char();  // consume opening "
                    let mut tok: token_t= self.read_string_lit(self.line);
                    token_vec_push(&tokens, tok);
                } else if (c == '\'') {
                    self.advance_char();  // consume opening '
                    let mut tok: token_t= self.read_char_lit(self.line);
                    token_vec_push(&tokens, tok);
                } else {
                    let mut tok: token_t= self.read_operator();
                    token_vec_push(&tokens, tok);
                }
            }
        }

        let mut eof_tok: token_t;
        eof_tok.type  = eof_t;
        eof_tok.value = str_dup("");
        eof_tok.line  = self.line;
        token_vec_push(&tokens, eof_tok);
        return tokens;
    }
}

} // namespace lexer
