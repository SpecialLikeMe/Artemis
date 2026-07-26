// PASS: @typeinfo on an istruc — returns Istruc variant (tag 13) with field count.
istruc Point {
    let mut x: i32;
    let mut y: i32;
    fn __construct__(self: *Point, px: i32, py: i32) void {
        self.x = px;
        self.y = py;
    }
}

pub fn main() i32 {
    let mut ti: *type_info = @typeinfo(Point);
    if (ti == (type_info*)0) { return 1; }
    // Istruc = tag 13
    if (ti.__tag != 13) { return 2; }

    // Extract field_count via match — type_info_istruc field layout:
    // 0=name, 1=fields, 2=field_count, 3=methods, 4=method_count, 5=interfaces,
    // 6=interface_count, 7=size_bytes, 8=align_bytes
    let mut fc: i64 = 0;
    match (*ti) {
        type_info::Istruc(nm, flds, count, meths, mc, ifc, ifc_c, sz, al) => { fc = count; }
        _ => { return 2; }
    }
    if (fc < 2) { return 3; }

    return 0;
}
