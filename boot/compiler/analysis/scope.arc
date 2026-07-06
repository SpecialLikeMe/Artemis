// Scope management for the Artemis self-hosting compiler analyzer.
// Uses linear-search symbol tables (no hash maps needed for bootstrap).

namespace analysis {

// ---- Symbol kinds ----
enum sym_kind {
    sym_var    = 0,
    sym_func   = 1,
    sym_type   = 2,
    sym_enum   = 3,
}

struct sym_entry {
    i8*  name;
    i32  kind;   // sym_kind
    i8*  type_ptr;   // parser::type_node* as i8*
    i32  scope_depth;
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
        t.entries = (sym_entry*)realloc((i8*)t.entries, sizeof(analysis__NS_sym_entry) * (u64)nc);
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
        t.entries = (struct_entry*)realloc((i8*)t.entries, sizeof(analysis__NS_struct_entry) * (u64)nc);
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
        sym_table_push(&self.syms, e);
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
