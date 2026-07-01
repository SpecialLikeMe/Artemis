// FAIL: writing to a protected field from an unrelated context
istruc Base { protected i32 val; }
void corrupt(Base* b) { b->val = 99; }  // ERROR: val is protected
i32 main() { return 0; }
