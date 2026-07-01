// std.unordered_map — Hash map (open addressing, robin-hood probing).

namespace std {

constexpr u64 UMAP_EMPTY   = 0xFFFFFFFFFFFFFFFFu;
constexpr u64 UMAP_DELETED = 0xFFFFFFFFFFFFFFFEu;
constexpr f64 UMAP_MAX_LOAD = 0.75;

istruc umap_slot<K, V> {
    u64 hash;
    K   key;
    V   val;
}

istruc unordered_map<K, V> {
    umap_slot<K,V>* slots;
    i32             count;
    i32             cap;

    private static u64 hash_key(i64 k) {
        u64 h = (u64)k;
        h = h ^ (h >> 30);
        h = h * 0xbf58476d1ce4e5b9u;
        h = h ^ (h >> 27);
        h = h * 0x94d049bb133111ebu;
        h = h ^ (h >> 31);
        return h;
    }

    void __construct__(&self, i32 initial_cap, &memstr a) {
        self.cap   = initial_cap;
        self.count = 0;
        self.slots = (umap_slot<K,V>*)a.mmap((u64)(sizeof(umap_slot<K,V>) * initial_cap));
        for (i32 i = 0; i < initial_cap; i = i + 1)
            self.slots[i].hash = UMAP_EMPTY;
    }

    void __construct__(&self) {
        self.cap   = 0;
        self.count = 0;
        self.slots = (umap_slot<K,V>*)0;
    }

    private void rehash(&self, &memstr a) {
        i32 old_cap = self.cap;
        umap_slot<K,V>* old_slots = self.slots;
        i32 new_cap = old_cap == 0 ? 16 : old_cap * 2;
        self.slots = (umap_slot<K,V>*)a.mmap((u64)(sizeof(umap_slot<K,V>) * new_cap));
        for (i32 i = 0; i < new_cap; i = i + 1) self.slots[i].hash = UMAP_EMPTY;
        self.cap   = new_cap;
        self.count = 0;
        for (i32 i = 0; i < old_cap; i = i + 1) {
            if (old_slots[i].hash != UMAP_EMPTY && old_slots[i].hash != UMAP_DELETED)
                self.insert(old_slots[i].key, old_slots[i].val, a);
        }
        if (old_slots != (umap_slot<K,V>*)0) a.deinit(old_slots);
    }

    void insert(&self, K key, V val, &memstr a) {
        if (self.count * 100 >= (i32)((f64)self.cap * 75.0)) { self.rehash(a); }
        u64 h  = hash_key((i64)key);
        if (h == UMAP_EMPTY || h == UMAP_DELETED) { h = h ^ 1u; }
        i32 idx = (i32)(h % (u64)self.cap);
        while (true) {
            u64 sh = self.slots[idx].hash;
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

    V* get(&self, K key) {
        if (self.cap == 0) { return (V*)0; }
        u64 h   = hash_key((i64)key);
        if (h == UMAP_EMPTY || h == UMAP_DELETED) { h = h ^ 1u; }
        i32 idx = (i32)(h % (u64)self.cap);
        while (true) {
            u64 sh = self.slots[idx].hash;
            if (sh == UMAP_EMPTY) { return (V*)0; }
            if (sh == h && self.slots[idx].key == key) { return &self.slots[idx].val; }
            idx = (idx + 1) % self.cap;
        }
    }

    bool contains(&self, K key) { return self.get(key) != (V*)0; }

    void remove(&self, K key) {
        if (self.cap == 0) { return; }
        u64 h   = hash_key((i64)key);
        if (h == UMAP_EMPTY || h == UMAP_DELETED) { h = h ^ 1u; }
        i32 idx = (i32)(h % (u64)self.cap);
        while (true) {
            u64 sh = self.slots[idx].hash;
            if (sh == UMAP_EMPTY) { return; }
            if (sh == h && self.slots[idx].key == key) {
                self.slots[idx].hash = UMAP_DELETED;
                self.count = self.count - 1;
                return;
            }
            idx = (idx + 1) % self.cap;
        }
    }

    i32  size(&self)     { return self.count; }
    bool is_empty(&self) { return self.count == 0; }

    void each(&self, void(K, V)* cb) {
        for (i32 i = 0; i < self.cap; i = i + 1) {
            u64 h = self.slots[i].hash;
            if (h != UMAP_EMPTY && h != UMAP_DELETED)
                cb(self.slots[i].key, self.slots[i].val);
        }
    }

    void deinit(&self, &memstr a) {
        if (self.slots != (umap_slot<K,V>*)0) a.deinit(self.slots);
        self.slots = (umap_slot<K,V>*)0;
        self.count = 0; self.cap = 0;
    }
}

} // std
