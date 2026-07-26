// Match with binding patterns (name @ range)
// PASS PASS PASS
fn puts(s: *i8) i32;

fn double_if_in_range(n: i32) i32 {
    match (n) {
        val @ 1..=10 => { return val * 2; }
        _ => { return 0; }
    }
}

pub fn main() i32 {
    if (double_if_in_range(5)  != 10) { return 1; }
    if (double_if_in_range(10) != 20) { return 2; }
    if (double_if_in_range(11) != 0)  { return 3; }
    puts("PASS");
    return 0;
}
