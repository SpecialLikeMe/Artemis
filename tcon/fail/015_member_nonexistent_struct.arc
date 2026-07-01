// FAIL: accessing a non-existent field in a struct
struct Pair { i32 a; i32 b; }
i32 main() {
    Pair p;
    p.c = 5;  // ERROR: 'c' does not exist
    return 0;
}
