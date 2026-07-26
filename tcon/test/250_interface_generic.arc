// PASS: generic interface — interface with type parameter, concrete istruc implementing it
interface Getter<T> {
    fn get() T;
}

istruc IntGetter : Getter<i32> {
    let mut val: i32;
    fn __construct__(self: *IntGetter, v: i32) void { self.val = v; }
    fn get(self: *IntGetter) i32 { return self.val; }
}

istruc StrGetter : Getter<i8*> {
    let mut s: *i8;
    fn __construct__(self: *StrGetter, v: *i8) void { self.s = v; }
    fn get(self: *StrGetter) *i8 { return self.s; }
}

pub fn main() i32 {
    let mut ig: IntGetter(42);
    if (ig.get() != 42) { return 1; }

    let mut sg: StrGetter("hello");
    if (sg.get() == (i8*)0) { return 2; }

    return 0;
}
