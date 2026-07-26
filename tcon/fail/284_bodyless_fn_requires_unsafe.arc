// FAIL: a bodyless declaration with no definition in the program is foreign.
fn puts(s: *const i8) i32;
pub fn main() i32 { return 0; }
