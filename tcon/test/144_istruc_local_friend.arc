// Verify that a regular function can access istruc fields via pointer
istruc Secret {
    let mut value: i32;

    fn __construct__(self: *Secret, v: i32) void {
        self.value = v;
    }

    fn get(self: *const Secret) i32 {
        return self.value;
    }
}

fn peek(s: *Secret) i32 {
    return (*s).get();
}

pub fn main() i32 {
    let mut s: Secret(77);
    if (s.get()  != 77) { return 1; }
    if (peek(&s) != 77) { return 2; }
    return 0;
}
