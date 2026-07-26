// PASS: #[attr] annotation on a function parses without error.
// Attributes are stored on func_decl and not compiled.

#[inline]
fn add(a: i32, b: i32) i32 {
    return a + b;
}

pub fn main() i32 {
    return add(1, 2) - 3;
}
