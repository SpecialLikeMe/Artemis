// PASS: derive proc macro — declared as derive function, applied via #derive[name]
// The macro is a pass-through; the decorated istruc compiles and runs normally.

fn add_default(&memstr alloc, tokenstream* input) *tokenstream derive {
    return input;
}

#derive[add_default]
istruc Counter {
    let mut count: i32;
    fn __construct__(self: *Counter) void { self.count = 0; }
    fn inc(self: *Counter) void { self.count = self.count + 1; }
    fn get(self: *Counter) i32 { return self.count; }
}

pub fn main() i32 {
    let mut c: Counter();
    c.inc();
    c.inc();
    c.inc();
    if (c.get() != 3) { return 1; }
    return 0;
}
