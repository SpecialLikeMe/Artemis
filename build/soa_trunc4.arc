// std.soa — Structure-of-Arrays data structures and generic SoA helpers.
// Access as: std.soa.make_soa(...), std.soa.soa_layout, etc.

namespace std {
namespace soa {

// ---- Generic parallel-array wrapper ----
// soa.array<T> is simply a dynamic array of T where the user is expected to
// keep parallel arrays for each field they care about. This gives the same
// allocation pattern as a true SoA without requiring compiler reflection.

istruc array<T> {
    T*  data;
    i32 len;
    i32 cap;

    void __construct__(array* self) { self.data=(T*)0; self.len=0; self.cap=0; }

    void reserve(array* self, i32 n, &memstr a) {
        if (n <= self.cap) { return; }
        T* nd = (T*)a.mmap((u64)(sizeof(T) * n));
        for (i32 i = 0; i < self.len; i = i + 1) nd[i] = self.data[i];
        if (self.data != (T*)0) { a.deinit(self.data); }
        self.data = nd; self.cap = n;
    }

    void push(array* self, T val, &memstr a) {
        if (self.len >= self.cap) {
            i32 nc = self.cap == 0 ? 8 : self.cap * 2;
            self.reserve(nc, a);
        }
        self.data[self.len] = val;
        self.len = self.len + 1;
    }

    void remove_at(array* self, i32 i) {
        for (i32 j = i; j < self.len - 1; j = j + 1)
            self.data[j] = self.data[j + 1];
        self.len = self.len - 1;
    }

    T   at(array* self, i32 i)    { return self.data[i]; }
    T*  ptr_at(array* self, i32 i)      { return self.data + i; }
    i32 length(array* self)       { return self.len; }
    bool is_empty(array* self)    { return self.len == 0; }

    void swap(array* self, i32 i, i32 j) {
        T tmp = self.data[i]; self.data[i] = self.data[j]; self.data[j] = tmp;
    }

    void deinit(array* self, &memstr a) {
        if (self.data != (T*)0) { a.deinit(self.data); }
        self.data = (T*)0; self.len = 0; self.cap = 0;
    }
}

// ---- soa.vec2f — SoA of f32 x/y pairs (e.g. 2D positions) ----

istruc vec2f {
    array<f32> x;
    array<f32> y;
    i32        len;

    void __construct__(vec2f* self) { self.len = 0; }

    void push(vec2f* self, f32 xv, f32 yv, &memstr a) {
        self.x.push(xv, a);
        self.y.push(yv, a);
        self.len = self.len + 1;
    }

    void remove_at(vec2f* self, i32 i) {
        self.x.remove_at(i); self.y.remove_at(i); self.len = self.len - 1;
    }

    // Swap-erase (O(1) removal preserving density, does not preserve order)
    void swap_erase(vec2f* self, i32 i) {
        i32 last = self.len - 1;
        self.x.swap(i, last); self.y.swap(i, last);
        self.x.len = self.x.len - 1;
        self.y.len = self.y.len - 1;
        self.len = self.len - 1;
    }

    void deinit(vec2f* self, &memstr a) { self.x.deinit(a); self.y.deinit(a); self.len = 0; }
}

// ---- soa.vec3f — SoA of f32 x/y/z triples (e.g. 3D positions) ----

istruc vec3f {
    array<f32> x;
    array<f32> y;
    array<f32> z;
    i32        len;

    void __construct__(vec3f* self) { self.len = 0; }

    void push(vec3f* self, f32 xv, f32 yv, f32 zv, &memstr a) {
        self.x.push(xv, a); self.y.push(yv, a); self.z.push(zv, a);
        self.len = self.len + 1;
    }

    void remove_at(vec3f* self, i32 i) {
        self.x.remove_at(i); self.y.remove_at(i); self.z.remove_at(i);
        self.len = self.len - 1;
    }

    void swap_erase(vec3f* self, i32 i) {
        i32 last = self.len - 1;
        self.x.swap(i,last); self.y.swap(i,last); self.z.swap(i,last);
        self.x.len=self.x.len-1; self.y.len=self.y.len-1; self.z.len=self.z.len-1;
        self.len = self.len - 1;
    }

    void deinit(vec3f* self, &memstr a) { self.x.deinit(a); self.y.deinit(a); self.z.deinit(a); self.len=0; }
}
} // soa
} // std
i32 main() { return 0; }
