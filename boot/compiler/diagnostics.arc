// Diagnostics module for the Artemis self-hosting compiler.

namespace diagnostics {

// Diagnostic level constants
enum diag_level_t {
    DIAG_NOTE    = 0,
    DIAG_WARNING = 1,
    DIAG_ERROR   = 2,
}

struct diagnostic_t {
    i32  level;
    i8*  filename;
    i32  line;
    i32  col;
    i8*  message;
}

// Dynamic array of diagnostics
struct diag_vec {
    diagnostic_t* data;
    i32           len;
    i32           cap;
}

void diag_vec_push(diag_vec* v, diagnostic_t d) {
    if (v.len >= v.cap) {
        i32 nc = v.cap == 0 ? 16 : v.cap * 2;
        v.data = (diagnostic_t*)realloc((i8*)v.data, sizeof(diagnostics__NS_diagnostic_t) * (u64)nc);
        v.cap = nc;
    }
    v.data[v.len] = d;
    v.len = v.len + 1;
}

// ---- Diagnostic engine ----

istruc diag_engine {
    i8*       filename;
    diag_vec  diags;
    i32       err_count;
    i32       max_errors;

    void init(diag_engine* self, i8* fname) {
        self.filename   = fname;
        self.err_count  = 0;
        self.max_errors = 20;
        self.diags.data = (diagnostic_t*)0;
        self.diags.len  = 0;
        self.diags.cap  = 0;
    }

    void emit_error(diag_engine* self, i32 line, i32 col, i8* msg) {
        if (self.err_count >= self.max_errors) { return; }
        diagnostic_t d;
        d.level    = DIAG_ERROR;
        d.filename = self.filename;
        d.line     = line;
        d.col      = col;
        d.message  = msg;
        diag_vec_push(&self.diags, d);
        self.err_count = self.err_count + 1;
    }

    void emit_warning(diag_engine* self, i32 line, i32 col, i8* msg) {
        diagnostic_t d;
        d.level    = DIAG_WARNING;
        d.filename = self.filename;
        d.line     = line;
        d.col      = col;
        d.message  = msg;
        diag_vec_push(&self.diags, d);
    }

    void absorb(diag_engine* self, i8* msg) {
        self.emit_error(0, 0, msg);
    }

    bool has_errors(diag_engine* self) {
        return self.err_count > 0;
    }

    void flush(diag_engine* self) {
        for (i32 i = 0; i < self.diags.len; i = i + 1) {
            diagnostic_t d = self.diags.data[i];
            i8* lvl = "note";
            if (d.level == DIAG_ERROR)   { lvl = "error"; }
            if (d.level == DIAG_WARNING) { lvl = "warning"; }
            printf("%s:%d:%d: %s: %s\n",
                    d.filename, d.line, d.col, lvl, d.message);
        }
        if (self.err_count >= self.max_errors) {
            printf("%s: fatal: too many errors (%d), stopping.\n",
                    self.filename, self.err_count);
        }
    }

    bool finish(diag_engine* self) {
        self.flush();
        return self.has_errors();
    }
}

} // namespace diagnostics
