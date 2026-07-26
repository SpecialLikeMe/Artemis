// Test: explicit self parameter — any name works, just pass pointer-to-class type
istruc Counter {
    let mut value: i32;

    fn __construct__(self: *Counter) void { self.value = 0; }

    fn increment(me: *Counter) void { me.value = me.value + 1; }
    fn add(c: *Counter, n: i32) void  { c.value = c.value + n; }

    fn get(reader: *const Counter) i32 { return reader.value; }

    fn reset(self: *Counter) void { self.value = 0; }
}

istruc Pair {
    let mut a: i32;
    let mut b: i32;

    fn sum(p: *const Pair) i32  { return p.a + p.b; }
    fn diff(p: *const Pair) i32 { return p.a - p.b; }
}

pub fn main() i32 {
    let mut c: Counter;
    c.increment();
    c.increment();
    if (c.get() != 2)  { return 1; }

    c.add(8);
    if (c.get() != 10) { return 2; }

    c.reset();
    if (c.get() != 0)  { return 3; }

    let mut p: Pair;
    p.a = 7;
    p.b = 3;
    if (p.sum()  != 10) { return 4; }
    if (p.diff() != 4)  { return 5; }

    return 0;
}
