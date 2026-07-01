// Test: std.test — runner istruc, debug::assert helpers, test_alloc
extern std.test;
extern i32 printf(i8* fmt, ...);

i32 main() {
    // Test the runner istruc
    test::runner r;
    r.begin("basic true");
    test::expect_true(&r, true, "true is true");
    r.end();

    r.begin("basic i32");
    test::expect_eq_i32(&r, 2 + 2, 4, "2+2==4");
    r.end();

    r.begin("string eq");
    test::expect_eq_str(&r, "hello", "hello", "hello eq");
    r.end();

    i32 result = r.finish();
    if (result != 0) { return 1; }

    // Test test_alloc
    test::test_alloc ta;
    if (ta.count != 0)       { printf("FAIL initial count\n"); return 2; }
    if (ta.has_leaks())      { printf("FAIL initial leaks\n"); return 3; }

    void* p1 = ta.alloc((u64)16);
    if (p1 == (void*)0)      { printf("FAIL alloc\n"); return 4; }
    if (ta.count != 1)       { printf("FAIL count after alloc\n"); return 5; }
    if (!ta.has_leaks())     { printf("FAIL should have leak before free\n"); return 6; }

    ta.dealloc(p1, (u64)16);
    if (ta.has_leaks())      { printf("FAIL has_leaks after free\n"); return 7; }
    if (ta.leak_count() != 0){ printf("FAIL leak_count\n"); return 8; }

    return 0;
}
