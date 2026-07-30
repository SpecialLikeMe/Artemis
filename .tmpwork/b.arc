@unsafe extern fn printf(f: *i8, ...) i32;
struct Named { let a: *i8; let b: i32; }
fn g(p: Named) void { let mut ti: *type_info= @typeinfo(@typeof(p)); @unsafe { printf("t=%d\n", ti.__tag); } }
pub fn main() i32 { let mut v: Named; g(v); return 0; }
