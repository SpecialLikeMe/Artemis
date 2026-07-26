// FAIL: accessing a non-existent field in a struct
struct Pair { let a: i32; let b: i32; }
fn main() i32 {
    let mut p: Pair;
    p.c = 5;  // ERROR: 'c' does not exist
    return 0;
}
