// std.alloc.slab — Slab allocator.
// Groups objects of the same size into slabs; each slab is a pool-backed page.
// Suitable for high-frequency allocation of fixed-size objects.
@unsafe extern fn printf(fmt: *const i8, ...) i32;
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

namespace std {
namespace alloc {

comptime i32 SLAB_OBJECTS_PER_SLAB = 64;

istruc slab_page {
    let mut base: *void;
    let mut slot_size: u64;
    let mut free_count: i32;
    let mut capacity: i32;
    let mut free_slots: [64]*void;
    let mut next: *slab_page;

    fn __construct__(self: *slab_page, sz: u64, buf: *void) void {
        self.slot_size  = sz;
        self.capacity   = SLAB_OBJECTS_PER_SLAB;
        self.free_count = SLAB_OBJECTS_PER_SLAB;
        self.next       = (void*)0;
        self.base       = buf;
        for (let mut i: i32 = 0; i < SLAB_OBJECTS_PER_SLAB; i = i + 1)
            self.free_slots[i] = (void*)((u8*)self.base + (u64)i * sz);
    }

    fn alloc_slot(self: *slab_page) *void {
        if (self.free_count == 0) { return (void*)0; }
        self.free_count = self.free_count - 1;
        return self.free_slots[self.free_count];
    }

    fn return_slot(self: *slab_page, p: *void) void {
        if (self.free_count < self.capacity) {
            self.free_slots[self.free_count] = p;
            self.free_count = self.free_count + 1;
        }
    }

    fn has_room(self: *slab_page) bool { return self.free_count > 0; }
}

// slab_page struct layout (for sizeof):
//   void* base      (8)
//   u64 slot_size   (8)
//   i32 free_count  (4)
//   i32 capacity    (4)
//   void* slots[64] (512)
//   slab_page* next (8)
// Total: 544 bytes
comptime u64 SLAB_PAGE_SIZE = (u64)544;

memstr slab {
    let mut head: *slab_page;
    let mut slot_size: u64;

    fn __construct__(self: *slab, object_size: u64) void {
        // Round up to 8-byte alignment
        let mut rem: u64= object_size % (u64)8;
        if (rem != (u64)0) { self.slot_size = object_size + ((u64)8 - rem); }
        else { self.slot_size = object_size; }
        self.head = (void*)0;
    }

    fn alloc_obj(self: *slab) *void {
        @unsafe {
            @unsafe {
                let mut pg: *slab_page= self.head;
                while (pg != (void*)0) {
                    if ((*pg).has_room()) { return (*pg).alloc_slot(); }
                    pg = (*pg).next;
                }
                // All pages full — allocate a new slab_page. Both allocations must be
                // checked: constructing a page over a null buffer hands out pointers
                // computed from null, which fail far from the actual OOM.
                let mut new_pg: *slab_page= (slab_page*)malloc(SLAB_PAGE_SIZE);
                if (new_pg == (slab_page*)0) {
                    printf("fatal: slab allocator out of memory (page header)\n");
                    return (void*)0;
                }
                let mut new_buf: *void= malloc(self.slot_size * (u64)SLAB_OBJECTS_PER_SLAB);
                if (new_buf == (void*)0) {
                    printf("fatal: slab allocator out of memory (page buffer)\n");
                    free((void*)new_pg);
                    return (void*)0;
                }
                (*new_pg).__construct__(self.slot_size, new_buf);
                (*new_pg).next = self.head;
                self.head = new_pg;
                return (*new_pg).alloc_slot();
            }
        }
    }

    fn free_obj(self: *slab, p: *void) void {
        let mut pg: *slab_page= self.head;
        while (pg != (void*)0) {
            let mut base_v: u64= (u64)((*pg).base);
            let mut ptr_v: u64= (u64)p;
            let mut cap: u64= (u64)((*pg).capacity);
            let mut end_v: u64= base_v + cap * (*pg).slot_size;
            if (ptr_v >= base_v && ptr_v < end_v) {
                (*pg).return_slot(p);
                return;
            }
            pg = (*pg).next;
        }
    }
}

} // alloc
} // std
