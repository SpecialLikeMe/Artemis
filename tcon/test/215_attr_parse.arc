// PASS: #[attr] annotation on a function parses without error.
// Attributes are stored on func_decl and not compiled.

#[inline]
i32 add(i32 a, i32 b) {
    return a + b;
}

i32 main() {
    return add(1, 2) - 3;
}
