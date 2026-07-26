// FAIL: using a variable declared in an inner scope from an outer scope
fn main() i32 {
    { let mut inner: i32= 5; }
    return inner;  // ERROR: inner is out of scope
}
