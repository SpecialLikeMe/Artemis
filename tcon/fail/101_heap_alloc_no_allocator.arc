// FAIL: top-level free function calls malloc without a &memstr allocator param.
// Expected: compile error about heap allocation without allocator.
extern fn malloc(n: u64) *void;

fn make_buffer(size: u64) *void {
    return malloc(size);  // error: no &memstr param
}

fn main() i32 {
    let mut p: *void= make_buffer(64);
    return 0;
}
