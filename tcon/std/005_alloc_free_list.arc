// std.alloc.free_list — general free-list allocator
extern  std.alloc.free_list;

pub fn main() i32 {
    let mut fl: std.alloc.free_list((u64)4096);
    if (fl.base == (void*)0) { return 1; }

    // Alloc a few blocks
    let mut a: *void= fl.alloc_bytes((u64)64);
    if (a == (void*)0) { return 2; }
    let mut b: *void= fl.alloc_bytes((u64)128);
    if (b == (void*)0) { return 3; }
    let mut c: *void= fl.alloc_bytes((u64)32);
    if (c == (void*)0) { return 4; }

    // Write to blocks
    ((i32*)a)[0] = 111;
    ((i32*)b)[0] = 222;
    ((i32*)c)[0] = 333;
    if (((i32*)a)[0] != 111) { return 5; }
    if (((i32*)b)[0] != 222) { return 6; }
    if (((i32*)c)[0] != 333) { return 7; }

    // Free middle block, then alloc again
    fl.free_ptr(b);
    let mut d: *void= fl.alloc_bytes((u64)64);
    if (d == (void*)0) { return 8; }
    ((i32*)d)[0] = 444;

    // Free remaining
    fl.free_ptr(a);
    fl.free_ptr(c);
    fl.free_ptr(d);

    // Can still alloc after all frees
    let mut e: *void= fl.alloc_bytes((u64)512);
    if (e == (void*)0) { return 9; }

    fl.deinit();
    return 0;
}
