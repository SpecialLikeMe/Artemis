@unsafe extern fn printf(f: *i8, ...) i32;
struct Named { let a: *i8; let b: i32; }
fn f_param(p: Named) void {
    let mut ti: *type_info= @typeinfo(@typeof(p));
    @unsafe { printf("named param: tag=%d csizeof=%d\n", ti.__tag, (i32)@csizeof(@typeof(p))); }
}
fn f_any(p: anytype) void {
    let mut ti: *type_info= @typeinfo(@typeof(p));
    @unsafe { printf("anytype    : tag=%d csizeof=%d\n", ti.__tag, (i32)@csizeof(@typeof(p))); }
}
pub fn main() i32 {
    let mut v: Named;
    f_param(v);
    f_any(v);
    let mut n: i32= 1;
    f_any(.{ "x", n });
    return 0;
}
