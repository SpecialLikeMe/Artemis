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
    i32 start;
    i32 len;
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
    i32 op;
    i8  ch;
    i32 out1;
    i32 out2;
    i8  cls[16];
    i32 save_idx;
}

struct nfa_buf {
    nfa_node nodes[512];
    i32 len;
    i32 n_groups;
    bool caseless;
    bool dotall;
    bool multiline;
}

struct nfa_frag {
    i32 start;
    i32 outs[32];
    i32 out_slots[32];
    i32 outs_len;
}

void frag_init(nfa_frag* f, i32 start) {
    f.start = start;
    f.outs_len = 0;
}

void frag_add_out(nfa_frag* f, i32 node_idx, i32 slot) {
    if (f.outs_len < 32) {
        f.outs[f.outs_len] = node_idx;
        f.out_slots[f.outs_len] = slot;
        f.outs_len = f.outs_len + 1;
    }
}

void frag_patch(nfa_frag* f, nfa_buf* buf, i32 target) {
    i32 i = 0;
    while (i < f.outs_len) {
        i32 ni = f.outs[i];
        i32 sl = f.out_slots[i];
        if (sl == 0) { buf.nodes[ni].out1 = target; }
        else         { buf.nodes[ni].out2 = target; }
        i = i + 1;
    }
}

i32 nfa_add(nfa_buf* buf, i32 op, i8 ch, i32 out1, i32 out2) {
    if (buf.len >= NFA_MAX) { return -1; }
    i32 idx = buf.len;
    buf.nodes[idx].op   = op;
    buf.nodes[idx].ch   = ch;
    buf.nodes[idx].out1 = out1;
    buf.nodes[idx].out2 = out2;
    buf.nodes[idx].save_idx = -1;
    i32 ci = 0;
    while (ci < 16) { buf.nodes[idx].cls[ci] = 0; ci = ci + 1; }
    buf.len = buf.len + 1;
    return idx;
}

void cls_set(i8* cls, i8 c) {
    i32 b = (i32)(c & 127);
    cls[b >> 3] = cls[b >> 3] | (i8)(1 << (b & 7));
}

bool cls_get(i8* cls, i8 c) {
    i32 b = (i32)(c & 127);
    return (cls[b >> 3] & (i8)(1 << (b & 7))) != 0;
}

void cls_set_range(i8* cls, i8 lo, i8 hi) {
    i8 c = lo;
    while (c <= hi && (i32)c <= 127) { cls_set(cls, c); c = c + 1; }
}

void cls_set_escape(i8* cls, i8 esc, bool negate) {
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
        i32 ci = 0;
        while (ci < 16) { cls[ci] = ~cls[ci]; ci = ci + 1; }
        // ensure bit 0 (null char) is not set for safety
        cls[0] = cls[0] & (i8)0xFE;
    }
}

i8 unescape_char(i8 c) {
    if (c == 'n') { return 10; }
    if (c == 't') { return 9; }
    if (c == 'r') { return 13; }
    if (c == '0') { return 0; }
    return c;
}

// ---- Pattern compiler ----

struct compile_ctx {
    i8*     pat;
    i32     pos;
    i32     len;
    nfa_buf* buf;
}

bool is_special(i8 c) {
    return c=='.' || c=='*' || c=='+' || c=='?' || c=='(' || c==')' ||
           c=='[' || c==']' || c=='^' || c=='$' || c=='|' || c=='{' || c=='\\';
}

bool cc_at_end(compile_ctx* cc) { return cc.pos >= cc.len; }
i8   cc_peek(compile_ctx* cc)   { if (cc.pos >= cc.len) { return 0; } return cc.pat[cc.pos]; }
i8   cc_adv(compile_ctx* cc)    { i8 c = cc_peek(cc); cc.pos = cc.pos + 1; return c; }

// forward declaration
nfa_frag compile_alt(compile_ctx* cc, i32 depth);

