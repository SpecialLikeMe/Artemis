// Arena (bump) allocator: carves out slices from a single malloc'd block
@unsafe extern fn malloc(size: u64) *void;
@unsafe extern fn free(ptr: *void) void;
@unsafe extern fn memset(ptr: *void, val: i32, n: u64) *void;

memstr Arena {
    let mut base: *void;
    let mut used: u64;
    let mut cap: u64;

    fn __construct__(self: *Arena, capacity: u64) void {
        self.base = malloc(capacity);
        self.used = 0;
        self.cap  = capacity;
    }

    fn alloc(self: *Arena, size: u64) *void {
        if (self.used + size > self.cap) { return 0; }
        // Manually compute the pointer offset: base + used
        let mut p: *u8= (u8*)self.base;
        let mut result: *void= (void*)(p + self.used);
        self.used = self.used + size;
        return result;
    }

    fn reset(self: *Arena) void { self.used = 0; }

    fn deinit(self: *Arena) void { free(self.base); }
}

pub fn main() i32 {
    let mut arena: Arena(1024);
    if (arena.base == 0) { return 1; }

    let mut a: *i32= (i32*)arena.alloc(sizeof(i32));
    let mut b: *i32= (i32*)arena.alloc(sizeof(i32));
    let mut c: *i32= (i32*)arena.alloc(sizeof(i32));
    if (a == 0 || b == 0 || c == 0) { return 2; }

    (*a) = 1; (*b) = 2; (*c) = 3;
    if ((*a) + (*b) + (*c) != 6) { return 3; }

    if (arena.used != (u64)(sizeof(i32) * 3)) { return 4; }

    arena.reset();
    if (arena.used != 0) { return 5; }

    // Allocate again after reset — should reuse same memory
    let mut x: *i32= (i32*)arena.alloc(sizeof(i32) * 4);
    if (x == 0) { return 6; }
    x[0] = 10; x[1] = 20; x[2] = 30; x[3] = 40;
    if (x[0] + x[1] + x[2] + x[3] != 100) { return 7; }

    arena.deinit();
    return 0;
}
