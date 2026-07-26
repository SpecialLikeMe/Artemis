fn add(a: i32, b: i32) i32 { return a + b; }
fn mul(a: i32, b: i32) i32 { return a * b; }
fn sub(a: i32, b: i32) i32 { return a - b; }

fn apply(op: *(i32, i32)i32, x: i32, y: i32) i32 {
    return op(x, y);
}

pub fn main() i32 {
    let mut op: *(i32, i32)i32 = &add;
    if (op(3, 4)   != 7)  { return 1; }

    op = &mul;
    if (op(3, 4)   != 12) { return 2; }

    op = &sub;
    if (op(10, 3)  != 7)  { return 3; }

    if (apply(&add, 5, 6) != 11) { return 4; }
    if (apply(&mul, 5, 6) != 30) { return 5; }

    return 0;
}
