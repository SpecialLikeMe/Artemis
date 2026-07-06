// PASS: get_ifo_t() returns correct metadata for primitive and struct types.
extern std.ifo;
extern i32 printf(i8* fmt, ...);

struct Point { i32 x; i32 y; }

i32 main() {
    // Primitive: i32
    std.ifo.ifo_t* ti = get_ifo_t(i32);
    if (ti.kind != std.ifo.IFO_KIND_PRIM)  { return 1; }
    if (ti.bits != 32)                         { return 2; }
    if (ti.size != 4)                          { return 3; }
    if (ti.is_signed != 1)                     { return 4; }
    if (ti.field_count != 0)                   { return 5; }

    // Unsigned: u64
    std.ifo.ifo_t* tu = get_ifo_t(u64);
    if (tu.kind != std.ifo.IFO_KIND_PRIM)  { return 6; }
    if (tu.bits != 64)                         { return 7; }
    if (tu.is_signed != 0)                     { return 8; }

    // Struct: Point (two i32 fields)
    std.ifo.ifo_t* tp = get_ifo_t(Point);
    if (tp.kind != std.ifo.IFO_KIND_STRUCT) { return 9; }
    if (tp.field_count != 2)                   { return 10; }
    if (tp.fields == (std.ifo.ifo_field_t*)0) { return 11; }

    // Check field names
    std.ifo.ifo_field_t* fx = std.ifo.ifo_find_field(tp, "x");
    if (fx == (std.ifo.ifo_field_t*)0) { return 12; }
    if (fx.size != 4) { return 13; }

    // Helper functions
    if (!std.ifo.ifo_is_numeric(ti))  { return 14; }
    if (!std.ifo.ifo_is_pointer(get_ifo_t(i32*))) { return 15; }

    // elem_type for pointer
    std.ifo.ifo_t* tpi = get_ifo_t(i32*);
    if (tpi.kind != std.ifo.IFO_KIND_PTR)  { return 16; }
    if (tpi.elem_type == (std.ifo.ifo_t*)0) { return 17; }

    return 0;
}
