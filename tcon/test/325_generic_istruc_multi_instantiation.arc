// Test: two instantiations of the same generic istruc get distinct layouts.
// Regression: the monomorphization key was built from the source spelling of the
// type argument. Inside Box's own methods `self: *Box<T>` spells its argument as
// "T" for every instantiation, so Box<i32> and Box<f64> produced the same key and
// the second silently reused the first one's struct — the method then returned a
// double from a function declared to return i32.
@unsafe extern fn printf(fmt: *i8, ...) i32;

istruc Box<T> {
    let mut v: T;
    fn get(self: *Box<T>) T { return self.v; }
    fn set(self: *Box<T>, nv: T) void { self.v = nv; }
}

istruc Pair<A, B> {
    let mut a: A;
    let mut b: B;
    fn first(self: *Pair<A, B>) A { return self.a; }
}

pub fn main() i32 {
    let mut bi: Box<i32>;
    bi.set(42);
    let mut bf: Box<f64>;
    bf.set(2.5);
    let mut bc: Box<i8>;
    bc.set('z');

    if (bi.get() != 42)   { return 1; }
    if (bf.get() < 2.49 || bf.get() > 2.51) { return 2; }
    if (bc.get() != 'z')  { return 3; }

    // Multi-parameter generics must key on both arguments.
    let mut p1: Pair<i32, f64>;
    p1.a = 7; p1.b = 1.5;
    let mut p2: Pair<f64, i32>;
    p2.a = 3.5; p2.b = 9;
    if (p1.first() != 7) { return 4; }
    if (p2.first() < 3.49 || p2.first() > 3.51) { return 5; }

    return 0;
}
