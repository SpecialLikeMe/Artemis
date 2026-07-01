// FAIL: accessing protected member from a function outside any class hierarchy
istruc Vault { protected i32 code; }
i32 crack(Vault* v) { return v->code; }  // ERROR: code is protected
i32 main() { return 0; }
