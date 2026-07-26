// Test: const_resolve macro — simple pattern substitution
// Verifies: single-capture expr rule expands and evaluates correctly.

@unsafe extern fn printf(fmt: *i8, ...) i32;

const_resolve double_it {
    ($x:expr) => { (($x) + ($x)) },
}

pub fn main() i32 {
    let mut val: i32= double_it(21);
    if (val != 42) { return 1; }
    return 0;
}
