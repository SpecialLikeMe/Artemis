i32 main() {
    if (sizeof(i8)  != 1) { return 1; }
    if (sizeof(i16) != 2) { return 2; }
    if (sizeof(i32) != 4) { return 3; }
    if (sizeof(i64) != 8) { return 4; }
    if (sizeof(f32) != 4) { return 5; }
    if (sizeof(f64) != 8) { return 6; }
    return 0;
}
