@unsafe extern fn printf(f: *i8, ...) i32;
fn shape(args: anytype) i32 { return (i32)@csizeof(@typeof(args)); }
pub fn main() i32 {
    let mut n: i32= 42;
    let mut a: i32= shape(.{ "hi", n });
    @unsafe { printf("sz=%d\n", a); }
    return 0;
}
