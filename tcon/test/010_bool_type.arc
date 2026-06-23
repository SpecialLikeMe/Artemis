i32 main() {
    bool t = 1;
    bool f = 0;
    if (!t) { return 1; }
    if (f)  { return 2; }
    bool r = t && !f;
    if (!r) { return 3; }
    return 0;
}
