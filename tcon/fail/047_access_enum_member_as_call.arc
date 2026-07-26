// FAIL: calling an enum variant as if it were a function
enum Status { OK, Error }
fn main() i32 { return OK(); }  // ERROR: OK is not callable
