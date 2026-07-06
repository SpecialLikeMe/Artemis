// FAIL: free function overloading is not supported
i32 compute(i32 a) { return a; }
i32 compute(i32 a, i32 b) { return a + b; }  // must error: same name, different sig

i32 main() { return compute(1); }
