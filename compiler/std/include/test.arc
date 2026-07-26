// std.test — Testing framework: assertions, test runner, leak detection,
// and a test allocator that tracks every allocation.

@unsafe extern fn printf(fmt: *i8, ...) i32;
@unsafe extern fn abort() void;
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

namespace std {
namespace test {

// ---- Test allocator ----
// Tracks allocation/free counts via malloc/free; detects potential leaks.

comptime i32 MAX_ALLOCS = 4096;

memstr test_alloc {
    let mut count: i32;
    let mut freed_count: i32;
    let mut total_bytes: u64;
    let mut peak_bytes: u64;
    let mut current_bytes: u64;

    fn __construct__(self: *test_alloc) void {
        self.count=0; self.freed_count=0;
        self.total_bytes=0; self.peak_bytes=0; self.current_bytes=0;
    }

    fn alloc(self: *test_alloc, size: u64) *void {
        let mut p: *void= malloc(size);
        if(p != (void*)0) {
            self.count         = self.count + 1;
            self.total_bytes   = self.total_bytes + size;
            self.current_bytes = self.current_bytes + size;
            if(self.current_bytes > self.peak_bytes) self.peak_bytes = self.current_bytes;
        }
        return p;
    }

    fn dealloc(self: *test_alloc, p: *void, size: u64) void {
        free(p);
        self.freed_count   = self.freed_count + 1;
        self.current_bytes = self.current_bytes - size;
    }

    fn has_leaks(self: *test_alloc) bool { return self.count != self.freed_count; }
    fn leak_count(self: *test_alloc) i32 { return self.count - self.freed_count; }
    fn report_leaks(self: *test_alloc) void {
        printf("  %d potential leaks (alloc:%d free:%d)\n",
               self.count - self.freed_count, self.count, self.freed_count);
    }
}

// ---- Assertion primitives ----

// Runtime assertion: on failure prints location and aborts.
fn assert_true(cond: bool, msg: *i8, file: *i8, line: i32) void {
    if(!cond) {
        printf("FAIL [%s:%d] assert_true: %s\n", file, line, msg);
        abort();
    }
}

fn assert_false(cond: bool, msg: *i8, file: *i8, line: i32) void {
    if(cond) {
        printf("FAIL [%s:%d] assert_false: %s\n", file, line, msg);
        abort();
    }
}

fn assert_eq_i32(a: i32, b: i32, msg: *i8, file: *i8, line: i32) void {
    if(a != b) {
        printf("FAIL [%s:%d] assert_eq_i32: %s — expected %d, got %d\n", file, line, msg, b, a);
        abort();
    }
}

fn assert_eq_i64(a: i64, b: i64, msg: *i8, file: *i8, line: i32) void {
    if(a != b) {
        printf("FAIL [%s:%d] assert_eq_i64: %s\n", file, line, msg);
        abort();
    }
}

fn assert_eq_f64(a: f64, b: f64, eps: f64, msg: *i8, file: *i8, line: i32) void {
    let mut diff: f64= a - b;
    if(diff < 0.0) { diff = -diff; }
    if(diff > eps) {
        printf("FAIL [%s:%d] assert_eq_f64: %s — delta = %f\n", file, line, msg, diff);
        abort();
    }
}

fn assert_eq_str(a: *i8, b: *i8, msg: *i8, file: *i8, line: i32) void {
    let mut i: i32=0;
    while(a[i]!=0&&b[i]!=0){if(a[i]!=b[i]) break;i=i+1;}
    if(a[i]!=b[i]) {
        printf("FAIL [%s:%d] assert_eq_str: %s — \"%s\" != \"%s\"\n", file, line, msg, a, b);
        abort();
    }
}

fn assert_null(p: *void, msg: *i8, file: *i8, line: i32) void {
    if(p != (void*)0) {
        printf("FAIL [%s:%d] assert_null: %s — expected null\n", file, line, msg);
        abort();
    }
}

fn assert_not_null(p: *void, msg: *i8, file: *i8, line: i32) void {
    if(p == (void*)0) {
        printf("FAIL [%s:%d] assert_not_null: %s — got null\n", file, line, msg);
        abort();
    }
}

// ---- Test runner ----

comptime i32 MAX_TESTS = 256;

istruc runner {
    let mut test_names: [256]*i8;
    let mut test_passed: [256]bool;
    let mut test_fails: [256]i32;
    let mut count: i32;
    let mut passed: i32;
    let mut failed: i32;

    fn __construct__(self: *runner) void { self.count=0; self.passed=0; self.failed=0; }

    fn begin(self: *runner, name: *i8) void {
        if(self.count < MAX_TESTS) {
            self.test_names[self.count]  = name;
            self.test_passed[self.count] = true;
            self.test_fails[self.count]  = 0;
            self.count = self.count + 1;
            printf("  RUN  %s\n", name);
        }
    }

    fn record_fail(self: *runner) void {
        let mut i: i32= self.count - 1;
        if(i >= 0) {
            self.test_passed[i] = false;
            self.test_fails[i]  = self.test_fails[i] + 1;
        }
    }

    fn end(self: *runner) void {
        let mut i: i32= self.count - 1;
        if(i < 0) { return; }
        if(self.test_passed[i]) {
            self.passed = self.passed + 1;
            printf("  OK   %s\n", self.test_names[i]);
        } else {
            self.failed = self.failed + 1;
            printf("  FAIL %s (%d failures)\n", self.test_names[i], self.test_fails[i]);
        }
    }

    fn finish(self: *runner) i32 {
        printf("\n=== %d passed, %d failed ===\n", self.passed, self.failed);
        return self.failed > 0 ? 1 : 0;
    }
}

// ---- Soft assertions (record failure, continue) ----

fn expect_true(r: *runner, cond: bool, msg: *i8) void {
    if(!cond) { printf("  EXPECT FAIL: %s\n", msg); (*r).record_fail(); }
}

fn expect_eq_i32(r: *runner, a: i32, b: i32, msg: *i8) void {
    if(a!=b) {
        printf("  EXPECT FAIL: %s — expected %d, got %d\n", msg, b, a);
        (*r).record_fail();
    }
}

fn expect_eq_str(r: *runner, a: *i8, b: *i8, msg: *i8) void {
    let mut i: i32=0;
    while(a[i]!=0&&b[i]!=0){if(a[i]!=b[i])break;i=i+1;}
    if(a[i]!=b[i]) { printf("  EXPECT FAIL: %s\n", msg); (*r).record_fail(); }
}

fn expect_null(r: *runner, p: *void, msg: *i8) void {
    if(p!=(void*)0) { printf("  EXPECT FAIL (not null): %s\n", msg); (*r).record_fail(); }
}

fn expect_not_null(r: *runner, p: *void, msg: *i8) void {
    if(p==(void*)0) { printf("  EXPECT FAIL (null): %s\n", msg); (*r).record_fail(); }
}

} // namespace test
} // namespace std
