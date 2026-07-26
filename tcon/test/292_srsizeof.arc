// PASS: @srsizeof returns the immediate (shallow) byte size of a value
struct Pair { let x: i32; let y: i32; }

pub fn main() i32 {
    let x: i32 = 42;
    if (@srsizeof(x) != (usize)4) { return 1; }

    let d: f64 = 3.14;
    if (@srsizeof(d) != (usize)8) { return 2; }

    let mut arr: [5]u8;
    if (@srsizeof(arr) != (usize)5) { return 3; }

    let mut arr4: [4]i32;
    if (@srsizeof(arr4) != (usize)16) { return 4; }

    let mut p: Pair;
    if (@srsizeof(p) != (usize)8) { return 5; }

    // Pointer: shallow size is pointer size (8), not pointee
    let mut pi: *i32 = &x;
    if (@srsizeof(pi) != (usize)8) { return 6; }

    return 0;
}
