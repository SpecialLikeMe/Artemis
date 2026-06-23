@define <WIDTH> <8>
@define <HEIGHT> <4>

i32 area() { return WIDTH * HEIGHT; }

i32 main() {
    if (area() != 32) { return 1; }
    i32 w = WIDTH;
    i32 h = HEIGHT;
    if (w != 8) { return 2; }
    if (h != 4) { return 3; }
    return 0;
}
