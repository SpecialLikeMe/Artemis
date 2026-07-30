// Minimal preprocessor for the Artemis self-hosting (boot) compiler.
// Handles: @define, @undef, @ifdef, @ifndef, @elifdef, @elifndef, @else, @endif,
//          @include, @embed, @error.
// Regex-pattern @define is NOT supported; <PATTERN> treated as a literal name.

namespace preproc {

// ---- dynamic string buffer ----

struct strbuf {
    let data: *i8;
    let len: u64;
    let cap: u64;
}

fn strbuf_init(b: *strbuf) void {
    b.data = (i8*)arc_malloc(1024u);
    b.len  = 0u;
    b.cap  = 1024u;
}

fn strbuf_ensure(b: *strbuf, extra: u64) void {
    if (b.len + extra < b.cap) { return; }
    let mut nc: u64= b.cap * 2u + extra + 1u;
    b.data = (i8*)arc_realloc(b.data, nc);
    b.cap  = nc;
}

fn strbuf_push(b: *strbuf, c: i8) void {
    strbuf_ensure(b, 1u);
    b.data[b.len] = c;
    b.len = b.len + 1u;
}

fn strbuf_append(b: *strbuf, s: *i8, n: u64) void {
    strbuf_ensure(b, n);
    let mut i: u64= 0u;
    while (i < n) { b.data[b.len + i] = s[i]; i = i + 1u; }
    b.len = b.len + n;
}

fn strbuf_append_cstr(b: *strbuf, s: *i8) void {
    if (s == (i8*)0) { return; }
    let mut n: u64= (u64)strlen(s);
    strbuf_append(b, s, n);
}

fn strbuf_finish(b: *strbuf) *i8 {
    strbuf_ensure(b, 1u);
    b.data[b.len] = 0;
    return b.data;
}

// ---- macro table (parallel arrays, avoids array-of-struct IR issues) ----

struct pp_table {
    let names: [512]*i8;
    let values: [512]*i8;
    let count: i32;
}

fn pp_table_init(t: *pp_table) void { t.count = 0; }

fn pp_defined(t: *pp_table, name: *i8) bool {
    let mut i: i32= 0;
    while (i < t.count) {
        if (strcmp(t.names[i], name) == 0) { return true; }
        i = i + 1;
    }
    return false;
}

fn pp_get(t: *pp_table, name: *i8) *i8 {
    let mut i: i32= 0;
    while (i < t.count) {
        if (strcmp(t.names[i], name) == 0) { return t.values[i]; }
        i = i + 1;
    }
    return (i8*)0;
}

fn pp_set(t: *pp_table, name: *i8, value: *i8) void {
    let mut i: i32= 0;
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
    } else {
        aprint("warning: preprocessor macro table full (512 entries); ignoring definition of '%s'\n", .{ name });
    }
}

fn pp_undef(t: *pp_table, name: *i8) void {
    let mut i: i32= 0;
    while (i < t.count) {
        if (strcmp(t.names[i], name) == 0) {
            let mut last: i32= t.count - 1;
            t.names[i]  = t.names[last];
            t.values[i] = t.values[last];
            t.count = t.count - 1;
            return;
        }
        i = i + 1;
    }
}

// ---- Function-like (regex-pattern) macro table ----

struct pp_func_table {
    let names: [64]*i8;
    let arities: [64]i32;
    let replacements: [64]*i8;
    let count: i32;
}

fn pp_func_table_init(t: *pp_func_table) void { t.count = 0; }

fn pp_func_get(t: *pp_func_table, name: *i8, out_arity: *i32, out_repl: **i8) bool {
    let mut i: i32= 0;
    while (i < t.count) {
        if (strcmp(t.names[i], name) == 0) {
            *out_arity = t.arities[i];
            *out_repl  = t.replacements[i];
            return true;
        }
        i = i + 1;
    }
    return false;
}

