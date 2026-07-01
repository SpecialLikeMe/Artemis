// FAIL: istruc method accessing protected member of an unrelated class
istruc A { protected i32 val; }
istruc B {
    i32 steal(A* a) { return a->val; }  // ERROR: B does not inherit A
}
i32 main() { return 0; }
