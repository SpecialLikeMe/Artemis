// FAIL: break inside a function body (even if that function is called from a loop)
fn inner() void { break; }  // ERROR: break not in a loop or switch
fn main() i32 {
    for (let mut i: i32 = 0; i < 5; i = i + 1) inner();
    return 0;
}
