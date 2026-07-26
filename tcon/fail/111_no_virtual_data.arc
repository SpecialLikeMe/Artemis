// virtual data member declared in base, stored in derived
istruc Base {
    virtual i32 tag;
}
istruc Child : Base {
    let mut tag: i32;
    fn __construct__(self: *Child, t: i32) void { self.tag = t; }
    fn get(self: *const Child) i32 { return self.tag; }
}

fn main() i32 {
    fn c(42) Child;
    if (c.get() != 42) { return 1; }
    if (c.tag   != 42) { return 2; }
    return 0;
}
