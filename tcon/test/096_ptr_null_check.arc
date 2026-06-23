extern void* malloc(u64 size);
extern void  free(void* ptr);

i32 main() {
    i32* p = (i32*)malloc(sizeof(i32));
    if (p == 0) { return 1; }
    *p = 77;
    i32 val = *p;
    free(p);
    if (val != 77) { return 2; }
    return 0;
}
