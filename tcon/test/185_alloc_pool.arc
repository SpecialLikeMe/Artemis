// Fixed-size pool allocator: pre-allocates N slots, O(1) alloc/free
// Free-slot stack stores void* pointers directly (no pointer arithmetic needed).
@unsafe extern fn malloc(size: u64) *void;
@unsafe extern fn free(ptr: *void) void;

memstr Pool {
    let mut free_slots: [16]*void;   // stack of available slot pointers
    let mut top: i32;              // number of free slots remaining
    let mut block: *void;            // backing allocation

    fn __construct__(self: *Pool, elem_size: u64, n: i32) void {
        self.block = malloc(elem_size * (u64)n);
        self.top   = 0;
        let mut p: *u8= (u8*)self.block;
        for (let mut i: i32 = 0; i < n; i = i + 1) {
            self.free_slots[self.top] = (void*)(p + elem_size * (u64)i);
            self.top = self.top + 1;
        }
    }

    fn acquire(self: *Pool) *void {
        if (self.top == 0) { return (void*)0; }
        self.top = self.top - 1;
        return self.free_slots[self.top];
    }

    fn release(self: *Pool, p: *void) void {
        if (self.top < 16) {
            self.free_slots[self.top] = p;
            self.top = self.top + 1;
        }
    }

    fn deinit(self: *Pool) void { free(self.block); }
}

pub fn main() i32 {
    let mut pool: Pool(sizeof(i32), 8);
    if (pool.block == 0) { return 1; }
    if (pool.top != 8)   { return 2; }

    let mut a: *i32= (i32*)pool.acquire();
    let mut b: *i32= (i32*)pool.acquire();
    let mut c: *i32= (i32*)pool.acquire();
    if (a == 0 || b == 0 || c == 0) { return 3; }
    if (pool.top != 5) { return 4; }

    (*a) = 10; (*b) = 20; (*c) = 30;
    if ((*a) + (*b) + (*c) != 60) { return 5; }

    pool.release(b);
    if (pool.top != 6) { return 6; }

    // Reacquire from pool — gets the slot we just released
    let mut d: *i32= (i32*)pool.acquire();
    if (d == 0)        { return 7; }
    if (pool.top != 5) { return 8; }

    pool.release(a);
    pool.release(c);
    pool.release(d);
    if (pool.top != 8) { return 9; }

    pool.deinit();
    return 0;
}
