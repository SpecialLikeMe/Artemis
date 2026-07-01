// &memstr as a parameter type: the compiler accepts memstr-typed parameters.
// The allocator is backed by an istruc passed by pointer.
extern "C" { void* malloc(u64 n); void free(void* p); }

istruc SimpleAlloc {
    i32 count;
    void __construct__(&self) { self.count = 0; }
    void* alloc(&self, u64 n)  { self.count = self.count + 1; return malloc(n); }
    void  drop(&self, void* p) { self.count = self.count - 1; free(p); }
}

// Accept allocator by pointer and use it
i32 sum_with_alloc(SimpleAlloc* a, i32 n) {
    i32* arr = (i32*)(*a).alloc((u64)sizeof(i32) * (u64)n);
    if (arr == 0) { return -1; }
    i32 s = 0;
    for (i32 i = 0; i < n; i = i + 1) { arr[i] = i + 1; s = s + arr[i]; }
    (*a).drop(arr);
    return s;
}

i32 main() {
    SimpleAlloc a;
    if (sum_with_alloc(&a, 5) != 15) { return 1; }  // 1+2+3+4+5
    if (sum_with_alloc(&a, 4) != 10) { return 2; }  // 1+2+3+4
    if (a.count != 0) { return 3; }                 // all freed
    return 0;
}
