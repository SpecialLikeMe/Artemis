// FAIL: 'mandatory' without 'virtual' must be rejected
istruc Broken {
    mandatory i32 f(const Broken* self) { return 0; }  // ERROR: mandatory requires virtual
}

fn main() i32 { return 0; }
