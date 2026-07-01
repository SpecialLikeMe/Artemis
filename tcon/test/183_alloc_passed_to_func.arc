// Passing a custom allocator to functions (Zig-style allocator pattern)
extern "C" { void* malloc(u64 size); void free(void* ptr); }

istruc Alloc {
    i32 total_allocs;
    i32 total_frees;

    void __construct__(&self) { self.total_allocs = 0; self.total_frees = 0; }

    void* alloc(&self, u64 n) {
        self.total_allocs = self.total_allocs + 1;
        return malloc(n);
    }

    void dealloc(&self, void* p) {
        self.total_frees = self.total_frees + 1;
        free(p);
    }
}

// Function that takes an allocator and uses it to build an array
i32 sum_allocated(Alloc* a, i32 n) {
    i32* arr = (i32*)(*a).alloc((u64)(sizeof(i32)) * (u64)n);
    if (arr == 0) { return -1; }
    i32 s = 0;
    for (i32 i = 0; i < n; i = i + 1) {
        arr[i] = i + 1;
        s = s + arr[i];
    }
    (*a).dealloc(arr);
    return s;
}

i32 main() {
    Alloc a;

    i32 result = sum_allocated(&a, 5);  // 1+2+3+4+5 = 15
    if (result != 15) { return 1; }
    if (a.total_allocs != 1) { return 2; }
    if (a.total_frees  != 1) { return 3; }

    result = sum_allocated(&a, 3);  // 1+2+3 = 6
    if (result != 6) { return 4; }
    if (a.total_allocs != 2) { return 5; }
    if (a.total_frees  != 2) { return 6; }

    return 0;
}
