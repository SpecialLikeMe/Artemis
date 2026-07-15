// Static local variables: persist across function calls
i32 counter() {
    static i32 count = 0;
    count = count + 1;
    return count;
}

i32 fib_memo(i32 n) {
    // Static locals in different functions are independent
    static i32 last_n = -1;
    static i32 last_result = 0;
    if (n == last_n) { return last_result; }
    i32 r = 0;
    if (n <= 1) { r = n; }
    else { r = fib_memo(n - 1) + fib_memo(n - 2); }
    last_n = n;
    last_result = r;
    return r;
}

i32 main() {
    // counter() should increment each call
    if (counter() != 1) { return 1; }
    if (counter() != 2) { return 2; }
    if (counter() != 3) { return 3; }

    // static local initialized only once even after multiple calls
    if (fib_memo(10) != 55) { return 4; }
    if (fib_memo(10) != 55) { return 5; }
    if (fib_memo(7)  != 13) { return 6; }

    return 0;
}
