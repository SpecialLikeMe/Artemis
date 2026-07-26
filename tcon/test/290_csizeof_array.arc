// PASS: @csizeof and @alignof with array types and pointer types
struct Pair { let x: i32; let y: i32; }

pub fn main() i32 {
    // Primitive types
    if (@csizeof(i32)  != (usize)4)  { return 1; }
    if (@csizeof(u8)   != (usize)1)  { return 2; }
    if (@csizeof(f64)  != (usize)8)  { return 3; }
    if (@csizeof(bool) != (usize)1)  { return 4; }

    // Struct type
    if (@csizeof(Pair) != (usize)8)  { return 5; }

    // Array types
    if (@csizeof([10]u8)  != (usize)10) { return 6; }
    if (@csizeof([4]i32)  != (usize)16) { return 7; }
    if (@csizeof([2]f64)  != (usize)16) { return 8; }

    // Pointer type
    if (@csizeof(*i32)    != (usize)8)  { return 9; }

    // @alignof with array and pointer types
    if (@alignof([4]i32)  != (usize)4)  { return 10; }
    if (@alignof(*void)   != (usize)8)  { return 11; }

    return 0;
}
