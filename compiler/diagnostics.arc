// Diagnostics module for the Artemis self-hosting compiler.

namespace diagnostics {

// Diagnostic level constants
enum diag_level_t {
    DIAG_NOTE    = 0,
    DIAG_WARNING = 1,
    DIAG_ERROR   = 2,
}

struct diagnostic_t {
    let level: i32;
    let filename: *i8;
    let line: i32;
    let col: i32;
    let message: *i8;
}

// Dynamic array of diagnostics
struct diag_vec {
    let data: *diagnostic_t;
    let len: i32;
    let cap: i32;
}

fn diag_vec_push(v: *diag_vec, d: diagnostic_t) void {
    if (v.len >= v.cap) {
        let mut nc: i32= v.cap == 0 ? 16 : v.cap * 2;
        let mut nd: *diagnostic_t= (diagnostic_t*)arc_realloc((i8*)v.data, sizeof(diagnostic_t) * (u64)nc);
        if (nd == (diagnostic_t*)0) {
            printf("fatal: out of memory in diagnostic vector\n");
            return;
        }
        v.data = nd;
        v.cap = nc;
    }
    v.data[v.len] = d;
    v.len = v.len + 1;
}

// ---- Diagnostic engine ----

istruc diag_engine {
    let mut filename: *i8;
    let mut diags: diag_vec;
    let mut err_count: i32;
    let mut max_errors: i32;

    fn init(self: *diag_engine, fname: *i8) void {
        self.filename   = fname;
        self.err_count  = 0;
        self.max_errors = 20;
        self.diags.data = (diagnostic_t*)0;
        self.diags.len  = 0;
        self.diags.cap  = 0;
    }

    fn emit_error(self: *diag_engine, line: i32, col: i32, msg: *i8) void {
        if (self.err_count >= self.max_errors) { return; }
        let mut d: diagnostic_t;
        d.level    = DIAG_ERROR;
        d.filename = self.filename;
        d.line     = line;
        d.col      = col;
        d.message  = msg;
        diag_vec_push(&self.diags, d);
        self.err_count = self.err_count + 1;
    }

    fn emit_warning(self: *diag_engine, line: i32, col: i32, msg: *i8) void {
        let mut d: diagnostic_t;
        d.level    = DIAG_WARNING;
        d.filename = self.filename;
        d.line     = line;
        d.col      = col;
        d.message  = msg;
        diag_vec_push(&self.diags, d);
    }

    fn absorb(self: *diag_engine, msg: *i8) void {
        (void)msg; // intentionally suppressed — caller determined this diagnostic is not an error
    }

    fn has_errors(self: *diag_engine) bool {
        return self.err_count > 0;
    }

    fn flush(self: *diag_engine) void {
        for (let mut i: i32 = 0; i < self.diags.len; i = i + 1) {
            let mut d: diagnostic_t= self.diags.data[i];
            let mut lvl: *i8= "note";
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

    fn finish(self: *diag_engine) bool {
        self.flush();
        return self.has_errors();
    }
}

} // namespace diagnostics
