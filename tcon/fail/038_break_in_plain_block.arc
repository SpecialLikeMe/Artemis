// FAIL: break used in a plain block (not a loop or switch)
fn main() i32 {
    let mut x: i32= 0;
    {
        x = 1;
        break;  // ERROR: not in a loop or switch
    }
    return x;
}
