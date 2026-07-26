// PASS: @typeinfo returns correct field metadata for struct types
// Struct variant = tag 12; type_info_struct { name, fields, field_count, size_bytes, align_bytes, is_tuple, is_packed }
@unsafe extern fn strcmp(a: *i8, b: *i8) i32;
struct Vec2 {
    let x: i32;
    let y: i32;
}
pub fn main() i32 {
    let t = @typeinfo(Vec2);
    // Struct variant: tag=12
    if (t.__tag != 12) { return 1; }

    let mut fc: i64 = 0;
    let mut flds_ptr: *i8 = (i8*)0;
    match (*t) {
        type_info::Struct(nm, fp, count, sz, al, is_tup, is_pak) => { flds_ptr = fp; fc = count; }
        _ => { return 2; }
    }
    if (fc != 2) { return 2; }
    if (flds_ptr == (i8*)0) { return 3; }

    // Access fields array: cast to *type_info_field
    let mut flds: *type_info_field = (type_info_field*)flds_ptr;
    if (strcmp(flds[0].name, "x") != 0) { return 4; }
    if (flds[0].size != 4) { return 5; }
    if (strcmp(flds[1].name, "y") != 0) { return 6; }
    if (flds[1].offset != 4) { return 7; }
    return 0;
}
