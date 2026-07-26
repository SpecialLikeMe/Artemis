// aciso — Artemis package manager & build system (Arc port)
// Original C++ implementation is in boot/aciso/

extern fn printf(fmt: *const i8, ...) i32;
extern fn fprintf(fp: *void, fmt: *const i8, ...) i32;
extern fn snprintf(buf: *i8, n: u64, fmt: *const i8, ...) i32;
extern fn strlen(s: *i8) u64;
extern fn strcmp(a: *i8, b: *i8) i32;
extern fn strncmp(a: *i8, b: *i8, n: u64) i32;
extern fn strcpy(dst: *i8, src: *i8) *i8;
extern fn strcat(dst: *i8, src: *i8) *i8;
extern fn strstr(hay: *i8, needle: *i8) *i8;
extern fn strchr(s: *i8, c: i32) *i8;
extern fn strrchr(s: *i8, c: i32) *i8;
extern fn malloc(n: u64) *i8;
extern fn realloc(p: *i8, n: u64) *i8;
extern fn free(p: *i8) void;
extern fn memcpy(dst: *i8, src: *i8, n: u64) *i8;
extern fn memset(dst: *i8, c: i32, n: u64) *i8;
extern fn system(cmd: *i8) i32;
extern fn fopen(path: *i8, mode: *i8) *void;
extern fn fclose(fp: *void) i32;
extern fn fread(buf: *void, sz: u64, n: u64, fp: *void) u64;
extern fn fwrite(buf: *void, sz: u64, n: u64, fp: *void) u64;
extern fn fseek(fp: *void, off: i64, w: i32) i32;
extern fn ftell(fp: *void) i64;
extern fn fgets(buf: *i8, n: i32, fp: *void) *i8;
extern fn remove(path: *i8) i32;
extern fn rename(old: *i8, n: *i8) i32;
extern fn access(path: *i8, mode: i32) i32;
extern fn getenv(name: *i8) *i8;
extern fn putchar(c: i32) i32;
extern fn stderr_ptr() *void;
extern fn atoi(s: *i8) i32;

extern fn _popen(cmd: *i8, mode: *i8) *void;
extern fn _pclose(fp: *void) i32;

// ---- allocator shim (malloc/realloc/free confined to memstr) ----

memstr SysAlloc {
    fn alloc_(self: *SysAlloc, n: u64) *void  { return (void*)malloc(n); }
    fn grow_(self: *SysAlloc, p: *i8, n: u64) *void { return (void*)realloc(p, n); }
    fn free_(self: *SysAlloc, p: *i8) void    { free(p); }
}

fn arc_malloc(n: u64) *i8  { let mut _s: SysAlloc; return (i8*)_s.alloc_(n); }
fn arc_realloc(p: *i8, n: u64) *i8 { let mut _s: SysAlloc; return (i8*)_s.grow_(p, n); }
fn arc_free(p: *i8) void   { let mut _s: SysAlloc; _s.free_(p); }

// ---- string helpers ----

fn ac_strdup(s: *i8) *i8 {
    let mut n: u64= strlen(s) + 1;
    let mut d: *i8= arc_malloc(n);
    memcpy(d, s, n);
    return d;
}

fn ac_str_ends_with(s: *i8, suffix: *i8) bool {
    let mut sl: i32= (i32)strlen(s);
    let mut tl: i32= (i32)strlen(suffix);
    if (tl > sl) { return false; }
    return strcmp(s + (i64)(sl - tl), suffix) == 0;
}

fn ac_str_starts_with(s: *i8, prefix: *i8) bool {
    let mut pl: i32= (i32)strlen(prefix);
    return strncmp(s, prefix, (u64)pl) == 0;
}

// ---- console output ----

fn ac_ok(msg: *i8)   { printf("ok:    %s\n", msg); }
fn ac_info(msg: *i8) { printf("info:  %s\n", msg); }
fn ac_warn(msg: *i8) { printf("warn:  %s\n", msg); }
fn ac_err(msg: *i8)  { printf("error: %s\n", msg); }

// ---- strbuf: growable string ----

struct strbuf {
    let mut data: *i8;
    let mut len: i32;
    let mut cap: i32;
}

fn strbuf_init(b: *strbuf) void {
    b.data = (i8*)0; b.len = 0; b.cap = 0;
}

fn strbuf_push(b: *strbuf, c: i8) void {
    if (b.len + 1 >= b.cap) {
        let mut nc: i32= b.cap == 0 ? 256 : b.cap * 2;
        b.data = arc_realloc(b.data, (u64)nc);
        b.cap  = nc;
    }
    b.data[b.len] = c; b.len = b.len + 1; b.data[b.len] = 0;
}

fn strbuf_append(b: *strbuf, s: *i8) void {
    let mut i: i32= 0;
    while (s[i] != 0) { strbuf_push(b, s[i]); i = i + 1; }
}

fn strbuf_finish(b: *strbuf) *i8 {
    if (b.data == (i8*)0) { return ac_strdup(""); }
    return b.data;
}

// ---- file helpers ----

fn ac_file_exists(path: *i8) bool { return access(path, 0) == 0; }

fn ac_read_file(path: *i8) *i8 {
    let mut fp: *void= fopen(path, "rb");
    if (fp == (void*)0) { return (i8*)0; }
    fseek(fp, (i64)0, 2);
    let mut sz: i64= ftell(fp);
    fseek(fp, (i64)0, 0);
    if (sz < 0) { fclose(fp); return (i8*)0; }
    let mut buf: *i8= arc_malloc((u64)(sz + 1));
    let mut n: u64= fread(buf, (u64)1, (u64)sz, fp);
    buf[n] = 0;
    fclose(fp);
    return buf;
}

fn ac_write_file(path: *i8, content: *i8) bool {
    let mut fp: *void= fopen(path, "wb");
    if (fp == (void*)0) { return false; }
    let mut n: u64= strlen(content);
    fwrite(content, (u64)1, n, fp);
    fclose(fp);
    return true;
}

fn ac_copy_file(src: *i8, dst: *i8) bool {
    let mut content: *i8= ac_read_file(src);
    if (content == (i8*)0) { return false; }
    let mut ok: bool= ac_write_file(dst, content);
    arc_free(content);
    return ok;
}

fn ac_mkdir_p(path: *i8) void {
    let mut cmd: [2048]i8;
    // CMD 'md' creates intermediate parent directories
    snprintf(cmd, 2048u, "md \"%s\" 2>NUL", path);
    system(cmd);
}

fn ac_rm_rf(path: *i8) void {
    let mut cmd: [2048]i8;
    snprintf(cmd, 2048u, "rmdir /s /q \"%s\" 2>NUL & del /f /q \"%s\" 2>NUL", path, path);
    system(cmd);
}

// ---- simple key-value config (flat: "section.key" -> value) ----
// Arrays stored as "key[0]", "key[1]", ..., "key._len" = count

struct ac_kv {
    let key: *i8;
    let val: *i8;
}

struct ac_cfg {
    let mut entries: *ac_kv;
    let mut len: i32;
    let mut cap: i32;
    let mut path: [2048]i8;
    let mut use_toml: bool;
}

fn ac_cfg_init(c: *ac_cfg) void {
    c.entries = (ac_kv*)0; c.len = 0; c.cap = 0;
    c.path[0] = 0; c.use_toml = false;
}

fn ac_cfg_set(c: *ac_cfg, key: *i8, val: *i8) void {
    let mut i: i32= 0;
    while (i < c.len) {
        if (strcmp(c.entries[i].key, key) == 0) {
            arc_free(c.entries[i].val);
            c.entries[i].val = ac_strdup(val);
            return;
        }
        i = i + 1;
    }
    if (c.len >= c.cap) {
        let mut nc: i32= c.cap == 0 ? 32 : c.cap * 2;
        c.entries = (ac_kv*)arc_realloc((i8*)c.entries, sizeof(ac_kv) * (u64)nc);
        c.cap = nc;
    }
    c.entries[c.len].key = ac_strdup(key);
    c.entries[c.len].val = ac_strdup(val);
    c.len = c.len + 1;
}

fn ac_cfg_get(c: *ac_cfg, key: *i8) *i8 {
    let mut i: i32= 0;
    while (i < c.len) {
        if (strcmp(c.entries[i].key, key) == 0) { return c.entries[i].val; }
        i = i + 1;
    }
    return (i8*)0;
}

fn ac_cfg_get_or(c: *ac_cfg, key: *i8, def: *i8) *i8 {
    let mut v: *i8= ac_cfg_get(c, key);
    return v != (i8*)0 ? v : def;
}

fn ac_cfg_del(c: *ac_cfg, key: *i8) void {
    let mut i: i32= 0;
    while (i < c.len) {
        if (strcmp(c.entries[i].key, key) == 0) {
            arc_free(c.entries[i].key); arc_free(c.entries[i].val);
            let mut j: i32= i + 1;
            while (j < c.len) { c.entries[j-1] = c.entries[j]; j = j + 1; }
            c.len = c.len - 1;
            return;
        }
        i = i + 1;
    }
}

fn ac_cfg_arr_len(c: *ac_cfg, key: *i8) i32 {
    let mut lk: [256]i8;
    snprintf(lk, 256u, "%s._len", key);
    let mut lv: *i8= ac_cfg_get(c, lk);
    if (lv == (i8*)0) { return 0; }
    return atoi(lv);
}

fn ac_cfg_arr_push(c: *ac_cfg, key: *i8, val: *i8) void {
    let mut n: i32= ac_cfg_arr_len(c, key);
    let mut ek: [256]i8;
    snprintf(ek, 256u, "%s[%d]", key, n);
    ac_cfg_set(c, ek, val);
    let mut lk: [256]i8;
    snprintf(lk, 256u, "%s._len", key);
    let mut lv: [16]i8;
    snprintf(lv, 16u, "%d", n + 1);
    ac_cfg_set(c, lk, lv);
}

fn ac_cfg_arr_get(c: *ac_cfg, key: *i8, idx: i32) *i8 {
    let mut ek: [256]i8;
    snprintf(ek, 256u, "%s[%d]", key, idx);
    return ac_cfg_get(c, ek);
}

// ---- JSON parser (minimal subset) ----

fn json_skip_ws(s: *i8, i: *i32) void {
    while (s[*i] == ' ' || s[*i] == '\t' || s[*i] == '\n' || s[*i] == '\r') { *i = *i + 1; }
}

fn json_parse_str(s: *i8, i: *i32, out: *i8, cap: i32) void {
    *i = *i + 1; // skip opening "
    let mut n: i32= 0;
    while (s[*i] != 0 && s[*i] != '"' && n < cap - 1) {
        if (s[*i] == '\\' && s[*i + 1] != 0) {
            *i = *i + 1;
            if (s[*i] == 'n') { out[n] = '\n'; }
            else if (s[*i] == 't') { out[n] = '\t'; }
            else if (s[*i] == 'r') { out[n] = '\r'; }
            else { out[n] = s[*i]; }
        } else {
            out[n] = s[*i];
        }
        n = n + 1; *i = *i + 1;
    }
    out[n] = 0;
    if (s[*i] == '"') { *i = *i + 1; }
}

// Iterative JSON parser supporting two-level {"section": {"key": "val"}}
// and string arrays. Sufficient for aciso/acm config files.

