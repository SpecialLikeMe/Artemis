// FAIL: 'break' used outside a loop or switch must be rejected
fn main() i32 {
    let mut x: i32= 0;
    break;  // ERROR: break outside loop/switch
    return x;
}
