// FAIL: inheriting from an undeclared base class must be rejected
istruc Child : Nonexistent {  // ERROR: 'Nonexistent' is not a known class
    i32 x;
}

i32 main() { return 0; }
