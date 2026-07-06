// Test: std.fmt — string operations (std.fmt.str_len, std.fmt.str_eq, std.fmt.str_copy, std.fmt.str_append, etc.)
extern std.fmt;
extern i32 printf(i8* fmt, ...);

i32 main() {
    // std.fmt.str_len
    i32 l = std.fmt.str_len("hello");
    if (l != 5) { printf("FAIL std.fmt.str_len\n"); return 1; }
    if (std.fmt.str_len("") != 0) { printf("FAIL std.fmt.str_len empty\n"); return 2; }

    // std.fmt.str_eq
    if (!std.fmt.str_eq("abc", "abc")) { printf("FAIL std.fmt.str_eq true\n"); return 3; }
    if (std.fmt.str_eq("abc", "xyz")) { printf("FAIL std.fmt.str_eq false\n"); return 4; }
    if (std.fmt.str_eq("abc", "abcd")) { printf("FAIL std.fmt.str_eq length\n"); return 5; }

    // std.fmt.str_copy
    i8 buf[32];
    std.fmt.str_copy(buf, "world", (u64)32);
    if (!std.fmt.str_eq(buf, "world")) { printf("FAIL std.fmt.str_copy\n"); return 6; }

    // std.fmt.str_append
    std.fmt.str_copy(buf, "foo", (u64)32);
    std.fmt.str_append(buf, "bar", (u64)32);
    if (!std.fmt.str_eq(buf, "foobar")) { printf("FAIL std.fmt.str_append\n"); return 7; }

    // std.fmt.str_starts_with
    if (!std.fmt.str_starts_with("foobar", "foo")) { printf("FAIL std.fmt.str_starts_with true\n"); return 8; }
    if (std.fmt.str_starts_with("foobar", "bar")) { printf("FAIL std.fmt.str_starts_with false\n"); return 9; }

    // std.fmt.str_ends_with
    if (!std.fmt.str_ends_with("foobar", "bar")) { printf("FAIL std.fmt.str_ends_with true\n"); return 10; }
    if (std.fmt.str_ends_with("foobar", "foo")) { printf("FAIL std.fmt.str_ends_with false\n"); return 11; }

    // std.fmt.str_find
    i32 idx = std.fmt.str_find("foobar", "oba");
    if (idx != 2) { printf("FAIL std.fmt.str_find\n"); return 12; }
    i32 idx2 = std.fmt.str_find("foobar", "xyz");
    if (idx2 != -1) { printf("FAIL std.fmt.str_find not found\n"); return 13; }

    // std.fmt.str_to_i32
    i32 v = std.fmt.str_to_i32("-123");
    if (v != -123) { printf("FAIL std.fmt.str_to_i32\n"); return 14; }

    // std.fmt.str_to_i64
    i64 v2 = std.fmt.str_to_i64("9876543210");
    if (v2 != (i64)9876543210) { printf("FAIL std.fmt.str_to_i64\n"); return 15; }

    return 0;
}
