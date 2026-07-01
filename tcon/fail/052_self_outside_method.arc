// FAIL: using 'self' outside a class method
i32 main() {
    i32 x = self.value;  // ERROR: self is undefined here
    return x;
}
