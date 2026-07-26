// PASS: !i32 error union — non-void success type
fn get_val(x: i32) !i32 {
    if (x == 0) { return error.zero; }
    return x * 2;
}
pub fn main() i32 {
    let a: i32 = get_val(5) catch |e| { return 1; };
    if (a != 10) { return 2; }
    let b: i32 = get_val(0) catch |e| { return 0; };
    return b;
}
