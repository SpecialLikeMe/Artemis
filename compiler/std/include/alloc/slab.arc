// std.alloc.slab — Slab allocator.
// Groups objects of the same size into slabs; each slab is a pool-backed page.
// Suitable for high-frequency allocation of fixed-size objects.
extern void* malloc(u64 n);
extern void  free(void* p);

namespace std {
namespace alloc {

constexpr i32 SLAB_OBJECTS_PER_SLAB = 64;

istruc slab_page {
    void*     base;
    u64       slot_size;
    i32       free_count;
    i32       capacity;
    void*     free_slots[64];
    slab_page* next;

    void __construct__(slab_page* self, u64 sz) {
        self.slot_size  = sz;
        self.capacity   = SLAB_OBJECTS_PER_SLAB;
        self.free_count = SLAB_OBJECTS_PER_SLAB;
        self.next       = (void*)0;
        self.base       = malloc(sz * (u64)SLAB_OBJECTS_PER_SLAB);
        for (i32 i = 0; i < SLAB_OBJECTS_PER_SLAB; i = i + 1)
            self.free_slots[i] = (void*)((u8*)self.base + (u64)i * sz);
    }

    void* alloc_slot(slab_page* self) {
        if (self.free_count == 0) { return (void*)0; }
        self.free_count = self.free_count - 1;
        return self.free_slots[self.free_count];
    }

    void return_slot(slab_page* self, void* p) {
        if (self.free_count < self.capacity) {
            self.free_slots[self.free_count] = p;
            self.free_count = self.free_count + 1;
        }
    }

    bool has_room(slab_page* self) { return self.free_count > 0; }
}

// slab_page struct layout (for sizeof):
//   void* base      (8)
//   u64 slot_size   (8)
//   i32 free_count  (4)
//   i32 capacity    (4)
//   void* slots[64] (512)
//   slab_page* next (8)
// Total: 544 bytes
constexpr u64 SLAB_PAGE_SIZE = (u64)544;

memstr slab {
    slab_page* head;
    u64        slot_size;

    void __construct__(slab* self, u64 object_size) {
        // Round up to 8-byte alignment
        u64 rem = object_size % (u64)8;
        if (rem != (u64)0) { self.slot_size = object_size + ((u64)8 - rem); }
        else { self.slot_size = object_size; }
        self.head = (void*)0;
    }

    void* alloc_obj(slab* self) {
        slab_page* pg = self.head;
        while (pg != (void*)0) {
            if ((*pg).has_room()) { return (*pg).alloc_slot(); }
            pg = (*pg).next;
        }
        // All pages full — allocate a new slab_page
        slab_page* new_pg = malloc(SLAB_PAGE_SIZE);
        (*new_pg).__construct__(self.slot_size);
        (*new_pg).next = self.head;
        self.head = new_pg;
        return (*new_pg).alloc_slot();
    }

    void free_obj(slab* self, void* p) {
        slab_page* pg = self.head;
        while (pg != (void*)0) {
            u64 base_v = (u64)((*pg).base);
            u64 ptr_v  = (u64)p;
            u64 cap    = (u64)((*pg).capacity);
            u64 end_v  = base_v + cap * (*pg).slot_size;
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
