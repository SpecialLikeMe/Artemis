i32 is_even(i32 n);
i32 is_odd(i32 n);

i32 is_even(i32 n) {
    if (n == 0) { return 1; }
    return is_odd(n - 1);
}
i32 is_odd(i32 n) {
    if (n == 0) { return 0; }
    return is_even(n - 1);
}

i32 main() {
    if (!is_even(4))  { return 1; }
    if (!is_odd(3))   { return 2; }
    if (is_even(7))   { return 3; }
    if (is_odd(8))    { return 4; }
    return 0;
}
