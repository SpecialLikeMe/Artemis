// Allocator factory via static methods using the new dot syntax
extern "C" { void* malloc(u64 n); void free(void* p); }

istruc BufAlloc {
    i32 alloc_count;
    i32 free_count;

    void __construct__(&self) { self.alloc_count = 0; self.free_count = 0; }

    // Static factory: creates a default BufAlloc
    static BufAlloc make() {
        BufAlloc b;
        return b;
    }

    void* alloc(&self, u64 n)  { self.alloc_count = self.alloc_count + 1; return malloc(n); }
    void  drop(&self, void* p) { self.free_count  = self.free_count  + 1; free(p); }

    static i32 overhead() { return 0; }  // no metadata overhead
}

i32 main() {
    // Use new . syntax for static method calls
    BufAlloc a = BufAlloc.make();

    if (BufAlloc.overhead() != 0) { return 1; }

    void* p1 = a.alloc((u64)64);
    void* p2 = a.alloc((u64)128);
    if (p1 == 0 || p2 == 0) { return 2; }
    if (a.alloc_count != 2) { return 3; }

    a.drop(p1);
    a.drop(p2);
    if (a.free_count != 2) { return 4; }

    return 0;
}
