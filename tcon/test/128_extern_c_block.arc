// extern "C" { } exports Artemis functions with C calling convention / no mangling.
// Plain extern decl (no "C") imports an external symbol.
extern i32 abs(i32 x);
extern i64 llabs(i64 x);

// These Artemis functions are exported with C ABI (no name mangling):
extern "C" {
    i32 arc_double(i32 x) { return x * 2; }
    i32 arc_negate(i32 x) { return -x; }
}

i32 main() {
    if (abs(-9)            != 9)   { return 1; }
    if (llabs((i64)-100)   != (i64)100) { return 2; }
    if (arc_double(5)      != 10)  { return 3; }
    if (arc_negate(7)      != -7)  { return 4; }
    return 0;
}
