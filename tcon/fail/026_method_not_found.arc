// FAIL: calling a method that doesn't exist on a class
istruc Counter { let mut n: i32; }
fn main() i32 {
    let mut c: Counter;
    c.n = 0;
    c.increment();  // ERROR: no method 'increment'
    return c.n;
}