fn pp_func_set(t: *pp_func_table, name: *i8, arity: i32, repl: *i8) void {
    let mut i: i32= 0;
    while (i < t.count) {
        if (strcmp(t.names[i], name) == 0) {
            t.arities[i]      = arity;
            t.replacements[i] = repl;
            return;
        }
        i = i + 1;
    }
    if (t.count < 64) {
        t.names[t.count]        = name;
        t.arities[t.count]      = arity;
        t.replacements[t.count] = repl;
        t.count = t.count + 1;
    } else {
        aprint("warning: function-like macro table full (64 entries); ignoring definition of '%s'\n", .{ name });
    }
}

// Parse pattern like MAX\(([^,]+),([^)]+)\) → extracts name="MAX", arity=2.
// Returns true if it looks function-like (pattern contains \().
fn pp_is_func_pattern(pat: *i8, out_name: **i8, out_arity: *i32) bool {
    let mut i: i32= 0;
    let mut escape_paren: i32= -1;
    while (pat[i] != 0) {
        if (pat[i] == '\\' && pat[i+1] == '(') { escape_paren = i; break; }
        i = i + 1;
    }
    if (escape_paren < 0) { return false; }
    *out_name = pp_substr_dup(pat, escape_paren);
    let mut arity: i32= 0;
    i = escape_paren + 2;
    while (pat[i] != 0) {
        if (pat[i] == '(' && pat[i+1] == '[' && pat[i+2] == '^') { arity = arity + 1; }
        i = i + 1;
    }
    *out_arity = arity;
    return true;
}

// Expand a function-like macro. lparen_pos points to '(' in the source line.
// Parses comma-separated arguments, substitutes %1/%2/... in replacement.
// Sets *end_pos to the position after the closing ')'. Returns malloc'd string.
fn pp_func_expand(ft: *pp_func_table, name: *i8, line: *i8, lparen_pos: i32, line_len: i32, end_pos: *i32) *i8 {
    let mut arity: i32= 0;
    let mut repl: *i8= (i8*)0;
    if (!pp_func_get(ft, name, &arity, &repl)) { *end_pos = lparen_pos; return (i8*)0; }
    let mut args: [8]*i8;
    let mut arg_lens: [8]i32;
    let mut nargs: i32= 0;
    let mut i: i32= lparen_pos + 1;
    while (i < line_len && nargs < 8) {
        while (i < line_len && (line[i] == ' ' || line[i] == '\t')) { i = i + 1; }
        let mut arg_start: i32= i;
        let mut depth: i32= 0;
        while (i < line_len) {
            if (line[i] == '(') { depth = depth + 1; }
            else if (line[i] == ')') { if (depth == 0) { break; } depth = depth - 1; }
            else if (line[i] == ',' && depth == 0) { break; }
            i = i + 1;
        }
        let mut arg_end: i32= i;
        while (arg_end > arg_start && (line[arg_end-1] == ' ' || line[arg_end-1] == '\t')) { arg_end = arg_end - 1; }
        args[nargs]     = line + arg_start;
        arg_lens[nargs] = arg_end - arg_start;
        nargs = nargs + 1;
        if (i < line_len && line[i] == ',') { i = i + 1; } else { break; }
    }
    while (i < line_len && line[i] != ')') { i = i + 1; }
    if (i < line_len) { i = i + 1; }
    *end_pos = i;
    let mut out: strbuf;
    strbuf_init(&out);
    if (repl != (i8*)0) {
        let mut ri: i32= 0;
        while (repl[ri] != 0) {
            if (repl[ri] == '%' && repl[ri+1] >= '1' && repl[ri+1] <= '9') {
                let mut idx: i32= (i32)(repl[ri+1] - '1');
                if (idx < nargs) { strbuf_append(&out, args[idx], (u64)arg_lens[idx]); }
                ri = ri + 2;
            } else {
                strbuf_push(&out, repl[ri]); ri = ri + 1;
            }
        }
    }
    return strbuf_finish(&out);
}

// ---- helpers ----

fn pp_is_id_start(c: i8) bool {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
}
fn pp_is_id_cont(c: i8) bool {
    return pp_is_id_start(c) || (c >= '0' && c <= '9');
}

