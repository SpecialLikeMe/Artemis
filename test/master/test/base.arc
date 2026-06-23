int recurse(int n) {
    if (n > 100) {
        return 1;
    } else {
        return recurse(n + 1);
    }
}

int main() {
    int x = recurse(0);
    return 0;
}