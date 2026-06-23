@include <inc/helper.inc>

i32 main() {
    if (square(5) != 25) { return 1; }
    if (square(0) != 0)  { return 2; }
    if (square(3) != 9)  { return 3; }
    return 0;
}
