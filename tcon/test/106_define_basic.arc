@define <ANSWER> <42>
@define <ONE> <1>

i32 main() {
    i32 x = ANSWER;
    i32 y = ONE;
    if (x != 42) { return 1; }
    if (y != 1)  { return 2; }
    return 0;
}
