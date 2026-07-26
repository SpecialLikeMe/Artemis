// PASS: @typeinfo reports method_count > 0 for istrucs with methods
// Istruc = tag 13; type_info_istruc { name, fields, field_count, methods, method_count, interfaces, interface_count, size_bytes, align_bytes }
istruc Counter {
    let mut value: i32;
    fn __construct__(self: *Counter, v: i32) void { self.value = v; }
    fn inc(self: *Counter) void { self.value = self.value + 1; }
    fn get(self: *Counter) i32 { return self.value; }
    fn reset(self: *Counter) void { self.value = 0; }
}

pub fn main() i32 {
    let mut t: *type_info = @typeinfo(Counter);
    if (t == (type_info*)0) { return 1; }
    // Istruc variant: tag=13
    if (t.__tag != 13) { return 2; }

    let mut fc: i64 = 0;
    let mut mc: i64 = 0;
    let mut mths_ptr: *i8 = (i8*)0;
    match (*t) {
        type_info::Istruc(nm, flds, count, mp, mcount, ifc, ifc_c, sz, al) => {
            fc = count;
            mths_ptr = mp;
            mc = mcount;
        }
        _ => { return 3; }
    }
    // field_count should be 1 (value)
    if (fc != 1) { return 3; }
    // method_count should be >= 3 (inc, get, reset; __construct__ excluded)
    if (mc < 3) { return 4; }
    // methods pointer should be non-null
    if (mths_ptr == (i8*)0) { return 5; }
    return 0;
}
