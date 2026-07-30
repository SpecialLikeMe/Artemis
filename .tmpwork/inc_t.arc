@include <__afmt_test.arc>
@unsafe extern fn printf(f: *i8, ...) i32;
pub fn main() i32 {
    let mut b: [64]i8;
    let mut n: i32= afmt_v(b, 64u, "hello", (u8*)0, (type_info_field*)0, 0);
    @unsafe { printf("afmt_v -> %d [%s]\n", n, b); }
    return 0;
}
