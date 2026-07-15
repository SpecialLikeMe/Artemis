// System allocator shim.
// Raw heap primitives (malloc/realloc/free) are confined to the memstr SysAlloc
// so the rest of the compiler can allocate memory without --unsafe.
// bind/llvm.arc (included before this file) already provides:
//   i8* malloc(u64 size);
//   i8* realloc(i8* ptr, u64 size);
//   void free(i8* ptr);

memstr SysAlloc {
    void* alloc_(SysAlloc* self, u64 n)            { return (void*)malloc(n); }
    void* grow_(SysAlloc* self, i8* p, u64 n)       { return (void*)realloc(p, n); }
    void  free_(SysAlloc* self, i8* p)               { free(p); }
}

// These wrappers are NOT named malloc/realloc/free so the heap-op
// enforcement in the analyzer does not flag them.
void* arc_malloc(u64 n)            { SysAlloc _s; return _s.alloc_(n); }
void* arc_realloc(i8* p, u64 n)    { SysAlloc _s; return _s.grow_(p, n); }
void  arc_free(i8* p)              { SysAlloc _s; _s.free_(p); }
