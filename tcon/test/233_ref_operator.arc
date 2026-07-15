// Test the `ref` operator — context-aware address-of
// PASS PASS PASS PASS
int puts(i8* s);
int printf(i8* fmt, ...);

int main() {
    // ref on lvalue: p = &x
    int x = 42;
    int* p = ref x;
    if (*p == 42) { puts("PASS"); } else { puts("FAIL ref basic"); }

    // Writing through ref affects original
    *p = 100;
    if (x == 100) { puts("PASS"); } else { puts("FAIL ref write-through"); }

    // ref on rvalue → allocates a temp
    int* q = ref 77;
    if (*q == 77) { puts("PASS"); } else { puts("FAIL ref rvalue"); }

    // ref on expression result
    int a = 5;
    int b = 6;
    int* r = ref a;
    if (*r == 5) { puts("PASS"); } else { puts("FAIL ref expr"); }

    return 0;
}
