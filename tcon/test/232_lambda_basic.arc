// Test basic lambda expressions
@unsafe extern fn puts(s: *i8) int;
@unsafe extern fn printf(fmt: *i8, x: i32) int;

pub @unsafe fn main() int {
    // Lambda with no captures — immediate invoke
    let mut result: int= [](int x) int { return x * 2; }(21);
    if (result == 42) { puts("PASS"); } else { puts("FAIL"); }

    // Lambda stored and called later
    let mut double_it= [](int x) int { return x * 2; };
    if (double_it(10) == 20) { puts("PASS"); } else { puts("FAIL"); }

    // Lambda with by-value capture
    let mut base: int= 100;
    let mut add_base= [=](int x) int { return base + x; };
    if (add_base(5) == 105) { puts("PASS"); } else { puts("FAIL"); }

    // Lambda with by-ref capture — modifies outer variable
    let mut counter: int= 0;
    let mut inc= [&]() void { counter = counter + 1; };
    inc();
    inc();
    inc();
    if (counter == 3) { puts("PASS"); } else { puts("FAIL"); }

    return 0;
}