fn pp_substr_dup(s: *i8, len: i32) *i8 {
    let mut r: *i8= (i8*)arc_malloc((u64)(len + 1));
    let mut i: i32= 0;
    while (i < len) { r[i] = s[i]; i = i + 1; }
    r[len] = 0;
    return r;
}

// Extract content inside <...>; returns pointer to inside, writes length.
fn pp_extract_angle(s: *i8, out_len: *i32) *i8 {
    while (*s == ' ' || *s == '\t') { s = s + 1; }
    if (*s != '<') { *out_len = 0; return (i8*)0; }
    s = s + 1;
    let mut start: *i8= s;
    let mut depth: i32= 1;
    let mut len: i32= 0;
    while (*s != 0 && depth > 0) {
        if (*s == '<') { depth = depth + 1; }
        else if (*s == '>') { depth = depth - 1; }
        if (depth > 0) { len = len + 1; s = s + 1; }
    }
    *out_len = len;
    return start;
}

// Smart variant: find the closing > that is either at end-of-line or followed by <.
// This handles replacements like <%1 > %2 ? %1 : %2> where > is used as an operator.
fn pp_extract_angle_smart(s: *i8, out_len: *i32) *i8 {
    while (*s == ' ' || *s == '\t') { s = s + 1; }
    if (*s != '<') { *out_len = 0; return (i8*)0; }
    s = s + 1;
    let mut start: *i8= s;
    // Find line end
    let mut line_end: i32= 0;
    while (s[line_end] != 0 && s[line_end] != '\n' && s[line_end] != '\r') { line_end = line_end + 1; }
    // Find first > followed by end-of-line (ignoring trailing whitespace) or another <
    let mut best: i32= -1;
    let mut i: i32= 0;
    while (i < line_end) {
        if (s[i] == '>') {
            let mut j: i32= i + 1;
            while (j < line_end && (s[j] == ' ' || s[j] == '\t')) { j = j + 1; }
            if (j >= line_end || s[j] == '<') { best = i; break; }
        }
        i = i + 1;
    }
    // Fallback: last >
    if (best < 0) {
        i = line_end - 1;
        while (i >= 0 && s[i] != '>') { i = i - 1; }
        if (i >= 0) { best = i; }
    }
    if (best < 0) { *out_len = 0; return (i8*)0; }
    *out_len = best;
    return start;
}

// Apply macro substitutions to one line (line_len bytes from line).
fn pp_apply(t: *pp_table, ft: *pp_func_table, line: *i8, line_len: i32, out: *strbuf) void {
    let mut i: i32= 0;
    while (i < line_len) {
        let mut c: i8= line[i];
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
        // Skip single-quoted char literals
        if (c == '\'') {
            strbuf_push(out, c); i = i + 1;
            while (i < line_len && line[i] != '\'') {
                if (line[i] == '\\' && i + 1 < line_len) {
                    strbuf_push(out, line[i]); i = i + 1;
                }
                strbuf_push(out, line[i]); i = i + 1;
            }
            if (i < line_len) { strbuf_push(out, line[i]); i = i + 1; }
            continue;
        }
        // Skip /* ... */ block comments
        if (c == '/' && i + 1 < line_len && line[i+1] == '*') {
            strbuf_push(out, c); i = i + 1;
            strbuf_push(out, line[i]); i = i + 1;
            while (i < line_len) {
                if (line[i] == '*' && i + 1 < line_len && line[i+1] == '/') {
                    strbuf_push(out, line[i]); i = i + 1;
                    strbuf_push(out, line[i]); i = i + 1;
                    break;
                }
                strbuf_push(out, line[i]); i = i + 1;
            }
            continue;
        }
        // Skip // line comments — copy rest as-is
        if (c == '/' && i + 1 < line_len && line[i+1] == '/') {
            strbuf_append(out, line + i, (u64)(line_len - i));
            return;
        }
        // Identifier: try substitution
        if (pp_is_id_start(c)) {
            let mut j: i32= i + 1;
            while (j < line_len && pp_is_id_cont(line[j])) { j = j + 1; }
            let mut id: *i8= pp_substr_dup(line + i, j - i);
            let mut repl: *i8= pp_get(t, id);
            if (repl != (i8*)0) {
                arc_free(id);
                strbuf_append_cstr(out, repl);
                i = j;
                continue;
            }
            // Try function-like macro expansion
            if (ft != (pp_func_table*)0) {
                let mut k: i32= j;
                while (k < line_len && (line[k] == ' ' || line[k] == '\t')) { k = k + 1; }
                if (k < line_len && line[k] == '(') {
                    let mut end_pos: i32= k;
                    let mut expanded: *i8= pp_func_expand(ft, id, line, k, line_len, &end_pos);
                    if (expanded != (i8*)0) {
                        arc_free(id);
                        strbuf_append_cstr(out, expanded);
                        arc_free(expanded);
                        i = end_pos;
                        continue;
                    }
                }
            }
            arc_free(id);
            strbuf_append(out, line + i, (u64)(j - i));
            i = j;
            continue;
        }
        strbuf_push(out, c);
        i = i + 1;
    }
}

