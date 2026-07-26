fn is_even(n: i32) i32;
fn is_odd(n: i32) i32;

fn is_even(n: i32) i32 {
    if (n == 0) { return 1; }
    return is_odd(n - 1);
}
fn is_odd(n: i32) i32 {
    if (n == 0) { return 0; }
    return is_even(n - 1);
}

pub fn main() i32 {
    if (!is_even(4))  { return 1; }
    if (!is_odd(3))   { return 2; }
    if (is_even(7))   { return 3; }
    if (is_odd(8))    { return 4; }
    return 0;
}
