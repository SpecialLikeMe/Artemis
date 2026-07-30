@unsafe extern fn printf(f: *i8, ...) i32;
fn shape(args: anytype) i32 { return (i32)@csizeof(@typeof(args)); }
pub fn main() i32 {
    let mut n: i32= 42;
    @unsafe { printf("sz2=%d sz3=%d\n", shape(.{ "hi", n }), shape(.{ "a", n, (i64)1 })); }
    return 0;
}
