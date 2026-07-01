// std.atomic — Lock-free atomic primitives and memory ordering fences.
// Uses inline assembly for x86-64; compatible with istruc types via pointer wrappers.

namespace std {
namespace atomic {

// Memory ordering constants (mirrors C11/C++ semantics)
constexpr i32 RELAXED = 0;
constexpr i32 ACQUIRE = 1;
constexpr i32 RELEASE = 2;
constexpr i32 ACQ_REL = 3;
constexpr i32 SEQ_CST = 4;

// --- fences ---

void fence_acquire() {
    __asm__ { lfence : : : memory }
}

void fence_release() {
    __asm__ { sfence : : : memory }
}

void fence_seq_cst() {
    __asm__ { mfence : : : memory }
}

// --- atomic i32 ---

istruc i32_t {
    volatile i32 val;

    void __construct__(&self, i32 v) { self.val = v; }

    i32 load(&self) {
        i32 r;
        __asm__ { mov %val, %r : r : val : }
        return r;
    }

    void store(&self, i32 v) {
        __asm__ { xchg %v, %val : : v, val : memory }
    }

    i32 fetch_add(&self, i32 delta) {
        i32 r;
        __asm__ { lock xadd %delta, %val : r : delta, val : memory }
        return r;
    }

    i32 fetch_sub(&self, i32 delta) { return self.fetch_add(-delta); }

    i32 fetch_and(&self, i32 mask) {
        i32 old;
        i32 new_val;
        old = self.load();
        while (true) {
            new_val = old & mask;
            i32 cmp = old;
            __asm__ { lock cmpxchg %new_val, %val : old : cmp, new_val, val : memory }
            if (old == cmp) { break; }
        }
        return old;
    }

    i32 fetch_or(&self, i32 mask) {
        i32 old;
        i32 new_val;
        old = self.load();
        while (true) {
            new_val = old | mask;
            i32 cmp = old;
            __asm__ { lock cmpxchg %new_val, %val : old : cmp, new_val, val : memory }
            if (old == cmp) { break; }
        }
        return old;
    }

    i32 fetch_xor(&self, i32 mask) {
        i32 old;
        i32 new_val;
        old = self.load();
        while (true) {
            new_val = old ^ mask;
            i32 cmp = old;
            __asm__ { lock cmpxchg %new_val, %val : old : cmp, new_val, val : memory }
            if (old == cmp) { break; }
        }
        return old;
    }

    // Compare-exchange: if val == expected, set val = desired; return old val
    i32 compare_exchange(&self, i32 expected, i32 desired) {
        i32 old = expected;
        __asm__ { lock cmpxchg %desired, %val : old : desired, val, expected : memory }
        return old;
    }

    bool cas(&self, i32 expected, i32 desired) {
        return self.compare_exchange(expected, desired) == expected;
    }

    i32 inc(&self) { return self.fetch_add(1) + 1; }
    i32 dec(&self) { return self.fetch_sub(1) - 1; }
}

// --- atomic i64 ---

istruc i64_t {
    volatile i64 val;

    void __construct__(&self, i64 v) { self.val = v; }

    i64 load(&self) {
        i64 r;
        __asm__ { mov %val, %r : r : val : }
        return r;
    }

    void store(&self, i64 v) {
        __asm__ { xchg %v, %val : : v, val : memory }
    }

    i64 fetch_add(&self, i64 delta) {
        i64 r;
        __asm__ { lock xadd %delta, %val : r : delta, val : memory }
        return r;
    }

    i64 fetch_sub(&self, i64 delta) { return self.fetch_add(-delta); }

    i64 compare_exchange(&self, i64 expected, i64 desired) {
        i64 old = expected;
        __asm__ { lock cmpxchg %desired, %val : old : desired, val, expected : memory }
        return old;
    }

    bool cas(&self, i64 expected, i64 desired) {
        return self.compare_exchange(expected, desired) == expected;
    }
}

// --- atomic bool ---

istruc bool_t {
    volatile i32 val;

    void __construct__(&self, bool v) { self.val = v ? 1 : 0; }

    bool load(&self) {
        i32 r;
        __asm__ { mov %val, %r : r : val : }
        return r != 0;
    }

    void store(&self, bool v) {
        i32 iv = v ? 1 : 0;
        __asm__ { xchg %iv, %val : : iv, val : memory }
    }

    bool test_and_set(&self) {
        i32 one = 1;
        i32 old;
        __asm__ { lock xchg %one, %val : old : one, val : memory }
        return old != 0;
    }

    void clear(&self) { self.store(false); }
}

// --- atomic pointer ---

istruc ptr_t {
    volatile void* val;

    void __construct__(&self, void* p) { self.val = p; }

    void* load(&self) {
        void* r;
        __asm__ { mov %val, %r : r : val : }
        return r;
    }

    void store(&self, void* p) {
        __asm__ { xchg %p, %val : : p, val : memory }
    }

    void* compare_exchange(&self, void* expected, void* desired) {
        void* old = expected;
        __asm__ { lock cmpxchg %desired, %val : old : desired, val, expected : memory }
        return old;
    }

    bool cas(&self, void* expected, void* desired) {
        return self.compare_exchange(expected, desired) == expected;
    }
}

// --- spin lock ---

istruc spin_lock {
    bool_t locked;

    void __construct__(&self) { self.locked.__construct__(false); }

    void lock(&self) {
        while (self.locked.test_and_set()) {
            __asm__ { pause : : : }
        }
    }

    void unlock(&self) { self.locked.clear(); }

    bool try_lock(&self) { return !self.locked.test_and_set(); }
}

// --- reference counter ---

istruc ref_count {
    i32_t count;

    void __construct__(&self) { self.count.__construct__(1); }

    void retain(&self)   { self.count.inc(); }
    bool release(&self)  { return self.count.dec() == 0; }
    i32  get(&self) { return self.count.load(); }
}

} // atomic
} // std
