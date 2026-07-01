// Test: std.fmt — string operations (fmt::str_len, fmt::str_eq, fmt::str_copy, fmt::str_append, etc.)
extern std.fmt;
extern i32 printf(i8* fmt, ...);

i32 main() {
    // fmt::str_len
    i32 l = fmt::str_len("hello");
    if (l != 5) { printf("FAIL fmt::str_len\n"); return 1; }
    if (fmt::str_len("") != 0) { printf("FAIL fmt::str_len empty\n"); return 2; }

    // fmt::str_eq
    if (!fmt::str_eq("abc", "abc")) { printf("FAIL fmt::str_eq true\n"); return 3; }
    if (fmt::str_eq("abc", "xyz")) { printf("FAIL fmt::str_eq false\n"); return 4; }
    if (fmt::str_eq("abc", "abcd")) { printf("FAIL fmt::str_eq length\n"); return 5; }

    // fmt::str_copy
    i8 buf[32];
    fmt::str_copy(buf, "world", (u64)32);
    if (!fmt::str_eq(buf, "world")) { printf("FAIL fmt::str_copy\n"); return 6; }

    // fmt::str_append
    fmt::str_copy(buf, "foo", (u64)32);
    fmt::str_append(buf, "bar", (u64)32);
    if (!fmt::str_eq(buf, "foobar")) { printf("FAIL fmt::str_append\n"); return 7; }

    // fmt::str_starts_with
    if (!fmt::str_starts_with("foobar", "foo")) { printf("FAIL fmt::str_starts_with true\n"); return 8; }
    if (fmt::str_starts_with("foobar", "bar")) { printf("FAIL fmt::str_starts_with false\n"); return 9; }

    // fmt::str_ends_with
    if (!fmt::str_ends_with("foobar", "bar")) { printf("FAIL fmt::str_ends_with true\n"); return 10; }
    if (fmt::str_ends_with("foobar", "foo")) { printf("FAIL fmt::str_ends_with false\n"); return 11; }

    // fmt::str_find
    i32 idx = fmt::str_find("foobar", "oba");
    if (idx != 2) { printf("FAIL fmt::str_find\n"); return 12; }
    i32 idx2 = fmt::str_find("foobar", "xyz");
    if (idx2 != -1) { printf("FAIL fmt::str_find not found\n"); return 13; }

    // fmt::str_to_i32
    i32 v = fmt::str_to_i32("-123");
    if (v != -123) { printf("FAIL fmt::str_to_i32\n"); return 14; }

    // fmt::str_to_i64
    i64 v2 = fmt::str_to_i64("9876543210");
    if (v2 != (i64)9876543210) { printf("FAIL fmt::str_to_i64\n"); return 15; }

    return 0;
}
