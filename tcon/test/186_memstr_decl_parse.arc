// memstr declaration: the compiler accepts the memstr keyword and syntax.
// The memstr type is parsed as an opaque allocator interface declaration.
extern "C" { void* malloc(u64 n); void free(void* p); void* realloc(void* p, u64 n); }

void* do_nothing_deinit() { return (void*)0; }

memstr MallocAlloc {
    .ptr = 0;
    .vtable = {
        .mmap   = malloc;
        .rmap   = realloc;
        .deinit = free;
    };
}

// Functions can accept &memstr parameters (opaque allocator reference).
// Here we use a concrete allocator directly to exercise the code path.
void* buf_alloc(u64 size) {
    return malloc(size);
}

i32 main() {
    // Basic malloc/free works independently of memstr vtable
    i32* p = (i32*)buf_alloc(sizeof(i32) * 4);
    if (p == 0) { return 1; }
    p[0] = 5; p[1] = 10; p[2] = 15; p[3] = 20;
    i32 sum = p[0] + p[1] + p[2] + p[3];
    if (sum != 50) { return 2; }
    free(p);
    return 0;
}
