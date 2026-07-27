// std.vector — Dynamic resizable array (equivalent to C++ std.vector).

namespace std {

istruc vector<T> {
    let mut data: *T;
    let mut length: i32;
    let mut cap: i32;

    fn __construct__(vector* self, i32 initial_cap, &memstr a) void {
        self.cap    = initial_cap;
        self.length = 0;
        self.data   = (T*)a.mmap((u64)(sizeof(T) * initial_cap));
    }

    fn grow(vector* self, &memstr a) void {
        let mut new_cap: i32= self.cap == 0 ? 8 : self.cap * 2;
        let mut new_data: *T= (T*)a.mmap((u64)(sizeof(T) * new_cap));
        for (let mut i: i32 = 0; i < self.length; i = i + 1) new_data[i] = self.data[i];
        if (self.data != (T*)0) { a.free(self.data); }
        self.data = new_data;
        self.cap  = new_cap;
    }

    fn push(vector* self, T val, &memstr a) void {
        if (self.length >= self.cap) { self.grow(a); }
        self.data[self.length] = val;
        self.length = self.length + 1;
    }

    fn pop(self: *vector) T {
        let mut val: T;
        if (self.length == 0) { return val; }
        self.length = self.length - 1;
        return self.data[self.length];
    }

    fn get(self: *vector, i: i32) *T          { return (T*)(self.data + i); }
    fn at(self: *vector, i: i32) T     { return self.data[i]; }
    T  operator[](vector* self, i32 i) { return self.data[i]; }

    fn set(self: *vector, i: i32, val: T) void { self.data[i] = val; }

    fn insert(vector* self, i32 idx, T val, &memstr a) void {
        if (self.length >= self.cap) { self.grow(a); }
        for (let mut i: i32 = self.length; i > idx; i = i - 1) self.data[i] = self.data[i-1];
        self.data[idx] = val;
        self.length = self.length + 1;
    }

    fn remove_at(self: *vector, idx: i32) void {
        for (let mut i: i32 = idx; i < self.length - 1; i = i + 1) self.data[i] = self.data[i+1];
        self.length = self.length - 1;
    }

    fn clear(self: *vector) void              { self.length = 0; }
    fn is_empty(self: *vector) bool     { return self.length == 0; }
    fn size(self: *vector) i32         { return self.length; }
    fn capacity(self: *vector) i32     { return self.cap; }
    fn raw(self: *vector) *T          { return self.data; }

    fn contains(self: *vector, val: T) bool {
        for (let mut i: i32 = 0; i < self.length; i = i + 1)
            if (self.data[i] == val) { return true; }
        return false;
    }

    fn index_of(self: *vector, val: T) i32 {
        for (let mut i: i32 = 0; i < self.length; i = i + 1)
            if (self.data[i] == val) { return i; }
        return -1;
    }

    fn reserve(vector* self, i32 new_cap, &memstr a) void {
        if (new_cap <= self.cap) { return; }
        let mut nd: *T= (T*)a.mmap((u64)(sizeof(T) * new_cap));
        for (let mut i: i32 = 0; i < self.length; i = i + 1) nd[i] = self.data[i];
        if (self.data != (T*)0) a.free(self.data);
        self.data = nd;
        self.cap  = new_cap;
    }

    fn resize(vector* self, i32 new_len, T fill, &memstr a) void {
        if (new_len > self.cap) { self.reserve(new_len, a); }
        for (let mut i: i32 = self.length; i < new_len; i = i + 1) self.data[i] = fill;
        self.length = new_len;
    }

    fn reverse(self: *vector) void {
        let mut lo: i32= 0; let mut hi: i32= self.length - 1;
        while (lo < hi) {
            let mut tmp: T= self.data[lo];
            self.data[lo] = self.data[hi];
            self.data[hi] = tmp;
            lo = lo + 1; hi = hi - 1;
        }
    }

    fn deinit(vector* self, &memstr a) void {
        if (self.data != (T*)0) { a.free(self.data); }
        self.data   = (T*)0;
        self.length = 0;
        self.cap    = 0;
    }
}

// Wrap an existing raw array pointer as a vector (non-owning view).
// The resulting vector's data, length, and cap are all set from the given pointer and length.
fn make_vector<T>(ptr: *T, len: i32) vector<T> {
    let mut v: vector<T>;
    v.data   = ptr;
    v.length = len;
    v.cap    = len;
    return v;
}

// Extract the underlying raw array pointer from a vector.
fn make_ptr<T>(v: *vector<T>) *T {
    return (*v).data;
}

} // std
