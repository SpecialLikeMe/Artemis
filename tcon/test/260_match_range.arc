// Match with range patterns (inclusive and exclusive)
// PASS PASS PASS
fn puts(s: *i8) i32;

fn classify(n: i32) i32 {
    match (n) {
        0..10   => { return 1; }
        10..=20 => { return 2; }
        _       => { return 3; }
    }
}

pub fn main() i32 {
    if (classify(0)  != 1) { return 1; }
    if (classify(5)  != 1) { return 2; }
    if (classify(9)  != 1) { return 3; }
    if (classify(10) != 2) { return 4; }
    if (classify(20) != 2) { return 5; }
    if (classify(21) != 3) { return 6; }
    puts("PASS");
    return 0;
}
