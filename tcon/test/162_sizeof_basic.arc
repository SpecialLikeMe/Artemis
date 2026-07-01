// sizeof: primitive types and structs
struct Pair { i32 a; i32 b; }
struct Triple { i32 x; i32 y; i32 z; }

i32 main() {
    if (sizeof(i8)   != 1) { return 1; }
    if (sizeof(i16)  != 2) { return 2; }
    if (sizeof(i32)  != 4) { return 3; }
    if (sizeof(i64)  != 8) { return 4; }
    if (sizeof(f32)  != 4) { return 5; }
    if (sizeof(f64)  != 8) { return 6; }
    if (sizeof(bool) != 1) { return 7; }
    if (sizeof(Pair)   != 8)  { return 8; }
    if (sizeof(Triple) != 12) { return 9; }
    return 0;
}
