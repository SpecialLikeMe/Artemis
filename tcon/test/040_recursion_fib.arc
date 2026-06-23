i32 fib(i32 n) {
    if (n <= 1) { return n; }
    return fib(n - 1) + fib(n - 2);
}

i32 main() {
    if (fib(0)  != 0)  { return 1; }
    if (fib(1)  != 1)  { return 2; }
    if (fib(5)  != 5)  { return 3; }
    if (fib(10) != 55) { return 4; }
    return 0;
}
