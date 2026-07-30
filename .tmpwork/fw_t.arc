@include <afmt_inc.arc>
@unsafe extern fn printf(f: *i8, ...) i32;
fn fwd(fmt: *i8, args: anytype) i32 {
    let mut b: [64]i8;
    let mut ti: *type_info= @typeinfo(@typeof(args));
    @unsafe { printf("  inside fwd: tag=%d fmt=[%s]\n", ti.__tag, fmt); }
    let mut n: i32= afmt(b, 64u, fmt, args);
    @unsafe { printf("  inner afmt -> %d [%s]\n", n, b); }
    return n;
}
pub fn main() i32 {
    let mut n: i32= 7;
    fwd("x=%d", .{ n });
    return 0;
}
