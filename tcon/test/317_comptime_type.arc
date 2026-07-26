// PASS: comptime T: type parameter
fn zero_val(comptime T: type) T {
    let mut v: T;
    return v;
}
fn type_size(comptime T: type) usize {
    return @csizeof(T);
}
pub fn main() i32 {
    let a: i32 = zero_val(i32);
    if (a != 0) { return 1; }
    if (type_size(i32) != 4) { return 2; }
    if (type_size(i64) != 8) { return 3; }
    return 0;
}
