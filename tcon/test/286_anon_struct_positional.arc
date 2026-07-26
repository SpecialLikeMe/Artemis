// PASS: anonymous struct positional fields accessed and written via subscript
pub fn main() i32 {
    let mut a = .{10, 20, 30};
    if (a[0] != 10) { return 1; }
    if (a[1] != 20) { return 2; }
    if (a[2] != 30) { return 3; }
    a[0] = 99;
    if (a[0] != 99) { return 4; }
    // Mixed: named and positional
    let mut b = .{42, .label = 7};
    if (b[0] != 42) { return 5; }
    if (b.label != 7) { return 6; }
    b[0] = 1;
    if (b[0] != 1) { return 7; }
    return 0;
}
