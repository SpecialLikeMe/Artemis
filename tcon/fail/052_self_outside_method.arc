// FAIL: using 'self' outside a class method
fn main() i32 {
    let mut x: i32= self.value;  // ERROR: self is undefined here
    return x;
}
