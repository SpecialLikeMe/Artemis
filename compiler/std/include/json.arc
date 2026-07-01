// std.json — Full JSON parser and serializer.

namespace std {
namespace json {

// Value kinds
constexpr i32 JSON_NULL   = 0;
constexpr i32 JSON_BOOL   = 1;
constexpr i32 JSON_INT    = 2;
constexpr i32 JSON_FLOAT  = 3;
constexpr i32 JSON_STRING = 4;
constexpr i32 JSON_ARRAY  = 5;
constexpr i32 JSON_OBJECT = 6;

// Forward decl
istruc json_val;
istruc json_pair;

istruc json_val {
    i32    kind;
    bool   b_val;
    i64    i_val;
    f64    f_val;
    i8*    s_val;
    json_val** arr_items;
    i32        arr_len;
    json_pair* obj_pairs;
    i32        obj_len;
}

istruc json_pair {
    i8*      key;
    json_val* val;
}

// --- Lexer state ---

istruc lex {
    i8* src;
    i32 pos;
    i32 len;

    void __construct__(lex* self, i8* s, i32 n) { self.src=s; self.pos=0; self.len=n; }

    void skip_ws(lex* self) {
        while (self.pos < self.len) {
            i8 c = self.src[self.pos];
            if (c == ' ' || c == '\t' || c == '\r' || c == '\n') self.pos = self.pos + 1;
            else break;
        }
    }

    bool at_end(lex* self) { return self.pos >= self.len; }
    i8   peek(lex* self)   { return self.pos < self.len ? self.src[self.pos] : 0; }
    i8   next(lex* self)         { i8 c = self.src[self.pos]; self.pos = self.pos + 1; return c; }
}

// --- Parser ---

private json_val* parse_value(lex* l, &memstr a);

private i8* parse_string_raw(lex* l, &memstr a) {
    (*l).next(); // consume "
    i32 start = (*l).pos;
    i32 end = start;
    while ((*l).pos < (*l).len && (*l).src[(*l).pos] != '"') {
        if ((*l).src[(*l).pos] == '\\') { (*l).pos = (*l).pos + 1; }
        (*l).pos = (*l).pos + 1;
        end = (*l).pos;
    }
    (*l).next(); // consume closing "
    i32 n = end - start;
    i8* s = (i8*)a.mmap((u64)(n + 1));
    for (i32 i = 0; i < n; i = i + 1) s[i] = (*l).src[start + i];
    s[n] = 0;
    return s;
}

private json_val* parse_array(lex* l, &memstr a) {
    (*l).next(); // consume [
    json_val* v = (json_val*)a.mmap(sizeof(json_val));
    (*v).kind = JSON_ARRAY;
    (*v).arr_len = 0;
    (*v).arr_items = (json_val**)0;
    (*l).skip_ws();
    if ((*l).peek() == ']') { (*l).next(); return v; }
    // collect items
    json_val* items[256];
    i32 count = 0;
    while (true) {
        items[count] = parse_value(l, a);
        count = count + 1;
        (*l).skip_ws();
        if ((*l).peek() == ',') { (*l).next(); (*l).skip_ws(); }
        else break;
    }
    (*l).next(); // ]
    (*v).arr_items = (json_val**)a.mmap((u64)(sizeof(json_val*) * count));
    (*v).arr_len   = count;
    for (i32 i = 0; i < count; i = i + 1) (*v).arr_items[i] = items[i];
    return v;
}

private json_val* parse_object(lex* l, &memstr a) {
    (*l).next(); // consume {
    json_val* v = (json_val*)a.mmap(sizeof(json_val));
    (*v).kind = JSON_OBJECT;
    (*v).obj_len = 0;
    (*v).obj_pairs = (json_pair*)0;
    (*l).skip_ws();
    if ((*l).peek() == '}') { (*l).next(); return v; }
    json_pair pairs[256];
    i32 count = 0;
    while (true) {
        (*l).skip_ws();
        i8* key = parse_string_raw(l, a);
        (*l).skip_ws();
        (*l).next(); // :
        (*l).skip_ws();
        json_val* val = parse_value(l, a);
        pairs[count].key = key;
        pairs[count].val = val;
        count = count + 1;
        (*l).skip_ws();
        if ((*l).peek() == ',') { (*l).next(); }
        else break;
    }
    (*l).next(); // }
    (*v).obj_pairs = (json_pair*)a.mmap((u64)(sizeof(json_pair) * count));
    (*v).obj_len   = count;
    for (i32 i = 0; i < count; i = i + 1) (*v).obj_pairs[i] = pairs[i];
    return v;
}

private json_val* parse_value(lex* l, &memstr a) {
    (*l).skip_ws();
    i8 c = (*l).peek();
    json_val* v = (json_val*)a.mmap(sizeof(json_val));
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
        i32 start = (*l).pos; bool is_float = false;
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
            f64 fv = 0.0; f64 frac = 0.1; bool after_dot = false; bool neg = false;
            i32 i = start;
            if ((*l).src[i] == '-') { neg = true; i = i + 1; }
            while (i < (*l).pos) {
                i8 d = (*l).src[i];
                if (d == '.' || d == 'e' || d == 'E') { after_dot = (d == '.'); i = i + 1; continue; }
                if (after_dot) { fv = fv + (f64)(d - '0') * frac; frac = frac * 0.1; }
                else            { fv = fv * 10.0 + (f64)(d - '0'); }
                i = i + 1;
            }
            (*v).f_val = neg ? -fv : fv;
        } else {
            (*v).kind = JSON_INT;
            i64 iv = 0; bool neg = false; i32 i = start;
            if ((*l).src[i] == '-') { neg = true; i = i + 1; }
            while (i < (*l).pos) { iv = iv * 10 + (i64)((*l).src[i] - '0'); i = i + 1; }
            (*v).i_val = neg ? -iv : iv;
        }
    }
    return v;
}