fn json_parse_inner_array(src: *i8, i: *i32, key: *i8, cfg: *ac_cfg) void {
    *i = *i + 1; // skip '['
    json_skip_ws(src, i);
    while (src[*i] != 0 && src[*i] != ']') {
        json_skip_ws(src, i);
        if (src[*i] == '"') {
            let mut val: [2048]i8;
            json_parse_str(src, i, val, 2048);
            ac_cfg_arr_push(cfg, key, val);
        } else if (src[*i] != ']') {
            *i = *i + 1; // skip unknown token
        }
        json_skip_ws(src, i);
        if (src[*i] == ',') { *i = *i + 1; }
        json_skip_ws(src, i);
    }
    if (src[*i] == ']') { *i = *i + 1; }
}

fn json_parse_inner_obj(src: *i8, i: *i32, section: *i8, cfg: *ac_cfg) void {
    *i = *i + 1; // skip '{'
    json_skip_ws(src, i);
    while (src[*i] != 0 && src[*i] != '}') {
        json_skip_ws(src, i);
        if (src[*i] != '"') { *i = *i + 1; }
        else {
            let mut key: [256]i8;
            json_parse_str(src, i, key, 256);
            json_skip_ws(src, i);
            if (src[*i] == ':') { *i = *i + 1; }
            json_skip_ws(src, i);

            let mut full_key: [512]i8;
            if (section[0] != 0) { snprintf(full_key, 512u, "%s.%s", section, key); }
            else { snprintf(full_key, 512u, "%s", key); }

            if (src[*i] == '"') {
                let mut val: [2048]i8;
                json_parse_str(src, i, val, 2048);
                ac_cfg_set(cfg, full_key, val);
            } else if (src[*i] == '[') {
                json_parse_inner_array(src, i, full_key, cfg);
            } else {
                let mut vbuf: [256]i8;
                let mut vn: i32= 0;
                while (src[*i] != 0 && src[*i] != ',' && src[*i] != '}' && src[*i] != '\n' && vn < 255) {
                    vbuf[vn] = src[*i]; vn = vn + 1; *i = *i + 1;
                }
                vbuf[vn] = 0;
                if (vn > 0) { ac_cfg_set(cfg, full_key, vbuf); }
            }
            json_skip_ws(src, i);
            if (src[*i] == ',') { *i = *i + 1; }
        }
        json_skip_ws(src, i);
    }
    if (src[*i] == '}') { *i = *i + 1; }
}

fn json_parse(src: *i8, cfg: *ac_cfg) void {
    let mut i: i32= 0;
    json_skip_ws(src, &i);
    if (src[i] != '{') { return; }
    i = i + 1; // skip outer '{'
    json_skip_ws(src, &i);
    while (src[i] != 0 && src[i] != '}') {
        json_skip_ws(src, &i);
        if (src[i] != '"') { i = i + 1; }
        else {
            let mut key: [256]i8;
            json_parse_str(src, &i, key, 256);
            json_skip_ws(src, &i);
            if (src[i] == ':') { i = i + 1; }
            json_skip_ws(src, &i);

            if (src[i] == '"') {
                let mut val: [2048]i8;
                json_parse_str(src, &i, val, 2048);
                ac_cfg_set(cfg, key, val);
            } else if (src[i] == '[') {
                json_parse_inner_array(src, &i, key, cfg);
            } else if (src[i] == '{') {
                json_parse_inner_obj(src, &i, key, cfg);
            } else {
                let mut vbuf: [256]i8;
                let mut vn: i32= 0;
                while (src[i] != 0 && src[i] != ',' && src[i] != '}' && src[i] != '\n' && vn < 255) {
                    vbuf[vn] = src[i]; vn = vn + 1; i = i + 1;
                }
                vbuf[vn] = 0;
                if (vn > 0) { ac_cfg_set(cfg, key, vbuf); }
            }
            json_skip_ws(src, &i);
            if (src[i] == ',') { i = i + 1; }
        }
        json_skip_ws(src, &i);
    }
}

// ---- TOML parser (minimal subset) ----

fn toml_trim(s: *i8) *i8 {
    while (*s == ' ' || *s == '\t') { s = s + 1; }
    return s;
}

fn toml_trim_end(s: *i8) void {
    let mut n: i32= (i32)strlen(s) - 1;
    while (n >= 0 && (s[n] == ' ' || s[n] == '\t' || s[n] == '\r' || s[n] == '\n')) {
        s[n] = 0; n = n - 1;
    }
}

fn toml_parse_str_val(s: *i8, out: *i8, cap: i32) void {
    s = toml_trim(s);
    if (*s == '"') {
        s = s + 1;
        let mut n: i32= 0;
        while (*s != 0 && *s != '"' && n < cap - 1) {
            if (*s == '\\' && *(s+1) != 0) {
                s = s + 1;
                if (*s == 'n') { out[n] = '\n'; }
                else if (*s == 't') { out[n] = '\t'; }
                else { out[n] = *s; }
            } else { out[n] = *s; }
            n = n + 1; s = s + 1;
        }
        out[n] = 0;
    } else {
        let mut n: i32= 0;
        while (*s != 0 && *s != '#' && *s != '\r' && *s != '\n' && n < cap - 1) {
            out[n] = *s; n = n + 1; s = s + 1;
        }
        out[n] = 0;
        toml_trim_end(out);
    }
}

fn toml_parse(src: *i8, cfg: *ac_cfg) void {
    let mut section: [256]i8;
    section[0] = 0;
    let mut line: [4096]i8;
    let mut si: i32= 0;
    let mut src_len: i32= (i32)strlen(src);

    while (si < src_len) {
        // Read a line
        let mut li: i32= 0;
        while (si < src_len && src[si] != '\n' && li < 4095) {
            line[li] = src[si]; li = li + 1; si = si + 1;
        }
        if (si < src_len && src[si] == '\n') { si = si + 1; }
        line[li] = 0;

        let mut p: *i8= toml_trim(line);
        // skip comments and blank lines
        if (*p == '#' || *p == 0) { continue; }

        if (*p == '[') {
            // section header
            p = p + 1;
            let mut se: i32= 0;
            while (*p != 0 && *p != ']' && se < 255) {
                section[se] = *p; se = se + 1; p = p + 1;
            }
            section[se] = 0;
            continue;
        }

        // key = value
        let mut eq: *i8= strchr(p, '=');
        if (eq == (i8*)0) { continue; }
        *eq = 0;
        let mut key: [256]i8;
        snprintf(key, 256u, "%s", p);
        toml_trim_end(key);
        let mut vp: *i8= toml_trim(eq + 1);

        let mut full_key: [512]i8;
        if (section[0] != 0) {
            snprintf(full_key, 512u, "%s.%s", section, key);
        } else {
            snprintf(full_key, 512u, "%s", key);
        }

        if (*vp == '[') {
            // inline array
            vp = vp + 1;
            while (*vp != 0 && *vp != ']') {
                vp = toml_trim(vp);
                if (*vp == '"') {
                    vp = vp + 1;
                    let mut val: [2048]i8;
                    let mut vn: i32= 0;
                    while (*vp != 0 && *vp != '"' && vn < 2047) {
                        val[vn] = *vp; vn = vn + 1; vp = vp + 1;
                    }
                    val[vn] = 0;
                    if (*vp == '"') { vp = vp + 1; }
                    ac_cfg_arr_push(cfg, full_key, val);
                } else if (*vp == ']') { break; }
                else { vp = vp + 1; }
                vp = toml_trim(vp);
                if (*vp == ',') { vp = vp + 1; }
            }
        } else {
            let mut val: [2048]i8;
            toml_parse_str_val(vp, val, 2048);
            ac_cfg_set(cfg, full_key, val);
        }
    }
}

// ---- JSON serialiser ----

fn json_emit_cfg(cfg: *ac_cfg) *i8 {
    let mut sb: strbuf;
    strbuf_init(&sb);
    strbuf_append(&sb, "{\n");

    // Emit JSON: scalar keys and arrays (via ._len sentinels)
    // Two-pass approach: first collect top-level scalars, then section keys
    let mut first: bool= true;
    let mut i: i32= 0;
    while (i < cfg.len) {
        let mut k: *i8= cfg.entries[i].key;
        // Skip raw array element entries
        let mut is_arr_elem: bool= false;
        let mut ki: i32= 0;
        while (k[ki] != 0) { if (k[ki] == '[') { is_arr_elem = true; break; } ki = ki + 1; }
        if (is_arr_elem) { i = i + 1; continue; }

        // Determine base key: for ._len, strip that suffix to get the array key
        let mut is_len_marker: bool= ac_str_ends_with(k, "._len");
        let mut base_key: [512]i8;
        if (is_len_marker) {
            let mut blen: i32= (i32)strlen(k) - 5;
            let mut bi: i32= 0;
            while (bi < blen) { base_key[bi] = k[bi]; bi = bi + 1; }
            base_key[blen] = 0;
        } else {
            snprintf(base_key, 512u, "%s", k);
        }

        // Only emit top-level (no dot in base_key for JSON root-level)
        // For sectioned keys like "project.name", skip unless it's a ._len sentinel
        // Actually for JSON we emit as nested objects; simpler: emit all non-nested scalar,
        // and for arrays use ._len sentinel. Nested objects are handled via "section.key" entries.
        // We'll group by first component (section).

        // Skip scalar section.key entries — they'll be handled when we emit the section object
        let mut dot_pos: i32= -1;
        let mut bki: i32= 0;
        while (base_key[bki] != 0) { if (base_key[bki] == '.') { dot_pos = bki; break; } bki = bki + 1; }

        // For now, simple flat JSON (no nested objects) is enough for aciso configs
        // Emit all entries at top level, using dot-in-key as-is
        if (!first) { strbuf_append(&sb, ",\n"); }
        first = false;

        if (is_len_marker) {
            // Emit as JSON array
            let mut n: i32= atoi(cfg.entries[i].val);
            strbuf_append(&sb, "  \"");
            strbuf_append(&sb, base_key);
            strbuf_append(&sb, "\": [");
            let mut ai: i32= 0;
            while (ai < n) {
                if (ai > 0) { strbuf_append(&sb, ", "); }
                let mut ek: [256]i8;
                snprintf(ek, 256u, "%s[%d]", base_key, ai);
                let mut av: *i8= ac_cfg_get(cfg, ek);
                strbuf_append(&sb, "\"");
                strbuf_append(&sb, av != (i8*)0 ? av : "");
                strbuf_append(&sb, "\"");
                ai = ai + 1;
            }
            strbuf_append(&sb, "]");
        } else {
            strbuf_append(&sb, "  \"");
            strbuf_append(&sb, k);
            strbuf_append(&sb, "\": \"");
            strbuf_append(&sb, cfg.entries[i].val);
            strbuf_append(&sb, "\"");
        }
        i = i + 1;
    }

    strbuf_append(&sb, "\n}\n");
    return strbuf_finish(&sb);
}

// ---- TOML serialiser ----

fn toml_get_sec_kname(k: *i8, sec: *i8, kname: *i8) void {
    // Find first dot: everything before = section, after = kname
    let mut dl: i32= 0;
    while (k[dl] != 0 && k[dl] != '.') { dl = dl + 1; }
    if (k[dl] == '.') {
        let mut si: i32= 0;
        while (si < dl) { sec[si] = k[si]; si = si + 1; }
        sec[dl] = 0;
        snprintf(kname, 256u, "%s", k + (i64)(dl + 1));
    } else {
        sec[0] = 0;
        snprintf(kname, 256u, "%s", k);
    }
}

