// Test: std.fmt — buffer formatting (std.fmt.fmt_i32/i64/u32/u64/hex)
extern  std.fmt;
@unsafe extern fn printf(fmt: *i8, ...) i32;

pub @unsafe fn main() i32 {
    let mut buf: [64]i8;

    // std.fmt.fmt_i32
    let mut n: i32= std.fmt.fmt_i32(buf, (u64)64, 42);
    if (n != 2) { printf("FAIL std.fmt.fmt_i32 len\n"); return 1; }
    if (buf[0] != '4' || buf[1] != '2') { printf("FAIL std.fmt.fmt_i32 val\n"); return 2; }

    // std.fmt.fmt_i64 negative
    let mut n2: i32= std.fmt.fmt_i64(buf, (u64)64, (i64)-999);
    if (n2 != 4) { printf("FAIL std.fmt.fmt_i64 len\n"); return 3; }
    if (buf[0] != '-') { printf("FAIL std.fmt.fmt_i64 sign\n"); return 4; }

    // std.fmt.fmt_u32 zero
    std.fmt.fmt_u32(buf, (u64)64, 0u);
    if (buf[0] != '0') { printf("FAIL std.fmt.fmt_u32 zero\n"); return 5; }

    // std.fmt.fmt_hex prefix
    std.fmt.fmt_hex(buf, (u64)64, (u64)255);
    if (buf[0] != '0' || buf[1] != 'x') { printf("FAIL std.fmt.fmt_hex prefix\n"); return 6; }

    // std.fmt.out_print and std.fmt.out_println don't crash
    std.fmt.out_print("test ");
    std.fmt.out_println("ok");

    return 0;
}
