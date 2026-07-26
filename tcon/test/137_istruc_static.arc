istruc Counter {
    let mut value: i32;

    fn __construct__(self: *Counter, v: i32) void {
        self.value = v;
    }

    static fn zero() i32 {
        return 0;
    }

    static fn add(a: i32, b: i32) i32 {
        return a + b;
    }

    fn get(self: *const Counter) i32 {
        return self.value;
    }

    fn inc(self: *Counter) void {
        self.value = self.value + 1;
    }
}

pub fn main() i32 {
    if (Counter.zero()     != 0)  { return 1; }
    if (Counter.add(3, 4)  != 7)  { return 2; }
    if (Counter.add(10, 5) != 15) { return 3; }

    let mut c: Counter(10);
    c.inc();
    if (c.get() != 11) { return 4; }

    return 0;
}
