// std.alloc.free_list — General free-list allocator (first-fit).
// Block layout: [u64 size | u64 next_addr | ...data...]
// Header size = 16 bytes. next_addr = 0 means end of list.
extern void* malloc(u64 n);
extern void  free(void* p);

namespace std {
namespace alloc {

memstr free_list {
    void* base;
    u64   cap;
    void* free_head;  // pointer to first free block (null = no free blocks)

    void __construct__(free_list* self, u64 capacity) {
        self.cap  = capacity;
        self.base = malloc(capacity);
        // Initialise the single free block covering the whole region.
        *((u64*)self.base) = capacity;                              // size
        *((u64*)((u8*)self.base + 8)) = (u64)0;                    // next = null
        self.free_head = self.base;
    }

    void* alloc_bytes(free_list* self, u64 n) {
        u64 header = (u64)16;
        u64 total  = n + header;
        // Align total up to 8
        u64 rem = total % (u64)8;
        if (rem != 0) { total = total + ((u64)8 - rem); }

        void* prev = (void*)0;
        void* curr = self.free_head;
        while (curr != (void*)0) {
            u64 curr_size = *((u64*)curr);
            u64 curr_next = *((u64*)((u8*)curr + 8));
            if (curr_size >= total) {
                if (curr_size >= total + (u64)24) {
                    // Split: leave a smaller free block after our allocation.
                    void* rest = (void*)((u8*)curr + total);
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

    void free_ptr(free_list* self, void* p) {
        if (p == (void*)0) { return; }
        void* h = (void*)((u8*)p - (u64)16);
        // Prepend to free list.
        *((u64*)((u8*)h + 8)) = (u64)self.free_head;
        self.free_head = h;
        // Coalesce adjacent free blocks.
        void* curr = self.free_head;
        while (curr != (void*)0) {
            u64 curr_size = *((u64*)curr);
            u64 curr_next = *((u64*)((u8*)curr + 8));
            if (curr_next == (u64)0) { break; }
            void* next = (void*)curr_next;
            void* expected = (void*)((u8*)curr + curr_size);
            if (expected == next) {
                u64 next_size = *((u64*)next);
                u64 next_next = *((u64*)((u8*)next + 8));
                *((u64*)curr) = curr_size + next_size;
                *((u64*)((u8*)curr + 8)) = next_next;
            } else {
                curr = next;
            }
        }
    }

    void deinit(free_list* self) { free(self.base); }
}

} // alloc
} // std
