enum Color { Red, Green, Blue }

i32 main() {
    i32 c = Red;
    if (c != 0)   { return 1; }
    c = Green;
    if (c != 1)   { return 2; }
    c = Blue;
    if (c != 2)   { return 3; }
    return 0;
}
