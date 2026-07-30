// Naive recursive Fibonacci — function-call overhead.
extern std.fmt;

fn fib(n: i32) i32 {
    if (n < 2) { return n; }
    return fib(n - 1) + fib(n - 2);
}

pub fn main() i32 {
    let mut r: i32= fib(35);
    std.fmt.out_print_i32(r);
    std.fmt.out_println("");
    return 0;
}
