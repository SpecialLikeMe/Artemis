let mut g_a: i32= 1;
let mut g_b: i32= 2;
let mut g_c: i32= 3;

fn sum_globals() i32 { return g_a + g_b + g_c; }

pub fn main() i32 {
    if (sum_globals() != 6) { return 1; }
    g_a = 10;
    g_b = 20;
    if (sum_globals() != 33) { return 2; }
    return 0;
}
