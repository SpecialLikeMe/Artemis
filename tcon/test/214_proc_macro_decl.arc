// PASS: proc macro declared as a regular function with attr/derive marker parses without error.
// The macro body is not compiled to IR.

fn add_debug(&memstr alloc, tokenstream* input) *tokenstream attr {
    return quote{ debug };
}

fn my_derive(&memstr alloc, tokenstream* input) *tokenstream derive {
    return quote{ let mut x: i32= 0; };
}

fn safe_macro(&memstr alloc, tokenstream* input) *tokenstream attr verify {
    return quote{ let mut y: i32= 1; };
}

pub fn main() i32 {
    return 0;
}
