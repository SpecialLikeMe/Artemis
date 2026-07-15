extern void* malloc(u64 size);
extern void  free(void* ptr);

memstr SysAlloc {
    void* mmap(SysAlloc* self, u64 n)         { return malloc(n); }
    void  rmap(SysAlloc* self, void* p, u64 n) { free(p); }
}

i32 main() {
    SysAlloc a;
    i32* p = (i32*)a.mmap(sizeof(i32));
    if (p == 0) { return 1; }
    *p = 77;
    i32 val = *p;
    a.rmap(p, sizeof(i32));
    if (val != 77) { return 2; }
    return 0;
}
