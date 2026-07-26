// Test: const_resolve macro — multiple captures and multi-rule dispatch
// Verifies: two captures, and two distinct rules matched by literal tokens.

@unsafe extern fn printf(fmt: *i8, ...) i32;

const_resolve swap_add {
    ($a:expr, $b:expr) => { (($a) + ($b)) },
}

const_resolve make_min {
    ($a:expr, $b:expr) => {
        (($a) < ($b) ? ($a) : ($b))
    },
}

pub fn main() i32 {
    let mut s: i32= swap_add(10, 32);
    if (s != 42) { return 1; }

    let mut m: i32= make_min(100, 7);
    if (m != 7) { return 2; }

    return 0;
}
