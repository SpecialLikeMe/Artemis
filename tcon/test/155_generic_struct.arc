istruc Box<T> {
    T value;
}
i32 main() {
    Box<i32> b;
    b.value = 77;
    if (b.value != 77) { return 1; }
    return 0;
}
