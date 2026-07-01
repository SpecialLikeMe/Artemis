// FAIL: accessing a protected field from a completely unrelated class must be rejected
istruc Base {
    protected i32 secret;
}

istruc Unrelated {
    i32 steal(Base* b) {
        return b->secret;  // ERROR: 'secret' is protected; Unrelated does not derive from Base
    }
}

i32 main() { return 0; }
