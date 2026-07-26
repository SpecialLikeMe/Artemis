// PASS: make_soa() transposes an AoS struct array into SoA layout.
extern  std.soa;
extern  std.alloc.bump;

struct Vec2 { let x: i32; let y: i32; }

pub fn main() i32 {
    // Set up a bump allocator for scratch space
    let mut scratch: std.alloc.bump((u64)65536);

    // Build a small AoS array of Vec2
    let mut aos: [4]Vec2;
    aos[0].x = 1; aos[0].y = 10;
    aos[1].x = 2; aos[1].y = 20;
    aos[2].x = 3; aos[2].y = 30;
    aos[3].x = 4; aos[3].y = 40;

    // Get type info and transpose
    let mut layout: std.soa.soa_layout= std.soa.make_soa((void*)aos, @typeinfo(Vec2), 4, scratch);

    // The layout should report 2 fields and 4 elements
    if (layout.field_count != 2)    { scratch.deinit(); return 1; }
    if (layout.element_count != 4)  { scratch.deinit(); return 2; }

    // Each field pointer should be non-null
    if (layout.field_ptrs[0] == (void*)0) { scratch.deinit(); return 3; }
    if (layout.field_ptrs[1] == (void*)0) { scratch.deinit(); return 4; }

    scratch.deinit();
    return 0;
}
