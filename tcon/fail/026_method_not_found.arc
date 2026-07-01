// FAIL: calling a method that doesn't exist on a class
istruc Counter { i32 n; }
i32 main() {
    Counter c;
    c.n = 0;
    c.increment();  // ERROR: no method 'increment'
    return c.n;
}
