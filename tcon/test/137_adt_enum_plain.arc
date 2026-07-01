// 137: ADT enum — plain variant (C-style tag only)
enum color {
    red,
    green,
    blue,
}

i32 main() {
    i32 c = color::green;
    if (c != color::green) { return 1; }
    if (c == color::red)   { return 2; }
    return 0;
}
