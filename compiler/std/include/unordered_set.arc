// std.unordered_set — Hash set (open addressing, same hash as unordered_map).

namespace std {

constexpr u64 USET_EMPTY   = 0xFFFFFFFFFFFFFFFFu;
constexpr u64 USET_DELETED = 0xFFFFFFFFFFFFFFFEu;

istruc uset_slot<K> {
    u64 hash;
    K   key;
}

istruc unordered_set<K> {
    uset_slot<K>* slots;
    i32           count;
    i32           cap;

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
        self.slots = (uset_slot<K>*)a.mmap((u64)(sizeof(uset_slot<K>) * initial_cap));
        for (i32 i = 0; i < initial_cap; i = i + 1) self.slots[i].hash = USET_EMPTY;
    }

    void __construct__(&self) {
        self.cap = 0; self.count = 0; self.slots = (uset_slot<K>*)0;
    }

    private void rehash(&self, &memstr a) {
        i32 old_cap = self.cap;
        uset_slot<K>* old_slots = self.slots;
        i32 new_cap = old_cap == 0 ? 16 : old_cap * 2;
        self.slots = (uset_slot<K>*)a.mmap((u64)(sizeof(uset_slot<K>) * new_cap));
        for (i32 i = 0; i < new_cap; i = i + 1) self.slots[i].hash = USET_EMPTY;
        self.cap = new_cap; self.count = 0;
        for (i32 i = 0; i < old_cap; i = i + 1)
            if (old_slots[i].hash != USET_EMPTY && old_slots[i].hash != USET_DELETED)
                self.insert(old_slots[i].key, a);
        if (old_slots != (uset_slot<K>*)0) a.deinit(old_slots);
    }

    void insert(&self, K key, &memstr a) {
        if (self.count * 100 >= self.cap * 75) { self.rehash(a); }
        u64 h = hash_key((i64)key);
        if (h == USET_EMPTY || h == USET_DELETED) { h = h ^ 1u; }
        i32 idx = (i32)(h % (u64)self.cap);
        while (true) {
            u64 sh = self.slots[idx].hash;
            if (sh == USET_EMPTY || sh == USET_DELETED) {
                self.slots[idx].hash = h; self.slots[idx].key = key;
                self.count = self.count + 1; return;
            }
            if (sh == h && self.slots[idx].key == key) { return; }
            idx = (idx + 1) % self.cap;
        }
    }

    bool contains(&self, K key) {
        if (self.cap == 0) { return false; }
        u64 h   = hash_key((i64)key);
        if (h == USET_EMPTY || h == USET_DELETED) { h = h ^ 1u; }
        i32 idx = (i32)(h % (u64)self.cap);
        while (true) {
            u64 sh = self.slots[idx].hash;
            if (sh == USET_EMPTY) { return false; }
            if (sh == h && self.slots[idx].key == key) { return true; }
            idx = (idx + 1) % self.cap;
        }
    }

    void remove(&self, K key) {
        if (self.cap == 0) { return; }
        u64 h   = hash_key((i64)key);
        if (h == USET_EMPTY || h == USET_DELETED) { h = h ^ 1u; }
        i32 idx = (i32)(h % (u64)self.cap);
        while (true) {
            u64 sh = self.slots[idx].hash;
            if (sh == USET_EMPTY) { return; }
            if (sh == h && self.slots[idx].key == key) {
                self.slots[idx].hash = USET_DELETED; self.count = self.count - 1; return;
            }
            idx = (idx + 1) % self.cap;
        }
    }

    i32  size(&self)     { return self.count; }
    bool is_empty(&self) { return self.count == 0; }

    void each(&self, void(K)* cb) {
        for (i32 i = 0; i < self.cap; i = i + 1)
            if (self.slots[i].hash != USET_EMPTY && self.slots[i].hash != USET_DELETED)
                cb(self.slots[i].key);
    }

    void deinit(&self, &memstr a) {
        if (self.slots != (uset_slot<K>*)0) a.deinit(self.slots);
        self.slots = (uset_slot<K>*)0; self.count = 0; self.cap = 0;
    }
}

} // std
