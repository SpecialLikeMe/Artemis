// PASS: @typeinfo() for istruc types reports correct kind (Istruc=13) and field count
istruc Point {
    let mut x: i32;
    let mut y: i32;
    fn __construct__(self: *Point, xv: i32, yv: i32) void {
        self.x = xv;
        self.y = yv;
    }
    fn sum(self: *Point) i32 { return self.x + self.y; }
}

pub fn main() i32 {
    let mut tp: *type_info = @typeinfo(Point);
    if (tp == (type_info*)0) { return 1; }
    // Istruc variant: tag=13
    if (tp.__tag != 13) { return 2; }

    // field_count should be >= 2 (x and y)
    let mut fc: i64 = 0;
    match (*tp) {
        type_info::Istruc(nm, flds, count, meths, mc, ifc, ifc_c, sz, al) => { fc = count; }
        _ => { return 3; }
    }
    if (fc < 2) { return 3; }

    // Also verify that @typeinfo on a used istruc instance still works
    let mut p: Point(3, 4);
    let mut tp2: *type_info = @typeinfo(Point);
    if (tp2 == (type_info*)0) { return 6; }
    let mut fc2: i64 = 0;
    match (*tp2) {
        type_info::Istruc(nm2, flds2, count2, meths2, mc2, ifc2, ifc_c2, sz2, al2) => { fc2 = count2; }
        _ => { return 7; }
    }
    if (fc2 != fc) { return 7; }

    return 0;
}
