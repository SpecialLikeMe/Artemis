// std.vector — Dynamic resizable array (equivalent to C++ std::vector).

namespace std {

istruc vector<T> {
    T*  data;
    i32 length;
    i32 cap;

    void __construct__(&self) {
        self.data   = (T*)0;
        self.length = 0;
        self.cap    = 0;
    }

    void __construct__(&self, i32 initial_cap, &memstr a) {
        self.cap    = initial_cap;
        self.length = 0;
        self.data   = (T*)a.mmap((u64)(sizeof(T) * initial_cap));
    }

    private void grow(&self, &memstr a) {
        i32 new_cap = self.cap == 0 ? 8 : self.cap * 2;
        T* new_data = (T*)a.mmap((u64)(sizeof(T) * new_cap));
        for (i32 i = 0; i < self.length; i = i + 1) new_data[i] = self.data[i];
        if (self.data != (T*)0) { a.deinit(self.data); }
        self.data = new_data;
        self.cap  = new_cap;
    }

    void push(&self, T val, &memstr a) {
        if (self.length >= self.cap) { self.grow(a); }
        self.data[self.length] = val;
        self.length = self.length + 1;
    }

    T pop(&self) {
        self.length = self.length - 1;
        return self.data[self.length];
    }

    T* get(&self, i32 i)          { return (T*)(self.data + i); }
    T  at(&self, i32 i)     { return self.data[i]; }
    T  operator[](&self, i32 i) { return self.data[i]; }

    void set(&self, i32 i, T val) { self.data[i] = val; }

    void insert(&self, i32 idx, T val, &memstr a) {
        if (self.length >= self.cap) { self.grow(a); }
        for (i32 i = self.length; i > idx; i = i - 1) self.data[i] = self.data[i-1];
        self.data[idx] = val;
        self.length = self.length + 1;
    }

    void remove_at(&self, i32 idx) {
        for (i32 i = idx; i < self.length - 1; i = i + 1) self.data[i] = self.data[i+1];
        self.length = self.length - 1;
    }

    void clear(&self)              { self.length = 0; }
    bool is_empty(&self)     { return self.length == 0; }
    i32  size(&self)         { return self.length; }
    i32  capacity(&self)     { return self.cap; }
    T*   raw(&self)          { return self.data; }

    bool contains(&self, T val) {
        for (i32 i = 0; i < self.length; i = i + 1)
            if (self.data[i] == val) { return true; }
        return false;
    }

    i32 index_of(&self, T val) {
        for (i32 i = 0; i < self.length; i = i + 1)
            if (self.data[i] == val) { return i; }
        return -1;
    }

    void reserve(&self, i32 new_cap, &memstr a) {
        if (new_cap <= self.cap) { return; }
        T* nd = (T*)a.mmap((u64)(sizeof(T) * new_cap));
        for (i32 i = 0; i < self.length; i = i + 1) nd[i] = self.data[i];
        if (self.data != (T*)0) a.deinit(self.data);
        self.data = nd;
        self.cap  = new_cap;
    }

    void resize(&self, i32 new_len, T fill, &memstr a) {
        if (new_len > self.cap) { self.reserve(new_len, a); }
        for (i32 i = self.length; i < new_len; i = i + 1) self.data[i] = fill;
        self.length = new_len;
    }

    void reverse(&self) {
        i32 lo = 0; i32 hi = self.length - 1;
        while (lo < hi) {
            T tmp = self.data[lo];
            self.data[lo] = self.data[hi];
            self.data[hi] = tmp;
            lo = lo + 1; hi = hi - 1;
        }
    }

    void deinit(&self, &memstr a) {
        if (self.data != (T*)0) { a.deinit(self.data); }
        self.data   = (T*)0;
        self.length = 0;
        self.cap    = 0;
    }
}

} // std
