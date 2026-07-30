@unsafe extern fn printf(f: *i8, ...) i32;
struct Named { let a: *i8; let b: i32; }
fn probe_any(args: anytype) i32 {
    let mut ti: *type_info= @typeinfo(@typeof(args));
    @unsafe { printf("anytype tag=%d\n", ti.__tag); }
    return 0;
}
fn probe_named(args: Named) i32 {
    let mut ti: *type_info= @typeinfo(@typeof(args));
    @unsafe { printf("named   tag=%d\n", ti.__tag); }
    return 0;
}
pub fn main() i32 {
    let mut n: i32= 42;
    let mut ti2: *type_info= @typeinfo(Named);
    @unsafe { printf("direct  tag=%d\n", ti2.__tag); }
    probe_named(.{ "hi", n });
    probe_any(.{ "hi", n });
    probe_any(n);
    return 0;
}
