// Test: std.fmt — buffer formatting (fmt::fmt_i32/i64/u32/u64/hex)
extern std.fmt;
extern i32 printf(i8* fmt, ...);

i32 main() {
    i8 buf[64];

    // fmt::fmt_i32
    i32 n = fmt::fmt_i32(buf, (u64)64, 42);
    if (n != 2) { printf("FAIL fmt::fmt_i32 len\n"); return 1; }
    if (buf[0] != '4' || buf[1] != '2') { printf("FAIL fmt::fmt_i32 val\n"); return 2; }

    // fmt::fmt_i64 negative
    i32 n2 = fmt::fmt_i64(buf, (u64)64, (i64)-999);
    if (n2 != 4) { printf("FAIL fmt::fmt_i64 len\n"); return 3; }
    if (buf[0] != '-') { printf("FAIL fmt::fmt_i64 sign\n"); return 4; }

    // fmt::fmt_u32 zero
    fmt::fmt_u32(buf, (u64)64, 0u);
    if (buf[0] != '0') { printf("FAIL fmt::fmt_u32 zero\n"); return 5; }

    // fmt::fmt_hex prefix
    fmt::fmt_hex(buf, (u64)64, (u64)255);
    if (buf[0] != '0' || buf[1] != 'x') { printf("FAIL fmt::fmt_hex prefix\n"); return 6; }

    // fmt::out_print and fmt::out_println don't crash
    fmt::out_print("test ");
    fmt::out_println("ok");

    return 0;
}
