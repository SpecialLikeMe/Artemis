// Test: const_resolve macro — simple pattern substitution
// Verifies: single-capture expr rule expands and evaluates correctly.

extern i32 printf(i8* fmt, ...);

const_resolve double_it {
    ($x:expr) => { (($x) + ($x)) },
}

i32 main() {
    i32 val = double_it(21);
    if (val != 42) { return 1; }
    return 0;
}
