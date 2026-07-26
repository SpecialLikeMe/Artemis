istruc Base {
    let mut v: i32;
    virtual i32 f(const Base* self) { return self.v; }
}
istruc Sub : Base {
    public final i32 f(const Sub* self)  const override { return self.v + 1; }
}
fn main() i32 {
    let mut s: Sub;
    s.v = 10;
    if (s.f() != 11) { return 1; }
    return 0;
}
