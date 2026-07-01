// nested try: inner throw caught by inner except
i32 main() {
    i32 outer = 0;
    i32 inner = 0;
    try {
        outer = 1;
        try {
            throw (i32)7;
        } except (i32 e) {
            inner = e;
        }
        outer = 2;
    } except (i32 e) {
        outer = 99;
    }
    if (inner != 7) { return 1; }
    if (outer != 2) { return 2; }
    return 0;
}
