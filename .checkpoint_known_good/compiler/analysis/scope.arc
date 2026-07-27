// Scope management for the Artemis self-hosting compiler analyzer.
// Uses linear-search symbol tables (no hash maps needed for bootstrap).

namespace analysis {

// ---- Symbol kinds ----
enum sym_kind {
    sym_var      = 0,
    sym_func     = 1,
    sym_type     = 2,
    sym_enum     = 3,
    sym_func_ptr = 4,  // variable holding a function pointer (callable)
    // Bound by a pattern (match arm). Its type comes from the matched variant's
    // payload, which this pass does not model, so it must not be reported as a
    // non-callable variable when the payload happens to be a function pointer.
    sym_pat_bind = 5,
}

struct sym_entry {
    let name: *i8;
    let kind: i32;   // sym_kind
    let type_ptr: *i8;   // parser::type_node* as i8*
    let scope_depth: i32;
    let param_count: i32;  // for sym_func: >= 0 = exact, -1 = unknown
    let is_variadic: bool;  // for sym_func: true if variadic (...)
    let is_nullable: bool;  // for sym_var: true if declared as ?T
    let is_void_ret: bool;  // for sym_func: true if return type is void
    let is_comptime: bool;  // for sym_var: true if declared with comptime keyword
}

struct sym_table {
    let entries: *sym_entry;
    let len: i32;
    let cap: i32;
}

fn sym_table_init(t: *sym_table) void {
    t.entries = (sym_entry*)0;
    t.len     = 0;
    t.cap     = 0;
}

fn sym_table_push(t: *sym_table, e: sym_entry) void {
    if (t.len >= t.cap) {
        let mut nc: i32= t.cap == 0 ? 32 : t.cap * 2;
        t.entries = (sym_entry*)arc_realloc((i8*)t.entries, sizeof(analysis__NS_sym_entry) * (u64)nc);
        t.cap = nc;
    }
    t.entries[t.len] = e;
    t.len = t.len + 1;
}

// ---- Struct registry ----
struct struct_entry {
    let name: *i8;
    let decl_ptr: *i8;   // parser::struct_decl* as i8*
}

struct struct_table {
    let entries: *struct_entry;
    let len: i32;
    let cap: i32;
}

fn struct_table_init(t: *struct_table) void {
    t.entries = (struct_entry*)0;
    t.len     = 0;
    t.cap     = 0;
}

fn struct_table_push(t: *struct_table, e: struct_entry) void {
    if (t.len >= t.cap) {
        let mut nc: i32= t.cap == 0 ? 16 : t.cap * 2;
        t.entries = (struct_entry*)arc_realloc((i8*)t.entries, sizeof(analysis__NS_struct_entry) * (u64)nc);
        t.cap = nc;
    }
    t.entries[t.len] = e;
    t.len = t.len + 1;
}

// ---- Scope manager ----

istruc scope_manager {
    let mut syms: sym_table;
    let mut structs: struct_table;
    let mut depth: i32;

    fn init(self: *scope_manager) void {
        sym_table_init(&self.syms);
        struct_table_init(&self.structs);
        self.depth = 0;
    }

    fn push_scope(self: *scope_manager) void {
        self.depth = self.depth + 1;
    }

    fn pop_scope(self: *scope_manager) void {
        // Remove all entries at the current depth
        let mut new_len: i32= 0;
        let mut i: i32= 0;
        while (i < self.syms.len) {
            if (self.syms.entries[i].scope_depth < self.depth) {
                self.syms.entries[new_len] = self.syms.entries[i];
                new_len = new_len + 1;
            }
            i = i + 1;
        }
        self.syms.len = new_len;
        self.depth = self.depth - 1;
    }

    fn declare(self: *scope_manager, name: *i8, kind: i32, type_ptr: *i8) void {
        let mut e: sym_entry;
        e.name        = name;
        e.kind        = kind;
        e.type_ptr    = type_ptr;
        e.scope_depth = self.depth;
        e.param_count = 0;
        e.is_variadic = false;
        e.is_nullable = false;
        e.is_void_ret = false;
        e.is_comptime = false;
        sym_table_push(&self.syms, e);
    }

    fn declare_var(self: *scope_manager, name: *i8, kind: i32, type_ptr: *i8, is_nullable: bool) void {
        let mut e: sym_entry;
        e.name        = name;
        e.kind        = kind;
        e.type_ptr    = type_ptr;
        e.scope_depth = self.depth;
        e.param_count = 0;
        e.is_variadic = false;
        e.is_nullable = is_nullable;
        e.is_void_ret = false;
        e.is_comptime = false;
        sym_table_push(&self.syms, e);
    }

    fn declare_var_comptime(self: *scope_manager, name: *i8, kind: i32, type_ptr: *i8, is_nullable: bool, is_comptime: bool) void {
        let mut e: sym_entry;
        e.name        = name;
        e.kind        = kind;
        e.type_ptr    = type_ptr;
        e.scope_depth = self.depth;
        e.param_count = 0;
        e.is_variadic = false;
        e.is_nullable = is_nullable;
        e.is_void_ret = false;
        e.is_comptime = is_comptime;
        sym_table_push(&self.syms, e);
    }

    fn lookup_is_comptime(self: *scope_manager, name: *i8) bool {
        let mut i: i32= self.syms.len - 1;
        while (i >= 0) {
            if (strcmp(self.syms.entries[i].name, name) == 0) {
                return self.syms.entries[i].is_comptime;
            }
            i = i - 1;
        }
        return false;
    }

    fn declare_func(self: *scope_manager, name: *i8, type_ptr: *i8, param_count: i32, is_variadic: bool) void {
        let mut e: sym_entry;
        e.name        = name;
        e.kind        = (i32)sym_func;
        e.type_ptr    = type_ptr;
        e.scope_depth = self.depth;
        e.param_count = param_count;
        e.is_variadic = is_variadic;
        e.is_nullable = false;
        e.is_void_ret = false;
        e.is_comptime = false;
        sym_table_push(&self.syms, e);
    }

    fn declare_func_v(self: *scope_manager, name: *i8, type_ptr: *i8, param_count: i32, is_variadic: bool, is_void_ret: bool) void {
        let mut e: sym_entry;
        e.name        = name;
        e.kind        = (i32)sym_func;
        e.type_ptr    = type_ptr;
        e.scope_depth = self.depth;
        e.param_count = param_count;
        e.is_variadic = is_variadic;
        e.is_nullable = false;
        e.is_void_ret = is_void_ret;
        e.is_comptime = false;
        sym_table_push(&self.syms, e);
    }

    fn lookup_is_void_ret(self: *scope_manager, name: *i8) bool {
        let mut i: i32= self.syms.len - 1;
        while (i >= 0) {
            if (strcmp(self.syms.entries[i].name, name) == 0) {
                return self.syms.entries[i].is_void_ret;
            }
            i = i - 1;
        }
        return false;
    }

    fn declare_struct(self: *scope_manager, name: *i8, decl_ptr: *i8) void {
        let mut e: struct_entry;
        e.name     = name;
        e.decl_ptr = decl_ptr;
        struct_table_push(&self.structs, e);
    }

    // Lookup: search from innermost scope outward
    fn lookup(self: *scope_manager, name: *i8) *i8 {
        let mut i: i32= self.syms.len - 1;
        while (i >= 0) {
            if (strcmp(self.syms.entries[i].name, name) == 0) {
                return self.syms.entries[i].type_ptr;
            }
            i = i - 1;
        }
        return (i8*)0;
    }

    // Returns true if the name exists in ANY scope (regardless of type_ptr value)
    fn exists(self: *scope_manager, name: *i8) bool {
        let mut i: i32= self.syms.len - 1;
        while (i >= 0) {
            if (strcmp(self.syms.entries[i].name, name) == 0) {
                return true;
            }
            i = i - 1;
        }
        return false;
    }

    // Lookup only at the current scope depth (for duplicate-in-same-scope detection)
    fn lookup_at_depth(self: *scope_manager, name: *i8) bool {
        let mut i: i32= self.syms.len - 1;
        while (i >= 0) {
            if (self.syms.entries[i].scope_depth == self.depth &&
                strcmp(self.syms.entries[i].name, name) == 0) {
                return true;
            }
            i = i - 1;
        }
        return false;
    }

    fn lookup_kind(self: *scope_manager, name: *i8) i32 {
        let mut i: i32= self.syms.len - 1;
        while (i >= 0) {
            if (strcmp(self.syms.entries[i].name, name) == 0) {
                return self.syms.entries[i].kind;
            }
            i = i - 1;
        }
        return -1;
    }

    fn lookup_param_count(self: *scope_manager, name: *i8) i32 {
        let mut i: i32= self.syms.len - 1;
        while (i >= 0) {
            if (strcmp(self.syms.entries[i].name, name) == 0) {
                return self.syms.entries[i].param_count;
            }
            i = i - 1;
        }
        return -1;
    }

    fn lookup_is_variadic(self: *scope_manager, name: *i8) bool {
        let mut i: i32= self.syms.len - 1;
        while (i >= 0) {
            if (strcmp(self.syms.entries[i].name, name) == 0) {
                return self.syms.entries[i].is_variadic;
            }
            i = i - 1;
        }
        return false;
    }

    fn lookup_is_nullable(self: *scope_manager, name: *i8) bool {
        let mut i: i32= self.syms.len - 1;
        while (i >= 0) {
            if (strcmp(self.syms.entries[i].name, name) == 0) {
                return self.syms.entries[i].is_nullable;
            }
            i = i - 1;
        }
        return false;
    }

    fn lookup_struct(self: *scope_manager, name: *i8) *i8 {
        let mut i: i32= self.structs.len - 1;
        while (i >= 0) {
            if (strcmp(self.structs.entries[i].name, name) == 0) {
                return self.structs.entries[i].decl_ptr;
            }
            i = i - 1;
        }
        return (i8*)0;
    }
}

} // namespace analysis
