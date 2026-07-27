@include <afmt.arc>
@unsafe extern fn printf(fmt: *const i8, ...) i32;
pub @unsafe fn main() i32 { printf("ok\n"); return 0; }
