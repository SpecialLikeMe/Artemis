// FAIL: static method call via dot on an undeclared class
fn main() i32 { return Phantom.compute(); }  // ERROR: Phantom undeclared
