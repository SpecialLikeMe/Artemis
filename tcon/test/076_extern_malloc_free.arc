extern void* malloc(u64 size);
extern void  free(void* ptr);

i32 main() {
    i32* p = (i32*)malloc(sizeof(i32) * 4);
    if (p == 0) { return 1; }
    p[0] = 10;
    p[1] = 20;
    p[2] = 30;
    p[3] = 40;
    i32 sum = p[0] + p[1] + p[2] + p[3];
    free(p);
    if (sum != 100) { return 2; }
    return 0;
}
