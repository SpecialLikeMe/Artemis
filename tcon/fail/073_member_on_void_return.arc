// FAIL: member access on a void-returning function call
void noop() { return; }
i32 main() {
    i32 x = noop().field;  // ERROR: void has no members
    return x;
}
