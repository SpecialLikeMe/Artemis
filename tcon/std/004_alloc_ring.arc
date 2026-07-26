// std.alloc.ring — circular buffer allocator
extern  std.alloc.ring;

pub fn main() i32 {
    let mut r: std.alloc.ring((u64)256);
    if (r.base == (void*)0) { return 1; }

    // Alloc a chunk
    let mut p1: *i32= (i32*)r.alloc_bytes((u64)4);
    if (p1 == (i32*)0) { return 2; }
    (*p1) = 100;

    // Alloc another chunk
    let mut p2: *i32= (i32*)r.alloc_bytes((u64)4);
    if (p2 == (i32*)0) { return 3; }
    (*p2) = 200;
    if ((*p1) != 100) { return 4; }

    // Reset wraps head back to 0
    r.reset();
    if (r.head != 0) { return 5; }

    // Can alloc from the beginning again
    let mut p3: *i32= (i32*)r.alloc_bytes((u64)16);
    if (p3 == (i32*)0) { return 6; }
    p3[0] = 1; p3[1] = 2; p3[2] = 3; p3[3] = 4;
    let mut sum: i32= p3[0] + p3[1] + p3[2] + p3[3];
    if (sum != 10) { return 7; }

    // Request larger than capacity returns null
    let mut big: *void= r.alloc_bytes((u64)1024);
    if (big != (void*)0) { return 8; }

    r.deinit();
    return 0;
}