// ---- conditional stack (parallel arrays, avoids array-of-struct IR issues) ----

struct pp_stack {
    let active: [64]bool;
    let ever_active: [64]bool;
    let done: [64]bool;
    let depth: i32;
}

fn pp_stack_init(s: *pp_stack) void { s.depth = 0; }

fn pp_all_active(s: *pp_stack) bool {
    let mut i: i32= 0;
    while (i < s.depth) {
        if (!s.active[i]) { return false; }
        i = i + 1;
    }
    return true;
}

fn pp_parents_active(s: *pp_stack) bool {
    let mut i: i32= 0;
    while (i < s.depth - 1) {
        if (!s.active[i]) { return false; }
        i = i + 1;
    }
    return true;
}

// ---- read a file ----
fn pp_read_file(path: *i8) *i8 {
    let mut fp: *void= fopen(path, "rb");
    if (fp == (void*)0) { return (i8*)0; }
    // A seek failure (non-seekable stream) makes ftell return -1; sizing the buffer
    // from that would allocate 0 bytes and then fread an enormous length into it.
    if (fseek(fp, (i64)0, 2) != 0) { fclose(fp); return (i8*)0; }
    let mut sz: i64= ftell(fp);
    if (sz < 0) { fclose(fp); return (i8*)0; }
    if (fseek(fp, (i64)0, 0) != 0) { fclose(fp); return (i8*)0; }
    let mut buf: *i8= (i8*)arc_malloc((u64)(sz + 1));
    if (buf == (i8*)0) { fclose(fp); return (i8*)0; }
    let mut n: u64= fread(buf, 1u, (u64)sz, fp);
    if (n > (u64)sz) { n = (u64)sz; }
    buf[n]  = 0;
    fclose(fp);
    return buf;
}

// Forward declaration
fn preprocess_inner(src: *i8, base_dir: *i8, macros: *pp_table, funcs: *pp_func_table, stdlib_path: *i8, included: *pp_table) *i8;

