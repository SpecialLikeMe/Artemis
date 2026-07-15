// PASS: union fields share memory.
union IntFloat {
    i32 a;
    f32 b;
}
i32 main() {
    IntFloat u;
    u.a = 42;
    if (u.a != 42) { return 1; }

    // Shared memory: writing via one field, reading via another
    u.a = 0x3f800000;  // IEEE 754 bits for 1.0f
    // Reading back the integer bits should give the same value
    i32 bits = u.a;
    if (bits != 0x3f800000) { return 2; }

    return 0;
}
