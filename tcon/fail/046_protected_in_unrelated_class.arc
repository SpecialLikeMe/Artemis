// FAIL: istruc method accessing protected member of an unrelated class
istruc A { protected i32 val; }
istruc B {
    fn steal(a: *A) i32 { return a->val; }  // ERROR: B does not inherit A
}
fn main() i32 { return 0; }
