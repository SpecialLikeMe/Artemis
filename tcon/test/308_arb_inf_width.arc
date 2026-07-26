// PASS: i[_] and u[_] are the infinite-width shorthand; they map to i1024/u1024
// (1024 bits = 128 bytes), which is the largest practical LLVM integer.

pub fn main() i32 {
    let mut x: i[_] = 0;
    let mut y: u[_] = 0;

    // i[_] maps to i1024 = 128 bytes
    if (@csizeof(i[_]) != 128) { return 1; }
    if (@csizeof(u[_]) != 128) { return 2; }

    // Basic arithmetic should work
    x = 100000000000;
    y = 200000000000;
    if (x != 100000000000) { return 3; }
    if (y != 200000000000) { return 4; }

    return 0;
}
