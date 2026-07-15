// PASS: attribute proc macro — declared as attr function, applied via #[name]
// The macro is a pass-through (returns input unchanged); the decorated function
// compiles and runs normally.

tokenstream* log_calls(&memstr alloc, tokenstream* input) attr {
    return input;
}

tokenstream* mark_pure(&memstr alloc, tokenstream* input) attr verify {
    return input;
}

#[log_calls]
i32 add(i32 a, i32 b) {
    return a + b;
}

#[mark_pure]
i32 mul(i32 a, i32 b) {
    return a * b;
}

i32 main() {
    if (add(2, 3) != 5)  { return 1; }
    if (mul(4, 5) != 20) { return 2; }
    return 0;
}
