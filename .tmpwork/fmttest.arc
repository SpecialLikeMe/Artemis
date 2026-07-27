@include <afmt.arc>
@unsafe extern fn printf(fmt: *const i8, ...) i32;

struct A2 { let a: *i8; let b: i32; }

pub @unsafe fn main() i32 {
    let mut buf: [256]i8;
    let mut args: A2;
    args.a = "hello";
    args.b = 42;
    let mut ti: *type_info= @typeinfo(A2);
    match (*ti) {
        type_info::Struct(nm, flds, fc, sz, al, tup, pk) => {
            let mut n: i32= afmt_v(buf, 256u, "s=%s d=%d done", (u8*)&args, flds, (i32)fc);
            printf("[%s] len=%d\n", buf, n);
        },
        _ => { printf("no typeinfo\n"); return 1; },
    }
    return 0;
}
