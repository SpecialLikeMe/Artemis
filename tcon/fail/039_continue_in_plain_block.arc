// FAIL: continue used in a plain block (not a loop)
fn main() i32 {
    let mut x: i32= 0;
    {
        x = 1;
        continue;  // ERROR: not in a loop
    }
    return x;
}
