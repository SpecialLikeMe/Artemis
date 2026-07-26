// FAIL: declarations in an extern "C" block are foreign and must be marked @unsafe.
extern "C" {
fn abs(x: i32) i32;
}
pub fn main() i32 { return 0; }