// ---- core pass ----
fn preprocess_inner(src: *i8, base_dir: *i8, macros: *pp_table, funcs: *pp_func_table, stdlib_path: *i8, included: *pp_table) *i8 {
    let mut out: strbuf;
    let mut cs: pp_stack;
    strbuf_init(&out);
    pp_stack_init(&cs);

    let mut pos: i32= 0;

    while (src[pos] != 0) {
        let mut line_start: i32= pos;
        while (src[pos] != 0 && src[pos] != '\n') { pos = pos + 1; }
        let mut line_end: i32= pos;
        if (src[pos] == '\n') { pos = pos + 1; }
        // Strip trailing \r for Windows line endings
        if (line_end > line_start && src[line_end - 1] == '\r') { line_end = line_end - 1; }

        let mut line: *i8= src + line_start;
        let mut line_len: i32= line_end - line_start;

        // Trim indent to find directive
        let mut ind: i32= 0;
        while (ind < line_len && (line[ind] == ' ' || line[ind] == '\t')) { ind = ind + 1; }

        let mut is_dir: bool= (ind < line_len && line[ind] == '@');
        if (is_dir) {
            let mut ks: i32= ind + 1;
            let mut ke: i32= ks;
            while (ke < line_len && pp_is_id_cont(line[ke])) { ke = ke + 1; }
            let mut kw: *i8= pp_substr_dup(line + ks, ke - ks);
            let mut rest: *i8= line + ke;
            while (*rest == ' ' || *rest == '\t') { rest = rest + 1; }
            // Only treat as directive if keyword is a known preprocessor keyword.
            // Unknown @-words (like @unsafe, @pub, @no_mangle) are code-level annotations
            // that must pass through to the parser unchanged.
            let mut is_known_dir: bool= (strcmp(kw, "define") == 0 || strcmp(kw, "undef") == 0 ||
                strcmp(kw, "ifdef") == 0 || strcmp(kw, "ifndef") == 0 ||
                strcmp(kw, "elifdef") == 0 || strcmp(kw, "elifndef") == 0 ||
                strcmp(kw, "else") == 0 || strcmp(kw, "endif") == 0 ||
                strcmp(kw, "include") == 0 || strcmp(kw, "embed") == 0 ||
                strcmp(kw, "error") == 0);
            if (!is_known_dir) {
                arc_free(kw);
                if (pp_all_active(&cs)) {
                    let mut li: i32= 0;
                    while (li < line_len) { strbuf_push(&out, line[li]); li = li + 1; }
                    strbuf_push(&out, '\n');
                } else {
                    strbuf_push(&out, '\n');
                }
                continue;
            }

            if (strcmp(kw, "define") == 0) {
                if (pp_all_active(&cs)) {
                    let mut plen: i32= 0;
                    let mut pstart: *i8= pp_extract_angle(rest, &plen);
                    if (pstart != (i8*)0) {
                        let mut pat: *i8= pp_substr_dup(pstart, plen);
                        let mut after: *i8= pstart + plen + 1;
                        while (*after == ' ' || *after == '\t') { after = after + 1; }
                        let mut vlen: i32= 0;
                        let mut vstart: *i8= pp_extract_angle_smart(after, &vlen);
                        let mut val: *i8;
                        if (vstart != (i8*)0) {
                            val = pp_substr_dup(vstart, vlen);
                        } else {
                            val = (i8*)arc_malloc(1u);
                            val[0] = 0;
                        }
                        // Detect function-like pattern (contains \()
                        let mut fname: *i8= (i8*)0;
                        let mut farity: i32= 0;
                        if (funcs != (pp_func_table*)0 && pp_is_func_pattern(pat, &fname, &farity)) {
                            pp_func_set(funcs, fname, farity, val);
                            arc_free(pat);
                        } else {
                            pp_set(macros, pat, val);
                        }
                    }
                }
            } else if (strcmp(kw, "undef") == 0) {
                if (pp_all_active(&cs)) {
                    let mut nlen: i32= 0;
                    let mut nstart: *i8= pp_extract_angle(rest, &nlen);
                    if (nstart != (i8*)0) {
                        let mut n: *i8= pp_substr_dup(nstart, nlen);
                        pp_undef(macros, n); arc_free(n);
                    } else {
                        let mut j: i32= 0;
                        while (rest[j] != 0 && rest[j] != ' ' && rest[j] != '\t' && rest[j] != '\r' && rest[j] != '\n') { j = j + 1; }
                        if (j > 0) { let mut n: *i8= pp_substr_dup(rest, j); pp_undef(macros, n); arc_free(n); }
                    }
                }
            } else if (strcmp(kw, "ifdef") == 0 || strcmp(kw, "ifndef") == 0) {
                let mut nlen: i32= 0;
                let mut nstart: *i8= pp_extract_angle(rest, &nlen);
                let mut name: *i8;
                if (nstart != (i8*)0) {
                    name = pp_substr_dup(nstart, nlen);
                } else {
                    let mut j: i32= 0;
                    while (rest[j] != 0 && rest[j] != ' ' && rest[j] != '\t' && rest[j] != '\r' && rest[j] != '\n') { j = j + 1; }
                    name = pp_substr_dup(rest, j);
                }
                let mut def: bool= pp_defined(macros, name);
                arc_free(name);
                let mut cond: bool;
                if (strcmp(kw, "ifdef") == 0) { cond = def; } else { cond = !def; }
                if (cs.depth < 64) {
                    cs.active[cs.depth]      = cond && pp_all_active(&cs);
                    cs.ever_active[cs.depth]  = cs.active[cs.depth];
                    cs.done[cs.depth]         = false;
                    cs.depth = cs.depth + 1;
                }
            } else if (strcmp(kw, "elifdef") == 0 || strcmp(kw, "elifndef") == 0) {
                if (cs.depth > 0) {
                    let mut ti: i32= cs.depth - 1;
                    if (!cs.ever_active[ti] && !cs.done[ti]) {
                        let mut nlen: i32= 0;
                        let mut nstart: *i8= pp_extract_angle(rest, &nlen);
                        let mut name: *i8;
                        if (nstart != (i8*)0) {
                            name = pp_substr_dup(nstart, nlen);
                        } else {
                            let mut j: i32= 0;
                            while (rest[j] != 0 && rest[j] != ' ' && rest[j] != '\t' && rest[j] != '\r' && rest[j] != '\n') { j = j + 1; }
                            name = pp_substr_dup(rest, j);
                        }
                        let mut def: bool= pp_defined(macros, name);
                        arc_free(name);
                        let mut cond: bool;
                        if (strcmp(kw, "elifdef") == 0) { cond = def; } else { cond = !def; }
                        cs.active[ti] = cond && pp_parents_active(&cs);
                        cs.ever_active[ti] = cs.ever_active[ti] || cs.active[ti];
                    } else {
                        cs.active[cs.depth - 1] = false;
                    }
                }
            } else if (strcmp(kw, "else") == 0) {
                if (cs.depth > 0) {
                    let mut ti: i32= cs.depth - 1;
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
                    let mut flen: i32= 0;
                    let mut fstart: *i8= pp_extract_angle(rest, &flen);
                    if (fstart != (i8*)0) {
                        let mut fname: *i8= pp_substr_dup(fstart, flen);
                        let mut fpath: [2048]i8;
                        afmt(fpath, 2048u, "%s/%s", .{ base_dir, fname });
                        arc_free(fname);
                        if (included == (pp_table*)0 || !pp_defined(included, fpath)) {
                            if (included != (pp_table*)0) { pp_set(included, pp_substr_dup(fpath, (i32)strlen(fpath)), "1"); }
                            let mut inc: *i8= pp_read_file(fpath);
                            if (inc != (i8*)0) {
                                let mut expanded: *i8= preprocess_inner(inc, base_dir, macros, funcs, stdlib_path, included);
                                strbuf_append_cstr(&out, expanded);
                                arc_free(expanded);
                                arc_free(inc);
                            }
                        }
                    }
                }
            } else if (strcmp(kw, "error") == 0) {
                if (pp_all_active(&cs)) {
                    aprint("preprocessor error: %s\n", .{ rest });
                    exit(1);
                }
            }
            // All directives become blank lines
            arc_free(kw);
            strbuf_push(&out, '\n');
        } else {
            if (pp_all_active(&cs)) {
                // Check for 'extern std.NAME;' — emit @import instead of raw text paste
                let mut handled_std: bool= false;
                {
                    let mut std_nm_start: i32= 0;
                    let mut got_std_nm: bool= false;
                    {
                        let mut ps: i32= ind;
                        if (line_len - ps >= 6 && line[ps]=='e' && line[ps+1]=='x' && line[ps+2]=='t' && line[ps+3]=='e' && line[ps+4]=='r' && line[ps+5]=='n') {
                            ps = ps + 6;
                            while (ps < line_len && (line[ps]==' ' || line[ps]=='\t')) { ps = ps + 1; }
                            if (line_len - ps >= 4 && line[ps]=='s' && line[ps+1]=='t' && line[ps+2]=='d' && line[ps+3]=='.') {
                                std_nm_start = ps + 4;
                                got_std_nm = true;
                            }
                        }
                    }
                    if (got_std_nm && line_len > 0 && line[line_len - 1] == ';') {
                        let mut name_start: i32= std_nm_start;
                        let mut name_end: i32= line_len - 1;
                        while (name_end > name_start && (line[name_end-1] == ' ' || line[name_end-1] == '\t')) { name_end = name_end - 1; }
                        if (name_end > name_start) {
                            let mut modname: *i8= pp_substr_dup(line + name_start, name_end - name_start);
                            // Convert dots to path separators (e.g. alloc.ring -> alloc/ring)
                            let mut di: i32= 0;
                            while (modname[di] != 0) {
                                if (modname[di] == '.') { modname[di] = '/'; }
                                di = di + 1;
                            }
                            // Dedup key: "std/modname.arc"
                            let mut dedup_key: [2048]i8;
                            afmt(dedup_key, 2048u, "std/%s.arc", .{ modname });
                            if (included == (pp_table*)0 || !pp_defined(included, dedup_key)) {
                                if (included != (pp_table*)0) { pp_set(included, pp_substr_dup(dedup_key, (i32)strlen(dedup_key)), "1"); }
                                // Emit safe @import splice — parser handles file resolution
                                let mut import_line: [2048]i8;
                                afmt(import_line, 2048u, "- = @import(\"std/%s.arc\");\n", .{ modname });
                                strbuf_append_cstr(&out, import_line);
                            }
                            arc_free(modname);
                            handled_std = true;
                        }
                    }
                }
                // Check for 'extern aciso.NAME;' — emit @import from modules/ directory
                if (!handled_std) {
                    let mut ac_nm_start: i32= 0;
                    let mut got_ac: bool= false;
                    {
                        let mut pa: i32= ind;
                        if (line_len - pa >= 6 && line[pa]=='e' && line[pa+1]=='x' && line[pa+2]=='t' && line[pa+3]=='e' && line[pa+4]=='r' && line[pa+5]=='n') {
                            pa = pa + 6;
                            while (pa < line_len && (line[pa]==' ' || line[pa]=='\t')) { pa = pa + 1; }
                            if (line_len - pa >= 6 && line[pa]=='a' && line[pa+1]=='c' && line[pa+2]=='i' && line[pa+3]=='s' && line[pa+4]=='o' && line[pa+5]=='.') {
                                ac_nm_start = pa + 6;
                                got_ac = true;
                            }
                        }
                    }
                    if (got_ac && line_len > 0 && line[line_len - 1] == ';') {
                        let mut ac_name_start: i32= ac_nm_start;
                        let mut ac_name_end: i32= line_len - 1;
                        while (ac_name_end > ac_name_start && (line[ac_name_end-1] == ' ' || line[ac_name_end-1] == '\t')) { ac_name_end = ac_name_end - 1; }
                        if (ac_name_end > ac_name_start) {
                            let mut pkgname: *i8= pp_substr_dup(line + ac_name_start, ac_name_end - ac_name_start);
                            // Dedup key
                            let mut dedup_key2: [512]i8;
                            afmt(dedup_key2, 512u, "aciso/%s", .{ pkgname });
                            if (included == (pp_table*)0 || !pp_defined(included, dedup_key2)) {
                                if (included != (pp_table*)0) { pp_set(included, pp_substr_dup(dedup_key2, (i32)strlen(dedup_key2)), "1"); }
                                // Determine entry file (PKG.arc preferred, then main.arc)
                                let mut arc_subpath: [512]i8;
                                afmt(arc_subpath, 512u, "modules/%s/%s.arc", .{ pkgname, pkgname });
                                if (base_dir != (i8*)0) {
                                    let mut fpath2: [2048]i8;
                                    afmt(fpath2, 2048u, "%s/%s", .{ base_dir, arc_subpath });
                                    let mut probe: *i8= pp_read_file(fpath2);
                                    if (probe == (i8*)0) {
                                        afmt(arc_subpath, 512u, "modules/%s/main.arc", .{ pkgname });
                                    } else {
                                        arc_free(probe);
                                    }
                                }
                                // Emit safe @import splice — parser handles file resolution
                                let mut import_line2: [2048]i8;
                                afmt(import_line2, 2048u, "- = @import(\"%s\");\n", .{ arc_subpath });
                                strbuf_append_cstr(&out, import_line2);
                            }
                            arc_free(pkgname);
                            handled_std = true;
                        }
                    }
                }
                if (!handled_std) {
                    pp_apply(macros, funcs, line, line_len, &out);
                }
            }
            strbuf_push(&out, '\n');
        }
    }

    return strbuf_finish(&out);
}

