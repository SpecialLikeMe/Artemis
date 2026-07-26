// FAIL: derived class cannot access private members of base
istruc Base { private i32 secret; }
istruc Child : Base {
    fn steal(self: *const Child) i32 { return self.secret; }  // ERROR: secret is private
}
fn main() i32 { return 0; }
