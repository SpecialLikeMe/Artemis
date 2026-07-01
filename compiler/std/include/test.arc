// std.test — Testing framework: assertions, test runner, leak detection,
// and a test allocator that tracks every allocation.

namespace std {
namespace test {

// ---- Test allocator ----
// Wraps any &memstr but records all allocations/frees to detect leaks.

constexpr i32 MAX_ALLOCS = 4096;

istruc alloc_record {
    void* ptr;
    u64   size;
    bool  freed;
}

istruc test_alloc {
    alloc_record records[4096];
    i32          count;
    u64          total_bytes;
    u64          peak_bytes;
    u64          current_bytes;

    void __construct__(&self) {
        self.count=0; self.total_bytes=0; self.peak_bytes=0; self.current_bytes=0;
        for(i32 i=0;i<MAX_ALLOCS;i=i+1){ self.records[i].ptr=(void*)0; self.records[i].freed=true; }
    }

    void* alloc(&self, u64 size, &memstr backing) {
        void* p = backing.mmap(size);
        if(self.count < MAX_ALLOCS) {
            self.records[self.count].ptr   = p;
            self.records[self.count].size  = size;
            self.records[self.count].freed = false;
            self.count = self.count + 1;
        }
        self.total_bytes   = self.total_bytes   + size;
        self.current_bytes = self.current_bytes + size;
        if(self.current_bytes > self.peak_bytes) self.peak_bytes = self.current_bytes;
        return p;
    }

    void free(&self, void* p, &memstr backing) {
        backing.deinit(p);
        for(i32 i=0;i<self.count;i=i+1) {
            if(self.records[i].ptr==p && !self.records[i].freed) {
                self.current_bytes = self.current_bytes - self.records[i].size;
                self.records[i].freed = true;
                return;
            }
        }
    }

    bool has_leaks(&self) {
        for(i32 i=0;i<self.count;i=i+1)
            if(!self.records[i].freed) { return true; }
        return false;
    }

    i32 leak_count(&self) {
        i32 n=0;
        for(i32 i=0;i<self.count;i=i+1)
            if(!self.records[i].freed) n=n+1;
        return n;
    }

    void report_leaks(&self) {
        extern i32 printf(i8* fmt, ...);
        for(i32 i=0;i<self.count;i=i+1) {
            if(!self.records[i].freed)
                printf("  LEAK: %p (%llu bytes)\n", self.records[i].ptr, self.records[i].size);
        }
    }
}

// ---- Assertion primitives ----

extern i32  printf(i8* fmt, ...);
extern void abort();

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

istruc test_fn {
    i8*  name;
    bool passed;
    i32  fail_count;
}

istruc runner {
    test_fn  tests[256];
    i32      count;
    i32      passed;
    i32      failed;

    void __construct__(&self) { self.count=0; self.passed=0; self.failed=0; }

    void begin(&self, i8* name) {
        if(self.count < MAX_TESTS) {
            self.tests[self.count].name       = name;
            self.tests[self.count].passed     = true;
            self.tests[self.count].fail_count = 0;
            self.count = self.count + 1;
            printf("  RUN  %s\n", name);
        }
    }

    void record_fail(&self) {
        i32 i = self.count - 1;
        if(i >= 0) {
            self.tests[i].passed = false;
            self.tests[i].fail_count = self.tests[i].fail_count + 1;
        }
    }

    void end(&self) {
        i32 i = self.count - 1;
        if(i < 0) { return; }
        if(self.tests[i].passed) {
            self.passed = self.passed + 1;
            printf("  OK   %s\n", self.tests[i].name);
        } else {
            self.failed = self.failed + 1;
            printf("  FAIL %s (%d failures)\n", self.tests[i].name, self.tests[i].fail_count);
        }
    }

    // Returns 0 if all tests passed, 1 if any failed.
    i32 finish(&self) {
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

} // test
} // std
