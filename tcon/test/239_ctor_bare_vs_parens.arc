// Test bare declaration vs explicit constructor call
// PASS PASS PASS PASS
@unsafe extern fn puts(s: *i8) int;

istruc Counter {
    let mut count: int;
    fn __construct__(self: *Counter) void {
        self.count = 999;
    }
}

istruc WithArg {
    let mut val: int;
    fn __construct__(self: *WithArg, v: int) void {
        self.val = v * 2;
    }
}

pub @unsafe fn main() int {
    // Bare declaration: constructor must NOT be called
    let mut b: Counter;
    if (b.count == 0) { puts("PASS"); } else { puts("FAIL bare no ctor"); }

    // Explicit no-arg ctor call: constructor MUST be called
    let mut c: Counter();
    if (c.count == 999) { puts("PASS"); } else { puts("FAIL parens ctor"); }

    // Ctor with arg
    let mut w: WithArg(21);
    if (w.val == 42) { puts("PASS"); } else { puts("FAIL arg ctor"); }

    // Bare decl of struct with arg ctor: no ctor call
    let mut x: WithArg;
    if (x.val == 0) { puts("PASS"); } else { puts("FAIL bare arg no ctor"); }

    return 0;
}
