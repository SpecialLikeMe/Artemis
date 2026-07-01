// std.atomic — Atomic-style primitives (lock-prefixed asm unsupported in current
// Artemis backend; implemented as direct field ops — not thread-safe but API-compatible).

namespace std {
namespace atomic {

constexpr i32 RELAXED = 0;
constexpr i32 ACQUIRE = 1;
constexpr i32 RELEASE = 2;
constexpr i32 ACQ_REL = 3;
constexpr i32 SEQ_CST = 4;

void fence_acquire() { }
void fence_release() { }
void fence_seq_cst() { }

// --- atomic i32 ---

istruc i32_t {
    volatile i32 val;

    void __construct__(i32_t* self) { self.val = 0; }

    i32  load(i32_t* self)           { return self.val; }
    void store(i32_t* self, i32 v)   { self.val = v; }

    i32 fetch_add(i32_t* self, i32 delta) {
        i32 old = self.val; self.val = self.val + delta; return old;
    }
    i32 fetch_sub(i32_t* self, i32 delta) {
        i32 old = self.val; self.val = self.val - delta; return old;
    }
    i32 fetch_and(i32_t* self, i32 mask) {
        i32 old = self.val; self.val = self.val & mask; return old;
    }
    i32 fetch_or(i32_t* self, i32 mask) {
        i32 old = self.val; self.val = self.val | mask; return old;
    }
    i32 fetch_xor(i32_t* self, i32 mask) {
        i32 old = self.val; self.val = self.val ^ mask; return old;
    }

    i32 compare_exchange(i32_t* self, i32 expected, i32 desired) {
        i32 old = self.val;
        if (self.val == expected) { self.val = desired; }
        return old;
    }
    bool cas(i32_t* self, i32 expected, i32 desired) {
        return self.compare_exchange(expected, desired) == expected;
    }

    i32 inc(i32_t* self) { self.val = self.val + 1; return self.val; }
    i32 dec(i32_t* self) { self.val = self.val - 1; return self.val; }
}

// --- atomic i64 ---

istruc i64_t {
    volatile i64 val;

    void __construct__(i64_t* self) { self.val = 0; }

    i64  load(i64_t* self)           { return self.val; }
    void store(i64_t* self, i64 v)   { self.val = v; }

    i64 fetch_add(i64_t* self, i64 delta) {
        i64 old = self.val; self.val = self.val + delta; return old;
    }
    i64 fetch_sub(i64_t* self, i64 delta) {
        i64 old = self.val; self.val = self.val - delta; return old;
    }

    i64 compare_exchange(i64_t* self, i64 expected, i64 desired) {
        i64 old = self.val;
        if (self.val == expected) { self.val = desired; }
        return old;
    }
    bool cas(i64_t* self, i64 expected, i64 desired) {
        return self.compare_exchange(expected, desired) == expected;
    }
}

// --- atomic bool ---

istruc bool_t {
    volatile i32 val;

    void __construct__(bool_t* self) { self.val = 0; }

    bool load(bool_t* self)          { return self.val != 0; }
    void store(bool_t* self, bool v) { self.val = v ? 1 : 0; }

    bool test_and_set(bool_t* self) {
        i32 old = self.val; self.val = 1; return old != 0;
    }
    void clear(bool_t* self) { self.val = 0; }
}

// --- atomic pointer ---

istruc ptr_t {
    volatile void* val;

    void __construct__(ptr_t* self) { self.val = (void*)0; }

    void* load(ptr_t* self)           { return self.val; }
    void  store(ptr_t* self, void* p) { self.val = p; }

    void* compare_exchange(ptr_t* self, void* expected, void* desired) {
        void* old = self.val;
        if (self.val == expected) { self.val = desired; }
        return old;
    }
    bool cas(ptr_t* self, void* expected, void* desired) {
        return self.compare_exchange(expected, desired) == expected;
    }
}

// --- spin lock ---

istruc spin_lock {
    bool_t locked;

    void __construct__(spin_lock* self) { self.locked.val = 0; }

    void lock(spin_lock* self) {
        while (true) {
            i32 old = self.locked.val;
            if (old == 0) { self.locked.val = 1; break; }
        }
    }

    void unlock(spin_lock* self)   { self.locked.val = 0; }
    bool try_lock(spin_lock* self) {
        i32 old = self.locked.val;
        if (old == 0) { self.locked.val = 1; return true; }
        return false;
    }
}

// --- reference counter ---

istruc ref_count {
    i32_t count;

    void __construct__(ref_count* self) { self.count.val = 1; }

    void retain(ref_count* self)  { self.count.val = self.count.val + 1; }
    bool release(ref_count* self) { self.count.val = self.count.val - 1; return self.count.val == 0; }
    i32  get(ref_count* self)     { return self.count.val; }
}

} // atomic
} // std
