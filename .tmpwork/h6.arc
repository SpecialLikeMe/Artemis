struct Pt { let x: i32; let y: i32; }
fn sz(comptime T: type) u64 { return (u64)@csizeof(T); }
pub fn main() i32 {
    let mut a: u64= sz(i32);
    if (a != 4u) { return 1; }
    let mut b: u64= sz(Pt);
    if (b != 8u) { return 2; }
    return 0;
}
