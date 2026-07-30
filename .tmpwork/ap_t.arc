@include <afmt_inc.arc>
@unsafe extern fn printf(f: *i8, ...) i32;
pub fn main() i32 {
    let mut n: i32= 7;
    let mut r: i32= aprint("hello %s %d\n", .{ "world", n });
    @unsafe { printf("aprint returned %d\n", r); }
    let mut b: [64]i8;
    let mut m: i32= afmt(b, 64u, "hello %s %d\n", .{ "world", n });
    @unsafe { printf("afmt returned %d [%s]\n", m, b); }
    return 0;
}
