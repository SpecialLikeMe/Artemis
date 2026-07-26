// Generic istruc with constructor and methods
istruc Pair<T> {
    let mut first: T;
    let mut second: T;

    fn __construct__(self: *Pair, a: T, b: T) void {
        self.first  = a;
        self.second = b;
    }

    fn sum(self: *const Pair) T { return self.first + self.second; }
    fn diff(self: *const Pair) T { return self.first - self.second; }
}

pub fn main() i32 {
    let mut p: Pair<i32>(10, 3);
    if (p.sum()  != 13) { return 1; }
    if (p.diff() != 7)  { return 2; }
    if (p.first  != 10) { return 3; }

    let mut q: Pair<i64>((i64)100, (i64)25);
    if (q.sum()  != 125) { return 4; }
    if (q.diff() != 75)  { return 5; }
    return 0;
}
