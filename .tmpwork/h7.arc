struct Pt { let x: i32; let y: i32; }
fn type_size(comptime T: type) usize {
    return @csizeof(T);
}
pub fn main() i32 {
    if (type_size(i32) != 4) { return 1; }
    if (type_size(Pt) != 8) { return 2; }
    return 0;
}
