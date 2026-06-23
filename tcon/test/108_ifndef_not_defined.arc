@ifndef MISSING_FLAG
i32 value() { return 9; }
@endif

i32 main() {
    if (value() != 9) { return 1; }
    return 0;
}
