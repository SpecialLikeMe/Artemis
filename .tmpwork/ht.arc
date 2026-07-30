extern std.fmt;
@unsafe extern fn snprintf(b: *i8, n: u64, f: *i8, ...) i32;
@unsafe extern fn strcmp(a: *i8, b: *i8) i32;
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn realloc(p: *void, n: u64) *void;

fn str_hash32(s: *i8) u32 {
    if (s == (i8*)0) { return 0u; }
    let mut h: u32= 2166136261u;
    let mut i: i32= 0;
    while (s[i] != 0) { h = h ^ (u32)(u8)s[i]; h = h * 16777619u; i = i + 1; }
    return h;
}
fn hash_cap_for(n: i32) i32 { let mut c: i32= 64; while (c < n && c < 268435456) { c = c * 2; } return c; }

struct ent { let name: *i8; let depth: i32; let val: i32; }
struct tbl { let e: *ent; let len: i32; let cap: i32; let head: *i32; let next: *i32; let nb: i32; }

fn t_init(t: *tbl) void { t.e=(ent*)0; t.len=0; t.cap=0; t.head=(i32*)0; t.next=(i32*)0; t.nb=0; }
fn t_bucket(t: *tbl, n: *i8) i32 { let mut r: i32; @unsafe { r = (i32)(str_hash32(n) & (u32)(t.nb - 1)); } return r; }
fn t_reindex(t: *tbl, nb: i32) void {
    t.nb = nb;
    @unsafe { t.head = (i32*)realloc((void*)t.head, (u64)(4 * nb)); }
    let mut b: i32= 0; while (b < nb) { t.head[b] = -1; b = b + 1; }
    let mut i: i32= 0;
    while (i < t.len) { let mut h: i32= t_bucket(t, t.e[i].name); t.next[i] = t.head[h]; t.head[h] = i; i = i + 1; }
}
fn t_push(t: *tbl, name: *i8, depth: i32, val: i32) void {
    if (t.len >= t.cap) {
        let mut nc: i32= t.cap == 0 ? 32 : t.cap * 2;
        @unsafe { t.e = (ent*)realloc((void*)t.e, (u64)(16 * nc)); t.next = (i32*)realloc((void*)t.next, (u64)(4 * nc)); }
        t.cap = nc;
    }
    t.e[t.len].name = name; t.e[t.len].depth = depth; t.e[t.len].val = val;
    if (t.nb == 0 || t.len + 1 > t.nb) { t_reindex(t, hash_cap_for(t.len + 1)); }
    let mut h: i32= t_bucket(t, name);
    t.next[t.len] = t.head[h]; t.head[h] = t.len; t.len = t.len + 1;
}
fn t_find(t: *tbl, name: *i8) i32 {
    if (t.nb == 0 || name == (i8*)0) { return -1; }
    let mut h: i32= t_bucket(t, name);
    let mut i: i32= t.head[h];
    while (i >= 0) {
        let mut c: i32; @unsafe { c = strcmp(t.e[i].name, name); }
        if (i < t.len && c == 0) { return i; }
        i = t.next[i];
    }
    return -1;
}
// reference: backwards linear scan
fn t_find_ref(t: *tbl, name: *i8) i32 {
    let mut i: i32= t.len - 1;
    while (i >= 0) {
        let mut c: i32; @unsafe { c = strcmp(t.e[i].name, name); }
        if (c == 0) { return i; }
        i = i - 1;
    }
    return -1;
}
fn t_pop(t: *tbl, depth: i32) void {
    let mut nl: i32= 0; let mut i: i32= 0;
    while (i < t.len) { if (t.e[i].depth < depth) { nl = nl + 1; } i = i + 1; }
    // Unlink each dead entry from its bucket, newest first: after the larger dead
    // indices are gone, a dead index is the head of its bucket if it is in it at all.
    let mut j: i32= t.len - 1;
    while (j >= nl) {
        let mut h: i32= t_bucket(t, t.e[j].name);
        if (t.head[h] == j) { t.head[h] = t.next[j]; }
        j = j - 1;
    }
    t.len = nl;
}

let mut names: [20000]*i8;

pub fn main() i32 {
    let mut buf: *i8;
    let mut i: i32= 0;
    while (i < 20000) {
        @unsafe { buf = (i8*)malloc(32u); snprintf(buf, 32u, "sym_%d", i % 120); }
        names[i] = buf;
        i = i + 1;
    }
    let mut t: tbl; t_init(&t);
    // interleave pushes at increasing depth, pops, and shadowing re-declarations
    let mut d: i32= 0;
    let mut k: i32= 0;
    let mut checks: i32= 0;
    while (k < 20000) {
        t_push(&t, names[k], d, k);
        if (k % 2 == 0) { d = d + 1; }
        if (k % 5 == 0 && d > 0) { t_pop(&t, d); d = d - 1; }
        if (k % 97 == 0 && d > 3) { t_pop(&t, d); t_pop(&t, d-1); t_pop(&t, d-2); d = d - 3; }
        if (k % 2 == 0) {
            let mut q: i32= (k * 37) % 20000;
            let mut a: i32= t_find(&t, names[q]);
            let mut b: i32= t_find_ref(&t, names[q]);
            if (a != b) { std.fmt.out_print("MISMATCH at k="); std.fmt.out_print_i32(k);
                          std.fmt.out_print(" got "); std.fmt.out_print_i32(a);
                          std.fmt.out_print(" want "); std.fmt.out_print_i32(b); std.fmt.out_println(""); return 1; }
            checks = checks + 1;
        }
        k = k + 1;
    }
    std.fmt.out_print("checks OK: "); std.fmt.out_print_i32(checks); std.fmt.out_println("");
    return 0;
}
