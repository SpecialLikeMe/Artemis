extern void* malloc(u64 size);
extern void  free(void* ptr);

memstr SysAlloc {
    void* mmap(SysAlloc* self, u64 n)         { return malloc(n); }
    void  rmap(SysAlloc* self, void* p, u64 n) { free(p); }
}

i32 main() {
    SysAlloc a;
    i32* p = (i32*)a.mmap(sizeof(i32) * 4);
    if (p == 0) { return 1; }
    p[0] = 10;
    p[1] = 20;
    p[2] = 30;
    p[3] = 40;
    i32 sum = p[0] + p[1] + p[2] + p[3];
    a.rmap(p, sizeof(i32) * 4);
    if (sum != 100) { return 2; }
    return 0;
}
