// Test: trailing-type syntax and using aliases
// Verifies: let x: T, fn() T, using alias = type, all work correctly.

// Trailing-type global variable declarations
let x: i32 = 10;
let y: i32 = 20;

// using alias: var = auto (type inference placeholder)
using var = auto;

fn add(a: i32, b: i32) i32 { return a + b; }

// Function with trailing return type
fn compute() i32 {
    let mut result: i32= add(x, y);
    return result;
}

pub fn main() i32 {
    // Trailing type local vars
    let mut b: i32= 7;
    let mut c: i32= b * 6;
    if (c != 42) { return 2; }

    // Function with trailing return type
    let mut v: i32= compute();
    if (v != 30) { return 3; }

    // using alias: var (= auto) with type inferred from initializer
    let mut d: var= 99;
    if (d != 99) { return 4; }

    return 0;
}
