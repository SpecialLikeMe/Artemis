// FAIL: #[derive(UnknownTrait)] should be a compile error.
// Expected: error "Unknown derive macro 'UnknownTrait'"

#[derive(UnknownTrait)]
istruc Point {
    i32 x;
    i32 y;
}

i32 main() {
    return 0;
}
