fn fact(n: i32) i32 {
    if (n <= 1) { return 1; }
    return n * fact(n - 1);
}

pub fn main() i32 {
    if (fact(0) != 1)   { return 1; }
    if (fact(1) != 1)   { return 2; }
    if (fact(5) != 120) { return 3; }
    if (fact(7) != 5040){ return 4; }
    return 0;
}
