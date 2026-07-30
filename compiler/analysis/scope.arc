// Scope management for the Artemis self-hosting compiler analyzer.
// Symbol lookup goes through a hash index over an insertion-ordered array
// (see compiler/hash.arc); the array order is preserved because other passes rely on it.

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
    // BORROWED, not owned. Every declare*() stores this pointer as-is, and lookup()
    // strcmp's through it long after the declaring frame is gone. Callers must pass a
    // string that outlives the table — an AST-owned name, a literal, or a str_dup.
    // Passing a local [N]i8 buffer leaves the entry comparing against recycled stack,
    // which silently makes one symbol answer to another symbol's name.
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
    // Hash index over `entries` — see compiler/hash.arc. `entries` keeps its insertion
    // order; this only makes finding a name cheap. Name resolution used to scan the
    // whole table with strcmp for every identifier, which made analysis quadratic:
    // doubling the source multiplied it by ~3.7x instead of 2x.
    let head: *i32;        // bucket -> newest matching entry index, or -1
    let next: *i32;        // entry index -> next older entry in the same bucket, or -1
    let nbuckets: i32;
}

fn sym_table_init(t: *sym_table) void {
    t.entries  = (sym_entry*)0;
    t.len      = 0;
    t.cap      = 0;
    t.head     = (i32*)0;
    t.next     = (i32*)0;
    t.nbuckets = 0;
}

fn sym_bucket(t: *sym_table, name: *i8) i32 {
    return (i32)(str_hash32(name) & (u32)(t.nbuckets - 1));
}

// Rebuild the index from the entry array. Called when the bucket count grows, and as
// the safety net if a pop ever compacts rather than truncates.
fn sym_table_reindex(t: *sym_table, nbuckets: i32) void {
    t.nbuckets = nbuckets;
    t.head = (i32*)arc_realloc((i8*)t.head, sizeof(i32) * (u64)nbuckets);
    let mut b: i32= 0;
    while (b < nbuckets) { t.head[b] = -1; b = b + 1; }
    let mut i: i32= 0;
    while (i < t.len) {
        let mut h: i32= sym_bucket(t, t.entries[i].name);
        t.next[i] = t.head[h];
        t.head[h] = i;
        i = i + 1;
    }
}

fn sym_table_push(t: *sym_table, e: sym_entry) void {
    if (t.len >= t.cap) {
        let mut nc: i32= t.cap == 0 ? 32 : t.cap * 2;
        t.entries = (sym_entry*)arc_realloc((i8*)t.entries, sizeof(analysis__NS_sym_entry) * (u64)nc);
        t.next    = (i32*)arc_realloc((i8*)t.next, sizeof(i32) * (u64)nc);
        t.cap = nc;
    }
    t.entries[t.len] = e;
    // Keep the load factor near 1 so chains stay short.
    if (t.nbuckets == 0 || t.len + 1 > t.nbuckets) {
        sym_table_reindex(t, hash_cap_for(t.len + 1));
    }
    let mut h: i32= sym_bucket(t, e.name);
    t.next[t.len] = t.head[h];
    t.head[h]     = t.len;
    t.len = t.len + 1;
}

// Index of the newest live entry named `name`, or -1.
//
// Equivalent to the backwards linear scan it replaces: chain indices decrease, so the
// first match found is the one the old loop would have returned. pop_scope unlinks the
// entries it drops, so every index on a chain is live.
fn sym_table_find(t: *sym_table, name: *i8) i32 {
    if (t.nbuckets == 0 || name == (i8*)0) { return -1; }
    let mut i: i32= t.head[sym_bucket(t, name)];
    while (i >= 0) {
        if (strcmp(t.entries[i].name, name) == 0) { return i; }
        i = t.next[i];
    }
    return -1;
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
        // Remove the entries declared at the current depth.
        //
        // Depths along the live array are non-decreasing: an entry records the depth in
        // force when it was declared, depth only rises via push_scope, and coming back
        // down goes through here, which removes that depth's entries. So everything at
        // or above `depth` is a suffix, and popping is a truncation — walk back from the
        // end rather than rescanning the whole table.
        //
        // This mattered: the old full scan made every block exit cost O(symbols), which
        // is O(n^2) over a program and was most of what remained of the analyzer's
        // quadratic behaviour after the lookups were indexed.
        let mut new_len: i32= self.syms.len;
        while (new_len > 0 && self.syms.entries[new_len - 1].scope_depth >= self.depth) {
            // Unlink from its bucket on the way past. Dropped entries are visited newest
            // first, so by the time one is reached it is the head of its bucket if it is
            // in that bucket at all.
            //
            // Leaving them linked and skipping them at lookup time does NOT work: the
            // slot gets reused by a later declaration, at which point the stale head
            // points into another bucket's chain and this bucket loses its entries.
            if (self.syms.nbuckets > 0) {
                let mut h: i32= sym_bucket(&self.syms, self.syms.entries[new_len - 1].name);
                if (self.syms.head[h] == new_len - 1) {
                    self.syms.head[h] = self.syms.next[new_len - 1];
                }
            }
            new_len = new_len - 1;
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
        let mut i: i32= sym_table_find(&self.syms, name);
        if (i >= 0) { return self.syms.entries[i].is_comptime; }
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
        let mut i: i32= sym_table_find(&self.syms, name);
        if (i >= 0) { return self.syms.entries[i].is_void_ret; }
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
        let mut i: i32= sym_table_find(&self.syms, name);
        if (i >= 0) { return self.syms.entries[i].type_ptr; }
        return (i8*)0;
    }

    // Returns true if the name exists in ANY scope (regardless of type_ptr value)
    fn exists(self: *scope_manager, name: *i8) bool {
        return sym_table_find(&self.syms, name) >= 0;
    }

    // Lookup only at the current scope depth (for duplicate-in-same-scope detection)
    fn lookup_at_depth(self: *scope_manager, name: *i8) bool {
        // Walks the whole chain: a name may be bound at an outer depth as well, and
        // only a binding at *this* depth counts as a duplicate.
        if (self.syms.nbuckets == 0 || name == (i8*)0) { return false; }
        let mut i: i32= self.syms.head[sym_bucket(&self.syms, name)];
        while (i >= 0) {
            if (self.syms.entries[i].scope_depth == self.depth &&
                strcmp(self.syms.entries[i].name, name) == 0) {
                return true;
            }
            i = self.syms.next[i];
        }
        return false;
    }

    fn lookup_kind(self: *scope_manager, name: *i8) i32 {
        let mut i: i32= sym_table_find(&self.syms, name);
        if (i >= 0) { return self.syms.entries[i].kind; }
        return -1;
    }

    fn lookup_param_count(self: *scope_manager, name: *i8) i32 {
        let mut i: i32= sym_table_find(&self.syms, name);
        if (i >= 0) { return self.syms.entries[i].param_count; }
        return -1;
    }

    fn lookup_is_variadic(self: *scope_manager, name: *i8) bool {
        let mut i: i32= sym_table_find(&self.syms, name);
        if (i >= 0) { return self.syms.entries[i].is_variadic; }
        return false;
    }

    fn lookup_is_nullable(self: *scope_manager, name: *i8) bool {
        let mut i: i32= sym_table_find(&self.syms, name);
        if (i >= 0) { return self.syms.entries[i].is_nullable; }
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
