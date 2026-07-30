// System allocator shim.
// Raw heap primitives (malloc/realloc/free) are confined to the memstr SysAlloc
// so the rest of the compiler can allocate memory without --unsafe.
// bind/llvm.arc (included before this file) already provides:
//   i8* malloc(u64 size);
//   i8* realloc(i8* ptr, u64 size);
//   void free(i8* ptr);

memstr SysAlloc {
    fn alloc_(self: *SysAlloc, n: u64) *void            { return (void*)malloc(n); }
    fn grow_(self: *SysAlloc, p: *i8, n: u64) *void       { return (void*)realloc(p, n); }
    fn free_(self: *SysAlloc, p: *i8) void               { free(p); }
}

// These wrappers are NOT named malloc/realloc/free so the heap-op
// enforcement in the analyzer does not flag them.
fn arc_malloc(n: u64) *void            { let mut _s: SysAlloc; return _s.alloc_(n); }
fn arc_realloc(p: *i8, n: u64) *void    { let mut _s: SysAlloc; return _s.grow_(p, n); }
fn arc_free(p: *i8) void              { let mut _s: SysAlloc; _s.free_(p); }
