// PASS: @typeinfo covers pointer (tag=9), array (tag=10), enum (tag=15), ADT enum (tag=16), istruc (tag=13).
enum Color { Red, Green, Blue }
enum Payload { Tag(i32), Value(i32, i32) }

istruc Vec2 {
    let mut x: f32;
    let mut y: f32;
}

pub fn main() i32 {
    // Pointer: Pointer variant (tag=9)
    let t_ptr = @typeinfo(*i32);
    if (t_ptr.__tag != 9) { return 1; }

    // Array: Array variant (tag=10); len=5
    let t_arr = @typeinfo([5]i32);
    if (t_arr.__tag != 10) { return 3; }
    let mut arr_len: i64 = 0;
    match (*t_arr) {
        type_info::Array(n, child) => { arr_len = n; }
        _ => { return 4; }
    }
    if (arr_len != 5) { return 4; }

    // Simple enum: Enum variant (tag=15), field_count=3
    let t_enum = @typeinfo(Color);
    if (t_enum.__tag != 15) { return 5; }
    let mut ec: i64 = 0;
    match (*t_enum) {
        type_info::Enum(nm, flds, count, exh) => { ec = count; }
        _ => { return 6; }
    }
    if (ec != 3) { return 6; }

    // ADT enum: AdtEnum variant (tag=16), variant_count=2
    let t_adt = @typeinfo(Payload);
    if (t_adt.__tag != 16) { return 7; }
    let mut vc: i64 = 0;
    match (*t_adt) {
        type_info::AdtEnum(nm, vars, count, exh) => { vc = count; }
        _ => { return 8; }
    }
    if (vc != 2) { return 8; }

    // istruc: Istruc variant (tag=13), field_count=2
    let t_vec2 = @typeinfo(Vec2);
    if (t_vec2.__tag != 13) { return 9; }
    let mut ifc: i64 = 0;
    match (*t_vec2) {
        type_info::Istruc(nm, flds, count, meths, mc, ifc_p, ifc_c, sz, al) => { ifc = count; }
        _ => { return 10; }
    }
    if (ifc != 2) { return 10; }

    return 0;
}
