// std.alloc.free_list — General free-list allocator (first-fit).
// Block layout: [u64 size | u64 next_addr | ...data...]
// Header size = 16 bytes. next_addr = 0 means end of list.
@unsafe extern fn printf(fmt: *const i8, ...) i32;
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

namespace std {
namespace alloc {

memstr free_list {
    let mut base: *void;
    let mut cap: u64;
    let mut free_head: *void;  // pointer to first free block (null = no free blocks)

    fn __construct__(self: *free_list, capacity: u64) void {
        @unsafe {
            @unsafe {
                self.base = malloc(capacity);
                if (self.base == (void*)0) {
                    printf("fatal: free_list allocator out of memory (requested %llu bytes)\n", capacity);
                    self.cap = 0;
                    self.free_head = (void*)0;
                    return;
                }
                self.cap  = capacity;
                // Initialise the single free block covering the whole region.
                *((u64*)self.base) = capacity;                              // size
                *((u64*)((u8*)self.base + 8)) = (u64)0;                    // next = null
                self.free_head = self.base;
            }
        }
    }

    fn alloc_bytes(self: *free_list, n: u64) *void {
        let mut header: u64= (u64)16;
        let mut total: u64= n + header;
        // Align total up to 8
        let mut rem: u64= total % (u64)8;
        if (rem != 0) { total = total + ((u64)8 - rem); }

        let mut prev: *void= (void*)0;
        let mut curr: *void= self.free_head;
        while (curr != (void*)0) {
            let mut curr_size: u64= *((u64*)curr);
            let mut curr_next: u64= *((u64*)((u8*)curr + 8));
            if (curr_size >= total) {
                if (curr_size >= total + (u64)24) {
                    // Split: leave a smaller free block after our allocation.
                    let mut rest: *void= (void*)((u8*)curr + total);
                    *((u64*)rest) = curr_size - total;
                    *((u64*)((u8*)rest + 8)) = curr_next;
                    *((u64*)curr) = total;
                    if (prev == (void*)0) { self.free_head = rest; }
                    else { *((u64*)((u8*)prev + 8)) = (u64)rest; }
                } else {
                    // Use whole block.
                    if (prev == (void*)0) { self.free_head = (void*)curr_next; }
                    else { *((u64*)((u8*)prev + 8)) = curr_next; }
                }
                return (void*)((u8*)curr + header);
            }
            prev = curr;
            curr = (void*)curr_next;
        }
        return (void*)0;
    }

    fn free_ptr(self: *free_list, p: *void) void {
        if (p == (void*)0) { return; }
        let mut h: *void= (void*)((u8*)p - (u64)16);
        // Prepend to free list.
        *((u64*)((u8*)h + 8)) = (u64)self.free_head;
        self.free_head = h;
        // Coalesce adjacent free blocks.
        let mut curr: *void= self.free_head;
        while (curr != (void*)0) {
            let mut curr_size: u64= *((u64*)curr);
            let mut curr_next: u64= *((u64*)((u8*)curr + 8));
            if (curr_next == (u64)0) { break; }
            let mut next: *void= (void*)curr_next;
            let mut expected: *void= (void*)((u8*)curr + curr_size);
            if (expected == next) {
                let mut next_size: u64= *((u64*)next);
                let mut next_next: u64= *((u64*)((u8*)next + 8));
                *((u64*)curr) = curr_size + next_size;
                *((u64*)((u8*)curr + 8)) = next_next;
            } else {
                curr = next;
            }
        }
    }

    fn deinit(self: *free_list) void { free(self.base); }
}

} // alloc
} // std
