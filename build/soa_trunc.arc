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
} }
i32 main() { return 0; }