fn toml_emit_cfg(cfg: *ac_cfg) *i8 {
    let mut sb: strbuf;
    strbuf_init(&sb);
    let mut cur_section: [256]i8;
    cur_section[0] = 0;

    let mut i: i32= 0;
    while (i < cfg.len) {
        let mut k: *i8= cfg.entries[i].key;

        // Skip raw array element entries — emitted via ._len sentinel
        let mut is_arr_elem: bool= false;
        let mut ki: i32= 0;
        while (k[ki] != 0) { if (k[ki] == '[') { is_arr_elem = true; break; } ki = ki + 1; }
        if (is_arr_elem) { i = i + 1; continue; }

        // Determine if this is a ._len sentinel (= array key)
        let mut is_len_marker: bool= ac_str_ends_with(k, "._len");
        let mut base_key: [512]i8;
        if (is_len_marker) {
            let mut blen: i32= (i32)strlen(k) - 5;
            let mut bi: i32= 0;
            while (bi < blen) { base_key[bi] = k[bi]; bi = bi + 1; }
            base_key[blen] = 0;
        } else {
            snprintf(base_key, 512u, "%s", k);
        }

        // Get section and key name from base_key
        let mut sec: [256]i8;
        let mut kname: [256]i8;
        toml_get_sec_kname(base_key, sec, kname);

        // Emit section header if changed
        if (strcmp(sec, cur_section) != 0) {
            if (sec[0] != 0) {
                strbuf_append(&sb, "\n[");
                strbuf_append(&sb, sec);
                strbuf_append(&sb, "]\n");
            }
            snprintf(cur_section, 256u, "%s", sec);
        }

        if (is_len_marker) {
            // Emit as inline TOML array
            let mut n: i32= atoi(cfg.entries[i].val);
            strbuf_append(&sb, kname);
            strbuf_append(&sb, " = [");
            let mut ai: i32= 0;
            while (ai < n) {
                if (ai > 0) { strbuf_append(&sb, ", "); }
                let mut ek: [256]i8;
                snprintf(ek, 256u, "%s[%d]", base_key, ai);
                let mut av: *i8= ac_cfg_get(cfg, ek);
                strbuf_append(&sb, "\"");
                strbuf_append(&sb, av != (i8*)0 ? av : "");
                strbuf_append(&sb, "\"");
                ai = ai + 1;
            }
            strbuf_append(&sb, "]\n");
        } else {
            strbuf_append(&sb, kname);
            strbuf_append(&sb, " = \"");
            strbuf_append(&sb, cfg.entries[i].val);
            strbuf_append(&sb, "\"\n");
        }
        i = i + 1;
    }
    return strbuf_finish(&sb);
}

// ---- config file I/O ----

fn find_config(prefix: *i8, path_out: *i8, cap: i32) bool {
    snprintf(path_out, (u64)cap, "%s.toml", prefix);
    if (ac_file_exists(path_out)) { return true; }
    snprintf(path_out, (u64)cap, "%s.json", prefix);
    if (ac_file_exists(path_out)) { return true; }
    path_out[0] = 0;
    return false;
}

fn project_uses_toml() bool { return ac_file_exists("aciso.toml"); }

fn load_config(path: *i8, cfg: *ac_cfg) bool {
    ac_cfg_init(cfg);
    snprintf(cfg.path, 2048u, "%s", path);
    cfg.use_toml = ac_str_ends_with(path, ".toml");
    let mut src: *i8= ac_read_file(path);
    if (src == (i8*)0) { return false; }
    if (cfg.use_toml) { toml_parse(src, cfg); } else { json_parse(src, cfg); }
    arc_free(src);
    return true;
}

fn save_config(cfg: *ac_cfg) bool {
    let mut out: *i8;
    if (cfg.use_toml) { out = toml_emit_cfg(cfg); } else { out = json_emit_cfg(cfg); }
    let mut ok: bool= ac_write_file(cfg.path, out);
    arc_free(out);
    return ok;
}

fn load_build_config(cfg: *ac_cfg) bool {
    let mut path: [2048]i8;
    if (!find_config("aciso", path, 2048)) {
        ac_err("no aciso.json or aciso.toml found in current directory");
        return false;
    }
    return load_config(path, cfg);
}

fn load_pkg_config(cfg: *ac_cfg) bool {
    let mut path: [2048]i8;
    if (!find_config("acm", path, 2048)) {
        ac_err("no acm.json or acm.toml found in current directory");
        return false;
    }
    return load_config(path, cfg);
}

fn load_lock(cfg: *ac_cfg) void {
    ac_cfg_init(cfg);
    snprintf(cfg.path, 2048u, "%s", "acm.lock");
    cfg.use_toml = true;
    if (!ac_file_exists("acm.lock")) { return; }
    let mut src: *i8= ac_read_file("acm.lock");
    if (src != (i8*)0) { toml_parse(src, cfg); arc_free(src); }
}

fn save_lock(cfg: *ac_cfg) bool {
    snprintf(cfg.path, 2048u, "%s", "acm.lock");
    cfg.use_toml = true;
    return save_config(cfg);
}

// ---- find artemis compiler ----

fn find_compiler(out: *i8, cap: i32) void {
    let mut h: *i8= getenv("ARTEMIS_HOME");
    if (h != (i8*)0) {
        snprintf(out, (u64)cap, "%s/bin/artemis.exe", h);
        if (ac_file_exists(out)) { return; }
        snprintf(out, (u64)cap, "%s/bin/artemis", h);
        if (ac_file_exists(out)) { return; }
    }
    snprintf(out, (u64)cap, "%s", "artemis");
}

// ---- SHA-256 for audit ----

fn ac_sha256_hex(data: *i8, dlen: i32, out: *i8) void {
    // Simple SHA-256 constants
    let mut K: [64]u32;
    K[0]=0x428a2f98u; K[1]=0x71374491u; K[2]=0xb5c0fbcfu; K[3]=0xe9b5dba5u;
    K[4]=0x3956c25bu; K[5]=0x59f111f1u; K[6]=0x923f82a4u; K[7]=0xab1c5ed5u;
    K[8]=0xd807aa98u; K[9]=0x12835b01u; K[10]=0x243185beu; K[11]=0x550c7dc3u;
    K[12]=0x72be5d74u; K[13]=0x80deb1feu; K[14]=0x9bdc06a7u; K[15]=0xc19bf174u;
    K[16]=0xe49b69c1u; K[17]=0xefbe4786u; K[18]=0x0fc19dc6u; K[19]=0x240ca1ccu;
    K[20]=0x2de92c6fu; K[21]=0x4a7484aau; K[22]=0x5cb0a9dcu; K[23]=0x76f988dau;
    K[24]=0x983e5152u; K[25]=0xa831c66du; K[26]=0xb00327c8u; K[27]=0xbf597fc7u;
    K[28]=0xc6e00bf3u; K[29]=0xd5a79147u; K[30]=0x06ca6351u; K[31]=0x14292967u;
    K[32]=0x27b70a85u; K[33]=0x2e1b2138u; K[34]=0x4d2c6dfcu; K[35]=0x53380d13u;
    K[36]=0x650a7354u; K[37]=0x766a0abbu; K[38]=0x81c2c92eu; K[39]=0x92722c85u;
    K[40]=0xa2bfe8a1u; K[41]=0xa81a664bu; K[42]=0xc24b8b70u; K[43]=0xc76c51a3u;
    K[44]=0xd192e819u; K[45]=0xd6990624u; K[46]=0xf40e3585u; K[47]=0x106aa070u;
    K[48]=0x19a4c116u; K[49]=0x1e376c08u; K[50]=0x2748774cu; K[51]=0x34b0bcb5u;
    K[52]=0x391c0cb3u; K[53]=0x4ed8aa4au; K[54]=0x5b9cca4fu; K[55]=0x682e6ff3u;
    K[56]=0x748f82eeu; K[57]=0x78a5636fu; K[58]=0x84c87814u; K[59]=0x8cc70208u;
    K[60]=0x90befffau; K[61]=0xa4506cebu; K[62]=0xbef9a3f7u; K[63]=0xc67178f2u;

    let mut h0: u32= 0x6a09e667u; let mut h1: u32= 0xbb67ae85u;
    let mut h2: u32= 0x3c6ef372u; let mut h3: u32= 0xa54ff53au;
    let mut h4: u32= 0x510e527fu; let mut h5: u32= 0x9b05688cu;
    let mut h6: u32= 0x1f83d9abu; let mut h7: u32= 0x5be0cd19u;

    let mut total: i32= dlen;
    let mut nblocks: i32= (total + 64 + 8) / 64;
    let mut padded: *i8= (i8*)arc_malloc((u64)(nblocks * 64));
    memset(padded, 0, (u64)(nblocks * 64));
    memcpy(padded, data, (u64)total);
    padded[total] = (i8)0x80;
    let mut bitlen: u64= (u64)total * 8u;
    let mut bl_off: i32= nblocks * 64 - 8;
    let mut bi: i32= 7;
    while (bi >= 0) {
        padded[bl_off + (7 - bi)] = (i8)((bitlen >> ((u64)bi * 8u)) & 0xFFu);
        bi = bi - 1;
    }

    let mut blk: i32= 0;
    while (blk < nblocks) {
        let mut w: [64]u32;
        let mut wi: i32= 0;
        while (wi < 16) {
            let mut off: i32= blk * 64 + wi * 4;
            w[wi] = ((u32)(u8)padded[off] << 24) | ((u32)(u8)padded[off+1] << 16) |
                    ((u32)(u8)padded[off+2] << 8) | (u32)(u8)padded[off+3];
            wi = wi + 1;
        }
        while (wi < 64) {
            let mut s0: u32= ((w[wi-15] >> 7) | (w[wi-15] << 25)) ^
                             ((w[wi-15] >> 18) | (w[wi-15] << 14)) ^ (w[wi-15] >> 3);
            let mut s1: u32= ((w[wi-2] >> 17) | (w[wi-2] << 15)) ^
                             ((w[wi-2] >> 19) | (w[wi-2] << 13)) ^ (w[wi-2] >> 10);
            w[wi] = w[wi-16] + s0 + w[wi-7] + s1;
            wi = wi + 1;
        }
        let mut a: u32= h0; let mut b: u32= h1; let mut c: u32= h2; let mut d: u32= h3;
        let mut e: u32= h4; let mut f: u32= h5; let mut g: u32= h6; let mut hv: u32= h7;
        let mut ri: i32= 0;
        while (ri < 64) {
            let mut S1: u32= ((e >> 6)|(e << 26))^((e >> 11)|(e << 21))^((e >> 25)|(e << 7));
            let mut ch: u32= (e & f) ^ ((~e) & g);
            let mut t1: u32= hv + S1 + ch + K[ri] + w[ri];
            let mut S0: u32= ((a >> 2)|(a << 30))^((a >> 13)|(a << 19))^((a >> 22)|(a << 10));
            let mut maj: u32= (a & b) ^ (a & c) ^ (b & c);
            let mut t2: u32= S0 + maj;
            hv = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
            ri = ri + 1;
        }
        h0 = h0 + a; h1 = h1 + b; h2 = h2 + c; h3 = h3 + d;
        h4 = h4 + e; h5 = h5 + f; h6 = h6 + g; h7 = h7 + hv;
        blk = blk + 1;
    }
    arc_free(padded);

    let mut digest: [8]u32;
    digest[0]=h0; digest[1]=h1; digest[2]=h2; digest[3]=h3;
    digest[4]=h4; digest[5]=h5; digest[6]=h6; digest[7]=h7;
    let mut oi: i32= 0;
    let mut di: i32= 0;
    while (di < 8) {
        snprintf(out + (i64)oi, 9u, "%08x", digest[di]);
        oi = oi + 8; di = di + 1;
    }
    out[64] = 0;
}

