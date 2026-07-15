// Test basic lambda expressions
int puts(i8* s);
int printf(i8* fmt, i32 x);

int main() {
    // Lambda with no captures — immediate invoke
    int result = [](int x) int { return x * 2; }(21);
    if (result == 42) { puts("PASS"); } else { puts("FAIL"); }

    // Lambda stored and called later
    auto double_it = [](int x) int { return x * 2; };
    if (double_it(10) == 20) { puts("PASS"); } else { puts("FAIL"); }

    // Lambda with by-value capture
    int base = 100;
    auto add_base = [=](int x) int { return base + x; };
    if (add_base(5) == 105) { puts("PASS"); } else { puts("FAIL"); }

    // Lambda with by-ref capture — modifies outer variable
    int counter = 0;
    auto inc = [&]() void { counter = counter + 1; };
    inc();
    inc();
    inc();
    if (counter == 3) { puts("PASS"); } else { puts("FAIL"); }

    return 0;
}
