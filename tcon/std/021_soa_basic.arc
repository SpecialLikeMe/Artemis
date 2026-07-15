// PASS: make_soa() transposes an AoS struct array into SoA layout.
extern std.soa;
extern std.alloc.bump;

struct Vec2 { i32 x; i32 y; }

i32 main() {
    // Set up a bump allocator for scratch space
    std.alloc.bump scratch(65536);

    // Build a small AoS array of Vec2
    Vec2 aos[4];
    aos[0].x = 1; aos[0].y = 10;
    aos[1].x = 2; aos[1].y = 20;
    aos[2].x = 3; aos[2].y = 30;
    aos[3].x = 4; aos[3].y = 40;

    // Get type info and transpose
    type_info* ti = @typeinfo(Vec2);
    std.soa.soa_layout layout = std.soa.make_soa((void*)aos, ti, 4, scratch);

    // The layout should report 2 fields and 4 elements
    if (layout.field_count != 2)    { scratch.deinit(); return 1; }
    if (layout.element_count != 4)  { scratch.deinit(); return 2; }

    // Each field pointer should be non-null
    if (layout.field_ptrs[0] == (void*)0) { scratch.deinit(); return 3; }
    if (layout.field_ptrs[1] == (void*)0) { scratch.deinit(); return 4; }

    scratch.deinit();
    return 0;
}