// ---- list .arc files recursively using system ----

fn ac_list_arc_files(dir: *i8, out: **i8, cap: i32) i32 {
    let mut cmd: [2048]i8;
    let mut tmpf: [512]i8;
    snprintf(tmpf, 512u, "%s", "aciso_ls_tmp.txt");
    // Use 'dir /s /b' on Windows to find .arc files recursively
    snprintf(cmd, 2048u, "dir /s /b \"%s\\*.arc\" > \"%s\" 2>NUL", dir, tmpf);
    system(cmd);
    let mut src: *i8= ac_read_file(tmpf);
    remove(tmpf);
    if (src == (i8*)0) { return 0; }
    let mut n: i32= 0;
    let mut p: *i8= src;
    while (*p != 0 && n < cap) {
        while (*p == ' ' || *p == '\t' || *p == '\r') { p = p + 1; }
        if (*p == '\n') { p = p + 1; continue; }
        if (*p == 0) { break; }
        let mut start: *i8= p;
        let mut line_len: i32= 0;
        while (*p != 0 && *p != '\n') { p = p + 1; line_len = line_len + 1; }
        if (line_len > 0) {
            let mut f: *i8= (i8*)arc_malloc((u64)(line_len + 1));
            memcpy(f, start, (u64)line_len);
            // trim trailing \r
            while (line_len > 0 && f[line_len-1] == '\r') { line_len = line_len - 1; }
            f[line_len] = 0;
            if (line_len > 0) { out[n] = f; n = n + 1; }
        }
        if (*p == '\n') { p = p + 1; }
    }
    arc_free(src);
    return n;
}

// ---- Windows CMD quoting fix ----
// When cmd.exe /c receives a command starting with ", it strips the outer
// pair of quotes, breaking the inner quoting. Fix: wrap in extra outer quotes.
fn ac_wrap_cmd(cmd: *i8, wcmd: *i8, cap: i32) void {
    if (cmd[0] == '"') {
        snprintf(wcmd, (u64)cap, "\"%s\"", cmd);
    } else {
        snprintf(wcmd, (u64)cap, "%s", cmd);
    }
}

fn ac_system_w(cmd: *i8) i32 {
    let mut wcmd: [4200]i8;
    ac_wrap_cmd(cmd, wcmd, 4200);
    return system(wcmd);
}

// ---- capture command output ----

fn ac_capture_cmd(cmd: *i8, out: *i8, cap: i32) void {
    let mut wcmd: [4200]i8;
    ac_wrap_cmd(cmd, wcmd, 4200);
    let mut fp: *void= _popen(wcmd, "r");
    if (fp == (void*)0) { out[0] = 0; return; }
    let mut n: i32= 0;
    let mut buf: [512]i8;
    while (fgets(buf, 512, fp) != (i8*)0 && n < cap - 1) {
        let mut bl: i32= (i32)strlen(buf);
        if (n + bl >= cap - 1) { bl = cap - 1 - n; }
        memcpy(out + (i64)n, buf, (u64)bl);
        n = n + bl;
    }
    out[n] = 0;
    _pclose(fp);
}

// ---- output type helpers ----

fn output_ext(ty: *i8) *i8 {
    if (strcmp(ty, "exe") == 0 || strcmp(ty, "executable") == 0) { return ".exe"; }
    if (strcmp(ty, "elf") == 0) { return ""; }
    if (strcmp(ty, "mco") == 0) { return ".mco"; }
    if (strcmp(ty, "dll") == 0) { return ".dll"; }
    if (strcmp(ty, "so") == 0)  { return ".so"; }
    if (strcmp(ty, "dylib") == 0) { return ".dylib"; }
    if (strcmp(ty, "static") == 0 || strcmp(ty, "a") == 0 || strcmp(ty, "lib") == 0) { return ".a"; }
    if (strcmp(ty, "wasm") == 0) { return ".wasm"; }
    if (strcmp(ty, "wasi") == 0) { return ".wasi"; }
    if (strcmp(ty, "ll") == 0) { return ".ll"; }
    if (strcmp(ty, "bc") == 0) { return ".bc"; }
    if (strcmp(ty, "obj") == 0 || strcmp(ty, "o") == 0) { return ".o"; }
    return "";
}

fn type_from_ext(filename: *i8) *i8 {
    if (ac_str_ends_with(filename, ".exe")) { return "exe"; }
    if (ac_str_ends_with(filename, ".dll")) { return "dll"; }
    if (ac_str_ends_with(filename, ".so"))  { return "so"; }
    if (ac_str_ends_with(filename, ".dylib")) { return "dylib"; }
    if (ac_str_ends_with(filename, ".a") || ac_str_ends_with(filename, ".lib")) { return "static"; }
    if (ac_str_ends_with(filename, ".wasm")) { return "wasm"; }
    if (ac_str_ends_with(filename, ".wasi")) { return "wasi"; }
    if (ac_str_ends_with(filename, ".ll")) { return "ll"; }
    if (ac_str_ends_with(filename, ".bc")) { return "bc"; }
    if (ac_str_ends_with(filename, ".o") || ac_str_ends_with(filename, ".obj")) { return "obj"; }
    return "exe";
}

fn file_stem(filename: *i8, out: *i8, cap: i32) void {
    // Find last path separator
    let mut base_off: i32= 0;
    let mut fi: i32= 0;
    while (filename[fi] != 0) {
        if (filename[fi] == '/' || filename[fi] == '\\') { base_off = fi + 1; }
        fi = fi + 1;
    }
    // Find last dot from base
    let mut dot_off: i32= -1;
    let mut fi2: i32= base_off;
    while (filename[fi2] != 0) {
        if (filename[fi2] == '.') { dot_off = fi2; }
        fi2 = fi2 + 1;
    }
    let mut n: i32;
    if (dot_off > base_off) { n = dot_off - base_off; } else { n = fi2 - base_off; }
    if (n >= cap) { n = cap - 1; }
    let mut oi: i32= 0;
    while (oi < n) { out[oi] = filename[base_off + oi]; oi = oi + 1; }
    out[n] = 0;
}

// ---- compile_one: invoke the compiler for one target ----

fn compile_one(compiler: *i8, src: *i8, out_path: *i8, ty: *i8, release: bool) i32 {
    let mut sym_str: [512]i8;
    sym_str[0] = 0;
    if (release) { snprintf(sym_str, 512u, " -D __RELEASE"); }

    let mut tmp_obj: [2048]i8;
    let mut tmp_ll: [2048]i8;
    snprintf(tmp_obj, 2048u, "%s.tmp.o", out_path);
    snprintf(tmp_ll, 2048u, "%s.tmp.ll", out_path);
    let mut cmd: [4096]i8;
    let mut rc: i32= 0;

    if (strcmp(ty, "exe") == 0 || strcmp(ty, "executable") == 0 || strcmp(ty, "elf") == 0) {
        snprintf(cmd, 4096u, "\"%s\" \"%s\" -o \"%s\"%s", compiler, src, out_path, sym_str);
        return ac_system_w(cmd);
    }
    if (strcmp(ty, "ll") == 0) {
        snprintf(cmd, 4096u, "\"%s\" -S \"%s\" -o \"%s\"%s", compiler, src, out_path, sym_str);
        return ac_system_w(cmd);
    }
    if (strcmp(ty, "obj") == 0 || strcmp(ty, "o") == 0) {
        snprintf(cmd, 4096u, "\"%s\" -c \"%s\" -o \"%s\"%s", compiler, src, out_path, sym_str);
        return ac_system_w(cmd);
    }
    if (strcmp(ty, "bc") == 0) {
        snprintf(cmd, 4096u, "\"%s\" -S \"%s\" -o \"%s\"%s", compiler, src, tmp_ll, sym_str);
        if (ac_system_w(cmd) != 0) { remove(tmp_ll); return 1; }
        snprintf(cmd, 4096u, "llvm-as \"%s\" -o \"%s\"", tmp_ll, out_path);
        rc = system(cmd);
        remove(tmp_ll);
        return rc;
    }
    if (strcmp(ty, "dll") == 0 || strcmp(ty, "so") == 0 || strcmp(ty, "dylib") == 0) {
        snprintf(cmd, 4096u, "\"%s\" -c \"%s\" -o \"%s\"%s", compiler, src, tmp_obj, sym_str);
        if (ac_system_w(cmd) != 0) { remove(tmp_obj); return 1; }
        if (strcmp(ty, "dll") == 0) {
            snprintf(cmd, 4096u, "clang -shared -o \"%s\" \"%s\"", out_path, tmp_obj);
        } else if (strcmp(ty, "so") == 0) {
            snprintf(cmd, 4096u, "clang -shared -fPIC -o \"%s\" \"%s\"", out_path, tmp_obj);
        } else {
            snprintf(cmd, 4096u, "clang -dynamiclib -o \"%s\" \"%s\"", out_path, tmp_obj);
        }
        rc = system(cmd);
        remove(tmp_obj);
        return rc;
    }
    if (strcmp(ty, "static") == 0 || strcmp(ty, "a") == 0 || strcmp(ty, "lib") == 0) {
        snprintf(cmd, 4096u, "\"%s\" -c \"%s\" -o \"%s\"%s", compiler, src, tmp_obj, sym_str);
        if (ac_system_w(cmd) != 0) { remove(tmp_obj); return 1; }
        snprintf(cmd, 4096u, "ar rcs \"%s\" \"%s\"", out_path, tmp_obj);
        rc = system(cmd);
        remove(tmp_obj);
        return rc;
    }
    if (strcmp(ty, "wasm") == 0) {
        snprintf(cmd, 4096u, "\"%s\" -S \"%s\" -o \"%s\"%s", compiler, src, tmp_ll, sym_str);
        if (ac_system_w(cmd) != 0) { remove(tmp_ll); return 1; }
        snprintf(cmd, 4096u, "clang --target=wasm32-unknown-unknown -nostdlib -Wl,--no-entry -Wl,--export-all -o \"%s\" \"%s\"", out_path, tmp_ll);
        rc = system(cmd);
        remove(tmp_ll);
        return rc;
    }
    if (strcmp(ty, "wasi") == 0) {
        snprintf(cmd, 4096u, "\"%s\" -S \"%s\" -o \"%s\"%s", compiler, src, tmp_ll, sym_str);
        if (ac_system_w(cmd) != 0) { remove(tmp_ll); return 1; }
        snprintf(cmd, 4096u, "clang --target=wasm32-wasi -o \"%s\" \"%s\"", out_path, tmp_ll);
        rc = system(cmd);
        remove(tmp_ll);
        return rc;
    }
    ac_err("unknown output type");
    return 1;
}

// ---- cmd_init ----