// Case-insensitive substring test, used for target-triple matching.
fn pp_triple_has(triple: *i8, needle: *i8) bool {
    if (triple == (i8*)0 || needle == (i8*)0) { return false; }
    let mut i: i32= 0;
    while (triple[i] != 0) {
        let mut j: i32= 0;
        while (needle[j] != 0 && triple[i + j] != 0) {
            let mut a: i8= triple[i + j];
            let mut b: i8= needle[j];
            if (a >= 'A' && a <= 'Z') { a = a + 32; }
            if (b >= 'A' && b <= 'Z') { b = b + 32; }
            if (a != b) { break; }
            j = j + 1;
        }
        if (needle[j] == 0) { return true; }
        i = i + 1;
    }
    return false;
}

// Seed the platform macros so `@ifdef _WIN32` / `@ifdef __linux__` guards in stdlib
// sources actually select a branch. The platform is read off the LLVM target triple
// rather than the host's own C macros, so a cross-compile targets the right branch —
// and so this stays correct while the compiler is bootstrapping itself.
fn pp_define_platform(macros: *pp_table) void {
    pp_set(macros, "__ARTEMIS__", "1");
    let mut triple: *i8= LLVMGetDefaultTargetTriple();
    if (triple == (i8*)0) { return; }
    if (pp_triple_has(triple, "windows") || pp_triple_has(triple, "mingw") ||
        pp_triple_has(triple, "msvc")) {
        pp_set(macros, "_WIN32", "1");
        pp_set(macros, "_WIN64", "1");
    } else if (pp_triple_has(triple, "darwin") || pp_triple_has(triple, "apple") ||
               pp_triple_has(triple, "macos")) {
        pp_set(macros, "__APPLE__", "1");
        pp_set(macros, "__unix__", "1");
    } else if (pp_triple_has(triple, "linux")) {
        pp_set(macros, "__linux__", "1");
        pp_set(macros, "__unix__", "1");
    }
}

// Public entry point.
fn preprocess(src: *i8, src_path: *i8, stdlib_path: *i8) *i8 {
    let mut macros: pp_table;
    pp_table_init(&macros);
    pp_define_platform(&macros);
    let mut funcs: pp_func_table;
    pp_func_table_init(&funcs);
    let mut included: pp_table;
    pp_table_init(&included);

    let mut base_dir: [2048]i8;
    base_dir[0] = 0;
    if (src_path != (i8*)0) {
        let mut i: i32= 0;
        let mut last_sep: i32= -1;
        while (src_path[i] != 0) {
            if (src_path[i] == '/' || src_path[i] == '\\') { last_sep = i; }
            i = i + 1;
        }
        if (last_sep >= 0) {
            let mut j: i32= 0;
            while (j < last_sep) { base_dir[j] = src_path[j]; j = j + 1; }
            base_dir[last_sep] = 0;
        } else {
            base_dir[0] = '.'; base_dir[1] = 0;
        }
    }

    let mut bd: *i8= (base_dir[0] != 0) ? base_dir : (i8*)0;
    return preprocess_inner(src, bd, &macros, &funcs, stdlib_path, &included);
}

} // namespace preproc
