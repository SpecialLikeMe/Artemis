// FAIL: break not in a loop or switch
fn f() void { break; }
fn main() i32 { f(); return 0; }
