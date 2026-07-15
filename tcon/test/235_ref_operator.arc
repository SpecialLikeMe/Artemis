// PASS: ref operator builds a pointer of depth inferred from LHS type,
// including depth > 1 (multi-level pointers).
i32 main() {
    i32 x = 7;
    i32* p = ref x;
    if (*p != 7) { return 1; }

    // Modify through pointer
    *p = 99;
    if (x != 99) { return 2; }

    // ref on rvalue: allocs a temporary
    i32* q = ref 55;
    if (*q != 55) { return 3; }

    // depth-2: i32** pp = ref x builds a pointer-to-pointer-to-x
    i32 y = 42;
    i32** pp = ref y;
    if (**pp != 42) { return 4; }

    return 0;
}
