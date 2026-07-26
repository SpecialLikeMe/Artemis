// Basic match with literal patterns and wildcard
// PASS PASS PASS
@unsafe extern fn puts(s: *i8) i32;

fn describe(x: i32) i32 {
    match (x) {
        1 => { return 10; }
        2 => { return 20; }
        _ => { return 99; }
    }
}

pub @unsafe fn main() i32 {
    if (describe(1) != 10) { return 1; }
    if (describe(2) != 20) { return 2; }
    if (describe(7) != 99) { return 3; }
    puts("PASS");
    return 0;
}
