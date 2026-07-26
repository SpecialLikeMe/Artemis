// Three-level inheritance: A -> B -> C
istruc A {
    let mut a: i32;
    fn __construct__(self: *A) void { self.a = 1; }
    fn get_a(self: *const A) i32 { return self.a; }
}

istruc B : A {
    let mut b: i32;
    fn __construct__(self: *B) void { self.a = 1; self.b = 2; }
    fn get_b(self: *const B) i32 { return self.b; }
}

istruc C : B {
    let mut c: i32;
    fn __construct__(self: *C) void { self.a = 1; self.b = 2; self.c = 3; }
    fn total(self: *const C) i32 { return self.a + self.b + self.c; }
}

fn main() i32 {
    let mut obj: C;
    if (obj.get_a() != 1)  { return 1; }
    if (obj.get_b() != 2)  { return 2; }
    if (obj.c       != 3)  { return 3; }
    if (obj.total() != 6)  { return 4; }
    return 0;
}
