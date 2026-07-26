// compiler/lsp/main.arc — Language Server Protocol (LSP) 3.17 implementation
//
// Implements JSON-RPC 2.0 over stdin/stdout.
// Invoked with: artemis --lsp
//
// Supported: initialize, initialized, shutdown, exit,
//   textDocument/didOpen, textDocument/didChange, textDocument/didClose,
//   textDocument/hover (declaration line for the identifier under the cursor),
//   textDocument/publishDiagnostics (outbound)

namespace lsp {

// ---- minimal JSON scanner for LSP messages ----

// Skip whitespace starting at pos; returns new pos.
fn js_skip_ws(s: *i8, pos: i32, len: i32) i32 {
    while (pos < len && (s[pos] == ' ' || s[pos] == '\t' || s[pos] == '\n' || s[pos] == '\r'))
        pos = pos + 1;
    return pos;
}

// Read a JSON string starting at pos (assumes s[pos]=='"').
// Copies into out_buf (max out_cap bytes). Returns pos after closing '"'.
fn js_read_str(s: *i8, pos: i32, len: i32, out_buf: *i8, out_cap: i32) i32 {
    if (pos >= len || s[pos] != '"') { out_buf[0] = 0; return pos; }
    pos = pos + 1;
    let mut oi: i32= 0;
    while (pos < len && s[pos] != '"') {
        if (s[pos] == '\\') {
            pos = pos + 1;
            if (pos >= len) { break; }
            let mut c: i8= s[pos];
            if      (c == 'n')  { if (oi + 1 < out_cap) { out_buf[oi] = '\n'; oi = oi + 1; } }
            else if (c == 'r')  { if (oi + 1 < out_cap) { out_buf[oi] = '\r'; oi = oi + 1; } }
            else if (c == 't')  { if (oi + 1 < out_cap) { out_buf[oi] = '\t'; oi = oi + 1; } }
            else if (c == '"')  { if (oi + 1 < out_cap) { out_buf[oi] = '"';  oi = oi + 1; } }
            else if (c == '\\') { if (oi + 1 < out_cap) { out_buf[oi] = '\\'; oi = oi + 1; } }
            else if (c == '/')  { if (oi + 1 < out_cap) { out_buf[oi] = '/';  oi = oi + 1; } }
            else                { if (oi + 1 < out_cap) { out_buf[oi] = c;    oi = oi + 1; } }
        } else {
            if (oi + 1 < out_cap) { out_buf[oi] = s[pos]; oi = oi + 1; }
        }
        pos = pos + 1;
    }
    out_buf[oi] = 0;
    if (pos < len) { pos = pos + 1; } // closing "
    return pos;
}

// Skip past one JSON value (string, number, object, array, bool, null) from pos.
fn js_skip_value(s: *i8, pos: i32, len: i32) i32 {
    pos = js_skip_ws(s, pos, len);
    if (pos >= len) { return pos; }
    let mut c: i8= s[pos];
    if (c == '"') {
        pos = pos + 1;
        while (pos < len && s[pos] != '"') {
            if (s[pos] == '\\') { pos = pos + 1; }
            pos = pos + 1;
        }
        if (pos < len) { pos = pos + 1; }
        return pos;
    }
    if (c == '{' || c == '[') {
        let mut open: i8= c;
        let mut close: i8= c == '{' ? '}' : ']';
        let mut depth: i32= 1;
        pos = pos + 1;
        while (pos < len && depth > 0) {
            let mut cc: i8= s[pos];
            if (cc == '"') { // skip string to avoid counting brackets inside strings
                pos = pos + 1;
                while (pos < len && s[pos] != '"') {
                    if (s[pos] == '\\') { pos = pos + 1; }
                    pos = pos + 1;
                }
                if (pos < len) { pos = pos + 1; }
            } else if (cc == open) { depth = depth + 1; pos = pos + 1; }
            else if (cc == close) { depth = depth - 1; pos = pos + 1; }
            else { pos = pos + 1; }
        }
        return pos;
    }
    // number, bool, null: skip until delimiter
    while (pos < len) {
        let mut cc: i8= s[pos];
        if (cc == ',' || cc == '}' || cc == ']' || cc == ' ' || cc == '\t' ||
                cc == '\n' || cc == '\r') { break; }
        pos = pos + 1;
    }
    return pos;
}

// Find key in a JSON object starting at pos (pos should point to '{').
// If found, returns the position of the VALUE (after ':').
// Returns -1 if not found.
fn js_find_key(s: *i8, pos: i32, len: i32, key: *i8) i32 {
    pos = js_skip_ws(s, pos, len);
    if (pos >= len || s[pos] != '{') { return -1; }
    pos = pos + 1;
    while (pos < len) {
        pos = js_skip_ws(s, pos, len);
        if (pos >= len) { return -1; }
        if (s[pos] == '}') { return -1; }
        if (s[pos] == ',') { pos = pos + 1; continue; }
        if (s[pos] != '"') { return -1; }
        // Read the key
        let mut kbuf: [256]i8;
        pos = js_read_str(s, pos, len, kbuf, 256);
        // Skip ':'
        pos = js_skip_ws(s, pos, len);
        if (pos >= len || s[pos] != ':') { return -1; }
        pos = pos + 1;
        pos = js_skip_ws(s, pos, len);
        // Compare
        if (strcmp(kbuf, key) == 0) { return pos; }
        // Skip value
        pos = js_skip_value(s, pos, len);
    }
    return -1;
}

// Extract string value for key from JSON object at pos (points to '{').
// Returns allocated string or null.
fn js_get_str(s: *i8, obj_pos: i32, len: i32, key: *i8) *i8 {
    let mut vpos: i32= js_find_key(s, obj_pos, len, key);
    if (vpos < 0) { return (i8*)0; }
    vpos = js_skip_ws(s, vpos, len);
    if (vpos >= len || s[vpos] != '"') { return (i8*)0; }
    let mut buf: [65536]i8; // 64KB for document text
    let mut end: i32= js_read_str(s, vpos, len, buf, 65536);
    return lexer.str_dup(buf);
}

// Extract integer value for key from JSON object at pos.
fn js_get_int(s: *i8, obj_pos: i32, len: i32, key: *i8) i64 {
    let mut vpos: i32= js_find_key(s, obj_pos, len, key);
    if (vpos < 0) { return 0; }
    vpos = js_skip_ws(s, vpos, len);
    if (vpos >= len) { return 0; }
    let mut neg: bool= s[vpos] == '-';
    if (neg) { vpos = vpos + 1; }
    let mut v: i64= 0;
    while (vpos < len && s[vpos] >= '0' && s[vpos] <= '9') {
        v = v * 10 + (i64)(s[vpos] - '0');
        vpos = vpos + 1;
    }
    return neg ? -v : v;
}

// Get position of a nested object value for key.
// Returns pos pointing to the nested '{', or -1.
fn js_get_obj(s: *i8, obj_pos: i32, len: i32, key: *i8) i32 {
    let mut vpos: i32= js_find_key(s, obj_pos, len, key);
    if (vpos < 0) { return -1; }
    vpos = js_skip_ws(s, vpos, len);
    if (vpos >= len || s[vpos] != '{') { return -1; }
    return vpos;
}

// Get position of array value for key.
fn js_get_arr(s: *i8, obj_pos: i32, len: i32, key: *i8) i32 {
    let mut vpos: i32= js_find_key(s, obj_pos, len, key);
    if (vpos < 0) { return -1; }
    vpos = js_skip_ws(s, vpos, len);
    if (vpos >= len || s[vpos] != '[') { return -1; }
    return vpos;
}

// Get the last element of a JSON array at arr_pos.
fn js_arr_last_elem(s: *i8, arr_pos: i32, len: i32) i32 {
    if (arr_pos < 0 || arr_pos >= len || s[arr_pos] != '[') { return -1; }
    let mut pos: i32= arr_pos + 1;
    let mut last_elem: i32= -1;
    while (pos < len) {
        pos = js_skip_ws(s, pos, len);
        if (pos >= len || s[pos] == ']') { break; }
        if (s[pos] == ',') { pos = pos + 1; continue; }
        last_elem = pos;
        pos = js_skip_value(s, pos, len);
    }
    return last_elem;
}

// ---- I/O helpers ----

fn lsp_read_exact(buf: *i8, n: i32) bool {
    let mut got: i32= 0;
    while (got < n) {
        let mut c: i32= getchar();
        if (c < 0) { return false; }
        buf[got] = (i8)c;
        got = got + 1;
    }
    return true;
}

fn lsp_read_message(out_len: *i32) *i8 {
    let mut hdrbuf: [4096]i8;
    let mut hlen: i32= 0;
    let mut content_len: i32= -1;

    // Read headers until \r\n\r\n
    while (hlen < 4090) {
        let mut c: i32= getchar();
        if (c < 0) { return (i8*)0; }
        hdrbuf[hlen] = (i8)c;
        hlen = hlen + 1;
        if (hlen >= 4 &&
            hdrbuf[hlen-4] == '\r' && hdrbuf[hlen-3] == '\n' &&
            hdrbuf[hlen-2] == '\r' && hdrbuf[hlen-1] == '\n') {
            break;
        }
    }
    hdrbuf[hlen] = 0;

    // Parse Content-Length
    let mut i: i32= 0;
    while (i + 15 < hlen) {
        if (hdrbuf[i] == 'C' && strncmp(hdrbuf + i, "Content-Length:", 15) == 0) {
            i = i + 15;
            while (i < hlen && hdrbuf[i] == ' ') { i = i + 1; }
            let mut num: i32= 0;
            while (i < hlen && hdrbuf[i] >= '0' && hdrbuf[i] <= '9') {
                num = num * 10 + (i32)(hdrbuf[i] - '0');
                i = i + 1;
            }
            content_len = num;
            break;
        }
        i = i + 1;
    }

    if (content_len <= 0) { return (i8*)0; }
    let mut body: *i8= (i8*)arc_malloc((u64)(content_len + 1));
    if (!lsp_read_exact(body, content_len)) { arc_free(body); return (i8*)0; }
    body[content_len] = 0;
    *out_len = content_len;
    return body;
}

fn lsp_write_message(json: *i8) void {
    let mut n: i32= (i32)strlen(json);
    let mut hdr: [64]i8;
    let mut hl: i32= snprintf(hdr, (u64)64, "Content-Length: %d\r\n\r\n", n);
    // Use fprintf to stdout so it goes to the correct output stream
    fprintf(stdout_file(), "%.*s%s", hl, hdr, json);
    fflush(stdout_file());
}

// ---- Simple JSON builder ----

struct jbuf {
    let mut data: *i8;
    let mut len: i32;
    let mut cap: i32;
}

fn jb_init(b: *jbuf) void {
    b.cap = 512; b.len = 0;
    b.data = (i8*)arc_malloc((u64)b.cap);
    b.data[0] = 0;
}

fn jb_grow(b: *jbuf, need: i32) void {
    if (b.len + need + 2 < b.cap) { return; }
    let mut nc: i32= b.cap * 2 + need + 2;
    b.data = (i8*)arc_realloc(b.data, (u64)nc);
    b.cap = nc;
}

fn jb_raw(b: *jbuf, s: *i8) void {
    let mut n: i32= (i32)strlen(s);
    jb_grow(b, n);
    memcpy(b.data + b.len, s, (u64)n);
    b.len = b.len + n;
    b.data[b.len] = 0;
}

fn jb_int(b: *jbuf, v: i64) void {
    let mut t: [32]i8; snprintf(t, 32u, "%lld", v); jb_raw(b, t);
}

fn jb_str(b: *jbuf, s: *i8) void {
    jb_raw(b, "\"");
    let mut i: i32= 0;
    while (s[i] != 0) {
        let mut e: [6]i8;
        let mut c: i8= s[i];
        if      (c == '"')  { jb_raw(b, "\\\""); }
        else if (c == '\\') { jb_raw(b, "\\\\"); }
        else if (c == '\n') { jb_raw(b, "\\n"); }
        else if (c == '\r') { jb_raw(b, "\\r"); }
        else if (c == '\t') { jb_raw(b, "\\t"); }
        else {
            jb_grow(b, 2);
            b.data[b.len] = c; b.len = b.len + 1;
            b.data[b.len] = 0;
        }
        i = i + 1;
    }
    jb_raw(b, "\"");
}

fn jb_free(b: *jbuf) void { arc_free(b.data); b.data = (i8*)0; b.len = 0; b.cap = 0; }

// ---- Send helpers ----

fn lsp_result(id_str: *i8, result: *i8) void {
    let mut b: jbuf; jb_init(&b);
    jb_raw(&b, "{\"jsonrpc\":\"2.0\",\"id\":"); jb_raw(&b, id_str);
    jb_raw(&b, ",\"result\":"); jb_raw(&b, result); jb_raw(&b, "}");
    lsp_write_message(b.data); jb_free(&b);
}

fn lsp_error(id_str: *i8, code: i32, msg: *i8) void {
    let mut b: jbuf; jb_init(&b);
    jb_raw(&b, "{\"jsonrpc\":\"2.0\",\"id\":"); jb_raw(&b, id_str);
    jb_raw(&b, ",\"error\":{\"code\":"); jb_int(&b, (i64)code);
    jb_raw(&b, ",\"message\":"); jb_str(&b, msg); jb_raw(&b, "}}");
    lsp_write_message(b.data); jb_free(&b);
}

fn lsp_notify(method: *i8, params: *i8) void {
    let mut b: jbuf; jb_init(&b);
    jb_raw(&b, "{\"jsonrpc\":\"2.0\",\"method\":"); jb_str(&b, method);
    jb_raw(&b, ",\"params\":"); jb_raw(&b, params); jb_raw(&b, "}");
    lsp_write_message(b.data); jb_free(&b);
}

// ---- Hover support ----

fn lsp_is_id_char(c: i8) bool {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
           (c >= '0' && c <= '9') || c == '_';
}

// Extract the identifier under (line, character). Returns false when the cursor is
// not on one. Line/character are 0-based, as in the LSP protocol.
fn lsp_word_at(text: *i8, line: i32, character: i32, out: *i8, cap: i32) bool {
    if (text == (i8*)0 || out == (i8*)0 || cap <= 1) { return false; }
    // Seek to the start of the requested line.
    let mut i: i32= 0;
    let mut cur_line: i32= 0;
    while (text[i] != 0 && cur_line < line) {
        if (text[i] == '
') { cur_line = cur_line + 1; }
        i = i + 1;
    }
    if (cur_line != line) { return false; }
    // Walk to the requested column, stopping at end of line.
    let mut col: i32= 0;
    while (text[i] != 0 && text[i] != '
' && col < character) { i = i + 1; col = col + 1; }
    if (text[i] == 0 || text[i] == '
' || !lsp_is_id_char(text[i])) { return false; }
    // Expand to the full identifier.
    let mut start: i32= i;
    while (start > 0 && lsp_is_id_char(text[start - 1])) { start = start - 1; }
    let mut end: i32= i;
    while (text[end] != 0 && lsp_is_id_char(text[end])) { end = end + 1; }
    let mut n: i32= end - start;
    if (n <= 0 || n >= cap) { return false; }
    let mut k: i32= 0;
    while (k < n) { out[k] = text[start + k]; k = k + 1; }
    out[n] = 0;
    return true;
}

// Find the line that declares `name` and return it as the hover text. Scanning the
// source keeps hover independent of a full semantic index while still reporting the
// real declaration (signature, type, or variant) rather than just the bare name.
fn lsp_describe_symbol(text: *i8, name: *i8, out: *i8, cap: i32) void {
    snprintf(out, (u64)cap, "%s", name);
    if (text == (i8*)0 || name == (i8*)0) { return; }
    let mut nlen: i32= (i32)strlen(name);
    if (nlen <= 0) { return; }

    let mut i: i32= 0;
    while (text[i] != 0) {
        // Start of a line
        let mut ls: i32= i;
        let mut le: i32= i;
        while (text[le] != 0 && text[le] != '
') { le = le + 1; }
        // Does this line declare `name`?
        let mut j: i32= ls;
        while (j + nlen <= le) {
            if (strncmp(text + j, name, (u64)nlen) == 0 &&
                (j == ls || !lsp_is_id_char(text[j - 1])) &&
                !lsp_is_id_char(text[j + nlen])) {
                // Look backwards on the line for a declaring keyword.
                let mut is_decl: bool= false;
                let mut k: i32= ls;
                while (k < j) {
                    if ((strncmp(text + k, "fn ", 3u) == 0) ||
                        (strncmp(text + k, "let ", 4u) == 0) ||
                        (strncmp(text + k, "struct ", 7u) == 0) ||
                        (strncmp(text + k, "istruc ", 7u) == 0) ||
                        (strncmp(text + k, "enum ", 5u) == 0) ||
                        (strncmp(text + k, "union ", 6u) == 0) ||
                        (strncmp(text + k, "interface ", 10u) == 0) ||
                        (strncmp(text + k, "memstr ", 7u) == 0) ||
                        (strncmp(text + k, "namespace ", 10u) == 0) ||
                        (strncmp(text + k, "comptime ", 9u) == 0)) { is_decl = true; }
                    k = k + 1;
                }
                if (is_decl) {
                    // Copy the line, trimming leading whitespace and a trailing '{'.
                    let mut s2: i32= ls;
                    while (s2 < le && (text[s2] == ' ' || text[s2] == '	')) { s2 = s2 + 1; }
                    let mut e2: i32= le;
                    while (e2 > s2 && (text[e2 - 1] == ' ' || text[e2 - 1] == '	' ||
                                       text[e2 - 1] == '{' || text[e2 - 1] == '
')) { e2 = e2 - 1; }
                    let mut n2: i32= e2 - s2;
                    if (n2 > 0 && n2 < cap) {
                        let mut c2: i32= 0;
                        while (c2 < n2) { out[c2] = text[s2 + c2]; c2 = c2 + 1; }
                        out[n2] = 0;
                        return;
                    }
                }
            }
            j = j + 1;
        }
        if (text[le] == 0) { break; }
        i = le + 1;
    }
}

// ---- Document store ----

struct lsp_doc {
    let mut uri: *i8;
    let mut text: *i8;
    let mut version: i32;
}

struct lsp_state {
    let mut initialized: bool;
    let mut shutting_down: bool;
    let mut exe_path: *i8;
    let mut docs: *lsp_doc;
    let mut docs_len: i32;
    let mut docs_cap: i32;
}

fn ls_init(st: *lsp_state, exe: *i8) void {
    st.initialized = false; st.shutting_down = false;
    st.exe_path = exe; st.docs_len = 0; st.docs_cap = 8;
    st.docs = (lsp_doc*)arc_malloc(sizeof(lsp_doc) * 8u);
}

fn ls_set_doc(st: *lsp_state, uri: *i8, text: *i8, ver: i32) void {
    let mut i: i32= 0;
    while (i < st.docs_len) {
        if (strcmp(st.docs[i].uri, uri) == 0) {
            arc_free(st.docs[i].text);
            st.docs[i].text = text; st.docs[i].version = ver; return;
        }
        i = i + 1;
    }
    if (st.docs_len >= st.docs_cap) {
        st.docs_cap = st.docs_cap * 2;
        st.docs = (lsp_doc*)arc_realloc((i8*)st.docs, sizeof(lsp_doc) * (u64)st.docs_cap);
    }
    st.docs[st.docs_len].uri = uri; st.docs[st.docs_len].text = text;
    st.docs[st.docs_len].version = ver; st.docs_len = st.docs_len + 1;
}

fn ls_get_text(st: *lsp_state, uri: *i8) *i8 {
    let mut i: i32= 0;
    while (i < st.docs_len) {
        if (strcmp(st.docs[i].uri, uri) == 0) { return st.docs[i].text; }
        i = i + 1;
    }
    return (i8*)0;
}

// ---- Diagnostics via subprocess ----

fn lsp_publish_diags(st: *lsp_state, uri: *i8, version: i32) void {
    let mut text: *i8= ls_get_text(st, uri);
    if (text == (i8*)0) { return; }

    // Write to a deterministic temp file path (based on exe path)
    let mut tmp_path: [1024]i8;
    snprintf(tmp_path, 1024u, "%s.lsp_tmp.arc", st.exe_path);

    let mut f: *void= fopen(tmp_path, "wb");
    if (f == (void*)0) { return; }
    fwrite((void*)text, 1u, (u64)strlen(text), f);
    fclose(f);

    // Run compiler, capture stderr+stdout
    let mut cmd: [2048]i8;
    snprintf(cmd, 2048u, "\"%s\" \"%s\" --unsafe -S -o NUL 2>&1",
             st.exe_path, tmp_path);

    let mut pipe_f: *void= popen(cmd, "r");
    if (pipe_f == (void*)0) { remove(tmp_path); return; }

    // Parse error lines into diagnostics JSON
    let mut db: jbuf; jb_init(&db); jb_raw(&db, "[");
    let mut first: bool= true;
    let mut linebuf: [2048]i8;

    while (fgets(linebuf, 2047, pipe_f) != (i8*)0) {
        let mut ln: *i8= linebuf;
        // Trim trailing newline
        let mut ll: i32= (i32)strlen(ln);
        while (ll > 0 && (ln[ll-1] == '\n' || ln[ll-1] == '\r')) { ln[ll-1] = 0; ll = ll - 1; }

        let mut err_line: i32= 0;
        let mut msg: *i8= (i8*)0;
        let mut sev: i32= 0;

        if (strncmp(ln, "error at line ", 14) == 0 ||
                strncmp(ln, "semantic error at line ", 23) == 0) {
            sev = 1; // error
            let mut p: *i8= ln;
            while (*p != 0 && (*p < '0' || *p > '9')) { p = p + 1; }
            while (*p >= '0' && *p <= '9') {
                err_line = err_line * 10 + (i32)(*p - '0'); p = p + 1;
            }
            if (*p == ':') { p = p + 1; }
            if (*p == ' ') { p = p + 1; }
            msg = p;
        } else if (strncmp(ln, "warning:", 8) == 0) {
            sev = 2; err_line = 1; msg = ln + 8;
            if (*msg == ' ') { msg = msg + 1; }
        }

        if (sev > 0 && msg != (i8*)0 && err_line > 0) {
            if (!first) { jb_raw(&db, ","); }
            first = false;
            let mut row: i32= err_line - 1; // 0-based
            jb_raw(&db, "{\"range\":{\"start\":{\"line\":");
            jb_int(&db, (i64)row);
            jb_raw(&db, ",\"character\":0},\"end\":{\"line\":");
            jb_int(&db, (i64)row);
            jb_raw(&db, ",\"character\":9999}},\"severity\":");
            jb_int(&db, (i64)sev);
            jb_raw(&db, ",\"source\":\"artemis\",\"message\":");
            jb_str(&db, msg);
            jb_raw(&db, "}");
        }
    }
    pclose(pipe_f);
    remove(tmp_path);

    jb_raw(&db, "]");

    // Publish diagnostics notification
    let mut pb: jbuf; jb_init(&pb);
    jb_raw(&pb, "{\"uri\":"); jb_str(&pb, uri);
    jb_raw(&pb, ",\"version\":"); jb_int(&pb, (i64)version);
    jb_raw(&pb, ",\"diagnostics\":"); jb_raw(&pb, db.data); jb_raw(&pb, "}");
    lsp_notify("textDocument/publishDiagnostics", pb.data);
    jb_free(&pb); jb_free(&db);
}

// ---- Main LSP loop ----

pub fn run_lsp_server(exe_path: *i8) void {
    let mut st: lsp_state;
    ls_init(&st, exe_path);

    while (!st.shutting_down) {
        let mut msg_len: i32= 0;
        let mut body: *i8= lsp_read_message(&msg_len);
        if (body == (i8*)0) { break; }

        let mut blen: i32= msg_len;

        // Find method (top-level string field)
        let mut method_buf: [128]i8;
        let mut method_vpos: i32= js_find_key(body, 0, blen, "method");
        if (method_vpos < 0) { arc_free(body); continue; }
        method_vpos = js_skip_ws(body, method_vpos, blen);
        if (method_vpos >= blen || body[method_vpos] != '"') { arc_free(body); continue; }
        let mut after_method: i32= js_read_str(body, method_vpos, blen, method_buf, 128);

        // Get id (may be int, string, or null)
        let mut id_buf: [64]i8; id_buf[0] = 0;
        let mut id_vpos: i32= js_find_key(body, 0, blen, "id");
        if (id_vpos >= 0) {
            id_vpos = js_skip_ws(body, id_vpos, blen);
            if (id_vpos < blen) {
                let mut c: i8= body[id_vpos];
                if (c == '"') {
                    let mut tmp: [64]i8;
                    js_read_str(body, id_vpos, blen, tmp, 64);
                    snprintf(id_buf, 64u, "\"%s\"", tmp);
                } else if ((c >= '0' && c <= '9') || c == '-') {
                    let mut ip: i32= id_vpos;
                    if (body[ip] == '-') { ip = ip + 1; }
                    let mut num: i64= 0;
                    while (ip < blen && body[ip] >= '0' && body[ip] <= '9') {
                        num = num * 10 + (i64)(body[ip] - '0'); ip = ip + 1;
                    }
                    if (body[id_vpos] == '-') { num = -num; }
                    snprintf(id_buf, 64u, "%lld", num);
                } else {
                    snprintf(id_buf, 64u, "null");
                }
            }
        } else {
            snprintf(id_buf, 64u, "null");
        }

        // Find params object position
        let mut params_pos: i32= js_find_key(body, 0, blen, "params");
        params_pos = (params_pos >= 0) ? js_skip_ws(body, params_pos, blen) : -1;

        // Dispatch
        if (strcmp(method_buf, "initialize") == 0) {
            st.initialized = true;
            lsp_result(id_buf, "{\"capabilities\":{\"textDocumentSync\":{\"openClose\":true,\"change\":1},\"hoverProvider\":true},\"serverInfo\":{\"name\":\"artemis-lsp\",\"version\":\"1.0\"}}");

        } else if (strcmp(method_buf, "initialized") == 0) {
            // notification, no response needed

        } else if (strcmp(method_buf, "shutdown") == 0) {
            st.shutting_down = true;
            lsp_result(id_buf, "null");

        } else if (strcmp(method_buf, "exit") == 0) {
            arc_free(body);
            break;

        } else if (strcmp(method_buf, "textDocument/didOpen") == 0) {
            if (params_pos >= 0 && body[params_pos] == '{') {
                let mut td_pos: i32= js_get_obj(body, params_pos, blen, "textDocument");
                if (td_pos >= 0) {
                    let mut uri: *i8= js_get_str(body, td_pos, blen, "uri");
                    let mut text: *i8= js_get_str(body, td_pos, blen, "text");
                    let mut ver: i64= js_get_int(body, td_pos, blen, "version");
                    if (uri != (i8*)0 && text != (i8*)0) {
                        ls_set_doc(&st, uri, text, (i32)ver);
                        lsp_publish_diags(&st, uri, (i32)ver);
                    } else {
                        if (uri != (i8*)0) { arc_free(uri); }
                        if (text != (i8*)0) { arc_free(text); }
                    }
                }
            }

        } else if (strcmp(method_buf, "textDocument/didChange") == 0) {
            if (params_pos >= 0 && body[params_pos] == '{') {
                let mut td_pos: i32= js_get_obj(body, params_pos, blen, "textDocument");
                if (td_pos >= 0) {
                    let mut uri: *i8= js_get_str(body, td_pos, blen, "uri");
                    let mut ver: i64= js_get_int(body, td_pos, blen, "version");
                    let mut arr_pos: i32= js_get_arr(body, params_pos, blen, "contentChanges");
                    let mut last_elem: i32= js_arr_last_elem(body, arr_pos, blen);
                    if (uri != (i8*)0 && last_elem >= 0 && body[last_elem] == '{') {
                        let mut text: *i8= js_get_str(body, last_elem, blen, "text");
                        if (text != (i8*)0) {
                            ls_set_doc(&st, uri, text, (i32)ver);
                            lsp_publish_diags(&st, uri, (i32)ver);
                        } else {
                            arc_free(uri);
                        }
                    } else {
                        if (uri != (i8*)0) { arc_free(uri); }
                    }
                }
            }

        } else if (strcmp(method_buf, "textDocument/didClose") == 0) {
            if (params_pos >= 0 && body[params_pos] == '{') {
                let mut td_pos: i32= js_get_obj(body, params_pos, blen, "textDocument");
                if (td_pos >= 0) {
                    let mut uri: *i8= js_get_str(body, td_pos, blen, "uri");
                    if (uri != (i8*)0) {
                        // Clear diagnostics
                        let mut pb: jbuf; jb_init(&pb);
                        jb_raw(&pb, "{\"uri\":"); jb_str(&pb, uri);
                        jb_raw(&pb, ",\"diagnostics\":[]}");
                        lsp_notify("textDocument/publishDiagnostics", pb.data);
                        jb_free(&pb); arc_free(uri);
                    }
                }
            }

        } else if (strcmp(method_buf, "textDocument/hover") == 0) {
            if (id_buf[0] != 0 && strcmp(id_buf, "null") != 0) {
                let mut answered: bool= false;
                if (params_pos >= 0 && body[params_pos] == '{') {
                    let mut td_h: i32= js_get_obj(body, params_pos, blen, "textDocument");
                    let mut pos_h: i32= js_get_obj(body, params_pos, blen, "position");
                    if (td_h >= 0 && pos_h >= 0) {
                        let mut uri_h: *i8= js_get_str(body, td_h, blen, "uri");
                        if (uri_h != (i8*)0) {
                            let mut line_h: i64= js_get_int(body, pos_h, blen, "line");
                            let mut char_h: i64= js_get_int(body, pos_h, blen, "character");
                            let mut text_h: *i8= ls_get_text(&st, uri_h);
                            let mut word: [256]i8;
                            if (text_h != (i8*)0 &&
                                    lsp_word_at(text_h, (i32)line_h, (i32)char_h, word, 256)) {
                                let mut desc: [512]i8;
                                lsp_describe_symbol(text_h, word, desc, 512);
                                let mut hb: jbuf; jb_init(&hb);
                                jb_raw(&hb, "{\"contents\":{\"kind\":\"plaintext\",\"value\":");
                                jb_str(&hb, desc);
                                jb_raw(&hb, "}}");
                                lsp_result(id_buf, hb.data);
                                jb_free(&hb);
                                answered = true;
                            }
                            arc_free(uri_h);
                        }
                    }
                }
                // No identifier under the cursor — null is the "no hover" reply.
                if (!answered) { lsp_result(id_buf, "null"); }
            }

        } else {
            // Unknown request (has id): method not found
            if (id_buf[0] != 0 && strcmp(id_buf, "null") != 0) {
                lsp_error(id_buf, -32601, "Method not found");
            }
        }

        arc_free(body);
    }
}

} // namespace lsp
