// Test static istruc member: belongs to the type, not any instance
// PASS PASS PASS PASS
int puts(i8* s);

istruc Counter {
    int count;
    static int total;
    void add(Counter* self, int n) {
        self.count = self.count + n;
        Counter__static_total = Counter__static_total + n;
    }
}

int main() {
    Counter a;
    Counter b;
    a.count = 0;
    b.count = 0;
    Counter__static_total = 0;

    a.add(5);
    b.add(3);

    if (Counter__static_total == 8)  { puts("PASS"); } else { puts("FAIL total"); }
    if (a.count == 5)                { puts("PASS"); } else { puts("FAIL a"); }
    if (b.count == 3)                { puts("PASS"); } else { puts("FAIL b"); }

    // Instance counts are independent
    a.add(10);
    if (a.count == 15 && b.count == 3) { puts("PASS"); } else { puts("FAIL independent"); }

    return 0;
}
