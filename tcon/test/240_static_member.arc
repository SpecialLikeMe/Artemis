// Test static istruc member: belongs to the type, not any instance
// PASS PASS PASS PASS
@unsafe extern fn puts(s: *i8) int;

istruc Counter {
    let mut count: int;
    static let mut total: int;
    fn add(self: *Counter, n: int) void {
        self.count = self.count + n;
        Counter__static_total = Counter__static_total + n;
    }
}

pub @unsafe fn main() int {
    let mut a: Counter;
    let mut b: Counter;
    a.count = 0;
    b.count = 0;
    Counter__static_total = 0;

    a.add(5);
    b.add(3);

    if (Counter__static_total == 8)  { puts("PASS"); } else { puts("FAIL total"); }
    if (a.count == 5)                { puts("PASS"); } else { puts("FAIL a"); }
    if (b.count == 3)                { puts("PASS"); } else { puts("FAIL b"); }

    // Instance counts are independent
    a.add(10);
    if (a.count == 15 && b.count == 3) { puts("PASS"); } else { puts("FAIL independent"); }

    return 0;
}
