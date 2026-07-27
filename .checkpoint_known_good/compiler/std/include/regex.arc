// std.regex — In-house NFA-based regular expression engine.
// No external dependencies required.
// ECMAScript-compatible subset:
//   Literals, ., \d\w\s\D\W\S, [...], [^...], *, +, ?, {n}, {n,m},
//   |, (...) capture groups, ^ and $ anchors.
// Up to 10 capture groups per pattern.

namespace std {
namespace regex {

// ---- Public constants ----

comptime u32 REGEX_CASELESS  = 0x00000001u;
comptime u32 REGEX_MULTILINE = 0x00000002u;
comptime u32 REGEX_DOTALL    = 0x00000004u;

comptime i32 REGEX_MAX_CAPTURES = 10;
comptime i32 REGEX_ERROR_NOMATCH = -1;

struct capture_t {
    let start: i32;
    let len: i32;
}

// ---- NFA internals ----

comptime i32 NFA_MAX = 512;

enum nfa_op_t {
    NFA_MATCH  = 0,
    NFA_CHAR   = 1,
    NFA_ANY    = 2,
    NFA_CLASS  = 3,
    NFA_ANCH_S = 4,
    NFA_ANCH_E = 5,
    NFA_SPLIT  = 6,
    NFA_SAVE   = 7,
}

struct nfa_node {
    let op: i32;
    let ch: i8;
    let out1: i32;
    let out2: i32;
    let cls: [16]i8;
    let save_idx: i32;
}

struct nfa_buf {
    let nodes: [512]nfa_node;
    let len: i32;
    let n_groups: i32;
    let caseless: bool;
    let dotall: bool;
    let multiline: bool;
}

struct nfa_frag {
    let start: i32;
    let outs: [32]i32;
    let out_slots: [32]i32;
    let outs_len: i32;
}

fn frag_init(f: *nfa_frag, start: i32) void {
    f.start = start;
    f.outs_len = 0;
}

fn frag_add_out(f: *nfa_frag, node_idx: i32, slot: i32) void {
    if (f.outs_len < 32) {
        f.outs[f.outs_len] = node_idx;
        f.out_slots[f.outs_len] = slot;
        f.outs_len = f.outs_len + 1;
    }
}

fn frag_patch(f: *nfa_frag, buf: *nfa_buf, target: i32) void {
    let mut i: i32= 0;
    while (i < f.outs_len) {
        let mut ni: i32= f.outs[i];
        let mut sl: i32= f.out_slots[i];
        if (sl == 0) { buf.nodes[ni].out1 = target; }
        else         { buf.nodes[ni].out2 = target; }
        i = i + 1;
    }
}

fn nfa_add(buf: *nfa_buf, op: i32, ch: i8, out1: i32, out2: i32) i32 {
    if (buf.len >= NFA_MAX) { return -1; }
    let mut idx: i32= buf.len;
    buf.nodes[idx].op   = op;
    buf.nodes[idx].ch   = ch;
    buf.nodes[idx].out1 = out1;
    buf.nodes[idx].out2 = out2;
    buf.nodes[idx].save_idx = -1;
    let mut ci: i32= 0;
    while (ci < 16) { buf.nodes[idx].cls[ci] = 0; ci = ci + 1; }
    buf.len = buf.len + 1;
    return idx;
}

fn cls_set(cls: *i8, c: i8) void {
    let mut b: i32= (i32)(c & 127);
    cls[b >> 3] = cls[b >> 3] | (i8)(1 << (b & 7));
}

fn cls_get(cls: *i8, c: i8) bool {
    let mut b: i32= (i32)(c & 127);
    return (cls[b >> 3] & (i8)(1 << (b & 7))) != 0;
}

fn cls_set_range(cls: *i8, lo: i8, hi: i8) void {
    let mut c: i8= lo;
    while (c <= hi && (i32)c <= 127) { cls_set(cls, c); c = c + 1; }
}

fn cls_set_escape(cls: *i8, esc: i8, negate: bool) void {
    if (esc == 'd' || esc == 'D') {
        cls_set_range(cls, '0', '9');
    } else if (esc == 'w' || esc == 'W') {
        cls_set_range(cls, 'a', 'z');
        cls_set_range(cls, 'A', 'Z');
        cls_set_range(cls, '0', '9');
        cls_set(cls, '_');
    } else if (esc == 's' || esc == 'S') {
        cls_set(cls, ' '); cls_set(cls, '\t'); cls_set(cls, '\n');
        cls_set(cls, '\r'); cls_set(cls, 12); cls_set(cls, 11);
    }
    if (negate) {
        let mut ci: i32= 0;
        while (ci < 16) { cls[ci] = ~cls[ci]; ci = ci + 1; }
        // ensure bit 0 (null char) is not set for safety
        cls[0] = cls[0] & (i8)0xFE;
    }
}

fn unescape_char(c: i8) i8 {
    if (c == 'n') { return 10; }
    if (c == 't') { return 9; }
    if (c == 'r') { return 13; }
    if (c == '0') { return 0; }
    return c;
}

// ---- Pattern compiler ----

struct compile_ctx {
    let pat: *i8;
    let pos: i32;
    let len: i32;
    let buf: *nfa_buf;
}

fn is_special(c: i8) bool {
    return c=='.' || c=='*' || c=='+' || c=='?' || c=='(' || c==')' ||
           c=='[' || c==']' || c=='^' || c=='$' || c=='|' || c=='{' || c=='\\';
}

fn cc_at_end(cc: *compile_ctx) bool { return cc.pos >= cc.len; }
fn cc_peek(cc: *compile_ctx) i8   { if (cc.pos >= cc.len) { return 0; } return cc.pat[cc.pos]; }
fn cc_adv(cc: *compile_ctx) i8    { let mut c: i8= cc_peek(cc); cc.pos = cc.pos + 1; return c; }

// forward declaration
fn compile_alt(cc: *compile_ctx, depth: i32) nfa_frag;

// Parse a character class [...]
fn compile_class(cc: *compile_ctx) nfa_frag {
    let mut idx: i32= nfa_add(cc.buf, NFA_CLASS, 0, -1, -1);
    let mut f: nfa_frag;
    frag_init(&f, idx);
    frag_add_out(&f, idx, 0);
    if (idx < 0) { return f; }
    let mut cls: *i8= cc.buf.nodes[idx].cls;

    let mut negate: bool= false;
    if (cc_peek(cc) == '^') { cc_adv(cc); negate = true; }

    // Handle ] as first char
    if (cc_peek(cc) == ']') { cls_set(cls, ']'); cc_adv(cc); }

    while (!cc_at_end(cc) && cc_peek(cc) != ']') {
        let mut c: i8= cc_adv(cc);
        if (c == '\\' && !cc_at_end(cc)) {
            let mut esc: i8= cc_adv(cc);
            if (esc=='d' || esc=='D' || esc=='w' || esc=='W' || esc=='s' || esc=='S') {
                let mut tmp: [16]i8;
                let mut ti: i32= 0;
                while (ti < 16) { tmp[ti] = 0; ti = ti + 1; }
                cls_set_escape(tmp, esc, esc>='A' && esc<='Z');
                ti = 0;
                while (ti < 16) { cls[ti] = cls[ti] | tmp[ti]; ti = ti + 1; }
            } else {
                cls_set(cls, unescape_char(esc));
            }
        } else if (!cc_at_end(cc) && cc_peek(cc) == '-' && (cc.pos + 1) < cc.len && cc.pat[cc.pos+1] != ']') {
            cc_adv(cc); // consume -
            let mut hi: i8= cc_adv(cc);
            if (cc.buf.caseless) {
                let mut lo2: i8= c; let mut hi2: i8= hi;
                if (lo2 >= 'A' && lo2 <= 'Z') { lo2 = lo2 + 32; }
                if (hi2 >= 'A' && hi2 <= 'Z') { hi2 = hi2 + 32; }
                cls_set_range(cls, lo2, hi2);
                if (c >= 'a' && c <= 'z') { c = c - 32; }
                if (hi >= 'a' && hi <= 'z') { hi = hi - 32; }
            }
            cls_set_range(cls, c, hi);
        } else {
            if (cc.buf.caseless && c >= 'A' && c <= 'Z') { cls_set(cls, c + 32); }
            if (cc.buf.caseless && c >= 'a' && c <= 'z') { cls_set(cls, c - 32); }
            cls_set(cls, c);
        }
    }
    if (!cc_at_end(cc)) { cc_adv(cc); } // consume ]

    if (negate) {
        let mut ci: i32= 0;
        while (ci < 16) { cls[ci] = ~cls[ci]; ci = ci + 1; }
        cls[0] = cls[0] & (i8)0xFE;
    }
    return f;
}

// Apply a quantifier to frag
fn apply_quant(inner: *nfa_frag, cc: *compile_ctx, q: i8) nfa_frag {
    let mut f: nfa_frag;
    if (q == '*') {
        // SPLIT → inner → back to SPLIT; SPLIT out2 is open
        let mut sp: i32= nfa_add(cc.buf, NFA_SPLIT, 0, inner.start, -1);
        frag_patch(inner, cc.buf, sp);
        frag_init(&f, sp);
        frag_add_out(&f, sp, 1);
    } else if (q == '+') {
        // inner → SPLIT → back to inner.start; SPLIT out2 is open
        let mut sp: i32= nfa_add(cc.buf, NFA_SPLIT, 0, inner.start, -1);
        frag_patch(inner, cc.buf, sp);
        frag_init(&f, inner.start);
        frag_add_out(&f, sp, 1);
    } else { // '?'
        // SPLIT → inner OR skip; both lead to next
        let mut sp: i32= nfa_add(cc.buf, NFA_SPLIT, 0, inner.start, -1);
        frag_init(&f, sp);
        let mut i: i32= 0;
        while (i < inner.outs_len) {
            frag_add_out(&f, inner.outs[i], inner.out_slots[i]);
            i = i + 1;
        }
        frag_add_out(&f, sp, 1);
    }
    return f;
}

fn compile_atom(cc: *compile_ctx, depth: i32) nfa_frag {
    let mut f: nfa_frag;
    f.outs_len = 0;
    f.start = -1;

    if (cc_at_end(cc)) { return f; }
    let mut c: i8= cc_peek(cc);

    if (c == '(') {
        cc_adv(cc);
        let mut grp: i32= cc.buf.n_groups;
        cc.buf.n_groups = cc.buf.n_groups + 1;
        // Save start
        let mut sv_s: i32= nfa_add(cc.buf, NFA_SAVE, 0, -1, -1);
        cc.buf.nodes[sv_s].save_idx = grp * 2;
        let mut body: nfa_frag= compile_alt(cc, depth + 1);
        if (!cc_at_end(cc) && cc_peek(cc) == ')') { cc_adv(cc); }
        // Save end
        let mut sv_e: i32= nfa_add(cc.buf, NFA_SAVE, 0, -1, -1);
        cc.buf.nodes[sv_e].save_idx = grp * 2 + 1;
        // Chain: sv_s → body → sv_e
        cc.buf.nodes[sv_s].out1 = body.start;
        frag_patch(&body, cc.buf, sv_e);
        frag_init(&f, sv_s);
        frag_add_out(&f, sv_e, 0);
    } else if (c == '[') {
        cc_adv(cc);
        f = compile_class(cc);
    } else if (c == '.') {
        cc_adv(cc);
        let mut idx: i32= nfa_add(cc.buf, NFA_ANY, 0, -1, -1);
        frag_init(&f, idx);
        frag_add_out(&f, idx, 0);
    } else if (c == '^') {
        cc_adv(cc);
        let mut idx: i32= nfa_add(cc.buf, NFA_ANCH_S, 0, -1, -1);
        frag_init(&f, idx);
        frag_add_out(&f, idx, 0);
    } else if (c == '$') {
        cc_adv(cc);
        let mut idx: i32= nfa_add(cc.buf, NFA_ANCH_E, 0, -1, -1);
        frag_init(&f, idx);
        frag_add_out(&f, idx, 0);
    } else if (c == '\\' && cc.pos + 1 < cc.len) {
        cc_adv(cc);
        let mut esc: i8= cc_adv(cc);
        if (esc=='d'||esc=='D'||esc=='w'||esc=='W'||esc=='s'||esc=='S') {
            let mut idx: i32= nfa_add(cc.buf, NFA_CLASS, 0, -1, -1);
            let mut cls: *i8= cc.buf.nodes[idx].cls;
            let mut is_neg: bool= esc>='A' && esc<='Z';
            cls_set_escape(cls, esc, is_neg);
            frag_init(&f, idx);
            frag_add_out(&f, idx, 0);
        } else {
            let mut lc: i8= unescape_char(esc);
            let mut idx: i32= nfa_add(cc.buf, NFA_CHAR, lc, -1, -1);
            frag_init(&f, idx);
            frag_add_out(&f, idx, 0);
        }
    } else if (!is_special(c)) {
        cc_adv(cc);
        let mut lc: i8= c;
        if (cc.buf.caseless && lc>='A' && lc<='Z') { lc = lc + 32; }
        let mut idx: i32= nfa_add(cc.buf, NFA_CHAR, lc, -1, -1);
        frag_init(&f, idx);
        frag_add_out(&f, idx, 0);
    }
    return f;
}

fn compile_piece(cc: *compile_ctx, depth: i32) nfa_frag {
    let mut atom: nfa_frag= compile_atom(cc, depth);
    if (atom.start < 0) { return atom; }
    if (cc_at_end(cc)) { return atom; }
    let mut q: i8= cc_peek(cc);
    if (q == '*' || q == '+' || q == '?') {
        cc_adv(cc);
        return apply_quant(&atom, cc, q);
    }
    if (q == '{') {
        // {n}, {n,}, {n,m}
        cc_adv(cc); // consume {
        let mut lo: i32= 0; let mut hi: i32= 0; let mut has_hi: bool= false;
        while (!cc_at_end(cc) && cc_peek(cc) >= '0' && cc_peek(cc) <= '9') {
            lo = lo * 10 + (i32)(cc_adv(cc) - '0');
        }
        hi = lo;
        if (!cc_at_end(cc) && cc_peek(cc) == ',') {
            cc_adv(cc);
            has_hi = true;
            hi = 0;
            if (!cc_at_end(cc) && cc_peek(cc) != '}') {
                while (!cc_at_end(cc) && cc_peek(cc) >= '0' && cc_peek(cc) <= '9') {
                    hi = hi * 10 + (i32)(cc_adv(cc) - '0');
                }
            } else {
                hi = -1; // unbounded
            }
        }
        if (!cc_at_end(cc) && cc_peek(cc) == '}') { cc_adv(cc); }
        // Expand: a{3} → aaa, a{2,4} → aaa?a?
        // For simplicity, expand up to 8 repetitions then use * for rest
        // Save atom start in buf for re-use
        let mut atom_start: i32= atom.start;
        let mut result: nfa_frag= atom;
        // Chain lo-1 additional required copies of the atom
        let mut rep: i32= 1;
        while (rep < lo) {
            frag_patch(&result, cc.buf, atom_start);
            rep = rep + 1;
        }
        if (hi == -1) {
            // {n,}: at least n, then unbounded — chain * after required copies
            let mut star: nfa_frag= apply_quant(&result, cc, '*');
            return star;
        } else if (has_hi && hi > lo) {
            // {n,m}: chain hi-lo optional copies after the required ones
            let mut opt_rep: i32= 0;
            while (opt_rep < hi - lo) {
                let mut opt: nfa_frag= apply_quant(&result, cc, '?');
                result = opt;
                opt_rep = opt_rep + 1;
            }
        }
        return result;
    }
    return atom;
}

fn compile_concat(cc: *compile_ctx, depth: i32) nfa_frag {
    let mut head: nfa_frag;
    head.start = -1;
    head.outs_len = 0;
    let mut first: bool= true;

    while (!cc_at_end(cc)) {
        let mut c: i8= cc_peek(cc);
        if (c == ')' || c == '|') { break; }

        let mut piece: nfa_frag= compile_piece(cc, depth);
        if (piece.start < 0) { break; }

        if (first) {
            head = piece;
            first = false;
        } else {
            frag_patch(&head, cc.buf, piece.start);
            head.start  = head.start;
            head.outs_len = piece.outs_len;
            let mut i: i32= 0;
            while (i < piece.outs_len) {
                head.outs[i]      = piece.outs[i];
                head.out_slots[i] = piece.out_slots[i];
                i = i + 1;
            }
        }
    }
    return head;
}

fn compile_alt(cc: *compile_ctx, depth: i32) nfa_frag {
    let mut lhs: nfa_frag= compile_concat(cc, depth);
    if (cc_at_end(cc) || cc_peek(cc) != '|') { return lhs; }

    cc_adv(cc); // consume |
    let mut rhs: nfa_frag= compile_alt(cc, depth);

    // Build SPLIT → (lhs | rhs)
    let mut sp: i32= nfa_add(cc.buf, NFA_SPLIT, 0,
                     lhs.start >= 0 ? lhs.start : -1,
                     rhs.start >= 0 ? rhs.start : -1);
    let mut f: nfa_frag;
    frag_init(&f, sp);
    // All open outs from both sides
    let mut i: i32= 0;
    while (i < lhs.outs_len) { frag_add_out(&f, lhs.outs[i], lhs.out_slots[i]); i = i + 1; }
    i = 0;
    while (i < rhs.outs_len) { frag_add_out(&f, rhs.outs[i], rhs.out_slots[i]); i = i + 1; }
    return f;
}

// ---- NFA simulator ----

comptime i32 SIM_MAX = 512;

struct sim_state {
    let nfa_idx: i32;
    let caps: [20]i32; // REGEX_MAX_CAPTURES * 2 start/end pairs
}

struct sim_ctx {
    let cur: [512]sim_state;
    let nxt: [512]sim_state;
    let cur_len: i32;
    let nxt_len: i32;
    let visited: [512]bool;
}

fn sim_add(sc: *sim_ctx, arr_is_nxt: i32, nfa_idx: i32, caps: *i32, buf: *nfa_buf, text: *i8, tlen: i32, pos: i32) void {
    if (nfa_idx < 0 || nfa_idx >= buf.len) { return; }
    if (sc.visited[nfa_idx]) { return; }
    sc.visited[nfa_idx] = true;

    let mut nd: *nfa_node= &buf.nodes[nfa_idx];
    if (nd.op == NFA_SPLIT) {
        sim_add(sc, arr_is_nxt, nd.out1, caps, buf, text, tlen, pos);
        sim_add(sc, arr_is_nxt, nd.out2, caps, buf, text, tlen, pos);
        return;
    }
    if (nd.op == NFA_SAVE) {
        let mut new_caps: [20]i32;
        let mut ci: i32= 0;
        while (ci < 20) { new_caps[ci] = caps[ci]; ci = ci + 1; }
        if (nd.save_idx >= 0 && nd.save_idx < 20) { new_caps[nd.save_idx] = pos; }
        sim_add(sc, arr_is_nxt, nd.out1, new_caps, buf, text, tlen, pos);
        return;
    }
    if (nd.op == NFA_ANCH_S) {
        let mut ok: bool= (pos == 0) || (buf.multiline && pos > 0 && text[pos-1] == '\n');
        if (!ok) { return; }
        sim_add(sc, arr_is_nxt, nd.out1, caps, buf, text, tlen, pos);
        return;
    }
    if (nd.op == NFA_ANCH_E) {
        let mut ok: bool= (pos == tlen) || (buf.multiline && pos < tlen && text[pos] == '\n');
        if (!ok) { return; }
        sim_add(sc, arr_is_nxt, nd.out1, caps, buf, text, tlen, pos);
        return;
    }

    // Real state: add to current or next list
    let mut arr: *sim_state= arr_is_nxt != 0 ? sc.nxt : sc.cur;
    let mut arr_len: *i32= arr_is_nxt != 0 ? &sc.nxt_len : &sc.cur_len;
    if (*arr_len < SIM_MAX) {
        arr[*arr_len].nfa_idx = nfa_idx;
        let mut ci: i32= 0;
        while (ci < 20) { arr[*arr_len].caps[ci] = caps[ci]; ci = ci + 1; }
        *arr_len = *arr_len + 1;
    }
}

fn char_matches(nd: *nfa_node, c: i8, caseless: bool) bool {
    if (nd.op == NFA_CHAR) {
        if (caseless) {
            let mut lc: i8= c; let mut lp: i8= nd.ch;
            if (lc >= 'A' && lc <= 'Z') { lc = lc + 32; }
            if (lp >= 'A' && lp <= 'Z') { lp = lp + 32; }
            return lc == lp;
        }
        return c == nd.ch;
    }
    if (nd.op == NFA_ANY) {
        return c != '\n' || false; // DOTALL handled outside
    }
    if (nd.op == NFA_CLASS) {
        return cls_get(nd.cls, c);
    }
    return false;
}

// Run NFA from start_node on text[start..tlen], storing captures in caps[0..19].
// Returns end position of match, or -1 if no match.
fn nfa_run(buf: *nfa_buf, start_node: i32, text: *i8, tlen: i32, start: i32, out_caps: *i32) i32 {
    let mut sc: sim_ctx;
    sc.cur_len = 0;
    sc.nxt_len = 0;
    let mut ii: i32= 0;
    while (ii < SIM_MAX) { sc.visited[ii] = false; ii = ii + 1; }

    let mut init_caps: [20]i32;
    let mut ci: i32= 0;
    while (ci < 20) { init_caps[ci] = -1; ci = ci + 1; }

    sim_add(&sc, 0, start_node, init_caps, buf, text, tlen, start);

    let mut match_end: i32= -1;
    let mut match_caps: [20]i32;
    ci = 0;
    while (ci < 20) { match_caps[ci] = -1; ci = ci + 1; }

    // Check for accept in initial state (zero-width match)
    let mut si: i32= 0;
    while (si < sc.cur_len) {
        if (buf.nodes[sc.cur[si].nfa_idx].op == NFA_MATCH) {
            match_end = start;
            ci = 0;
            while (ci < 20) { match_caps[ci] = sc.cur[si].caps[ci]; ci = ci + 1; }
        }
        si = si + 1;
    }

    let mut pos: i32= start;
    while (pos < tlen && sc.cur_len > 0) {
        let mut ch: i8= text[pos];
        sc.nxt_len = 0;
        ii = 0;
        while (ii < SIM_MAX) { sc.visited[ii] = false; ii = ii + 1; }

        si = 0;
        while (si < sc.cur_len) {
            let mut ni: i32= sc.cur[si].nfa_idx;
            let mut nd: *nfa_node= &buf.nodes[ni];
            let mut ok: bool= false;
            if (nd.op == NFA_CHAR || nd.op == NFA_CLASS) {
                ok = char_matches(nd, ch, buf.caseless);
            } else if (nd.op == NFA_ANY) {
                ok = ch != '\n' || buf.dotall;
            }
            if (ok) {
                sim_add(&sc, 1, nd.out1, sc.cur[si].caps, buf, text, tlen, pos + 1);
            }
            si = si + 1;
        }

        pos = pos + 1;

        // Move nxt → cur for next iteration
        sc.cur_len = sc.nxt_len;
        ii = 0;
        while (ii < sc.cur_len && ii < SIM_MAX) {
            sc.cur[ii] = sc.nxt[ii];
            ii = ii + 1;
        }
        sc.nxt_len = 0;

        si = 0;
        while (si < sc.cur_len) {
            if (buf.nodes[sc.cur[si].nfa_idx].op == NFA_MATCH) {
                match_end = pos;
                ci = 0;
                while (ci < 20) { match_caps[ci] = sc.cur[si].caps[ci]; ci = ci + 1; }
            }
            si = si + 1;
        }
    }

    if (match_end >= 0 && out_caps != (i32*)0) {
        ci = 0;
        while (ci < 20) { out_caps[ci] = match_caps[ci]; ci = ci + 1; }
    }
    return match_end;
}

// ---- regex_t istruc ----

istruc regex_t {
    let mut _buf: nfa_buf;
    let mut _start: i32;
    let mut _valid: bool;

    fn __construct__(self: *regex_t, pattern: *i8, options: u32) void {
        self._buf.len      = 0;
        self._buf.n_groups = 0;
        self._buf.caseless  = (options & REGEX_CASELESS)  != 0u;
        self._buf.dotall    = (options & REGEX_DOTALL)    != 0u;
        self._buf.multiline = (options & REGEX_MULTILINE) != 0u;
        self._valid = false;
        self._start = -1;
        if (pattern == (i8*)0) { return; }
        let mut plen: i32= 0;
        while (pattern[plen] != 0) { plen = plen + 1; }
        let mut cc: compile_ctx;
        cc.pat = pattern;
        cc.pos = 0;
        cc.len = plen;
        cc.buf = &self._buf;
        let mut f: nfa_frag= compile_alt(&cc, 0);
        if (f.start < 0) { return; }
        let mut match_node: i32= nfa_add(&self._buf, NFA_MATCH, 0, -1, -1);
        frag_patch(&f, &self._buf, match_node);
        self._start = f.start;
        self._valid = true;
    }

    fn is_valid(self: *regex_t) bool { return self._valid; }

    fn match_at(self: *regex_t, subject: *i8, slen: i32, start: i32, cap: *capture_t, cap_cap: i32, cap_count: *i32) bool {
        if (!self._valid || subject == (i8*)0) { if (cap_count != (i32*)0) { *cap_count = 0; } return false; }
        let mut raw_caps: [20]i32;
        let mut end: i32= nfa_run(&self._buf, self._start, subject, slen, start, raw_caps);
        if (end < 0) { if (cap_count != (i32*)0) { *cap_count = 0; } return false; }
        if (cap != (capture_t*)0 && cap_cap > 0) {
            cap[0].start = start;
            cap[0].len   = end - start;
            let mut g: i32= 1;
            while (g < cap_cap && g <= self._buf.n_groups) {
                let mut gs: i32= raw_caps[(g-1)*2];
                let mut ge: i32= raw_caps[(g-1)*2+1];
                if (gs < 0 || ge < 0) { cap[g].start = -1; cap[g].len = 0; }
                else { cap[g].start = gs; cap[g].len = ge - gs; }
                g = g + 1;
            }
            if (cap_count != (i32*)0) { *cap_count = g; }
        } else {
            if (cap_count != (i32*)0) { *cap_count = 0; }
        }
        return true;
    }

    fn test(self: *regex_t, subject: *i8, slen: i32) bool {
        if (!self._valid || subject == (i8*)0) { return false; }
        // Try starting at every position
        let mut pos: i32= 0;
        while (pos <= slen) {
            let mut end: i32= nfa_run(&self._buf, self._start, subject, slen, pos, (i32*)0);
            if (end >= 0) { return true; }
            pos = pos + 1;
        }
        return false;
    }

    fn find(self: *regex_t, subject: *i8, slen: i32, cap: *capture_t, cap_cap: i32, cap_count: *i32) bool {
        if (!self._valid || subject == (i8*)0) { if (cap_count != (i32*)0) { *cap_count = 0; } return false; }
        let mut pos: i32= 0;
        while (pos <= slen) {
            let mut raw_caps: [20]i32;
            let mut end: i32= nfa_run(&self._buf, self._start, subject, slen, pos, raw_caps);
            if (end >= 0) {
                if (cap != (capture_t*)0 && cap_cap > 0) {
                    cap[0].start = pos;
                    cap[0].len   = end - pos;
                    let mut g: i32= 1;
                    while (g < cap_cap && g <= self._buf.n_groups) {
                        let mut gs: i32= raw_caps[(g-1)*2];
                        let mut ge: i32= raw_caps[(g-1)*2+1];
                        if (gs < 0 || ge < 0) { cap[g].start = -1; cap[g].len = 0; }
                        else { cap[g].start = gs; cap[g].len = ge - gs; }
                        g = g + 1;
                    }
                    if (cap_count != (i32*)0) { *cap_count = g; }
                }
                return true;
            }
            pos = pos + 1;
        }
        if (cap_count != (i32*)0) { *cap_count = 0; }
        return false;
    }

    fn free(self: *regex_t) void { self._valid = false; }
}

// ---- Standalone helpers ----

fn test(pattern: *i8, subject: *i8, slen: i32, options: u32) bool {
    let mut re: regex_t(pattern, options);
    if (!re.is_valid()) { return false; }
    return re.test(subject, slen);
}

fn find_offset(pattern: *i8, subject: *i8, slen: i32, options: u32) i32 {
    let mut re: regex_t(pattern, options);
    if (!re.is_valid()) { return -1; }
    let mut cap: [1]capture_t;
    let mut n: i32= 0;
    let mut ok: bool= re.find(subject, slen, cap, 1, &n);
    return ok ? cap[0].start : -1;
}

} // namespace regex
} // namespace std
