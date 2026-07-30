// std.json — Full JSON parser and serializer.

namespace std {
namespace json {

// Value kinds
comptime i32 JSON_NULL   = 0;
comptime i32 JSON_BOOL   = 1;
comptime i32 JSON_INT    = 2;
comptime i32 JSON_FLOAT  = 3;
comptime i32 JSON_STRING = 4;
comptime i32 JSON_ARRAY  = 5;
comptime i32 JSON_OBJECT = 6;

istruc json_val {
    let mut kind: i32;
    let mut b_val: bool;
    let mut i_val: i64;
    let mut f_val: f64;
    let mut s_val: *i8;
    let mut arr_items: **json_val;
    let mut arr_len: i32;
    let mut obj_pairs: *json_pair;
    let mut obj_len: i32;
}

istruc json_pair {
    let mut key: *i8;
    let mut val: *json_val;
}

// --- Lexer state ---

istruc lex {
    let mut src: *i8;
    let mut pos: i32;
    let mut len: i32;

    fn __construct__(self: *lex, s: *i8, n: i32) void { self.src=s; self.pos=0; self.len=n; }

    fn skip_ws(self: *lex) void {
        while (self.pos < self.len) {
            let mut c: i8= self.src[self.pos];
            if (c == ' ' || c == '\t' || c == '\r' || c == '\n') self.pos = self.pos + 1;
            else break;
        }
    }

    fn at_end(self: *lex) bool { return self.pos >= self.len; }
    fn peek(self: *lex) i8   { return self.pos < self.len ? self.src[self.pos] : 0; }
    fn next(self: *lex) i8         { let mut c: i8= self.src[self.pos]; self.pos = self.pos + 1; return c; }
}

// --- Parser ---

fn parse_value(l: *lex, a: &memstr) *json_val;

fn parse_string_raw(l: *lex, a: &memstr) *i8 {
    (*l).next(); // consume "
    let mut start: i32= (*l).pos;
    let mut end: i32= start;
    while ((*l).pos < (*l).len && (*l).src[(*l).pos] != '"') {
        if ((*l).src[(*l).pos] == '\\') { (*l).pos = (*l).pos + 1; }
        (*l).pos = (*l).pos + 1;
        end = (*l).pos;
    }
    (*l).next(); // consume closing "
    let mut n: i32= end - start;
    let mut s: *i8= (i8*)a.mmap((u64)(n + 1)) catch |e| { };
    for (let mut i: i32 = 0; i < n; i = i + 1) s[i] = (*l).src[start + i];
    s[n] = 0;
    return s;
}

fn parse_array(l: *lex, a: &memstr) *json_val {
    (*l).next(); // consume [
    let mut v: *json_val= (json_val*)a.mmap(sizeof(json_val)) catch |e| { };
    (*v).kind = JSON_ARRAY;
    (*v).arr_len = 0;
    (*v).arr_items = (json_val**)0;
    (*l).skip_ws();
    if ((*l).peek() == ']') { (*l).next(); return v; }
    // Collect items into an allocator-backed buffer that grows on demand, so
    // arrays of any size parse correctly (a fixed stack buffer here would
    // overflow, and a fixed cap would reject valid documents).
    let mut cap: i32= 16;
    let mut items: **json_val= (json_val**)a.mmap((u64)(sizeof(json_val*) * (u64)cap)) catch |e| { };
    if (items == (json_val**)0) { return v; }
    let mut count: i32= 0;
    while (true) {
        if (count >= cap) {
            let mut ncap: i32= cap * 2;
            let mut grown: **json_val= (json_val**)a.mmap((u64)(sizeof(json_val*) * (u64)ncap)) catch |e| { };
            if (grown == (json_val**)0) { break; }
            for (let mut gi: i32 = 0; gi < count; gi = gi + 1) grown[gi] = items[gi];
            items = grown;
            cap   = ncap;
        }
        items[count] = parse_value(l, a);
        count = count + 1;
        (*l).skip_ws();
        if ((*l).peek() == ',') { (*l).next(); (*l).skip_ws(); }
        else break;
    }
    (*l).next(); // ]
    (*v).arr_items = items;
    (*v).arr_len   = count;
    return v;
}

fn parse_object(l: *lex, a: &memstr) *json_val {
    (*l).next(); // consume {
    let mut v: *json_val= (json_val*)a.mmap(sizeof(json_val)) catch |e| { };
    (*v).kind = JSON_OBJECT;
    (*v).obj_len = 0;
    (*v).obj_pairs = (json_pair*)0;
    (*l).skip_ws();
    if ((*l).peek() == '}') { (*l).next(); return v; }
    // Allocator-backed and growable — see parse_array for the rationale.
    let mut cap: i32= 16;
    let mut pairs: *json_pair= (json_pair*)a.mmap((u64)(sizeof(json_pair) * (u64)cap)) catch |e| { };
    if (pairs == (json_pair*)0) { return v; }
    let mut count: i32= 0;
    while (true) {
        if (count >= cap) {
            let mut ncap: i32= cap * 2;
            let mut grown: *json_pair= (json_pair*)a.mmap((u64)(sizeof(json_pair) * (u64)ncap)) catch |e| { };
            if (grown == (json_pair*)0) { break; }
            for (let mut gi: i32 = 0; gi < count; gi = gi + 1) grown[gi] = pairs[gi];
            pairs = grown;
            cap   = ncap;
        }
        (*l).skip_ws();
        let mut key: *i8= parse_string_raw(l, a);
        (*l).skip_ws();
        (*l).next(); // :
        (*l).skip_ws();
        let mut val: *json_val= parse_value(l, a);
        pairs[count].key = key;
        pairs[count].val = val;
        count = count + 1;
        (*l).skip_ws();
        if ((*l).peek() == ',') { (*l).next(); }
        else break;
    }
    (*l).next(); // }
    (*v).obj_pairs = pairs;
    (*v).obj_len   = count;
    return v;
}

fn parse_value(l: *lex, a: &memstr) *json_val {
    (*l).skip_ws();
    let mut c: i8= (*l).peek();
    let mut v: *json_val= (json_val*)a.mmap(sizeof(json_val)) catch |e| { };
    if (c == '"') {
        (*v).kind  = JSON_STRING;
        (*v).s_val = parse_string_raw(l, a);
    } else if (c == '{') {
        return parse_object(l, a);
    } else if (c == '[') {
        return parse_array(l, a);
    } else if (c == 't') {
        (*l).pos = (*l).pos + 4; (*v).kind = JSON_BOOL; (*v).b_val = true;
    } else if (c == 'f') {
        (*l).pos = (*l).pos + 5; (*v).kind = JSON_BOOL; (*v).b_val = false;
    } else if (c == 'n') {
        (*l).pos = (*l).pos + 4; (*v).kind = JSON_NULL;
    } else {
        // number
        let mut start: i32= (*l).pos; let mut is_float: bool= false;
        if ((*l).peek() == '-') { (*l).pos = (*l).pos + 1; }
        while ((*l).pos < (*l).len && (*l).src[(*l).pos] >= '0' && (*l).src[(*l).pos] <= '9')
            (*l).pos = (*l).pos + 1;
        if ((*l).pos < (*l).len && (*l).src[(*l).pos] == '.') {
            is_float = true; (*l).pos = (*l).pos + 1;
            while ((*l).pos < (*l).len && (*l).src[(*l).pos] >= '0' && (*l).src[(*l).pos] <= '9')
                (*l).pos = (*l).pos + 1;
        }
        if ((*l).pos < (*l).len && ((*l).src[(*l).pos] == 'e' || (*l).src[(*l).pos] == 'E')) {
            is_float = true; (*l).pos = (*l).pos + 1;
            if ((*l).pos < (*l).len && ((*l).src[(*l).pos] == '+' || (*l).src[(*l).pos] == '-'))
                (*l).pos = (*l).pos + 1;
            while ((*l).pos < (*l).len && (*l).src[(*l).pos] >= '0' && (*l).src[(*l).pos] <= '9')
                (*l).pos = (*l).pos + 1;
        }
        if (is_float) {
            (*v).kind = JSON_FLOAT;
            let mut fv: f64= 0.0; let mut frac: f64= 0.1; let mut after_dot: bool= false; let mut neg: bool= false;
            let mut i: i32= start;
            if ((*l).src[i] == '-') { neg = true; i = i + 1; }
            while (i < (*l).pos) {
                let mut d: i8= (*l).src[i];
                if (d == '.' || d == 'e' || d == 'E') { after_dot = (d == '.'); i = i + 1; continue; }
                if (after_dot) { fv = fv + (f64)(d - '0') * frac; frac = frac * 0.1; }
                else            { fv = fv * 10.0 + (f64)(d - '0'); }
                i = i + 1;
            }
            (*v).f_val = neg ? -fv : fv;
        } else {
            (*v).kind = JSON_INT;
            let mut iv: i64= 0; let mut neg: bool= false; let mut i: i32= start;
            if ((*l).src[i] == '-') { neg = true; i = i + 1; }
            while (i < (*l).pos) { iv = iv * 10 + (i64)((*l).src[i] - '0'); i = i + 1; }
            (*v).i_val = neg ? -iv : iv;
        }
    }
    return v;
}

fn parse(src: *i8, len: i32, a: &memstr) *json_val {
    let mut l: lex(src, len);
    return parse_value(&l, a);
}

fn parse_str(src: *i8, a: &memstr) *json_val {
    let mut n: i32= 0; while (src[n] != 0) n = n + 1;
    return parse(src, n, a);
}

// --- Accessors ---

fn is_null(v: *json_val) bool    { return (*v).kind == JSON_NULL; }
fn is_bool(v: *json_val) bool    { return (*v).kind == JSON_BOOL; }
fn is_int(v: *json_val) bool     { return (*v).kind == JSON_INT; }
fn is_float(v: *json_val) bool   { return (*v).kind == JSON_FLOAT; }
fn is_string(v: *json_val) bool  { return (*v).kind == JSON_STRING; }
fn is_array(v: *json_val) bool   { return (*v).kind == JSON_ARRAY; }
fn is_object(v: *json_val) bool  { return (*v).kind == JSON_OBJECT; }

fn as_bool(v: *json_val) bool   { return (*v).b_val; }
fn as_int(v: *json_val) i64    { return (*v).i_val; }
fn as_float(v: *json_val) f64  { return (*v).f_val; }
fn as_string(v: *json_val) *i8 { return (*v).s_val; }

fn array_at(v: *json_val, i: i32) *json_val   { return (*v).arr_items[i]; }
fn array_len(v: *json_val) i32         { return (*v).arr_len; }

fn object_get(v: *json_val, key: *i8) *json_val {
    for (let mut i: i32 = 0; i < (*v).obj_len; i = i + 1) {
        let mut k: *i8= (*v).obj_pairs[i].key;
        let mut j: i32= 0;
        let mut eq: bool= true;
        while (k[j] != 0 && key[j] != 0) { if (k[j] != key[j]) { eq = false; break; } j = j + 1; }
        if (eq && k[j] == key[j]) { return (*v).obj_pairs[i].val; }
    }
    return (json_val*)0;
}

} // json
} // std
