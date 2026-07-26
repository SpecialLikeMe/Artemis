// extern "C" { } exports Artemis functions with C calling convention / no mangling.
// Plain extern decl (no "C") imports an external symbol.
@unsafe extern fn abs(x: i32) i32;
@unsafe extern fn llabs(x: i64) i64;

// These Artemis functions are exported with C ABI (no name mangling):
extern "C" {
    fn arc_double(x: i32) i32 { return x * 2; }
    fn arc_negate(x: i32) i32 { return -x; }
}

pub fn main() i32 {
    if (abs(-9)            != 9)   { return 1; }
    if (llabs((i64)-100)   != (i64)100) { return 2; }
    if (arc_double(5)      != 10)  { return 3; }
    if (arc_negate(7)      != -7)  { return 4; }
    return 0;
}
