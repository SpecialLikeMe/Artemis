i32 counter = 0;

void inc() { counter = counter + 1; }
void reset() { counter = 0; }

i32 main() {
    if (counter != 0) { return 1; }
    inc(); inc(); inc();
    if (counter != 3) { return 2; }
    reset();
    if (counter != 0) { return 3; }
    return 0;
}
