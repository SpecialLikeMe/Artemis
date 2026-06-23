int add(int a, int b) { return a + b; }

int main() {
    int x = add(7, 8);
    if (x != 15) { return 1; }
    return 0;
}
