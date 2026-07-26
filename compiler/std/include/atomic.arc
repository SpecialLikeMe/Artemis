// std.atomic — Atomic primitives using GCC/Clang __sync built-ins.
// These map directly to atomic machine instructions on x86/ARM.

// GCC/Clang __sync built-ins for 32-bit integers
@unsafe extern fn __sync_fetch_and_add_4(ptr: *i32, val: i32) i32;
@unsafe extern fn __sync_fetch_and_sub_4(ptr: *i32, val: i32) i32;
@unsafe extern fn __sync_fetch_and_and_4(ptr: *i32, val: i32) i32;
@unsafe extern fn __sync_fetch_and_or_4(ptr: *i32, val: i32) i32;
@unsafe extern fn __sync_fetch_and_xor_4(ptr: *i32, val: i32) i32;
@unsafe extern fn __sync_val_compare_and_swap_4(ptr: *i32, expected: i32, desired: i32) i32;
@unsafe extern fn __sync_lock_test_and_set_4(ptr: *i32, val: i32) i32;
@unsafe extern fn __sync_lock_release_4(ptr: *i32) void;
@unsafe extern fn __sync_synchronize() void;

// GCC/Clang __sync built-ins for 64-bit integers
@unsafe extern fn __sync_fetch_and_add_8(ptr: *i64, val: i64) i64;
@unsafe extern fn __sync_fetch_and_sub_8(ptr: *i64, val: i64) i64;
@unsafe extern fn __sync_val_compare_and_swap_8(ptr: *i64, expected: i64, desired: i64) i64;

namespace std {
namespace atomic {

comptime i32 RELAXED = 0;
comptime i32 ACQUIRE = 1;
comptime i32 RELEASE = 2;
comptime i32 ACQ_REL = 3;
comptime i32 SEQ_CST = 4;

fn fence_acquire() void { __sync_synchronize(); }
fn fence_release() void { __sync_synchronize(); }
fn fence_seq_cst() void { __sync_synchronize(); }

// --- atomic i32 ---

istruc i32_t {
    volatile i32 val;

    fn __construct__(self: *i32_t) void { self.val = 0; }

    fn load(self: *i32_t) i32           { return self.val; }
    fn store(self: *i32_t, v: i32) void   { self.val = v; }

    fn fetch_add(self: *i32_t, delta: i32) i32 {
        return __sync_fetch_and_add_4(&self.val, delta);
    }
    fn fetch_sub(self: *i32_t, delta: i32) i32 {
        return __sync_fetch_and_sub_4(&self.val, delta);
    }
    fn fetch_and(self: *i32_t, mask: i32) i32 {
        return __sync_fetch_and_and_4(&self.val, mask);
    }
    fn fetch_or(self: *i32_t, mask: i32) i32 {
        return __sync_fetch_and_or_4(&self.val, mask);
    }
    fn fetch_xor(self: *i32_t, mask: i32) i32 {
        return __sync_fetch_and_xor_4(&self.val, mask);
    }

    fn compare_exchange(self: *i32_t, expected: i32, desired: i32) i32 {
        return __sync_val_compare_and_swap_4(&self.val, expected, desired);
    }
    fn cas(self: *i32_t, expected: i32, desired: i32) bool {
        return self.compare_exchange(expected, desired) == expected;
    }

    fn inc(self: *i32_t) i32 { return __sync_fetch_and_add_4(&self.val, 1) + 1; }
    fn dec(self: *i32_t) i32 { return __sync_fetch_and_sub_4(&self.val, 1) - 1; }
}

// --- atomic i64 ---

istruc i64_t {
    volatile i64 val;

    fn __construct__(self: *i64_t) void { self.val = 0; }

    fn load(self: *i64_t) i64           { return self.val; }
    fn store(self: *i64_t, v: i64) void   { self.val = v; }

    fn fetch_add(self: *i64_t, delta: i64) i64 {
        return __sync_fetch_and_add_8(&self.val, delta);
    }
    fn fetch_sub(self: *i64_t, delta: i64) i64 {
        return __sync_fetch_and_sub_8(&self.val, delta);
    }

    fn compare_exchange(self: *i64_t, expected: i64, desired: i64) i64 {
        return __sync_val_compare_and_swap_8(&self.val, expected, desired);
    }
    fn cas(self: *i64_t, expected: i64, desired: i64) bool {
        return self.compare_exchange(expected, desired) == expected;
    }
}

// --- atomic bool ---

istruc bool_t {
    volatile i32 val;

    fn __construct__(self: *bool_t) void { self.val = 0; }

    fn load(self: *bool_t) bool          { return self.val != 0; }
    fn store(self: *bool_t, v: bool) void { self.val = v ? 1 : 0; }

    fn test_and_set(self: *bool_t) bool {
        return __sync_lock_test_and_set_4(&self.val, 1) != 0;
    }
    fn clear(self: *bool_t) void { __sync_lock_release_4(&self.val); }
}

// --- atomic pointer ---

istruc ptr_t {
    volatile void* val;

    fn __construct__(self: *ptr_t) void { self.val = (void*)0; }

    fn load(self: *ptr_t) *void           { return self.val; }
    fn store(self: *ptr_t, p: *void) void { self.val = p; }

    fn compare_exchange(self: *ptr_t, expected: *void, desired: *void) *void {
        let mut old: *void= self.val;
        if (self.val == expected) { self.val = desired; }
        return old;
    }
    fn cas(self: *ptr_t, expected: *void, desired: *void) bool {
        return self.compare_exchange(expected, desired) == expected;
    }
}

// --- spin lock ---

istruc spin_lock {
    let mut locked: bool_t;

    fn __construct__(self: *spin_lock) void { self.locked.val = 0; }

    fn lock(self: *spin_lock) void {
        // Atomic test-and-set: spin until we acquire the lock
        while (__sync_lock_test_and_set_4(&self.locked.val, 1) != 0) { }
        __sync_synchronize(); // acquire fence
    }

    fn unlock(self: *spin_lock) void {
        __sync_synchronize(); // release fence
        __sync_lock_release_4(&self.locked.val);
    }
    fn try_lock(self: *spin_lock) bool {
        if (__sync_lock_test_and_set_4(&self.locked.val, 1) == 0) {
            __sync_synchronize();
            return true;
        }
        return false;
    }
}

// --- reference counter ---

istruc ref_count {
    let mut count: i32_t;

    fn __construct__(self: *ref_count) void { self.count.val = 1; }

    fn retain(self: *ref_count) void  { __sync_fetch_and_add_4(&self.count.val, 1); }
    fn release(self: *ref_count) bool { return __sync_fetch_and_sub_4(&self.count.val, 1) == 1; }
    fn get(self: *ref_count) i32     { return self.count.val; }
}

} // atomic
} // std
