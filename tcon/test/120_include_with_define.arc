@define <MULT> <3>
@include <inc/use_define.inc>

i32 main() {
    if (triple(4) != 12) { return 1; }
    if (triple(0) != 0)  { return 2; }
    if (triple(7) != 21) { return 3; }
    return 0;
}
