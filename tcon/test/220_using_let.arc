// PASS: `using let = const auto;` and `using var = auto;` contextual aliases work.
using let = const auto;
using var = auto;

pub fn main() i32 {
    let x = 42;
    let mut y: var= x + 8;
    if (y != 50) { return 1; }
    return 0;
}
