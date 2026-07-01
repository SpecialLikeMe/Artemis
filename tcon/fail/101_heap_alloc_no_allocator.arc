// FAIL: top-level free function calls malloc without a &memstr allocator param.
// Expected: compile error about heap allocation without allocator.
extern void* malloc(u64 n);

void* make_buffer(u64 size) {
    return malloc(size);  // error: no &memstr param
}

i32 main() {
    void* p = make_buffer(64);
    return 0;
}
