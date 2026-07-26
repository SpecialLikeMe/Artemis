// PASS: extended static member tests — static fields and static methods on istruc
istruc Counter {
    static let mut total: i32;
    let mut n: i32;
    fn __construct__(self: *Counter, v: i32) void {
        self.n = v;
        Counter.total = Counter.total + 1;
    }
    static fn get_total() i32 { return Counter.total; }
    fn get(self: *Counter) i32 { return self.n; }
}

pub fn main() i32 {
    let mut c: Counter(10);
    let mut d: Counter(20);
    if (Counter.total != 2)         { return 1; }
    if (Counter.get_total() != 2)   { return 2; }
    if (c.get() != 10)              { return 3; }
    if (d.get() != 20)              { return 4; }
    // Static field is shared across instances
    Counter.total = 0;
    if (Counter.get_total() != 0)   { return 5; }
    return 0;
}
