// FAIL: derived class cannot access private members of base
istruc Base { private i32 secret; }
istruc Child : Base {
    i32 steal(const Child* self) { return self.secret; }  // ERROR: secret is private
}
i32 main() { return 0; }
