// FAIL: #[derive(UnknownTrait)] should be a compile error.
// Expected: error "Unknown derive macro 'UnknownTrait'"

#[derive(UnknownTrait)]
istruc Point {
    let mut x: i32;
    let mut y: i32;
}

fn main() i32 {
    return 0;
}
