i32 main() {
    i32 caught = 0;
    try {
        throw (i32)42;
    } except (i32 e) {
        caught = e;
    }
    if (caught != 42) { return 1; }
    return 0;
}
