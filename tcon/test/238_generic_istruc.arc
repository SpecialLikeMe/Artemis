// PASS: generic istruc (istruc Foo<T>) with multiple instantiations.
istruc Box<T> {
    let mut val: T;
    fn set(self: *Box<T>, v: T) void { self.val = v; }
    fn get(self: *Box<T>) T      { return self.val; }
}
pub fn main() i32 {
    let mut bi: Box<i32>;
    bi.set(42);
    if (bi.get() != 42) { return 1; }

    let mut bl: Box<i64>;
    bl.set((i64)1000000);
    if (bl.get() != (i64)1000000) { return 2; }

    return 0;
}
