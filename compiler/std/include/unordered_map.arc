// std.unordered_map — Hash map (open addressing, robin-hood probing).

namespace std {

comptime u64 UMAP_EMPTY   = 0xFFFFFFFFFFFFFFFFu;
comptime u64 UMAP_DELETED = 0xFFFFFFFFFFFFFFFEu;
comptime f64 UMAP_MAX_LOAD = 0.75;

istruc umap_slot<K, V> {
    let mut hash: u64;
    let mut key: K;
    let mut val: V;
}

istruc unordered_map<K, V> {
    let mut slots: *umap_slot<K,V>;
    let mut count: i32;
    let mut cap: i32;

    static fn hash_key(k: i64) u64 {
        let mut h: u64= (u64)k;
        h = h ^ (h >> 30);
        h = h * 0xbf58476d1ce4e5b9u;
        h = h ^ (h >> 27);
        h = h * 0x94d049bb133111ebu;
        h = h ^ (h >> 31);
        return h;
    }

    fn __construct__(self: *unordered_map, initial_cap: i32, a: &memstr) void {
        self.cap   = initial_cap;
        self.count = 0;
        self.slots = (umap_slot<K,V>*)a.mmap((u64)(sizeof(umap_slot<K,V>) * (u64)initial_cap));
        for (let mut i: i32 = 0; i < initial_cap; i = i + 1)
            self.slots[i].hash = UMAP_EMPTY;
    }

    fn rehash(self: *unordered_map, a: &memstr) void {
        let mut old_cap: i32= self.cap;
        let mut old_slots: *umap_slot<K,V>= self.slots;
        let mut new_cap: i32= old_cap == 0 ? 16 : old_cap * 2;
        self.slots = (umap_slot<K,V>*)a.mmap((u64)(sizeof(umap_slot<K,V>) * (u64)new_cap));
        for (let mut i: i32 = 0; i < new_cap; i = i + 1) self.slots[i].hash = UMAP_EMPTY;
        self.cap   = new_cap;
        self.count = 0;
        for (let mut i: i32 = 0; i < old_cap; i = i + 1) {
            if (old_slots[i].hash != UMAP_EMPTY && old_slots[i].hash != UMAP_DELETED)
                self.insert(old_slots[i].key, old_slots[i].val, a);
        }
        if (old_slots != (umap_slot<K,V>*)0) a.free((void*)old_slots);
    }

    fn insert(self: *unordered_map, key: K, val: V, a: &memstr) void {
        if (self.count * 100 >= (i32)((f64)self.cap * 75.0)) { self.rehash(a); }
        let mut h: u64= hash_key((i64)key);
        if (h == UMAP_EMPTY || h == UMAP_DELETED) { h = h ^ 1u; }
        let mut idx: i32= (i32)(h % (u64)self.cap);
        while (true) {
            let mut sh: u64= self.slots[idx].hash;
            if (sh == UMAP_EMPTY || sh == UMAP_DELETED) {
                self.slots[idx].hash = h;
                self.slots[idx].key  = key;
                self.slots[idx].val  = val;
                self.count = self.count + 1;
                return;
            }
            if (self.slots[idx].hash == h && self.slots[idx].key == key) {
                self.slots[idx].val = val;
                return;
            }
            idx = (idx + 1) % self.cap;
        }
    }

    fn get(self: *unordered_map, key: K) *V {
        if (self.cap == 0) { return (V*)0; }
        let mut h: u64= hash_key((i64)key);
        if (h == UMAP_EMPTY || h == UMAP_DELETED) { h = h ^ 1u; }
        let mut idx: i32= (i32)(h % (u64)self.cap);
        while (true) {
            let mut sh: u64= self.slots[idx].hash;
            if (sh == UMAP_EMPTY) { return (V*)0; }
            if (sh == h && self.slots[idx].key == key) { return &self.slots[idx].val; }
            idx = (idx + 1) % self.cap;
        }
        return (V*)0;
    }

    fn contains(self: *unordered_map, key: K) bool { return self.get(key) != (V*)0; }

    fn remove(self: *unordered_map, key: K) void {
        if (self.cap == 0) { return; }
        let mut h: u64= hash_key((i64)key);
        if (h == UMAP_EMPTY || h == UMAP_DELETED) { h = h ^ 1u; }
        let mut idx: i32= (i32)(h % (u64)self.cap);
        while (true) {
            let mut sh: u64= self.slots[idx].hash;
            if (sh == UMAP_EMPTY) { return; }
            if (sh == h && self.slots[idx].key == key) {
                self.slots[idx].hash = UMAP_DELETED;
                self.count = self.count - 1;
                return;
            }
            idx = (idx + 1) % self.cap;
        }
    }

    fn size(self: *unordered_map) i32     { return self.count; }
    fn is_empty(self: *unordered_map) bool { return self.count == 0; }

    fn each(self: *unordered_map, cb: void(K, V)*) void {
        for (let mut i: i32 = 0; i < self.cap; i = i + 1) {
            let mut h: u64= self.slots[i].hash;
            if (h != UMAP_EMPTY && h != UMAP_DELETED)
                cb(self.slots[i].key, self.slots[i].val);
        }
    }

    fn deinit(self: *unordered_map, a: &memstr) void {
        if (self.slots != (umap_slot<K,V>*)0) a.free((void*)self.slots);
        self.slots = (umap_slot<K,V>*)0;
        self.count = 0; self.cap = 0;
    }
}

// Specialization for *i8 (C-string) keys: content-based hash and strcmp equality.
// Use this instead of unordered_map<*i8, V> to avoid pointer-address hashing.

istruc str_umap_slot<V> {
    let mut hash: u64;
    let mut key: *i8;
    let mut val: V;
}

istruc str_unordered_map<V> {
    let mut slots: *str_umap_slot<V>;
    let mut count: i32;
    let mut cap: i32;

    @unsafe extern fn strlen(s: *i8) u64;
    @unsafe extern fn strcmp(a: *i8, b: *i8) i32;

    static fn hash_str(s: *i8) u64 {
        if (s == (i8*)0) { return 0u; }
        let mut h: u64= 14695981039346656037u; // FNV-1a offset basis
        let mut i: i32= 0;
        while (s[i] != '\0') {
            h = h ^ (u64)(u8)s[i];
            h = h * 1099511628211u; // FNV prime
            i = i + 1;
        }
        return h;
    }

    fn __construct__(self: *str_unordered_map, initial_cap: i32, a: &memstr) void {
        self.cap   = initial_cap;
        self.count = 0;
        self.slots = (str_umap_slot<V>*)a.mmap((u64)(sizeof(str_umap_slot<V>) * (u64)initial_cap));
        for (let mut i: i32 = 0; i < initial_cap; i = i + 1)
            self.slots[i].hash = UMAP_EMPTY;
    }

    fn rehash(self: *str_unordered_map, a: &memstr) void {
        let mut old_cap: i32= self.cap;
        let mut old_slots: *str_umap_slot<V>= self.slots;
        let mut new_cap: i32= old_cap == 0 ? 16 : old_cap * 2;
        self.slots = (str_umap_slot<V>*)a.mmap((u64)(sizeof(str_umap_slot<V>) * (u64)new_cap));
        for (let mut i: i32 = 0; i < new_cap; i = i + 1) self.slots[i].hash = UMAP_EMPTY;
        self.cap   = new_cap;
        self.count = 0;
        for (let mut i: i32 = 0; i < old_cap; i = i + 1) {
            if (old_slots[i].hash != UMAP_EMPTY && old_slots[i].hash != UMAP_DELETED)
                self.insert(old_slots[i].key, old_slots[i].val, a);
        }
        if (old_slots != (str_umap_slot<V>*)0)
            a.free((void*)old_slots);
    }

    fn insert(self: *str_unordered_map, key: *i8, val: V, a: &memstr) void {
        if (self.count * 100 >= (i32)((f64)self.cap * 75.0)) { self.rehash(a); }
        let mut h: u64= hash_str(key);
        if (h == UMAP_EMPTY || h == UMAP_DELETED) { h = h ^ 1u; }
        let mut idx: i32= (i32)(h % (u64)self.cap);
        while (true) {
            let mut sh: u64= self.slots[idx].hash;
            if (sh == UMAP_EMPTY || sh == UMAP_DELETED) {
                self.slots[idx].hash = h;
                self.slots[idx].key  = key;
                self.slots[idx].val  = val;
                self.count = self.count + 1;
                return;
            }
            if (sh == h && strcmp(self.slots[idx].key, key) == 0) {
                self.slots[idx].val = val;
                return;
            }
            idx = (idx + 1) % self.cap;
        }
    }

    fn get(self: *str_unordered_map, key: *i8) *V {
        if (self.cap == 0) { return (V*)0; }
        let mut h: u64= hash_str(key);
        if (h == UMAP_EMPTY || h == UMAP_DELETED) { h = h ^ 1u; }
        let mut idx: i32= (i32)(h % (u64)self.cap);
        while (true) {
            let mut sh: u64= self.slots[idx].hash;
            if (sh == UMAP_EMPTY) { return (V*)0; }
            if (sh == h && strcmp(self.slots[idx].key, key) == 0) { return &self.slots[idx].val; }
            idx = (idx + 1) % self.cap;
        }
        return (V*)0;
    }

    fn contains(self: *str_unordered_map, key: *i8) bool { return self.get(key) != (V*)0; }

    fn remove(self: *str_unordered_map, key: *i8) void {
        if (self.cap == 0) { return; }
        let mut h: u64= hash_str(key);
        if (h == UMAP_EMPTY || h == UMAP_DELETED) { h = h ^ 1u; }
        let mut idx: i32= (i32)(h % (u64)self.cap);
        while (true) {
            let mut sh: u64= self.slots[idx].hash;
            if (sh == UMAP_EMPTY) { return; }
            if (sh == h && strcmp(self.slots[idx].key, key) == 0) {
                self.slots[idx].hash = UMAP_DELETED;
                self.count = self.count - 1;
                return;
            }
            idx = (idx + 1) % self.cap;
        }
    }

    fn size(self: *str_unordered_map) i32      { return self.count; }
    fn is_empty(self: *str_unordered_map) bool  { return self.count == 0; }

    fn each(self: *str_unordered_map, cb: void(*i8, V)*) void {
        for (let mut i: i32 = 0; i < self.cap; i = i + 1) {
            let mut h: u64= self.slots[i].hash;
            if (h != UMAP_EMPTY && h != UMAP_DELETED)
                cb(self.slots[i].key, self.slots[i].val);
        }
    }

    fn deinit(self: *str_unordered_map, a: &memstr) void {
        if (self.slots != (str_umap_slot<V>*)0)
            a.free((void*)self.slots);
        self.slots = (str_umap_slot<V>*)0;
        self.count = 0; self.cap = 0;
    }
}

} // std
