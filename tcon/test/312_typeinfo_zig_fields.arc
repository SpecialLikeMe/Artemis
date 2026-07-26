// PASS: @typeinfo ADT variant fields — pointer depth/const, enum exhaustive.

enum Color { Red = 0, Green = 1, Blue = 2 }
struct Point { let x: i32; let y: i32; }

pub fn main() i32 {
    // Pointer: depth=1, is_const=0 (non-const data), child != null
    let ti_ptr: *type_info = @typeinfo(*i32);
    if (ti_ptr.__tag != 9) { return 1; }  // Pointer=9
    let mut depth: i64 = 0;
    let mut is_c: i64 = 1;
    match (*ti_ptr) {
        type_info::Pointer(dep, constness, ch) => { depth = dep; is_c = constness; }
        _ => { return 2; }
    }
    if (depth != 1) { return 2; }
    if (is_c != 0)  { return 3; }

    // Enum: Enum variant (tag=15), is_exhaustive=1 for all Arc enums
    let ti_en: *type_info = @typeinfo(Color);
    if (ti_en.__tag != 15) { return 4; }  // Enum=15
    let mut exhaustive: i64 = 0;
    match (*ti_en) {
        type_info::Enum(nm, flds, count, exh) => { exhaustive = exh; }
        _ => { return 5; }
    }
    if (exhaustive != 1) { return 5; }

    // Struct: Struct variant (tag=12)
    let ti_st: *type_info = @typeinfo(Point);
    if (ti_st.__tag != 12) { return 6; }  // Struct=12

    // Primitive int: Int variant (tag=2)
    let ti_i32: *type_info = @typeinfo(i32);
    if (ti_i32.__tag != 2) { return 8; }  // Int=2

    return 0;
}
