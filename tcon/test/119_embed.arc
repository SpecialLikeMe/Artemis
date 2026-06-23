@embed <inc/embed_code.inc>

i32 main() {
    if (cube(3) != 27) { return 1; }
    if (cube(2) != 8)  { return 2; }
    if (cube(0) != 0)  { return 3; }
    return 0;
}