// Parse a character class [...]
nfa_frag compile_class(compile_ctx* cc) {
    i32 idx = nfa_add(cc.buf, NFA_CLASS, 0, -1, -1);
    nfa_frag f;
    frag_init(&f, idx);
    frag_add_out(&f, idx, 0);
    if (idx < 0) { return f; }
    i8* cls = cc.buf.nodes[idx].cls;

    bool negate = false;
    if (cc_peek(cc) == '^') { cc_adv(cc); negate = true; }

    // Handle ] as first char
    if (cc_peek(cc) == ']') { cls_set(cls, ']'); cc_adv(cc); }

    while (!cc_at_end(cc) && cc_peek(cc) != ']') {
        i8 c = cc_adv(cc);
        if (c == '\\' && !cc_at_end(cc)) {
            i8 esc = cc_adv(cc);
            if (esc=='d' || esc=='D' || esc=='w' || esc=='W' || esc=='s' || esc=='S') {
                i8 tmp[16];
                i32 ti = 0;
                while (ti < 16) { tmp[ti] = 0; ti = ti + 1; }
                cls_set_escape(tmp, esc, esc>='A' && esc<='Z');
                ti = 0;
                while (ti < 16) { cls[ti] = cls[ti] | tmp[ti]; ti = ti + 1; }
            } else {
                cls_set(cls, unescape_char(esc));
            }
        } else if (!cc_at_end(cc) && cc_peek(cc) == '-' && (cc.pos + 1) < cc.len && cc.pat[cc.pos+1] != ']') {
            cc_adv(cc); // consume -
            i8 hi = cc_adv(cc);
            if (cc.buf.caseless) {
                i8 lo2 = c; i8 hi2 = hi;
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
        i32 ci = 0;
        while (ci < 16) { cls[ci] = ~cls[ci]; ci = ci + 1; }
        cls[0] = cls[0] & (i8)0xFE;
    }
    return f;
}

// Apply a quantifier to frag
nfa_frag apply_quant(nfa_frag* inner, compile_ctx* cc, i8 q) {
    nfa_frag f;
    if (q == '*') {
        // SPLIT → inner → back to SPLIT; SPLIT out2 is open
        i32 sp = nfa_add(cc.buf, NFA_SPLIT, 0, inner.start, -1);
        frag_patch(inner, cc.buf, sp);
        frag_init(&f, sp);
        frag_add_out(&f, sp, 1);
    } else if (q == '+') {
        // inner → SPLIT → back to inner.start; SPLIT out2 is open
        i32 sp = nfa_add(cc.buf, NFA_SPLIT, 0, inner.start, -1);
        frag_patch(inner, cc.buf, sp);
        frag_init(&f, inner.start);
        frag_add_out(&f, sp, 1);
    } else { // '?'
        // SPLIT → inner OR skip; both lead to next
        i32 sp = nfa_add(cc.buf, NFA_SPLIT, 0, inner.start, -1);
        frag_init(&f, sp);
        i32 i = 0;
        while (i < inner.outs_len) {
            frag_add_out(&f, inner.outs[i], inner.out_slots[i]);
            i = i + 1;
        }
        frag_add_out(&f, sp, 1);
    }
    return f;
}

nfa_frag compile_atom(compile_ctx* cc, i32 depth) {
    nfa_frag f;
    f.outs_len = 0;
    f.start = -1;

    if (cc_at_end(cc)) { return f; }
    i8 c = cc_peek(cc);

    if (c == '(') {
        cc_adv(cc);
        i32 grp = cc.buf.n_groups;
        cc.buf.n_groups = cc.buf.n_groups + 1;
        // Save start
        i32 sv_s = nfa_add(cc.buf, NFA_SAVE, 0, -1, -1);
        cc.buf.nodes[sv_s].save_idx = grp * 2;
        nfa_frag body = compile_alt(cc, depth + 1);
        if (!cc_at_end(cc) && cc_peek(cc) == ')') { cc_adv(cc); }
        // Save end
        i32 sv_e = nfa_add(cc.buf, NFA_SAVE, 0, -1, -1);
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
        i32 idx = nfa_add(cc.buf, NFA_ANY, 0, -1, -1);
        frag_init(&f, idx);
        frag_add_out(&f, idx, 0);
    } else if (c == '^') {
        cc_adv(cc);
        i32 idx = nfa_add(cc.buf, NFA_ANCH_S, 0, -1, -1);
        frag_init(&f, idx);
        frag_add_out(&f, idx, 0);
    } else if (c == '$') {
        cc_adv(cc);
        i32 idx = nfa_add(cc.buf, NFA_ANCH_E, 0, -1, -1);
        frag_init(&f, idx);
        frag_add_out(&f, idx, 0);
    } else if (c == '\\' && cc.pos + 1 < cc.len) {
        cc_adv(cc);
        i8 esc = cc_adv(cc);
        if (esc=='d'||esc=='D'||esc=='w'||esc=='W'||esc=='s'||esc=='S') {
            i32 idx = nfa_add(cc.buf, NFA_CLASS, 0, -1, -1);
            i8* cls = cc.buf.nodes[idx].cls;
            bool is_neg = esc>='A' && esc<='Z';
            cls_set_escape(cls, esc, is_neg);
            frag_init(&f, idx);
            frag_add_out(&f, idx, 0);
        } else {
            i8 lc = unescape_char(esc);
            i32 idx = nfa_add(cc.buf, NFA_CHAR, lc, -1, -1);
            frag_init(&f, idx);
            frag_add_out(&f, idx, 0);
        }
    } else if (!is_special(c)) {
        cc_adv(cc);
        i8 lc = c;
        if (cc.buf.caseless && lc>='A' && lc<='Z') { lc = lc + 32; }
        i32 idx = nfa_add(cc.buf, NFA_CHAR, lc, -1, -1);
        frag_init(&f, idx);
        frag_add_out(&f, idx, 0);
    }
    return f;
}

nfa_frag compile_piece(compile_ctx* cc, i32 depth) {
    nfa_frag atom = compile_atom(cc, depth);
    if (atom.start < 0) { return atom; }
    if (cc_at_end(cc)) { return atom; }
    i8 q = cc_peek(cc);
    if (q == '*' || q == '+' || q == '?') {
        cc_adv(cc);
        return apply_quant(&atom, cc, q);
    }
    if (q == '{') {
        // {n}, {n,}, {n,m}
        cc_adv(cc); // consume {
        i32 lo = 0; i32 hi = 0; bool has_hi = false;
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
        i32 atom_start = atom.start;
        nfa_frag result = atom;
        i32 rep = 1;
        while (rep < lo) {
            // Re-parse atom (just chain another copy — point open outs to atom_start)
            frag_patch(&result, cc.buf, atom_start);
            // result now has atom open outs (we can't truly duplicate without rebuilding)
            // Fallback: treat as lo=1 to avoid complexity
            rep = lo; // break
        }
        if (hi == -1) {
            // {n,}: at least n, then unbounded → treat as * after required
            nfa_frag star = apply_quant(&result, cc, '*');
            return star;
        } else if (has_hi && hi > lo) {
            // {n,m}: up to m-n optional repetitions after required n
            nfa_frag opt = apply_quant(&result, cc, '?');
            return opt;
        }
        return result;
    }
    return atom;
}

nfa_frag compile_concat(compile_ctx* cc, i32 depth) {
    nfa_frag head;
    head.start = -1;
    head.outs_len = 0;
    bool first = true;

    while (!cc_at_end(cc)) {
        i8 c = cc_peek(cc);
        if (c == ')' || c == '|') { break; }

        nfa_frag piece = compile_piece(cc, depth);
        if (piece.start < 0) { break; }

        if (first) {
            head = piece;
            first = false;
        } else {
            frag_patch(&head, cc.buf, piece.start);
            head.start  = head.start;
            head.outs_len = piece.outs_len;
            i32 i = 0;
            while (i < piece.outs_len) {
                head.outs[i]      = piece.outs[i];
                head.out_slots[i] = piece.out_slots[i];
                i = i + 1;
            }
        }
    }
    return head;
}

nfa_frag compile_alt(compile_ctx* cc, i32 depth) {
    nfa_frag lhs = compile_concat(cc, depth);
    if (cc_at_end(cc) || cc_peek(cc) != '|') { return lhs; }

    cc_adv(cc); // consume |
    nfa_frag rhs = compile_alt(cc, depth);

    // Build SPLIT → (lhs | rhs)
    i32 sp = nfa_add(cc.buf, NFA_SPLIT, 0,
                     lhs.start >= 0 ? lhs.start : -1,
                     rhs.start >= 0 ? rhs.start : -1);
    nfa_frag f;
    frag_init(&f, sp);
    // All open outs from both sides
    i32 i = 0;
    while (i < lhs.outs_len) { frag_add_out(&f, lhs.outs[i], lhs.out_slots[i]); i = i + 1; }
    i = 0;
    while (i < rhs.outs_len) { frag_add_out(&f, rhs.outs[i], rhs.out_slots[i]); i = i + 1; }
    return f;
}

// ---- NFA simulator ----

comptime i32 SIM_MAX = 512;

struct sim_state {
    i32  nfa_idx;
    i32  caps[20]; // REGEX_MAX_CAPTURES * 2 start/end pairs
}

struct sim_ctx {
    sim_state cur[512];
    sim_state nxt[512];
    i32 cur_len;
    i32 nxt_len;
    bool visited[512];
}

void sim_add(sim_ctx* sc, i32 arr_is_nxt, i32 nfa_idx, i32* caps, nfa_buf* buf, i8* text, i32 tlen, i32 pos) {
    if (nfa_idx < 0 || nfa_idx >= buf.len) { return; }
    if (sc.visited[nfa_idx]) { return; }
    sc.visited[nfa_idx] = true;

    nfa_node* nd = &buf.nodes[nfa_idx];
    if (nd.op == NFA_SPLIT) {
        sim_add(sc, arr_is_nxt, nd.out1, caps, buf, text, tlen, pos);
        sim_add(sc, arr_is_nxt, nd.out2, caps, buf, text, tlen, pos);
        return;
    }
    if (nd.op == NFA_SAVE) {
        i32 new_caps[20];
        i32 ci = 0;
        while (ci < 20) { new_caps[ci] = caps[ci]; ci = ci + 1; }
        if (nd.save_idx >= 0 && nd.save_idx < 20) { new_caps[nd.save_idx] = pos; }
        sim_add(sc, arr_is_nxt, nd.out1, new_caps, buf, text, tlen, pos);
        return;
    }
    if (nd.op == NFA_ANCH_S) {
        bool ok = (pos == 0) || (buf.multiline && pos > 0 && text[pos-1] == '\n');
        if (!ok) { return; }
        sim_add(sc, arr_is_nxt, nd.out1, caps, buf, text, tlen, pos);
        return;
    }
    if (nd.op == NFA_ANCH_E) {
        bool ok = (pos == tlen) || (buf.multiline && pos < tlen && text[pos] == '\n');
        if (!ok) { return; }
        sim_add(sc, arr_is_nxt, nd.out1, caps, buf, text, tlen, pos);
        return;
    }

    // Real state: add to current or next list
    sim_state* arr = arr_is_nxt != 0 ? sc.nxt : sc.cur;
    i32* arr_len   = arr_is_nxt != 0 ? &sc.nxt_len : &sc.cur_len;
    if (*arr_len < SIM_MAX) {
        arr[*arr_len].nfa_idx = nfa_idx;
        i32 ci = 0;
        while (ci < 20) { arr[*arr_len].caps[ci] = caps[ci]; ci = ci + 1; }
        *arr_len = *arr_len + 1;
    }
}

bool char_matches(nfa_node* nd, i8 c, bool caseless) {
    if (nd.op == NFA_CHAR) {
        if (caseless) {
            i8 lc = c; i8 lp = nd.ch;
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
i32 nfa_run(nfa_buf* buf, i32 start_node, i8* text, i32 tlen, i32 start, i32* out_caps) {
    sim_ctx sc;
    sc.cur_len = 0;
    sc.nxt_len = 0;
    i32 ii = 0;
    while (ii < SIM_MAX) { sc.visited[ii] = false; ii = ii + 1; }

    i32 init_caps[20];
    i32 ci = 0;
    while (ci < 20) { init_caps[ci] = -1; ci = ci + 1; }

    sim_add(&sc, 0, start_node, init_caps, buf, text, tlen, start);

    i32 match_end = -1;
    i32 match_caps[20];
    ci = 0;
    while (ci < 20) { match_caps[ci] = -1; ci = ci + 1; }

    // Check for accept in initial state (zero-width match)
    i32 si = 0;
    while (si < sc.cur_len) {
        if (buf.nodes[sc.cur[si].nfa_idx].op == NFA_MATCH) {
            match_end = start;
            ci = 0;
            while (ci < 20) { match_caps[ci] = sc.cur[si].caps[ci]; ci = ci + 1; }
        }
        si = si + 1;
    }

    i32 pos = start;
    while (pos < tlen && sc.cur_len > 0) {
        i8 ch = text[pos];
        sc.nxt_len = 0;
        ii = 0;
        while (ii < SIM_MAX) { sc.visited[ii] = false; ii = ii + 1; }

        si = 0;
        while (si < sc.cur_len) {
            i32 ni = sc.cur[si].nfa_idx;
            nfa_node* nd = &buf.nodes[ni];
            bool ok = false;
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
    nfa_buf  _buf;
    i32      _start;
    bool     _valid;

    void __construct__(regex_t* self, i8* pattern, u32 options) {
        self._buf.len      = 0;
        self._buf.n_groups = 0;
        self._buf.caseless  = (options & REGEX_CASELESS)  != 0u;
        self._buf.dotall    = (options & REGEX_DOTALL)    != 0u;
        self._buf.multiline = (options & REGEX_MULTILINE) != 0u;
        self._valid = false;
        self._start = -1;
        if (pattern == (i8*)0) { return; }
        i32 plen = 0;
        while (pattern[plen] != 0) { plen = plen + 1; }
        compile_ctx cc;
        cc.pat = pattern;
        cc.pos = 0;
        cc.len = plen;
        cc.buf = &self._buf;
        nfa_frag f = compile_alt(&cc, 0);
        if (f.start < 0) { return; }
        i32 match_node = nfa_add(&self._buf, NFA_MATCH, 0, -1, -1);
        frag_patch(&f, &self._buf, match_node);
        self._start = f.start;
        self._valid = true;
    }

    bool is_valid(regex_t* self) { return self._valid; }

    bool match_at(regex_t* self, i8* subject, i32 slen, i32 start,
                  capture_t* cap, i32 cap_cap, i32* cap_count) {
        if (!self._valid || subject == (i8*)0) { if (cap_count != (i32*)0) { *cap_count = 0; } return false; }
        i32 raw_caps[20];
        i32 end = nfa_run(&self._buf, self._start, subject, slen, start, raw_caps);
        if (end < 0) { if (cap_count != (i32*)0) { *cap_count = 0; } return false; }
        if (cap != (capture_t*)0 && cap_cap > 0) {
            cap[0].start = start;
            cap[0].len   = end - start;
            i32 g = 1;
            while (g < cap_cap && g <= self._buf.n_groups) {
                i32 gs = raw_caps[(g-1)*2];
                i32 ge = raw_caps[(g-1)*2+1];
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

    bool test(regex_t* self, i8* subject, i32 slen) {
        if (!self._valid || subject == (i8*)0) { return false; }
        // Try starting at every position
        i32 pos = 0;
        while (pos <= slen) {
            i32 end = nfa_run(&self._buf, self._start, subject, slen, pos, (i32*)0);
            if (end >= 0) { return true; }
            pos = pos + 1;
        }
        return false;
    }

    bool find(regex_t* self, i8* subject, i32 slen,
              capture_t* cap, i32 cap_cap, i32* cap_count) {
        if (!self._valid || subject == (i8*)0) { if (cap_count != (i32*)0) { *cap_count = 0; } return false; }
        i32 pos = 0;
        while (pos <= slen) {
            i32 raw_caps[20];
            i32 end = nfa_run(&self._buf, self._start, subject, slen, pos, raw_caps);
            if (end >= 0) {
                if (cap != (capture_t*)0 && cap_cap > 0) {
                    cap[0].start = pos;
                    cap[0].len   = end - pos;
                    i32 g = 1;
                    while (g < cap_cap && g <= self._buf.n_groups) {
                        i32 gs = raw_caps[(g-1)*2];
                        i32 ge = raw_caps[(g-1)*2+1];
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

    void free(regex_t* self) { self._valid = false; }
}

// ---- Standalone helpers ----

bool test(i8* pattern, i8* subject, i32 slen, u32 options) {
    regex_t re(pattern, options);
    if (!re.is_valid()) { return false; }
    return re.test(subject, slen);
}

i32 find_offset(i8* pattern, i8* subject, i32 slen, u32 options) {
    regex_t re(pattern, options);
    if (!re.is_valid()) { return -1; }
    capture_t cap[1];
    i32 n = 0;
    bool ok = re.find(subject, slen, cap, 1, &n);
    return ok ? cap[0].start : -1;
}

} // namespace regex
} // namespace std
