// FAIL: accessing protected member from a function outside any class hierarchy
istruc Vault { protected i32 code; }
fn crack(v: *Vault) i32 { return v->code; }  // ERROR: code is protected
fn main() i32 { return 0; }
