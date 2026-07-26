// Test distinct function names (overloading removed; use unique names per arity)
fn sum0() i32                    { return 0; }
fn sum1(a: i32) i32               { return a; }
fn sum2(a: i32, b: i32) i32        { return a + b; }
fn sum3(a: i32, b: i32, c: i32) i32 { return a + b + c; }

pub fn main() i32 {
    if (sum0()        != 0)  { return 1; }
    if (sum1(5)       != 5)  { return 2; }
    if (sum2(3, 4)    != 7)  { return 3; }
    if (sum3(1, 2, 3) != 6)  { return 4; }
    return 0;
}
