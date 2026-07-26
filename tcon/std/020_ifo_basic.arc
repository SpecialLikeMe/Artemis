// PASS: @typeinfo() returns correct metadata for primitive and struct types.
// Uses compiler-builtin type_info; no stdlib import needed.

struct Point { let x: i32; let y: i32; }

pub fn main() i32 {
    // Primitive: i32
    let mut ti: *type_info= @typeinfo(i32);
    if (ti.kind != 0)       { return 1; }   // 0 = IFO_KIND_PRIM
    if (ti.bits != 32)      { return 2; }
    if (ti.size != 4)       { return 3; }
    if (ti.is_signed != 1)  { return 4; }
    if (ti.field_count != 0){ return 5; }

    // Unsigned: u64
    let mut tu: *type_info= @typeinfo(u64);
    if (tu.kind != 0)       { return 6; }   // IFO_KIND_PRIM
    if (tu.bits != 64)      { return 7; }
    if (tu.is_signed != 0)  { return 8; }

    // Struct: Point (two i32 fields)
    let mut tp: *type_info= @typeinfo(Point);
    if (tp.kind != 2)       { return 9; }   // 2 = IFO_KIND_STRUCT
    if (tp.field_count != 2){ return 10; }
    if (tp.fields == (type_info_field*)0) { return 11; }

    // Numeric check: i32 kind is PRIM and has nonzero bits
    if (ti.kind != 0 || ti.bits == 0) { return 12; }

    // Pointer kind
    let mut tpi: *type_info= @typeinfo(i32*);
    if (tpi.kind != 1)      { return 13; }  // 1 = IFO_KIND_PTR
    if (tpi.elem_type == (type_info*)0) { return 14; }

    return 0;
}
