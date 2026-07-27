// std.alloc.memstr — Allocator interface (vtable fat-pointer pattern).
//
// 'memstr' is a compiler built-in fat-pointer type: { ptr data; *__vtable__ vtable }.
// __vtable__ holds five typed function-pointer slots:
//   mmap    : (meta: *void, size: u64) -> *void          — allocate size bytes
//   rsmap   : (meta: *void, ptr: *void, size: i64) -> bool  — resize in-place
//   rmap    : (meta: *void, ptr: *void, size: i64) -> *void — reallocate (may move)
//   free    : (meta: *void, ptr: *void) -> void           — free a pointer
//   destroy : (meta: *void) -> void                       — tear down allocator
//             (also accepted as 'deinit' for the destroy vtable slot)
//
// Usage — low-level fat pointer dispatch:
//   let ms: &memstr = MyAllocator;
//   let p: *void = ms.mmap(n);     // allocate n bytes
//   ms.free(p);                    // free it
//   ms.deinit();                   // destroy allocator (alias for ms.destroy())
//
// Usage — high-level Allocator wrapper:
//   let a: Allocator;
//   a.init(MyAllocator);
//   let p: *void = a.alloc(size);
//   a.dealloc(p);
//   a.deinit();

// __vtable__ is a compiler builtin — pre-registered by ensure_memstr_types(), no declaration needed.

// High-level allocator wrapper — wraps a '&memstr' fat pointer.
istruc Allocator {
    let ms: memstr;

    fn init(self: *Allocator, src: &memstr) void {
        self.ms = src;
    }

    fn alloc(self: *Allocator, n: u64) *void {
        return self.ms.mmap(n);
    }

    fn resize(self: *Allocator, p: *void, n: i64) bool {
        return self.ms.rsmap(p, n);
    }

    fn realloc(self: *Allocator, p: *void, n: i64) *void {
        return self.ms.rmap(p, n);
    }

    fn dealloc(self: *Allocator, p: *void) void {
        self.ms.free(p);
    }

    fn deinit(self: *Allocator) void {
        self.ms.deinit();
    }
}