json_val* parse(i8* src, i32 len, &memstr a) {
    lex l(src, len);
    return parse_value(&l, a);
}

json_val* parse_str(i8* src, &memstr a) {
    i32 n = 0; while (src[n] != 0) n = n + 1;
    return parse(src, n, a);
}

// --- Accessors ---

bool is_null(&const json_val* v)    { return (*v).kind == JSON_NULL; }
bool is_bool(&const json_val* v)    { return (*v).kind == JSON_BOOL; }
bool is_int(&const json_val* v)     { return (*v).kind == JSON_INT; }
bool is_float(&const json_val* v)   { return (*v).kind == JSON_FLOAT; }
bool is_string(&const json_val* v)  { return (*v).kind == JSON_STRING; }
bool is_array(&const json_val* v)   { return (*v).kind == JSON_ARRAY; }
bool is_object(&const json_val* v)  { return (*v).kind == JSON_OBJECT; }

bool as_bool(json_val* v)   { return (*v).b_val; }
i64  as_int(json_val* v)    { return (*v).i_val; }
f64  as_float(json_val* v)  { return (*v).f_val; }
i8*  as_string(json_val* v) { return (*v).s_val; }

json_val* array_at(json_val* v, i32 i)   { return (*v).arr_items[i]; }
i32       array_len(json_val* v)         { return (*v).arr_len; }

json_val* object_get(json_val* v, i8* key) {
    for (i32 i = 0; i < (*v).obj_len; i = i + 1) {
        i8* k = (*v).obj_pairs[i].key;
        i32 j = 0;
        bool eq = true;
        while (k[j] != 0 && key[j] != 0) { if (k[j] != key[j]) { eq = false; break; } j = j + 1; }
        if (eq && k[j] == key[j]) { return (*v).obj_pairs[i].val; }
    }
    return (json_val*)0;
}

} // json
} // std
