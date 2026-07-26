// Test: const_resolve macro — statement-level expansion
// Verifies: a macro that expands to a variable declaration works inside a function body.
// The expansion does NOT include a trailing ';'; the call-site ';' terminates the statement.

@unsafe extern fn printf(fmt: *i8, ...) i32;

const_resolve let_i32 {
    ($name:ident, $val:expr) => { let mut $name: i32 = $val },
}

pub fn main() i32 {
    let_i32(x, 21);
    let_i32(y, x + x);
    if (y != 42) { return 1; }
    return 0;
}
