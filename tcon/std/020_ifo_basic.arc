// PASS: @typeinfo() returns correct metadata for primitive and struct types.
// Uses compiler-builtin type_info; no stdlib import needed.

struct Point { i32 x; i32 y; }

i32 main() {
    // Primitive: i32
    type_info* ti = @typeinfo(i32);
    if (ti.kind != 0)       { return 1; }   // 0 = IFO_KIND_PRIM
    if (ti.bits != 32)      { return 2; }
    if (ti.size != 4)       { return 3; }
    if (ti.is_signed != 1)  { return 4; }
    if (ti.field_count != 0){ return 5; }

    // Unsigned: u64
    type_info* tu = @typeinfo(u64);
    if (tu.kind != 0)       { return 6; }   // IFO_KIND_PRIM
    if (tu.bits != 64)      { return 7; }
    if (tu.is_signed != 0)  { return 8; }

    // Struct: Point (two i32 fields)
    type_info* tp = @typeinfo(Point);
    if (tp.kind != 2)       { return 9; }   // 2 = IFO_KIND_STRUCT
    if (tp.field_count != 2){ return 10; }
    if (tp.fields == (type_info_field*)0) { return 11; }

    // Numeric check: i32 kind is PRIM and has nonzero bits
    if (ti.kind != 0 || ti.bits == 0) { return 12; }

    // Pointer kind
    type_info* tpi = @typeinfo(i32*);
    if (tpi.kind != 1)      { return 13; }  // 1 = IFO_KIND_PTR
    if (tpi.elem_type == (type_info*)0) { return 14; }

    return 0;
}
