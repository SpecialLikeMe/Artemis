// FAIL: 'continue' used outside a loop must be rejected
fn main() i32 {
    continue;  // ERROR: continue outside loop
    return 0;
}
