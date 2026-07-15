// PASS: @shcopy, @decopy, @move, ref operator basics.
i32 main() {
    i32 a = 42;

    // @shcopy: explicit shallow copy (same as assignment for primitives)
    i32 b = @shcopy(a);
    if (b != 42) { return 1; }

    // @decopy: deep copy (same as shallow for primitives)
    i32 c = @decopy(a);
    if (c != 42) { return 2; }

    // @move: copy value, zero source
    i32 d = @move(a);
    if (d != 42)  { return 3; }
    if (a != 0)   { return 4; }

    // ref: build a pointer to a value
    i32 x = 100;
    i32* p = ref x;
    if (*p != 100) { return 5; }
    *p = 200;
    if (x != 200)  { return 6; }

    return 0;
}
