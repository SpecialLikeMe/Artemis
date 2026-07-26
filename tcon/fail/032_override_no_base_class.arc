// FAIL: 'override' in a class with no base class
istruc Lone {
    fn f(self: *const Lone) i32 override { return 1; }  // ERROR: no base to override
}
fn main() i32 { return 0; }
