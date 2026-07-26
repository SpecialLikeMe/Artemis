// FAIL: accessing a protected field from a completely unrelated class must be rejected
istruc Base {
    protected i32 secret;
}

istruc Unrelated {
    fn steal(b: *Base) i32 {
        return b->secret;  // ERROR: 'secret' is protected; Unrelated does not derive from Base
    }
}

fn main() i32 { return 0; }
