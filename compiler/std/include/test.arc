// std.test — Testing framework: assertions, test runner, leak detection,
// and a test allocator that tracks every allocation.

extern i32   printf(i8* fmt, ...);
extern void  abort();
extern void* malloc(u64 n);
extern void  free(void* p);

namespace test {

// ---- Test allocator ----
// Tracks allocation/free counts via malloc/free; detects potential leaks.

constexpr i32 MAX_ALLOCS = 4096;

istruc test_alloc {
    i32 count;
    i32 freed_count;
    u64 total_bytes;
    u64 peak_bytes;
    u64 current_bytes;

    void __construct__(test_alloc* self) {
        self.count=0; self.freed_count=0;
        self.total_bytes=0; self.peak_bytes=0; self.current_bytes=0;
    }

    void* alloc(test_alloc* self, u64 size) {
        void* p = malloc(size);
        if(p != (void*)0) {
            self.count         = self.count + 1;
            self.total_bytes   = self.total_bytes + size;
            self.current_bytes = self.current_bytes + size;
            if(self.current_bytes > self.peak_bytes) self.peak_bytes = self.current_bytes;
        }
        return p;
    }

    void dealloc(test_alloc* self, void* p, u64 size) {
        free(p);
        self.freed_count   = self.freed_count + 1;
        self.current_bytes = self.current_bytes - size;
    }

    bool has_leaks(test_alloc* self) { return self.count != self.freed_count; }
    i32  leak_count(test_alloc* self) { return self.count - self.freed_count; }
    void report_leaks(test_alloc* self) {
        printf("  %d potential leaks (alloc:%d free:%d)\n",
               self.count - self.freed_count, self.count, self.freed_count);
    }
}

// ---- Assertion primitives ----

// Runtime assertion: on failure prints location and aborts.
void assert_true(bool cond, i8* msg, i8* file, i32 line) {
    if(!cond) {
        printf("FAIL [%s:%d] assert_true: %s\n", file, line, msg);
        abort();
    }
}

void assert_false(bool cond, i8* msg, i8* file, i32 line) {
    if(cond) {
        printf("FAIL [%s:%d] assert_false: %s\n", file, line, msg);
        abort();
    }
}

void assert_eq_i32(i32 a, i32 b, i8* msg, i8* file, i32 line) {
    if(a != b) {
        printf("FAIL [%s:%d] assert_eq_i32: %s — expected %d, got %d\n", file, line, msg, b, a);
        abort();
    }
}

void assert_eq_i64(i64 a, i64 b, i8* msg, i8* file, i32 line) {
    if(a != b) {
        printf("FAIL [%s:%d] assert_eq_i64: %s\n", file, line, msg);
        abort();
    }
}

void assert_eq_f64(f64 a, f64 b, f64 eps, i8* msg, i8* file, i32 line) {
    f64 diff = a - b;
    if(diff < 0.0) { diff = -diff; }
    if(diff > eps) {
        printf("FAIL [%s:%d] assert_eq_f64: %s — delta = %f\n", file, line, msg, diff);
        abort();
    }
}

void assert_eq_str(i8* a, i8* b, i8* msg, i8* file, i32 line) {
    i32 i=0;
    while(a[i]!=0&&b[i]!=0){if(a[i]!=b[i]) break;i=i+1;}
    if(a[i]!=b[i]) {
        printf("FAIL [%s:%d] assert_eq_str: %s — \"%s\" != \"%s\"\n", file, line, msg, a, b);
        abort();
    }
}

void assert_null(void* p, i8* msg, i8* file, i32 line) {
    if(p != (void*)0) {
        printf("FAIL [%s:%d] assert_null: %s — expected null\n", file, line, msg);
        abort();
    }
}

void assert_not_null(void* p, i8* msg, i8* file, i32 line) {
    if(p == (void*)0) {
        printf("FAIL [%s:%d] assert_not_null: %s — got null\n", file, line, msg);
        abort();
    }
}

// ---- Test runner ----

constexpr i32 MAX_TESTS = 256;

istruc runner {
    i8*  test_names[256];
    bool test_passed[256];
    i32  test_fails[256];
    i32  count;
    i32  passed;
    i32  failed;

    void __construct__(runner* self) { self.count=0; self.passed=0; self.failed=0; }

    void begin(runner* self, i8* name) {
        if(self.count < MAX_TESTS) {
            self.test_names[self.count]  = name;
            self.test_passed[self.count] = true;
            self.test_fails[self.count]  = 0;
            self.count = self.count + 1;
            printf("  RUN  %s\n", name);
        }
    }

    void record_fail(runner* self) {
        i32 i = self.count - 1;
        if(i >= 0) {
            self.test_passed[i] = false;
            self.test_fails[i]  = self.test_fails[i] + 1;
        }
    }

    void end(runner* self) {
        i32 i = self.count - 1;
        if(i < 0) { return; }
        if(self.test_passed[i]) {
            self.passed = self.passed + 1;
            printf("  OK   %s\n", self.test_names[i]);
        } else {
            self.failed = self.failed + 1;
            printf("  FAIL %s (%d failures)\n", self.test_names[i], self.test_fails[i]);
        }
    }

    i32 finish(runner* self) {
        printf("\n=== %d passed, %d failed ===\n", self.passed, self.failed);
        return self.failed > 0 ? 1 : 0;
    }
}

// ---- Soft assertions (record failure, continue) ----

void expect_true(runner* r, bool cond, i8* msg) {
    if(!cond) { printf("  EXPECT FAIL: %s\n", msg); (*r).record_fail(); }
}

void expect_eq_i32(runner* r, i32 a, i32 b, i8* msg) {
    if(a!=b) {
        printf("  EXPECT FAIL: %s — expected %d, got %d\n", msg, b, a);
        (*r).record_fail();
    }
}

void expect_eq_str(runner* r, i8* a, i8* b, i8* msg) {
    i32 i=0;
    while(a[i]!=0&&b[i]!=0){if(a[i]!=b[i])break;i=i+1;}
    if(a[i]!=b[i]) { printf("  EXPECT FAIL: %s\n", msg); (*r).record_fail(); }
}

void expect_null(runner* r, void* p, i8* msg) {
    if(p!=(void*)0) { printf("  EXPECT FAIL (not null): %s\n", msg); (*r).record_fail(); }
}

void expect_not_null(runner* r, void* p, i8* msg) {
    if(p==(void*)0) { printf("  EXPECT FAIL (null): %s\n", msg); (*r).record_fail(); }
}

} // namespace test
