// FAIL: inheriting from an undeclared base class must be rejected
istruc Child : Nonexistent {  // ERROR: 'Nonexistent' is not a known class
    let mut x: i32;
}

fn main() i32 { return 0; }