fn cmd_init(use_toml: bool) void {
    let mut ext: *i8= use_toml ? ".toml" : ".json";
    let mut aciso_p: [32]i8;
    let mut acm_p: [16]i8;
    snprintf(aciso_p, 32u, "aciso%s", ext);
    snprintf(acm_p, 16u, "acm%s", ext);
    if (ac_file_exists(aciso_p) || ac_file_exists(acm_p)) {
        ac_err("project already initialised");
        return;
    }

    // Use "project" as default name
    let mut name: *i8= "project";

    if (use_toml) {
        let mut build_content: [1024]i8;
        snprintf(build_content, 1024u,
            "[project]\nname = \"%s\"\nversion = \"0.1.0\"\nmain = \"src/main.arc\"\nowner = \"\"\nauthors = []\n\n[build]\noutput_dir = \"build/\"\nsource_dir = \"src/\"\n\n[symbol]\ndefined_symbols = []\n\n[targets]\nmain_f = [\"dll\", \"so\", \"dylib\"]\n",
            name);
        ac_write_file("aciso.toml", build_content);
        let mut pkg_content: [512]i8;
        snprintf(pkg_content, 512u,
            "[package]\nname = \"%s\"\nversion = \"0.1.0\"\nauthors = []\n\n[dependencies]\n\n[dev-dependencies]\n",
            name);
        ac_write_file("acm.toml", pkg_content);
    } else {
        let mut build_content: [1024]i8;
        snprintf(build_content, 1024u,
            "{\n  \"project\": {\"name\": \"%s\", \"version\": \"0.1.0\", \"main\": \"src/main.arc\", \"owner\": \"\", \"authors\": []},\n  \"build\": {\"output_dir\": \"build/\", \"source_dir\": \"src/\"},\n  \"symbol\": {\"defined_symbols\": []},\n  \"targets\": {\"main_f\": [\"dll\", \"so\", \"dylib\"]}\n}\n",
            name);
        ac_write_file("aciso.json", build_content);
        let mut pkg_content: [512]i8;
        snprintf(pkg_content, 512u,
            "{\n  \"package\": {\"name\": \"%s\", \"version\": \"0.1.0\", \"authors\": []},\n  \"dependencies\": {},\n  \"dev-dependencies\": {}\n}\n",
            name);
        ac_write_file("acm.json", pkg_content);
    }

    ac_mkdir_p("src");
    if (!ac_file_exists("src/main.arc")) {
        ac_write_file("src/main.arc", "pub fn main() int {\n    return 0;\n}\n");
    }
    ac_mkdir_p("build");
    ac_mkdir_p("modules");

    let mut msg: [256]i8;
    snprintf(msg, 256u, "initialised project \"%s\" (%s format)", name, use_toml ? "toml" : "json");
    ac_ok(msg);
}

fn cmd_deinit() void {
    let mut removed: bool= false;
    let mut files: [5]*i8;
    files[0] = "aciso.toml"; files[1] = "aciso.json";
    files[2] = "acm.toml";   files[3] = "acm.json"; files[4] = "acm.lock";
    let mut fi: i32= 0;
    while (fi < 5) {
        if (ac_file_exists(files[fi])) { remove(files[fi]); removed = true; }
        fi = fi + 1;
    }
    if (!removed) { ac_warn("no manifest files found"); return; }
    ac_ok("removed manifests; source files preserved");
}

// ---- cmd_install ----

fn cmd_install(pkg_name: *i8, url: *i8) void {
    if (strcmp(pkg_name, ".") == 0) { ac_err("invalid package name '.'"); return; }

    let mut tmp_dir: [512]i8;
    snprintf(tmp_dir, 512u, "aciso_tmp_%s", pkg_name);

    ac_rm_rf(tmp_dir);

    let mut msg: [256]i8;
    snprintf(msg, 256u, "cloning %s ...", url);
    ac_info(msg);

    let mut clone_cmd: [2048]i8;
    snprintf(clone_cmd, 2048u, "git clone --depth=1 \"%s\" \"%s\"", url, tmp_dir);
    if (system(clone_cmd) != 0) {
        snprintf(msg, 256u, "git clone failed for %s", url);
        ac_err(msg);
        return;
    }

    // Read export manifest
    let mut exp_cfg: ac_cfg;
    let mut exp_path: [512]i8;
    let mut found_exp: bool= false;
    snprintf(exp_path, 512u, "%s/export.toml", tmp_dir);
    if (ac_file_exists(exp_path)) {
        load_config(exp_path, &exp_cfg);
        found_exp = true;
    } else {
        snprintf(exp_path, 512u, "%s/export.json", tmp_dir);
        if (ac_file_exists(exp_path)) {
            load_config(exp_path, &exp_cfg);
            found_exp = true;
        }
    }

    if (!found_exp) {
        ac_err("no export.[toml|json] found in package");
        ac_rm_rf(tmp_dir);
        return;
    }

    let mut n_exports: i32= ac_cfg_arr_len(&exp_cfg, "export");
    if (n_exports == 0) {
        ac_err("'export' array missing or empty in manifest");
        ac_rm_rf(tmp_dir);
        return;
    }

    let mut dest: [512]i8;
    snprintf(dest, 512u, "modules/%s", pkg_name);
    ac_mkdir_p(dest);

    // Combine all exported file content for SHA-256
    let mut combined_sb: strbuf;
    strbuf_init(&combined_sb);

    let mut ei: i32= 0;
    while (ei < n_exports) {
        let mut rel: *i8= ac_cfg_arr_get(&exp_cfg, "export", ei);
        if (rel == (i8*)0) { ei = ei + 1; continue; }
        let mut src_p: [2048]i8;
        let mut dst_p: [2048]i8;
        snprintf(src_p, 2048u, "%s/%s", tmp_dir, rel);
        snprintf(dst_p, 2048u, "%s/%s", dest, rel);

        // Ensure destination subdir exists
        let mut dst_dir: [2048]i8;
        snprintf(dst_dir, 2048u, "%s", dst_p);
        let mut last_sep: *i8= strrchr(dst_dir, '/');
        if (last_sep != (i8*)0) { *last_sep = 0; ac_mkdir_p(dst_dir); }

        if (!ac_file_exists(src_p)) {
            snprintf(msg, 256u, "export file not found: %s", src_p);
            ac_warn(msg);
            ei = ei + 1;
            continue;
        }
        ac_copy_file(src_p, dst_p);
        let mut fc: *i8= ac_read_file(src_p);
        if (fc != (i8*)0) { strbuf_append(&combined_sb, fc); arc_free(fc); }

        snprintf(msg, 256u, "installed %s", dst_p);
        ac_info(msg);
        ei = ei + 1;
    }

    ac_rm_rf(tmp_dir);

    let mut hash: [65]i8;
    let mut combined: *i8= strbuf_finish(&combined_sb);
    ac_sha256_hex(combined, (i32)strlen(combined), hash);
    arc_free(combined);

    // Update acm.json/toml
    let mut acm: ac_cfg;
    if (load_pkg_config(&acm)) {
        let mut dep_key: [256]i8;
        snprintf(dep_key, 256u, "dependencies.%s", pkg_name);
        ac_cfg_set(&acm, dep_key, url);
        save_config(&acm);
    }

    // Update acm.lock
    let mut lock: ac_cfg;
    load_lock(&lock);

    // Remove existing entry for this package
    let mut n_pkgs: i32= ac_cfg_arr_len(&lock, "package");
    let mut new_lock: ac_cfg;
    ac_cfg_init(&new_lock);
    snprintf(new_lock.path, 2048u, "acm.lock");
    new_lock.use_toml = true;
    ac_cfg_set(&new_lock, "version", "1");
    let mut pi2: i32= 0;
    while (pi2 < n_pkgs) {
        let mut pname_key: [64]i8;
        snprintf(pname_key, 64u, "package[%d].name", pi2);
        let mut pname: *i8= ac_cfg_get(&lock, pname_key);
        if (pname != (i8*)0 && strcmp(pname, pkg_name) != 0) {
            // Copy all fields for this package to new_lock
            let mut pn2: i32= ac_cfg_arr_len(&new_lock, "package");
            let mut fn_key: [64]i8;
            snprintf(fn_key, 64u, "package[%d].name", pi2);
            let mut fs_key: [64]i8;
            snprintf(fs_key, 64u, "package[%d].source", pi2);
            let mut fh_key: [64]i8;
            snprintf(fh_key, 64u, "package[%d].sha256", pi2);
            let mut new_nk: [64]i8;
            snprintf(new_nk, 64u, "package[%d].name", pn2);
            let mut new_sk: [64]i8;
            snprintf(new_sk, 64u, "package[%d].source", pn2);
            let mut new_hk: [64]i8;
            snprintf(new_hk, 64u, "package[%d].sha256", pn2);
            let mut lk2: [64]i8;
            snprintf(lk2, 64u, "package._len");
            let mut lv2: [16]i8;
            snprintf(lv2, 16u, "%d", pn2 + 1);
            ac_cfg_set(&new_lock, new_nk, ac_cfg_get(&lock, fn_key));
            ac_cfg_set(&new_lock, new_sk, ac_cfg_get(&lock, fs_key));
            ac_cfg_set(&new_lock, new_hk, ac_cfg_get(&lock, fh_key));
            ac_cfg_set(&new_lock, lk2, lv2);
        }
        pi2 = pi2 + 1;
    }
    // Add new entry
    let mut new_idx: i32= ac_cfg_arr_len(&new_lock, "package");
    let mut nn_key: [64]i8;
    snprintf(nn_key, 64u, "package[%d].name", new_idx);
    let mut ns_key: [64]i8;
    snprintf(ns_key, 64u, "package[%d].source", new_idx);
    let mut nh_key: [64]i8;
    snprintf(nh_key, 64u, "package[%d].sha256", new_idx);
    let mut nl_key: [64]i8;
    snprintf(nl_key, 64u, "package._len");
    let mut nl_val: [16]i8;
    snprintf(nl_val, 16u, "%d", new_idx + 1);
    ac_cfg_set(&new_lock, nn_key, pkg_name);
    ac_cfg_set(&new_lock, ns_key, url);
    ac_cfg_set(&new_lock, nh_key, hash);
    ac_cfg_set(&new_lock, nl_key, nl_val);
    save_lock(&new_lock);

    snprintf(msg, 256u, "installed %s", pkg_name);
    ac_ok(msg);
}

fn cmd_uninstall(pkg_name: *i8) void {
    let mut dest: [512]i8;
    snprintf(dest, 512u, "modules/%s", pkg_name);
    if (!ac_file_exists(dest)) {
        let mut msg: [256]i8;
        snprintf(msg, 256u, "package not installed: %s", pkg_name);
        ac_err(msg);
        return;
    }
    ac_rm_rf(dest);

    let mut acm: ac_cfg;
    if (load_pkg_config(&acm)) {
        let mut dep_key: [256]i8;
        snprintf(dep_key, 256u, "dependencies.%s", pkg_name);
        ac_cfg_del(&acm, dep_key);
        snprintf(dep_key, 256u, "dev-dependencies.%s", pkg_name);
        ac_cfg_del(&acm, dep_key);
        save_config(&acm);
    }

    let mut msg: [256]i8;
    snprintf(msg, 256u, "uninstalled %s", pkg_name);
    ac_ok(msg);
}

