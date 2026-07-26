// FAIL: function return type is an undeclared type name
fn foo() Zork { return 0; }  // ERROR: Zork undeclared
fn main() i32 { return 0; }
