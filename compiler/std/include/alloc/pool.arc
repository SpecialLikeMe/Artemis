// std.alloc.pool — Fixed-size object pool.
// Allocates a block of N objects of a fixed stride; O(1) alloc/free via free-list.
@unsafe extern fn printf(fmt: *const i8, ...) i32;
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

namespace std {
namespace alloc {

memstr pool {
    let mut base: *void;
    let mut free_list: **void;  // stack of free slot pointers
    let mut capacity: i32;
    let mut free_count: i32;
    let mut slot_size: u64;

    fn __construct__(self: *pool, n: i32, object_size: u64) void {
        @unsafe {
            @unsafe {
                // Round up to 8-byte alignment
                let mut rem: u64= object_size % (u64)8;
                if (rem != 0) { self.slot_size = object_size + ((u64)8 - rem); }
                else { self.slot_size = object_size; }
                self.capacity  = n;
                self.base      = malloc(self.slot_size * (u64)n);
                self.free_list = (void**)malloc((u64)8 * (u64)n);
                if (self.base == (void*)0 || self.free_list == (void**)0) {
                    printf("fatal: pool allocator out of memory\n");
                    self.capacity   = 0;
                    self.free_count = 0;
                    return;
                }
                self.free_count = n;
                for (let mut i: i32 = 0; i < n; i = i + 1) {
                    self.free_list[i] = (void*)((u8*)self.base + (u64)i * self.slot_size);
                }
            }
        }
    }

    fn alloc_slot(self: *pool) *void {
        if (self.free_count == 0) { return (void*)0; }
        self.free_count = self.free_count - 1;
        return self.free_list[self.free_count];
    }

    fn free_slot(self: *pool, p: *void) void {
        if (self.free_count >= self.capacity) { return; }
        self.free_list[self.free_count] = p;
        self.free_count = self.free_count + 1;
    }

    fn full(self: *pool) bool  { return self.free_count == 0; }
    fn empty(self: *pool) bool { return self.free_count == self.capacity; }
    fn used_count(self: *pool) i32 { return self.capacity - self.free_count; }

    fn deinit(self: *pool) !void {
        free(self.base);
        free(self.free_list);
    }
}

} // alloc
} // std