fn cmd_update(pkg_name: *i8) void {
    let mut acm: ac_cfg;
    if (!load_pkg_config(&acm)) { return; }
    let mut dep_key: [256]i8;
    snprintf(dep_key, 256u, "dependencies.%s", pkg_name);
    let mut url: *i8= ac_cfg_get(&acm, dep_key);
    if (url == (i8*)0) {
        snprintf(dep_key, 256u, "dev-dependencies.%s", pkg_name);
        url = ac_cfg_get(&acm, dep_key);
    }
    if (url == (i8*)0) {
        let mut msg: [256]i8;
        snprintf(msg, 256u, "package not found in dependencies: %s", pkg_name);
        ac_err(msg);
        return;
    }
    let mut dest: [512]i8;
    snprintf(dest, 512u, "modules/%s", pkg_name);
    ac_rm_rf(dest);
    cmd_install(pkg_name, url);
}

fn cmd_vald() void {
    let mut acm: ac_cfg;
    if (!load_pkg_config(&acm)) { return; }
    let mut all_ok: bool= true;
    let mut i: i32= 0;
    // Check dependencies.*
    while (i < acm.len) {
        let mut k: *i8= acm.entries[i].key;
        if (ac_str_starts_with(k, "dependencies.") && !ac_str_ends_with(k, "._len")) {
            let mut dot2: *i8= strchr(k + 13, '.');
            if (dot2 == (i8*)0) {
                let mut pname: *i8= k + 13;
                let mut pdir: [512]i8;
                snprintf(pdir, 512u, "modules/%s", pname);
                if (!ac_file_exists(pdir)) {
                    let mut msg: [256]i8;
                    snprintf(msg, 256u, "missing package directory: modules/%s", pname);
                    ac_err(msg);
                    all_ok = false;
                }
            }
        }
        i = i + 1;
    }
    if (all_ok) { ac_ok("all packages present in modules/"); }
}

fn cmd_audit() void {
    let mut lock: ac_cfg;
    load_lock(&lock);
    let mut n_pkgs: i32= ac_cfg_arr_len(&lock, "package");
    if (n_pkgs == 0) { ac_info("no packages in lock file"); return; }

    let mut clean: bool= true;
    let mut pi: i32= 0;
    while (pi < n_pkgs) {
        let mut nk: [64]i8;
        snprintf(nk, 64u, "package[%d].name", pi);
        let mut hk: [64]i8;
        snprintf(hk, 64u, "package[%d].sha256", pi);
        let mut pname: *i8= ac_cfg_get(&lock, nk);
        let mut stored: *i8= ac_cfg_get(&lock, hk);
        if (pname == (i8*)0) { pi = pi + 1; continue; }

        let mut mod_dir: [512]i8;
        snprintf(mod_dir, 512u, "modules/%s", pname);
        if (!ac_file_exists(mod_dir)) {
            let mut msg: [256]i8;
            snprintf(msg, 256u, "package %s not installed", pname);
            ac_warn(msg);
            pi = pi + 1;
            continue;
        }

        // Hash all .arc files in module directory
        let mut files: [256]*i8;
        let mut nf: i32= ac_list_arc_files(mod_dir, files, 256);
        let mut combined_sb: strbuf;
        strbuf_init(&combined_sb);
        let mut fi: i32= 0;
        while (fi < nf) {
            let mut fc: *i8= ac_read_file(files[fi]);
            if (fc != (i8*)0) { strbuf_append(&combined_sb, fc); arc_free(fc); }
            arc_free(files[fi]);
            fi = fi + 1;
        }
        let mut combined: *i8= strbuf_finish(&combined_sb);
        let mut actual: [65]i8;
        ac_sha256_hex(combined, (i32)strlen(combined), actual);
        arc_free(combined);

        let mut msg: [256]i8;
        if (stored != (i8*)0 && strcmp(actual, stored) == 0) {
            snprintf(msg, 256u, "verified %s", pname);
            ac_ok(msg);
        } else {
            snprintf(msg, 256u, "hash mismatch for %s", pname);
            ac_err(msg);
            clean = false;
        }
        pi = pi + 1;
    }
    if (clean) { ac_ok("audit passed — all hashes match"); }
}

// ---- build ----

fn do_build_target(compiler: *i8, src: *i8, name: *i8, ty: *i8, out_dir: *i8, release: bool) bool {
    let mut out_name: [512]i8;
    snprintf(out_name, 512u, "%s%s", name, output_ext(ty));
    let mut out_path: [2048]i8;
    snprintf(out_path, 2048u, "%s%s", out_dir, out_name);
    ac_mkdir_p(out_dir);
    let mut msg: [256]i8;
    snprintf(msg, 256u, "building %s [%s] from %s", out_path, ty, src);
    ac_info(msg);
    let mut rc: i32= compile_one(compiler, src, out_path, ty, release);
    if (rc != 0) {
        snprintf(msg, 256u, "build failed for %s (exit %d)", out_path, rc);
        ac_err(msg);
        return false;
    }
    snprintf(msg, 256u, "built %s", out_path);
    ac_ok(msg);
    return true;
}

fn cmd_build(release: bool) void {
    let mut cfg: ac_cfg;
    if (!load_build_config(&cfg)) { return; }

    let mut compiler: [512]i8;
    find_compiler(compiler, 512);

    let mut main_src: *i8= ac_cfg_get_or(&cfg, "project.main", "src/main.arc");
    let mut name: *i8= ac_cfg_get_or(&cfg, "project.name", "out");
    let mut out_dir: *i8= ac_cfg_get_or(&cfg, "build.output_dir", "build/");

    let mut all_ok: bool= true;

    // Check if targets.main_f is defined
    let mut mf_len: i32= ac_cfg_arr_len(&cfg, "targets.main_f");
    if (mf_len > 0) {
        let mut ti: i32= 0;
        while (ti < mf_len) {
            let mut ty: *i8= ac_cfg_arr_get(&cfg, "targets.main_f", ti);
            if (ty != (i8*)0) {
                if (!do_build_target(compiler, main_src, name, ty, out_dir, release)) { all_ok = false; }
            }
            ti = ti + 1;
        }
    } else {
        // Default: build executable
        if (!do_build_target(compiler, main_src, name, "exe", out_dir, release)) { all_ok = false; }
    }

    if (all_ok) { ac_ok("build complete"); } else { ac_err("build finished with errors"); }
}

fn cmd_sbuild(target_name: *i8) void {
    let mut cfg: ac_cfg;
    if (!load_build_config(&cfg)) { return; }
    let mut compiler: [512]i8;
    find_compiler(compiler, 512);
    let mut main_src: *i8= ac_cfg_get_or(&cfg, "project.main", "src/main.arc");
    let mut out_dir: *i8= ac_cfg_get_or(&cfg, "build.output_dir", "build/");

    // targets.TARGET_NAME.source / .type
    let mut src_key: [512]i8;
    snprintf(src_key, 512u, "targets.%s.source", target_name);
    let mut ty_key: [512]i8;
    snprintf(ty_key, 512u, "targets.%s.type", target_name);
    let mut src: *i8= ac_cfg_get_or(&cfg, src_key, main_src);
    let mut ty: *i8= ac_cfg_get_or(&cfg, ty_key, "exe");
    do_build_target(compiler, src, target_name, ty, out_dir, false);
}

fn cmd_run() void {
    let mut cfg: ac_cfg;
    if (!load_build_config(&cfg)) { return; }
    let mut compiler: [512]i8;
    find_compiler(compiler, 512);
    let mut main_src: *i8= ac_cfg_get_or(&cfg, "project.main", "src/main.arc");
    let mut name: *i8= ac_cfg_get_or(&cfg, "project.name", "out");
    let mut out_dir: *i8= ac_cfg_get_or(&cfg, "build.output_dir", "build/");
    let mut exe: [512]i8;
    snprintf(exe, 512u, "%s%s.exe", out_dir, name);
    let mut cmd: [4096]i8;
    snprintf(cmd, 4096u, "\"%s\" \"%s\" -o \"%s\"", compiler, main_src, exe);
    if (ac_system_w(cmd) != 0) { ac_err("build failed"); return; }
    let mut msg: [256]i8;
    snprintf(msg, 256u, "built %s, running...", exe);
    ac_ok(msg);
    snprintf(cmd, 4096u, "\"%s\"", exe);
    ac_system_w(cmd);
}

fn cmd_clean() void {
    let mut cfg: ac_cfg;
    let mut out_dir: [256]i8;
    snprintf(out_dir, 256u, "build/");
    if (load_build_config(&cfg)) {
        let mut od: *i8= ac_cfg_get(&cfg, "build.output_dir");
        if (od != (i8*)0) { snprintf(out_dir, 256u, "%s", od); }
    }
    if (ac_file_exists(out_dir)) {
        ac_rm_rf(out_dir);
        let mut msg: [256]i8;
        snprintf(msg, 256u, "removed %s", out_dir);
        ac_ok(msg);
    } else {
        let mut msg: [256]i8;
        snprintf(msg, 256u, "build directory not found: %s", out_dir);
        ac_warn(msg);
    }
}

// ---- targets ----

fn cmd_add(filename: *i8) void {
    let mut ty: *i8= type_from_ext(filename);
    let mut stem: [256]i8;
    file_stem(filename, stem, 256);
    let mut cfg: ac_cfg;
    if (!load_build_config(&cfg)) { return; }
    let mut src_dir: *i8= ac_cfg_get_or(&cfg, "build.source_dir", "src/");
    let mut source: [512]i8;
    snprintf(source, 512u, "%s%s.arc", src_dir, stem);
    let mut src_key: [512]i8;
    snprintf(src_key, 512u, "targets.%s.source", filename);
    let mut ty_key: [512]i8;
    snprintf(ty_key, 512u, "targets.%s.type", filename);
    ac_cfg_set(&cfg, src_key, source);
    ac_cfg_set(&cfg, ty_key, ty);
    save_config(&cfg);
    let mut msg: [256]i8;
    snprintf(msg, 256u, "added target \"%s\" (%s) <- %s", filename, ty, source);
    ac_ok(msg);
}

fn cmd_addf(filename: *i8, ty: *i8) void {
    let mut stem: [256]i8;
    file_stem(filename, stem, 256);
    let mut cfg: ac_cfg;
    if (!load_build_config(&cfg)) { return; }
    let mut src_dir: *i8= ac_cfg_get_or(&cfg, "build.source_dir", "src/");
    let mut source: [512]i8;
    snprintf(source, 512u, "%s%s.arc", src_dir, stem);
    let mut src_key: [512]i8;
    snprintf(src_key, 512u, "targets.%s.source", filename);
    let mut ty_key: [512]i8;
    snprintf(ty_key, 512u, "targets.%s.type", filename);
    ac_cfg_set(&cfg, src_key, source);
    ac_cfg_set(&cfg, ty_key, ty);
    save_config(&cfg);
    let mut msg: [256]i8;
    snprintf(msg, 256u, "added target \"%s\" (%s) <- %s", filename, ty, source);
    ac_ok(msg);
}

fn cmd_rmt(target_name: *i8) void {
    let mut cfg: ac_cfg;
    if (!load_build_config(&cfg)) { return; }
    let mut src_key: [512]i8;
    snprintf(src_key, 512u, "targets.%s.source", target_name);
    let mut ty_key: [512]i8;
    snprintf(ty_key, 512u, "targets.%s.type", target_name);
    if (ac_cfg_get(&cfg, src_key) == (i8*)0) {
        let mut msg: [256]i8;
        snprintf(msg, 256u, "target not found: %s", target_name);
        ac_err(msg);
        return;
    }
    ac_cfg_del(&cfg, src_key);
    ac_cfg_del(&cfg, ty_key);
    save_config(&cfg);
    let mut msg: [256]i8;
    snprintf(msg, 256u, "removed target %s", target_name);
    ac_ok(msg);
}

