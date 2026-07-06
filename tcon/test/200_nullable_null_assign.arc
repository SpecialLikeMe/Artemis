// ?T nullable: null is assignable to ?T and to pointer types
extern void* malloc(u64 n);
extern void  free(void* p);

i32 main() {
    ?i32 a = null;
    if (a != null) { return 1; }

    i32* p = null;
    if (p != null) { return 2; }

    return 0;
}
