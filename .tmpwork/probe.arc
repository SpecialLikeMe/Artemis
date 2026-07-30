extern std.fmt;
let mut g_arr: [1000000]i32;
fn work(n: i32) f64 {
    let mut s: f64= 0.0;
    let mut i: i32= 0;
    while (i < n) { s = s + (f64)i * 1.5; i = i + 1; }
    return s;
}
fn fib(n: i32) i32 { if (n < 2) { return n; } return fib(n-1) + fib(n-2); }
pub fn main() i32 {
    g_arr[999999] = 7;
    let mut d: f64= work(1000);
    let mut f: i32= fib(20);
    std.fmt.out_print_f64(d); std.fmt.out_print(" ");
    std.fmt.out_print_i32(f); std.fmt.out_print(" ");
    std.fmt.out_print_i32(g_arr[999999]); std.fmt.out_println("");
    return 0;
}
