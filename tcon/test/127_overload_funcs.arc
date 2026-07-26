// Test functions with distinct names (overloading was removed; each fn has a unique name)
fn square_i32(x: i32) i32 { return x * x; }
fn square_i64(x: i64) i64 { return x * x; }

fn describe_one(x: i32) i32 { return 0; }
fn describe_two(x: i32, y: i32) i32 { return 1; }

pub fn main() i32 {
    let mut a: i32= square_i32(5);
    if (a != 25) { return 1; }

    let mut b: i64= square_i64((i64)7);
    if (b != 49) { return 2; }

    if (describe_one(1)    != 0) { return 3; }
    if (describe_two(1, 2) != 1) { return 4; }

    return 0;
}