fn cmd_lst() void {
    let mut cfg: ac_cfg;
    if (!load_build_config(&cfg)) { return; }
    printf("Build targets:\n");
    let mut main_src: *i8= ac_cfg_get_or(&cfg, "project.main", "src/main.arc");
    let mut name: *i8= ac_cfg_get_or(&cfg, "project.name", "out");
    let mut mf_len: i32= ac_cfg_arr_len(&cfg, "targets.main_f");
    if (mf_len > 0) {
        printf("  main_f  [");
        let mut ti: i32= 0;
        while (ti < mf_len) {
            let mut ty: *i8= ac_cfg_arr_get(&cfg, "targets.main_f", ti);
            if (ti > 0) { printf(", "); }
            printf("%s", ty != (i8*)0 ? ty : "");
            ti = ti + 1;
        }
        printf("]  %s -> build/%s.<type>\n", main_src, name);
    }
    // Print named targets
    let mut i: i32= 0;
    while (i < cfg.len) {
        let mut k: *i8= cfg.entries[i].key;
        if (ac_str_starts_with(k, "targets.") && ac_str_ends_with(k, ".type")) {
            let mut after: *i8= k + 8; // after "targets."
            let mut dot: *i8= strrchr(after, '.');
            if (dot != (i8*)0) {
                let mut tname_len: i32= 0;
                while (after[tname_len] != 0 && after[tname_len] != '.') { tname_len = tname_len + 1; }
                let mut tname: [256]i8;
                memcpy(tname, after, (u64)tname_len);
                tname[tname_len] = 0;
                let mut src_key: [512]i8;
                snprintf(src_key, 512u, "targets.%s.source", tname);
                let mut src: *i8= ac_cfg_get_or(&cfg, src_key, main_src);
                printf("  %s  [%s]  %s\n", tname, cfg.entries[i].val, src);
            }
        }
        i = i + 1;
    }
}

// ---- symbols ----

fn cmd_itarget(symbol: *i8) void {
    let mut cfg: ac_cfg;
    if (!load_build_config(&cfg)) { return; }
    let mut n: i32= ac_cfg_arr_len(&cfg, "symbol.defined_symbols");
    let mut si: i32= 0;
    while (si < n) {
        let mut sv: *i8= ac_cfg_arr_get(&cfg, "symbol.defined_symbols", si);
        if (sv != (i8*)0 && strcmp(sv, symbol) == 0) {
            let mut msg: [256]i8;
            snprintf(msg, 256u, "symbol already defined: %s", symbol);
            ac_warn(msg);
            return;
        }
        si = si + 1;
    }
    ac_cfg_arr_push(&cfg, "symbol.defined_symbols", symbol);
    save_config(&cfg);
    let mut msg: [256]i8;
    snprintf(msg, 256u, "defined symbol: %s", symbol);
    ac_ok(msg);
}

fn cmd_utarget(symbol: *i8) void {
    let mut cfg: ac_cfg;
    if (!load_build_config(&cfg)) { return; }
    let mut n: i32= ac_cfg_arr_len(&cfg, "symbol.defined_symbols");
    let mut found: bool= false;
    // rebuild array without the symbol
    let mut new_syms: [256]*i8;
    let mut nn: i32= 0;
    let mut si: i32= 0;
    while (si < n) {
        let mut sv: *i8= ac_cfg_arr_get(&cfg, "symbol.defined_symbols", si);
        if (sv != (i8*)0 && strcmp(sv, symbol) != 0) {
            new_syms[nn] = sv; nn = nn + 1;
        } else if (sv != (i8*)0) { found = true; }
        si = si + 1;
    }
    if (!found) {
        let mut msg: [256]i8;
        snprintf(msg, 256u, "symbol not defined: %s", symbol);
        ac_err(msg);
        return;
    }
    // Clear old array
    let mut lk: [256]i8;
    snprintf(lk, 256u, "symbol.defined_symbols._len");
    ac_cfg_set(&cfg, lk, "0");
    let mut ri: i32= 0;
    while (ri < n) {
        let mut ek: [256]i8;
        snprintf(ek, 256u, "symbol.defined_symbols[%d]", ri);
        ac_cfg_del(&cfg, ek);
        ri = ri + 1;
    }
    // Re-insert
    ri = 0;
    while (ri < nn) {
        ac_cfg_arr_push(&cfg, "symbol.defined_symbols", new_syms[ri]);
        ri = ri + 1;
    }
    save_config(&cfg);
    let mut msg: [256]i8;
    snprintf(msg, 256u, "undefined symbol: %s", symbol);
    ac_ok(msg);
}

// ---- fmt ----

fn fmt_arc_src(src: *i8, out: *i8, cap: i32) void {
    let mut sb: strbuf;
    strbuf_init(&sb);
    let mut p: *i8= src;
    let mut blanks: i32= 0;
    while (*p != 0) {
        let mut line_start: *i8= p;
        let mut line_len: i32= 0;
        while (*p != 0 && *p != '\n') { p = p + 1; line_len = line_len + 1; }
        // Strip trailing \r
        while (line_len > 0 && (line_start[line_len-1] == '\r' || line_start[line_len-1] == ' ' || line_start[line_len-1] == '\t')) {
            line_len = line_len - 1;
        }
        if (line_len == 0) {
            blanks = blanks + 1;
            if (blanks <= 1) { strbuf_push(&sb, '\n'); }
        } else {
            blanks = 0;
            let mut ci: i32= 0;
            while (ci < line_len) { strbuf_push(&sb, line_start[ci]); ci = ci + 1; }
            strbuf_push(&sb, '\n');
        }
        if (*p == '\n') { p = p + 1; }
    }
    let mut res: *i8= strbuf_finish(&sb);
    let mut rlen: i32= (i32)strlen(res);
    if (rlen >= cap) { rlen = cap - 1; }
    memcpy(out, res, (u64)rlen);
    out[rlen] = 0;
    arc_free(res);
}

fn fmt_file(path: *i8) void {
    let mut orig: *i8= ac_read_file(path);
    if (orig == (i8*)0) { return; }
    let mut orig_len: i32= (i32)strlen(orig);
    let mut cap: i32= orig_len * 2 + 256;
    if (cap < 1024) { cap = 1024; }
    let mut fmtd: *i8= arc_malloc((u64)cap);
    fmtd[0] = 0;
    fmt_arc_src(orig, fmtd, cap);
    let mut msg: [256]i8;
    if (strcmp(orig, fmtd) == 0) {
        snprintf(msg, 256u, "unchanged: %s", path);
        ac_info(msg);
    } else {
        ac_write_file(path, fmtd);
        snprintf(msg, 256u, "formatted: %s", path);
        ac_ok(msg);
    }
    arc_free(fmtd);
    arc_free(orig);
}

fn cmd_fmt(path: *i8) void {
    if (path[0] == 0) {
        let mut cfg: ac_cfg;
        let mut src_dir: [256]i8;
        snprintf(src_dir, 256u, "src/");
        if (load_build_config(&cfg)) {
            let mut sd: *i8= ac_cfg_get(&cfg, "build.source_dir");
            if (sd != (i8*)0) { snprintf(src_dir, 256u, "%s", sd); }
        }
        let mut files: [256]*i8;
        let mut nf: i32= ac_list_arc_files(src_dir, files, 256);
        let mut fi: i32= 0;
        while (fi < nf) { fmt_file(files[fi]); arc_free(files[fi]); fi = fi + 1; }
    } else {
        fmt_file(path);
    }
}

// ---- sta ----

fn cmd_sta(path: *i8) void {
    let mut cfg: ac_cfg;
    let mut src_dir: [256]i8;
    snprintf(src_dir, 256u, "src/");
    let mut compiler: [512]i8;
    find_compiler(compiler, 512);
    if (load_build_config(&cfg)) {
        let mut sd: *i8= ac_cfg_get(&cfg, "build.source_dir");
        if (sd != (i8*)0) { snprintf(src_dir, 256u, "%s", sd); }
    }
    let mut target_path: [256]i8;
    if (path[0] == 0) { snprintf(target_path, 256u, "%s", src_dir); }
    else { snprintf(target_path, 256u, "%s", path); }

    let mut files: [256]*i8;
    let mut nf: i32= ac_list_arc_files(target_path, files, 256);
    let mut fi: i32= 0;
    while (fi < nf) {
        let mut check_cmd: [2048]i8;
        snprintf(check_cmd, 2048u, "\"%s\" \"%s\" --analyze-only 2>&1", compiler, files[fi]);
        let mut out: [4096]i8;
        ac_capture_cmd(check_cmd, out, 4096);
        // Filter out warning: and SMT note: lines (these aren't errors)
        let mut filtered: [4096]i8;
        let mut oi: i32= 0;
        let mut pi: i32= 0;
        while (out[pi] != 0) {
            let mut ls: i32= pi;
            while (out[pi] != 0 && out[pi] != '\n') { pi = pi + 1; }
            let mut ll: i32= pi - ls;
            let mut skip: bool= false;
            if (ll >= 8 && strncmp(out + (i64)ls, "warning:", 8u) == 0) { skip = true; }
            if (ll >= 9 && strncmp(out + (i64)ls, "SMT note:", 9u) == 0) { skip = true; }
            if (!skip && ll > 0) {
                memcpy(filtered + (i64)oi, out + (i64)ls, (u64)ll);
                oi = oi + ll;
                filtered[oi] = '\n'; oi = oi + 1;
            }
            if (out[pi] == '\n') { pi = pi + 1; }
        }
        filtered[oi] = 0;
        if (filtered[0] == 0) {
            let mut msg: [256]i8;
            snprintf(msg, 256u, "clean: %s", files[fi]);
            ac_ok(msg);
        } else {
            printf("ERRORS in %s:\n%s\n", files[fi], filtered);
        }
        arc_free(files[fi]);
        fi = fi + 1;
    }
}

// ---- test ----

fn cmd_test() void {
    let mut compiler: [512]i8;
    find_compiler(compiler, 512);
    let mut files: [256]*i8;
    let mut nf: i32= ac_list_arc_files(".", files, 256);
    // filter to .arct
    let mut passed: i32= 0;
    let mut failed: i32= 0;
    let mut fi: i32= 0;
    while (fi < nf) {
        if (ac_str_ends_with(files[fi], ".arct")) {
            let mut exe: [512]i8;
            snprintf(exe, 512u, "aciso_test_tmp.exe");
            let mut cmd: [2048]i8;
            snprintf(cmd, 2048u, "\"%s\" \"%s\" -o \"%s\"", compiler, files[fi], exe);
            if (ac_system_w(cmd) != 0) {
                let mut msg: [256]i8;
                snprintf(msg, 256u, "test compile failed: %s", files[fi]);
                ac_err(msg);
                failed = failed + 1;
            } else {
                snprintf(cmd, 2048u, "\"%s\"", exe);
                let mut rc: i32= ac_system_w(cmd);
                remove(exe);
                let mut msg: [256]i8;
                if (rc == 0) {
                    snprintf(msg, 256u, "PASS: %s", files[fi]);
                    ac_ok(msg);
                    passed = passed + 1;
                } else {
                    snprintf(msg, 256u, "FAIL: %s (exit %d)", files[fi], rc);
                    ac_err(msg);
                    failed = failed + 1;
                }
            }
        }
        arc_free(files[fi]);
        fi = fi + 1;
    }
    if (nf == 0) { ac_info("no .arct test files found"); return; }
    printf("\n%d/%d tests passed\n", passed, passed + failed);
}

