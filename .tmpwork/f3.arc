@include <afmt.arc>
@unsafe extern fn printf(fmt: *const i8, ...) i32;
struct A2 { let a: *i8; let b: i32; }
pub @unsafe fn main() i32 {
    let mut buf: [256]i8;
    let mut args: A2;
    args.a = "hi"; args.b = 7;
    let mut flds: *type_info_field= (type_info_field*)0;
    let mut n: i32= afmt_v(buf, 256u, "x", (u8*)&args, flds, 0);
    printf("n=%d\n", n);
    return 0;
}
