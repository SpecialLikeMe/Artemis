// std.unordered_set — Hash set (open addressing, same hash as unordered_map).

namespace std {

comptime u64 USET_EMPTY   = 0xFFFFFFFFFFFFFFFFu;
comptime u64 USET_DELETED = 0xFFFFFFFFFFFFFFFEu;

istruc uset_slot<K> {
    let mut hash: u64;
    let mut key: K;
}

istruc unordered_set<K> {
    let mut slots: *uset_slot<K>;
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

    fn __construct__(self: *unordered_set, initial_cap: i32, a: &memstr) void {
        self.cap   = initial_cap;
        self.count = 0;
        self.slots = (uset_slot<K>*)a.mmap((u64)(sizeof(uset_slot<K>) * (u64)initial_cap));
        for (let mut i: i32 = 0; i < initial_cap; i = i + 1) self.slots[i].hash = USET_EMPTY;
    }

    fn rehash(self: *unordered_set, a: &memstr) void {
        let mut old_cap: i32= self.cap;
        let mut old_slots: *uset_slot<K>= self.slots;
        let mut new_cap: i32= old_cap == 0 ? 16 : old_cap * 2;
        self.slots = (uset_slot<K>*)a.mmap((u64)(sizeof(uset_slot<K>) * (u64)new_cap));
        for (let mut i: i32 = 0; i < new_cap; i = i + 1) self.slots[i].hash = USET_EMPTY;
        self.cap = new_cap; self.count = 0;
        for (let mut i: i32 = 0; i < old_cap; i = i + 1)
            if (old_slots[i].hash != USET_EMPTY && old_slots[i].hash != USET_DELETED)
                self.insert(old_slots[i].key, a);
        if (old_slots != (uset_slot<K>*)0) a.rmap((void*)old_slots, (u64)(sizeof(uset_slot<K>) * (u64)old_cap));
    }

    fn insert(self: *unordered_set, key: K, a: &memstr) void {
        if (self.count * 100 >= self.cap * 75) { self.rehash(a); }
        let mut h: u64= hash_key((i64)key);
        if (h == USET_EMPTY || h == USET_DELETED) { h = h ^ 1u; }
        let mut idx: i32= (i32)(h % (u64)self.cap);
        while (true) {
            let mut sh: u64= self.slots[idx].hash;
            if (sh == USET_EMPTY || sh == USET_DELETED) {
                self.slots[idx].hash = h; self.slots[idx].key = key;
                self.count = self.count + 1; return;
            }
            if (sh == h && self.slots[idx].key == key) { return; }
            idx = (idx + 1) % self.cap;
        }
    }

    fn contains(self: *unordered_set, key: K) bool {
        if (self.cap == 0) { return false; }
        let mut h: u64= hash_key((i64)key);
        if (h == USET_EMPTY || h == USET_DELETED) { h = h ^ 1u; }
        let mut idx: i32= (i32)(h % (u64)self.cap);
        while (true) {
            let mut sh: u64= self.slots[idx].hash;
            if (sh == USET_EMPTY) { return false; }
            if (sh == h && self.slots[idx].key == key) { return true; }
            idx = (idx + 1) % self.cap;
        }
        return false;
    }

    fn remove(self: *unordered_set, key: K) void {
        if (self.cap == 0) { return; }
        let mut h: u64= hash_key((i64)key);
        if (h == USET_EMPTY || h == USET_DELETED) { h = h ^ 1u; }
        let mut idx: i32= (i32)(h % (u64)self.cap);
        while (true) {
            let mut sh: u64= self.slots[idx].hash;
            if (sh == USET_EMPTY) { return; }
            if (sh == h && self.slots[idx].key == key) {
                self.slots[idx].hash = USET_DELETED; self.count = self.count - 1; return;
            }
            idx = (idx + 1) % self.cap;
        }
    }

    fn size(self: *unordered_set) i32     { return self.count; }
    fn is_empty(self: *unordered_set) bool { return self.count == 0; }

    fn each(self: *unordered_set, cb: void(K)*) void {
        for (let mut i: i32 = 0; i < self.cap; i = i + 1)
            if (self.slots[i].hash != USET_EMPTY && self.slots[i].hash != USET_DELETED)
                cb(self.slots[i].key);
    }

    fn deinit(self: *unordered_set, a: &memstr) void {
        if (self.slots != (uset_slot<K>*)0) a.rmap((void*)self.slots, (u64)(sizeof(uset_slot<K>) * (u64)self.cap));
        self.slots = (uset_slot<K>*)0; self.count = 0; self.cap = 0;
    }
}

} // std
