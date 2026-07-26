// PASS: try propagates error across !i32 functions
fn inner(x: i32) !i32 {
    if (x == 0) { return error.fail; }
    return x;
}
fn outer(x: i32) !i32 {
    let v: i32 = try inner(x);
    return v + 1;
}
pub fn main() i32 {
    let a: i32 = outer(5) catch |e| { return 1; };
    if (a != 6) { return 2; }
    let b: i32 = outer(0) catch |e| { return 0; };
    return b;
}
