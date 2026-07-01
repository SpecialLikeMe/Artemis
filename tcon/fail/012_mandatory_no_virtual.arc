// FAIL: 'mandatory' without 'virtual' must be rejected
istruc Broken {
    mandatory i32 f(&const self) { return 0; }  // ERROR: mandatory requires virtual
}

i32 main() { return 0; }