// ---- bench ----

fn cmd_bench() void {
    let mut compiler: [512]i8;
    find_compiler(compiler, 512);
    let mut files: [256]*i8;
    let mut nf: i32= ac_list_arc_files(".", files, 256);
    let mut passed: i32= 0;
    let mut failed: i32= 0;
    let mut fi: i32= 0;
    while (fi < nf) {
        if (ac_str_ends_with(files[fi], ".arcb")) {
            let mut exe: [512]i8;
            snprintf(exe, 512u, "aciso_bench_tmp.exe");
            let mut cmd: [2048]i8;
            snprintf(cmd, 2048u, "\"%s\" \"%s\" -o \"%s\"", compiler, files[fi], exe);
            if (ac_system_w(cmd) == 0) {
                snprintf(cmd, 2048u, "\"%s\"", exe);
                let mut rc: i32= ac_system_w(cmd);
                remove(exe);
                if (rc == 0) {
                    printf("ok:    %s\n", files[fi]);
                    passed = passed + 1;
                } else {
                    printf("FAIL:  %s  (exit %d)\n", files[fi], rc);
                    failed = failed + 1;
                }
            } else {
                let mut msg: [256]i8;
                snprintf(msg, 256u, "bench compile failed: %s", files[fi]);
                ac_err(msg);
                failed = failed + 1;
            }
        }
        arc_free(files[fi]);
        fi = fi + 1;
    }
    if (nf == 0) { ac_info("no .arcb bench files found"); return; }
    printf("\n%d/%d benchmarks passed\n", passed, passed + failed);
}

// ---- export ----

fn cmd_export_pkg(use_toml: bool) void {
    let mut cfg: ac_cfg;
    if (!load_build_config(&cfg)) { return; }
    let mut name: *i8= ac_cfg_get_or(&cfg, "project.name", "unnamed");
    let mut version: *i8= ac_cfg_get_or(&cfg, "project.version", "0.1.0");
    let mut src_dir: *i8= ac_cfg_get_or(&cfg, "build.source_dir", "src/");

    let mut exp_cfg: ac_cfg;
    ac_cfg_init(&exp_cfg);
    ac_cfg_set(&exp_cfg, "registry.package", name);
    ac_cfg_set(&exp_cfg, "registry.version", version);

    let mut files: [256]*i8;
    let mut nf: i32= ac_list_arc_files(src_dir, files, 256);
    let mut fi: i32= 0;
    while (fi < nf) {
        ac_cfg_arr_push(&exp_cfg, "export", files[fi]);
        arc_free(files[fi]);
        fi = fi + 1;
    }

    if (use_toml) {
        snprintf(exp_cfg.path, 2048u, "export.toml");
        exp_cfg.use_toml = true;
    } else {
        snprintf(exp_cfg.path, 2048u, "export.json");
        exp_cfg.use_toml = false;
    }
    save_config(&exp_cfg);
    ac_ok(use_toml ? "created export.toml" : "created export.json");
}

// ---- conv ----

fn cmd_conv(to_toml: bool) void {
    let mut srcs: [2]*i8;
    let mut dsts: [2]*i8;
    if (to_toml) {
        srcs[0] = "aciso.json"; dsts[0] = "aciso.toml";
        srcs[1] = "acm.json";   dsts[1] = "acm.toml";
    } else {
        srcs[0] = "aciso.toml"; dsts[0] = "aciso.json";
        srcs[1] = "acm.toml";   dsts[1] = "acm.json";
    }
    let mut pi: i32= 0;
    while (pi < 2) {
        if (ac_file_exists(srcs[pi])) {
            let mut c: ac_cfg;
            load_config(srcs[pi], &c);
            snprintf(c.path, 2048u, "%s", dsts[pi]);
            c.use_toml = to_toml;
            save_config(&c);
            remove(srcs[pi]);
            let mut msg: [256]i8;
            snprintf(msg, 256u, "converted %s -> %s", srcs[pi], dsts[pi]);
            ac_ok(msg);
        }
        pi = pi + 1;
    }
}

// ---- help ----

fn print_help() void {
    printf("aciso — Artemis package manager & build system\n\n");
    printf("USAGE: aciso <command> [args]\n\n");
    printf("INIT\n");
    printf("  init [-t|-j]         Create aciso/acm config + src/main.arc\n");
    printf("  deinit               Remove manifests (preserves source)\n\n");
    printf("PACKAGES\n");
    printf("  install <name> <url> Clone URL, pull export files into modules/<name>/\n");
    printf("  uninstall <name>     Remove package from modules/ and manifests\n");
    printf("  update <name>        Re-download and reinstall package\n");
    printf("  vald                 Check all declared packages exist in modules/\n");
    printf("  audit                Verify SHA-256 hashes of installed packages\n\n");
    printf("BUILD\n");
    printf("  build [--release]    Compile all targets\n");
    printf("  run                  Build native executable and run it\n");
    printf("  sbuild <target>      Build a single named target\n");
    printf("  clean                Delete build/ directory\n\n");
    printf("TARGETS\n");
    printf("  add <file.ext>       Detect type from extension and register target\n");
    printf("  addf <file.ext> <t>  Register target with explicit type\n");
    printf("  rmt <target>         Remove a named build target\n");
    printf("  lst                  List all build targets\n\n");
    printf("SYMBOLS\n");
    printf("  itarget <SYM>        Define preprocessor symbol\n");
    printf("  utarget <SYM>        Undefine preprocessor symbol\n\n");
    printf("DEV TOOLS\n");
    printf("  fmt [path]           Format .arc source\n");
    printf("  sta [path]           Static analysis\n");
    printf("  test                 Run all .arct test files\n");
    printf("  bench                Run all .arcb bench files\n\n");
    printf("PUBLISH\n");
    printf("  export [-t|-j]       Create export.[json|toml] for this package\n");
    printf("  conv [-j|-t]         Convert config files between JSON and TOML\n\n");
    printf("OUTPUT TYPES:  exe  elf  mco  dll  so  dylib  static  wasm  wasi  ll  bc  obj\n");
}

// ---- main ----

pub fn main(argc: i32, argv: **i8) i32 {
    if (argc < 2) { print_help(); return 0; }

    let mut cmd: *i8= argv[1];

    if (strcmp(cmd, "help") == 0 || strcmp(cmd, "-h") == 0 || strcmp(cmd, "--help") == 0) {
        print_help(); return 0;
    }

    if (strcmp(cmd, "init") == 0) {
        let mut use_toml: bool= false;
        let mut i: i32= 2;
        while (i < argc) {
            if (strcmp(argv[i], "-t") == 0) { use_toml = true; }
            i = i + 1;
        }
        cmd_init(use_toml);
        return 0;
    }

    if (strcmp(cmd, "deinit") == 0) { cmd_deinit(); return 0; }

    if (strcmp(cmd, "install") == 0) {
        if (argc < 4) { ac_err("usage: aciso install <name> <url>"); return 1; }
        cmd_install(argv[2], argv[3]);
        return 0;
    }

    if (strcmp(cmd, "uninstall") == 0) {
        if (argc < 3) { ac_err("usage: aciso uninstall <name>"); return 1; }
        cmd_uninstall(argv[2]);
        return 0;
    }

    if (strcmp(cmd, "update") == 0) {
        if (argc < 3) { ac_err("usage: aciso update <name>"); return 1; }
        cmd_update(argv[2]);
        return 0;
    }

    if (strcmp(cmd, "vald") == 0)  { cmd_vald();  return 0; }
    if (strcmp(cmd, "audit") == 0) { cmd_audit(); return 0; }

    if (strcmp(cmd, "build") == 0) {
        let mut rel: bool= (argc >= 3 && strcmp(argv[2], "--release") == 0);
        cmd_build(rel);
        return 0;
    }

    if (strcmp(cmd, "run") == 0)   { cmd_run();   return 0; }
    if (strcmp(cmd, "clean") == 0) { cmd_clean(); return 0; }

    if (strcmp(cmd, "sbuild") == 0) {
        if (argc < 3) { ac_err("usage: aciso sbuild <target>"); return 1; }
        cmd_sbuild(argv[2]);
        return 0;
    }

    if (strcmp(cmd, "add") == 0) {
        if (argc < 3) { ac_err("usage: aciso add <filename.ext>"); return 1; }
        cmd_add(argv[2]);
        return 0;
    }

    if (strcmp(cmd, "addf") == 0) {
        if (argc < 4) { ac_err("usage: aciso addf <filename.ext> <type>"); return 1; }
        cmd_addf(argv[2], argv[3]);
        return 0;
    }

    if (strcmp(cmd, "rmt") == 0) {
        if (argc < 3) { ac_err("usage: aciso rmt <target>"); return 1; }
        cmd_rmt(argv[2]);
        return 0;
    }

    if (strcmp(cmd, "lst") == 0) { cmd_lst(); return 0; }

    if (strcmp(cmd, "itarget") == 0) {
        if (argc < 3) { ac_err("usage: aciso itarget <SYMBOL>"); return 1; }
        cmd_itarget(argv[2]);
        return 0;
    }

    if (strcmp(cmd, "utarget") == 0) {
        if (argc < 3) { ac_err("usage: aciso utarget <SYMBOL>"); return 1; }
        cmd_utarget(argv[2]);
        return 0;
    }

    if (strcmp(cmd, "fmt") == 0) {
        let mut p: [512]i8;
        p[0] = 0;
        if (argc >= 3) { snprintf(p, 512u, "%s", argv[2]); }
        cmd_fmt(p);
        return 0;
    }

    if (strcmp(cmd, "sta") == 0) {
        let mut p: [512]i8;
        p[0] = 0;
        if (argc >= 3) { snprintf(p, 512u, "%s", argv[2]); }
        cmd_sta(p);
        return 0;
    }

    if (strcmp(cmd, "test") == 0)  { cmd_test();  return 0; }
    if (strcmp(cmd, "bench") == 0) { cmd_bench(); return 0; }

    if (strcmp(cmd, "export") == 0) {
        let mut use_toml2: bool= project_uses_toml();
        let mut i2: i32= 2;
        while (i2 < argc) {
            if (strcmp(argv[i2], "-t") == 0) { use_toml2 = true; }
            if (strcmp(argv[i2], "-j") == 0) { use_toml2 = false; }
            i2 = i2 + 1;
        }
        cmd_export_pkg(use_toml2);
        return 0;
    }

    if (strcmp(cmd, "conv") == 0) {
        let mut to_toml2: bool= false;
        let mut to_json: bool= false;
        let mut ci: i32= 2;
        while (ci < argc) {
            if (strcmp(argv[ci], "-t") == 0) { to_toml2 = true; }
            if (strcmp(argv[ci], "-j") == 0) { to_json = true; }
            ci = ci + 1;
        }
        if (!to_toml2 && !to_json) { ac_err("usage: aciso conv [-j|-t]"); return 1; }
        cmd_conv(to_toml2);
        return 0;
    }

    let mut errmsg: [256]i8;
    snprintf(errmsg, 256u, "unknown command: %s  (run 'aciso help' for usage)", cmd);
    ac_err(errmsg);
    return 1;
}
