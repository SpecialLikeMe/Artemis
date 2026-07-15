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
    b.data = (i8*)arc_malloc(1024u);
    b.len  = 0u;
    b.cap  = 1024u;
}

void strbuf_ensure(strbuf* b, u64 extra) {
    if (b.len + extra < b.cap) { return; }
    u64 nc = b.cap * 2u + extra + 1u;
    b.data = (i8*)arc_realloc(b.data, nc);
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

// ---- Function-like (regex-pattern) macro table ----

struct pp_func_table {
    i8*  names[64];
    i32  arities[64];
    i8*  replacements[64];
    i32  count;
}

void pp_func_table_init(pp_func_table* t) { t.count = 0; }

bool pp_func_get(pp_func_table* t, i8* name, i32* out_arity, i8** out_repl) {
    i32 i = 0;
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

void pp_func_set(pp_func_table* t, i8* name, i32 arity, i8* repl) {
    i32 i = 0;
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
    }
}

// Parse pattern like MAX\(([^,]+),([^)]+)\) → extracts name="MAX", arity=2.
// Returns true if it looks function-like (pattern contains \().
bool pp_is_func_pattern(i8* pat, i8** out_name, i32* out_arity) {
    i32 i = 0;
    i32 escape_paren = -1;
    while (pat[i] != 0) {
        if (pat[i] == '\\' && pat[i+1] == '(') { escape_paren = i; break; }
        i = i + 1;
    }
    if (escape_paren < 0) { return false; }
    *out_name = pp_substr_dup(pat, escape_paren);
    i32 arity = 0;
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
i8* pp_func_expand(pp_func_table* ft, i8* name, i8* line, i32 lparen_pos, i32 line_len, i32* end_pos) {
    i32 arity = 0;
    i8* repl  = (i8*)0;
    if (!pp_func_get(ft, name, &arity, &repl)) { *end_pos = lparen_pos; return (i8*)0; }
    i8*  args[8];
    i32  arg_lens[8];
    i32  nargs = 0;
    i32  i = lparen_pos + 1;
    while (i < line_len && nargs < 8) {
        while (i < line_len && (line[i] == ' ' || line[i] == '\t')) { i = i + 1; }
        i32 arg_start = i;
        i32 depth = 0;
        while (i < line_len) {
            if (line[i] == '(') { depth = depth + 1; }
            else if (line[i] == ')') { if (depth == 0) { break; } depth = depth - 1; }
            else if (line[i] == ',' && depth == 0) { break; }
            i = i + 1;
        }
        i32 arg_end = i;
        while (arg_end > arg_start && (line[arg_end-1] == ' ' || line[arg_end-1] == '\t')) { arg_end = arg_end - 1; }
        args[nargs]     = line + arg_start;
        arg_lens[nargs] = arg_end - arg_start;
        nargs = nargs + 1;
        if (i < line_len && line[i] == ',') { i = i + 1; } else { break; }
    }
    while (i < line_len && line[i] != ')') { i = i + 1; }
    if (i < line_len) { i = i + 1; }
    *end_pos = i;
    strbuf out;
    strbuf_init(&out);
    if (repl != (i8*)0) {
        i32 ri = 0;
        while (repl[ri] != 0) {
            if (repl[ri] == '%' && repl[ri+1] >= '1' && repl[ri+1] <= '9') {
                i32 idx = (i32)(repl[ri+1] - '1');
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

bool pp_is_id_start(i8 c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
}
bool pp_is_id_cont(i8 c) {
    return pp_is_id_start(c) || (c >= '0' && c <= '9');
}

i8* pp_substr_dup(i8* s, i32 len) {
    i8* r = (i8*)arc_malloc((u64)(len + 1));
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

// Smart variant: find the closing > that is either at end-of-line or followed by <.
// This handles replacements like <%1 > %2 ? %1 : %2> where > is used as an operator.
i8* pp_extract_angle_smart(i8* s, i32* out_len) {
    while (*s == ' ' || *s == '\t') { s = s + 1; }
    if (*s != '<') { *out_len = 0; return (i8*)0; }
    s = s + 1;
    i8* start = s;
    // Find line end
    i32 line_end = 0;
    while (s[line_end] != 0 && s[line_end] != '\n' && s[line_end] != '\r') { line_end = line_end + 1; }
    // Find first > followed by end-of-line (ignoring trailing whitespace) or another <
    i32 best = -1;
    i32 i = 0;
    while (i < line_end) {
        if (s[i] == '>') {
            i32 j = i + 1;
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
void pp_apply(pp_table* t, pp_func_table* ft, i8* line, i32 line_len, strbuf* out) {
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
            if (repl != (i8*)0) {
                arc_free(id);
                strbuf_append_cstr(out, repl);
                i = j;
                continue;
            }
            // Try function-like macro expansion
            if (ft != (pp_func_table*)0) {
                i32 k = j;
                while (k < line_len && (line[k] == ' ' || line[k] == '\t')) { k = k + 1; }
                if (k < line_len && line[k] == '(') {
                    i32 end_pos = k;
                    i8* expanded = pp_func_expand(ft, id, line, k, line_len, &end_pos);
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
    i8* buf = (i8*)arc_malloc((u64)(sz + 1));
    u64 n   = fread(buf, 1u, (u64)sz, fp);
    buf[n]  = 0;
    fclose(fp);
    return buf;
}

// Forward declaration
i8* preprocess_inner(i8* src, i8* base_dir, pp_table* macros, pp_func_table* funcs, i8* stdlib_path);

// ---- core pass ----
i8* preprocess_inner(i8* src, i8* base_dir, pp_table* macros, pp_func_table* funcs, i8* stdlib_path) {
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
                        i8* vstart = pp_extract_angle_smart(after, &vlen);
                        i8* val;
                        if (vstart != (i8*)0) {
                            val = pp_substr_dup(vstart, vlen);
                        } else {
                            val = (i8*)arc_malloc(1u);
                            val[0] = 0;
                        }
                        // Detect function-like pattern (contains \()
                        i8* fname = (i8*)0;
                        i32 farity = 0;
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
                    i32 nlen = 0;
                    i8* nstart = pp_extract_angle(rest, &nlen);
                    if (nstart != (i8*)0) {
                        i8* n = pp_substr_dup(nstart, nlen);
                        pp_undef(macros, n); arc_free(n);
                    } else {
                        i32 j = 0;
                        while (rest[j] != 0 && rest[j] != ' ' && rest[j] != '\t' && rest[j] != '\r' && rest[j] != '\n') { j = j + 1; }
                        if (j > 0) { i8* n = pp_substr_dup(rest, j); pp_undef(macros, n); arc_free(n); }
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
                arc_free(name);
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
                        arc_free(name);
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
                        arc_free(fname);
                        i8* inc = pp_read_file(fpath);
                        if (inc != (i8*)0) {
                            i8* expanded = preprocess_inner(inc, base_dir, macros, funcs, stdlib_path);
                            strbuf_append_cstr(&out, expanded);
                            arc_free(expanded);
                            arc_free(inc);
                        }
                    }
                }
            } else if (strcmp(kw, "error") == 0) {
                if (pp_all_active(&cs)) {
                    printf("preprocessor error: %s\n", rest);
                }
            }
            // All directives become blank lines
            arc_free(kw);
            strbuf_push(&out, '\n');
        } else {
            if (pp_all_active(&cs)) {
                // Check for 'extern std.NAME;' and expand to stdlib include
                bool handled_std = false;
                {
                    // First check if the line looks like extern std.X; regardless of stdlib_path
                    // so we can give a useful error when -I is missing
                    i8* ext_prefix2 = "extern std.";
                    i32 ext_plen2 = 11;
                    bool looks_like_std_import = false;
                    if (line_len - ind > ext_plen2 + 1) {
                        bool prefix_ok2 = true;
                        i32 ki2 = 0;
                        while (ki2 < ext_plen2 && prefix_ok2) {
                            if (line[ind + ki2] != ext_prefix2[ki2]) { prefix_ok2 = false; }
                            ki2 = ki2 + 1;
                        }
                        if (prefix_ok2 && line[line_len - 1] == ';') { looks_like_std_import = true; }
                    }
                    if (looks_like_std_import && stdlib_path == (i8*)0) {
                        // Extract module name for the error message
                        i32 nm_start = ind + ext_plen2;
                        i32 nm_end = line_len - 1;
                        while (nm_end > nm_start && (line[nm_end-1] == ' ' || line[nm_end-1] == '\t')) { nm_end = nm_end - 1; }
                        i8* modname2 = pp_substr_dup(line + nm_start, nm_end - nm_start);
                        printf("error: 'extern std.%s;' requires the stdlib path; pass -I <path/to/std/include>\n", modname2);
                        arc_free(modname2);
                        handled_std = true; // suppress the line so parser doesn't see it
                    }
                }
                if (stdlib_path != (i8*)0) {
                    i32 ext_ind = ind;
                    i8* ext_prefix = "extern std.";
                    i32 ext_plen = 11;
                    if (line_len - ext_ind > ext_plen + 1) {
                        bool prefix_ok = true;
                        i32 ki = 0;
                        while (ki < ext_plen && prefix_ok) {
                            if (line[ext_ind + ki] != ext_prefix[ki]) { prefix_ok = false; }
                            ki = ki + 1;
                        }
                        if (prefix_ok && line[line_len - 1] == ';') {
                            i32 name_start = ext_ind + ext_plen;
                            i32 name_end   = line_len - 1;
                            while (name_end > name_start && (line[name_end-1] == ' ' || line[name_end-1] == '\t')) { name_end = name_end - 1; }
                            if (name_end > name_start) {
                                i8* modname = pp_substr_dup(line + name_start, name_end - name_start);
                                // Convert dots to path separators for nested modules (e.g. alloc.ring -> alloc/ring)
                                i32 di = 0;
                                while (modname[di] != 0) {
                                    if (modname[di] == '.') { modname[di] = '/'; }
                                    di = di + 1;
                                }
                                i8 fpath[2048];
                                snprintf(fpath, 2048u, "%s/%s.arc", stdlib_path, modname);
                                arc_free(modname);
                                i8* inc = pp_read_file(fpath);
                                if (inc != (i8*)0) {
                                    i8* expanded = preprocess_inner(inc, stdlib_path, macros, funcs, stdlib_path);
                                    strbuf_append_cstr(&out, expanded);
                                    arc_free(expanded);
                                    arc_free(inc);
                                    handled_std = true;
                                }
                            }
                        }
                    }
                }
                // Check for: [qualifiers] NAME = @import("PATH");
                // Replace with: namespace NAME { [file content] }
                bool handled_import = false;
                if (!handled_std) {
                    // Scan for @import( in the line
                    i32 imp_at = -1;
                    i32 scan_i = ind;
                    while (scan_i < line_len - 8 && imp_at < 0) {
                        if (line[scan_i] == '@' &&
                            line[scan_i+1] == 'i' && line[scan_i+2] == 'm' &&
                            line[scan_i+3] == 'p' && line[scan_i+4] == 'o' &&
                            line[scan_i+5] == 'r' && line[scan_i+6] == 't' &&
                            line[scan_i+7] == '(') {
                            imp_at = scan_i;
                        }
                        scan_i = scan_i + 1;
                    }
                    if (imp_at >= 0) {
                        // Extract the import path: @import("PATH")
                        i32 q_start = imp_at + 8; // skip @import(
                        while (q_start < line_len && (line[q_start] == ' ' || line[q_start] == '\t')) { q_start = q_start + 1; }
                        if (q_start < line_len && line[q_start] == '"') {
                            q_start = q_start + 1; // skip opening "
                            i32 q_end = q_start;
                            while (q_end < line_len && line[q_end] != '"') { q_end = q_end + 1; }
                            if (q_end < line_len) {
                                i8* imp_path = pp_substr_dup(line + q_start, q_end - q_start);
                                // Extract the binding name: the identifier before '='
                                // Scan backwards from imp_at to find '=' then skip whitespace
                                i32 eq_pos = imp_at - 1;
                                while (eq_pos > ind && (line[eq_pos] == ' ' || line[eq_pos] == '\t')) { eq_pos = eq_pos - 1; }
                                if (eq_pos > ind && line[eq_pos] == '=') {
                                    eq_pos = eq_pos - 1;
                                    while (eq_pos > ind && (line[eq_pos] == ' ' || line[eq_pos] == '\t')) { eq_pos = eq_pos - 1; }
                                    // eq_pos now points to last char of name
                                    i32 name_end = eq_pos + 1;
                                    while (eq_pos >= ind && (
                                        (line[eq_pos] >= 'a' && line[eq_pos] <= 'z') ||
                                        (line[eq_pos] >= 'A' && line[eq_pos] <= 'Z') ||
                                        (line[eq_pos] >= '0' && line[eq_pos] <= '9') ||
                                        line[eq_pos] == '_')) { eq_pos = eq_pos - 1; }
                                    i32 name_start = eq_pos + 1;
                                    if (name_end > name_start) {
                                        i8* imp_name = pp_substr_dup(line + name_start, name_end - name_start);
                                        // Resolve the import path relative to base_dir
                                        i8 full_path[2048];
                                        if (base_dir != (i8*)0 && imp_path[0] != '/' && imp_path[0] != '\\') {
                                            snprintf(full_path, 2048u, "%s/%s", base_dir, imp_path);
                                        } else {
                                            snprintf(full_path, 2048u, "%s", imp_path);
                                        }
                                        i8* inc = pp_read_file(full_path);
                                        if (inc != (i8*)0) {
                                            strbuf_append_cstr(&out, "namespace ");
                                            strbuf_append_cstr(&out, imp_name);
                                            strbuf_append_cstr(&out, " {\n");
                                            i8* expanded = preprocess_inner(inc, base_dir, macros, funcs, stdlib_path);
                                            strbuf_append_cstr(&out, expanded);
                                            arc_free(expanded);
                                            arc_free(inc);
                                            strbuf_append_cstr(&out, "}\n");
                                            handled_import = true;
                                        } else {
                                            printf("error: @import: cannot open '%s'\n", full_path);
                                        }
                                        arc_free(imp_name);
                                    }
                                }
                                arc_free(imp_path);
                            }
                        }
                    }
                }
                if (!handled_std && !handled_import) {
                    pp_apply(macros, funcs, line, line_len, &out);
                }
            }
            strbuf_push(&out, '\n');
        }
    }

    return strbuf_finish(&out);
}

// Public entry point.
i8* preprocess(i8* src, i8* src_path, i8* stdlib_path) {
    pp_table macros;
    pp_table_init(&macros);
    pp_func_table funcs;
    pp_func_table_init(&funcs);

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
    return preprocess_inner(src, bd, &macros, &funcs, stdlib_path);
}

} // namespace preproc
