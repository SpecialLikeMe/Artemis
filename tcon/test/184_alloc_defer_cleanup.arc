// Allocator cleanup with defer — allocation released automatically on scope exit
extern "C" { void* malloc(u64 size); void free(void* ptr); }

istruc TrackedAlloc {
    i32 live;
    void __construct__(&self) { self.live = 0; }
    void* alloc(&self, u64 n)  { self.live = self.live + 1; return malloc(n); }
    void  drop(&self, void* p) { self.live = self.live - 1; free(p); }
}

// Returns the sum of 1..n using allocator-backed storage; frees on return
i32 compute(TrackedAlloc* a, i32 n) {
    i32* buf = (i32*)(*a).alloc((u64)sizeof(i32) * (u64)n);
    if (buf == 0) { return -1; }
    defer (*a).drop(buf);   // guaranteed cleanup on any return path

    i32 total = 0;
    for (i32 i = 0; i < n; i = i + 1) {
        buf[i] = i + 1;
        total = total + buf[i];
    }
    return total;
}

i32 main() {
    TrackedAlloc ta;

    i32 r = compute(&ta, 4);   // 1+2+3+4 = 10
    if (r != 10) { return 1; }
    if (ta.live != 0) { return 2; }  // defer freed it

    r = compute(&ta, 5);       // 1+2+3+4+5 = 15
    if (r != 15) { return 3; }
    if (ta.live != 0) { return 4; }

    return 0;
}
