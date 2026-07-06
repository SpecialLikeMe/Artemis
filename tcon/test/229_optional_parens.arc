// Test: optional parentheses around conditions for if/while/for/switch.

i32 main() {
    i32 x = 0;

    // if without parens
    if x == 0 { x = 1; }
    if (x != 1) { return 1; }

    // while without parens
    i32 i = 0;
    while i < 3 { i = i + 1; }
    if (i != 3) { return 2; }

    // for without parens (classic form)
    i32 sum = 0;
    for i = 0; i < 4; i = i + 1 { sum = sum + i; }
    if (sum != 6) { return 3; }

    // switch without parens
    i32 r = 0;
    switch x {
        case 1: r = 10; break;
        default: r = 0;
    }
    if (r != 10) { return 4; }

    return 0;
}
