@unsafe extern fn printf(f: *i8, ...) i32;
struct Named { let a: *i8; let b: i32; }
fn f_param(p: Named) void {
    let mut t1: *type_info= @typeinfo(@typeof(p));
    @unsafe { printf("param        tag=%d\n", t1.__tag); }
}
fn f_local() void {
    let mut lv: Named;
    let mut t2: *type_info= @typeinfo(@typeof(lv));
    @unsafe { printf("local        tag=%d\n", t2.__tag); }
    let mut i: i32= 1;
    let mut t3: *type_info= @typeinfo(@typeof(i));
    @unsafe { printf("local i32    tag=%d\n", t3.__tag); }
}
fn f_param_i(x: i32) void {
    let mut t4: *type_info= @typeinfo(@typeof(x));
    @unsafe { printf("param i32    tag=%d\n", t4.__tag); }
}
pub fn main() i32 { let mut v: Named; f_param(v); f_local(); f_param_i(3); return 0; }
