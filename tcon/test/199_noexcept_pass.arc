//  functions that contain no try/res/error-union return compile and run
fn add(a: i32, b: i32) i32  { return a + b; }
fn noop() void  { return; }

pub fn main() i32 {
    if (add(10, 32) != 42) { return 1; }
    noop();
    return 0;
}
