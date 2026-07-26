// Match with or-patterns and guards
// PASS PASS PASS
@unsafe extern fn puts(s: *i8) i32;

fn check(n: i32) i32 {
    match (n) {
        1 | 2 | 3 => { return 1; }
        val @ 10..=20 if (val != 15) => { return 2; }
        _ => { return 0; }
    }
}

pub @unsafe fn main() i32 {
    if (check(1)  != 1) { return 1; }
    if (check(2)  != 1) { return 2; }
    if (check(3)  != 1) { return 3; }
    if (check(10) != 2) { return 4; }
    if (check(15) != 0) { return 5; }
    if (check(20) != 2) { return 6; }
    if (check(99) != 0) { return 7; }
    puts("PASS");
    return 0;
}
