// std.alloc.bump — basic bump allocator test
extern  std.alloc.bump;

pub fn main() i32 {
    let mut a: std.alloc.bump((u64)4096);
    if (a.base == (void*)0) { return 1; }

    // Allocate some bytes
    let mut p1: *i32= (i32*)a.alloc_bytes(sizeof(i32));
    if (p1 == (i32*)0) { return 2; }
    (*p1) = 42;
    if ((*p1) != 42) { return 3; }

    // Allocate more
    let mut p2: *i32= (i32*)a.alloc_bytes(sizeof(i32) * 4);
    if (p2 == (i32*)0) { return 4; }
    p2[0] = 10; p2[1] = 20; p2[2] = 30; p2[3] = 40;
    let mut sum: i32= p2[0] + p2[1] + p2[2] + p2[3];
    if (sum != 100) { return 5; }

    // Reset reclaims memory
    a.reset();
    if (a.used != 0) { return 6; }

    // After reset, can allocate the same region again
    let mut p3: *i32= (i32*)a.alloc_bytes(sizeof(i32));
    if (p3 == (i32*)0) { return 7; }

    a.deinit();
    return 0;
}
