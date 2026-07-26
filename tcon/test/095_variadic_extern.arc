@unsafe extern fn sprintf(buf: *i8, fmt: *const i8, ...) i32;

pub @unsafe fn main() i32 {
    let mut buf: [32]i8;
    let mut n: i32= sprintf(buf, "%d", 12345);
    if (n != 5) { return 1; }
    return 0;
}
