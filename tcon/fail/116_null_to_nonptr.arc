// FAIL: null is not assignable to a plain non-nullable, non-pointer type
i32 main() {
    i32 x = null;  // must error: i32 is neither a pointer nor nullable
    return x;
}
