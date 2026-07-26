fn add(a: i32, b: i32) i32 { return a + b; }
fn mul(a: i32, b: i32) i32 { return a * b; }

fn apply_twice(op: *(i32, i32)i32, x: i32, y: i32) i32 {
    return op(op(x, y), y);
}

fn dispatch(choice: i32, a: i32, b: i32) i32 {
    let mut op: *(i32, i32)i32;
    if (choice == 0) {
        op = &add;
    } else {
        op = &mul;
    }
    return op(a, b);
}

pub fn main() i32 {
    let mut f: *(i32, i32)i32 = &add;
    if (f(2, 3)  != 5)  { return 1; }

    f = &mul;
    if (f(2, 3)  != 6)  { return 2; }

    if (apply_twice(&add, 1, 2) != 5)  { return 3; }
    if (apply_twice(&mul, 2, 3) != 18) { return 4; }

    if (dispatch(0, 10, 5) != 15) { return 5; }
    if (dispatch(1, 10, 5) != 50) { return 6; }

    return 0;
}
