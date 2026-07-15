// PASS: @typeinfo on primitive types — returns valid type_info with correct fields.
i32 main() {
    type_info* ti = @typeinfo(i32);
    if (ti == (type_info*)0) { return 1; }
    if (ti.kind != 0)  { return 2; }  // 0 = primitive
    if (ti.bits != 32) { return 3; }
    if (ti.size != 4)  { return 4; }

    type_info* tf = @typeinfo(f64);
    if (tf == (type_info*)0) { return 5; }
    if (tf.kind != 0)  { return 6; }
    if (tf.bits != 64) { return 7; }

    type_info* tu = @typeinfo(u8);
    if (tu == (type_info*)0) { return 8; }
    if (tu.bits != 8)  { return 9; }

    return 0;
}
