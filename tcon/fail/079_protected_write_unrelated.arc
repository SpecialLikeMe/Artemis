// FAIL: writing to a protected field from an unrelated context
istruc Base { protected i32 val; }
fn corrupt(b: *Base) void { b->val = 99; }  // ERROR: val is protected
fn main() i32 { return 0; }
