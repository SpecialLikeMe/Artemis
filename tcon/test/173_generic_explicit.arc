// Generic function with explicit type argument
fn identity<T>(x: T) T { return x; }
fn add_vals<T>(a: T, b: T) T { return a + b; }

pub fn main() i32 {
    let mut a: i32= identity<i32>(42);
    let mut b: i64= identity<i64>((i64)999);
    let mut c: bool= identity<bool>(1);

    if (a != 42)    { return 1; }
    if (b != 999)   { return 2; }
    if (!c)         { return 3; }

    if (add_vals<i32>(3, 4)   != 7)  { return 4; }
    if (add_vals<i64>((i64)10, (i64)20) != 30) { return 5; }
    return 0;
}
