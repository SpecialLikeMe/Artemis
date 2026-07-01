// FAIL: 'mandatory' keyword without 'virtual'
istruc Bad {
    mandatory i32 f(&const self) { return 0; }  // ERROR: mandatory requires virtual
}
i32 main() { return 0; }
