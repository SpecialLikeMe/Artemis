// FAIL: member access on a primitive type
i32 main() {
    i32 x = 5;
    i32 y = x.value;  // ERROR: i32 has no members
    return y;
}
