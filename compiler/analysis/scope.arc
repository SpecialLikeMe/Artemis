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
}

struct sym_entry {
    i8*  name;
    i32  kind;   // sym_kind
    i8*  type_ptr;   // parser::type_node* as i8*
    i32  scope_depth;
    i32  param_count;  // for sym_func: >= 0 = exact, -1 = unknown
    bool is_variadic;  // for sym_func: true if variadic (...)
    bool is_nullable;  // for sym_var: true if declared as ?T
    bool is_void_ret;  // for sym_func: true if return type is void
    bool is_comptime;  // for sym_var: true if declared with comptime keyword
}

struct sym_table {
    sym_entry* entries;
    i32        len;
    i32        cap;
}

void sym_table_init(sym_table* t) {
    t.entries = (sym_entry*)0;
    t.len     = 0;
    t.cap     = 0;
}

void sym_table_push(sym_table* t, sym_entry e) {
    if (t.len >= t.cap) {
        i32 nc = t.cap == 0 ? 32 : t.cap * 2;
        t.entries = (sym_entry*)arc_realloc((i8*)t.entries, sizeof(analysis__NS_sym_entry) * (u64)nc);
        t.cap = nc;
    }
    t.entries[t.len] = e;
    t.len = t.len + 1;
}

// ---- Struct registry ----
struct struct_entry {
    i8*  name;
    i8*  decl_ptr;   // parser::struct_decl* as i8*
}

struct struct_table {
    struct_entry* entries;
    i32           len;
    i32           cap;
}

void struct_table_init(struct_table* t) {
    t.entries = (struct_entry*)0;
    t.len     = 0;
    t.cap     = 0;
}

void struct_table_push(struct_table* t, struct_entry e) {
    if (t.len >= t.cap) {
        i32 nc = t.cap == 0 ? 16 : t.cap * 2;
        t.entries = (struct_entry*)arc_realloc((i8*)t.entries, sizeof(analysis__NS_struct_entry) * (u64)nc);
        t.cap = nc;
    }
    t.entries[t.len] = e;
    t.len = t.len + 1;
}

// ---- Scope manager ----

istruc scope_manager {
    sym_table    syms;
    struct_table structs;
    i32          depth;

    void init(scope_manager* self) {
        sym_table_init(&self.syms);
        struct_table_init(&self.structs);
        self.depth = 0;
    }

    void push_scope(scope_manager* self) {
        self.depth = self.depth + 1;
    }

    void pop_scope(scope_manager* self) {
        // Remove all entries at the current depth
        i32 new_len = 0;
        i32 i = 0;
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

    void declare(scope_manager* self, i8* name, i32 kind, i8* type_ptr) {
        sym_entry e;
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

    void declare_var(scope_manager* self, i8* name, i32 kind, i8* type_ptr, bool is_nullable) {
        sym_entry e;
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

    void declare_var_comptime(scope_manager* self, i8* name, i32 kind, i8* type_ptr, bool is_nullable, bool is_comptime) {
        sym_entry e;
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

    bool lookup_is_comptime(scope_manager* self, i8* name) {
        i32 i = self.syms.len - 1;
        while (i >= 0) {
            if (strcmp(self.syms.entries[i].name, name) == 0) {
                return self.syms.entries[i].is_comptime;
            }
            i = i - 1;
        }
        return false;
    }

    void declare_func(scope_manager* self, i8* name, i8* type_ptr, i32 param_count, bool is_variadic) {
        sym_entry e;
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

    void declare_func_v(scope_manager* self, i8* name, i8* type_ptr, i32 param_count, bool is_variadic, bool is_void_ret) {
        sym_entry e;
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

    bool lookup_is_void_ret(scope_manager* self, i8* name) {
        i32 i = self.syms.len - 1;
        while (i >= 0) {
            if (strcmp(self.syms.entries[i].name, name) == 0) {
                return self.syms.entries[i].is_void_ret;
            }
            i = i - 1;
        }
        return false;
    }

    void declare_struct(scope_manager* self, i8* name, i8* decl_ptr) {
        struct_entry e;
        e.name     = name;
        e.decl_ptr = decl_ptr;
        struct_table_push(&self.structs, e);
    }

    // Lookup: search from innermost scope outward
    i8* lookup(scope_manager* self, i8* name) {
        i32 i = self.syms.len - 1;
        while (i >= 0) {
            if (strcmp(self.syms.entries[i].name, name) == 0) {
                return self.syms.entries[i].type_ptr;
            }
            i = i - 1;
        }
        return (i8*)0;
    }

    // Returns true if the name exists in ANY scope (regardless of type_ptr value)
    bool exists(scope_manager* self, i8* name) {
        i32 i = self.syms.len - 1;
        while (i >= 0) {
            if (strcmp(self.syms.entries[i].name, name) == 0) {
                return true;
            }
            i = i - 1;
        }
        return false;
    }

    // Lookup only at the current scope depth (for duplicate-in-same-scope detection)
    bool lookup_at_depth(scope_manager* self, i8* name) {
        i32 i = self.syms.len - 1;
        while (i >= 0) {
            if (self.syms.entries[i].scope_depth == self.depth &&
                strcmp(self.syms.entries[i].name, name) == 0) {
                return true;
            }
            i = i - 1;
        }
        return false;
    }

    i32 lookup_kind(scope_manager* self, i8* name) {
        i32 i = self.syms.len - 1;
        while (i >= 0) {
            if (strcmp(self.syms.entries[i].name, name) == 0) {
                return self.syms.entries[i].kind;
            }
            i = i - 1;
        }
        return -1;
    }

    i32 lookup_param_count(scope_manager* self, i8* name) {
        i32 i = self.syms.len - 1;
        while (i >= 0) {
            if (strcmp(self.syms.entries[i].name, name) == 0) {
                return self.syms.entries[i].param_count;
            }
            i = i - 1;
        }
        return -1;
    }

    bool lookup_is_variadic(scope_manager* self, i8* name) {
        i32 i = self.syms.len - 1;
        while (i >= 0) {
            if (strcmp(self.syms.entries[i].name, name) == 0) {
                return self.syms.entries[i].is_variadic;
            }
            i = i - 1;
        }
        return false;
    }

    bool lookup_is_nullable(scope_manager* self, i8* name) {
        i32 i = self.syms.len - 1;
        while (i >= 0) {
            if (strcmp(self.syms.entries[i].name, name) == 0) {
                return self.syms.entries[i].is_nullable;
            }
            i = i - 1;
        }
        return false;
    }

    i8* lookup_struct(scope_manager* self, i8* name) {
        i32 i = self.structs.len - 1;
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
