// FAIL: 'override' used on a class with no base class must be rejected
istruc Lone {
    fn f(self: *const Lone) i32 override { return 1; }  // ERROR: override without base class
}

fn main() i32 { return 0; }
