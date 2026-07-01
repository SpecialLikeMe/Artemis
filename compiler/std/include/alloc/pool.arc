// std.alloc.pool — Fixed-size object pool.
// Allocates a block of N objects of a fixed stride; O(1) alloc/free via free-list.
extern void* malloc(u64 n);
extern void  free(void* p);

namespace std {
namespace alloc {

memstr pool {
    void*  base;
    void** free_list;  // stack of free slot pointers
    i32    capacity;
    i32    free_count;
    u64    slot_size;

    void __construct__(pool* self, i32 n, u64 object_size) {
        // Round up to 8-byte alignment
        u64 rem = object_size % (u64)8;
        if (rem != 0) { self.slot_size = object_size + ((u64)8 - rem); }
        else { self.slot_size = object_size; }
        self.capacity   = n;
        self.base       = malloc(self.slot_size * (u64)n);
        self.free_list  = (void**)malloc((u64)8 * (u64)n);
        self.free_count = n;
        for (i32 i = 0; i < n; i = i + 1) {
            self.free_list[i] = (void*)((u8*)self.base + (u64)i * self.slot_size);
        }
    }

    void* alloc_slot(pool* self) {
        if (self.free_count == 0) { return (void*)0; }
        self.free_count = self.free_count - 1;
        return self.free_list[self.free_count];
    }

    void free_slot(pool* self, void* p) {
        if (self.free_count >= self.capacity) { return; }
        self.free_list[self.free_count] = p;
        self.free_count = self.free_count + 1;
    }

    bool full(pool* self)  { return self.free_count == 0; }
    bool empty(pool* self) { return self.free_count == self.capacity; }
    i32  used_count(pool* self) { return self.capacity - self.free_count; }

    void deinit(pool* self) {
        free(self.base);
        free(self.free_list);
    }
}

} // alloc
} // std
