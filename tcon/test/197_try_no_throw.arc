// try block that does NOT throw — handler must not run
i32 main() {
    i32 x = 0;
    try {
        x = 10;
    } except (i32 e) {
        x = 99;
    }
    if (x != 10) { return 1; }
    return 0;
}
