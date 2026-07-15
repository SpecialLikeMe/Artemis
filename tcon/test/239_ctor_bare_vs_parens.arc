// Test bare declaration vs explicit constructor call
// PASS PASS PASS PASS
int puts(i8* s);

istruc Counter {
    int count;
    void __construct__(Counter* self) {
        self.count = 999;
    }
}

istruc WithArg {
    int val;
    void __construct__(WithArg* self, int v) {
        self.val = v * 2;
    }
}

int main() {
    // Bare declaration: constructor must NOT be called
    Counter b;
    if (b.count == 0) { puts("PASS"); } else { puts("FAIL bare no ctor"); }

    // Explicit no-arg ctor call: constructor MUST be called
    Counter c();
    if (c.count == 999) { puts("PASS"); } else { puts("FAIL parens ctor"); }

    // Ctor with arg
    WithArg w(21);
    if (w.val == 42) { puts("PASS"); } else { puts("FAIL arg ctor"); }

    // Bare decl of struct with arg ctor: no ctor call
    WithArg x;
    if (x.val == 0) { puts("PASS"); } else { puts("FAIL bare arg no ctor"); }

    return 0;
}
