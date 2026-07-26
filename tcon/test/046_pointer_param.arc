fn double_val(p: *i32) void {
    *p = *p * 2;
}

fn swap(a: *i32, b: *i32) void {
    let mut tmp: i32= *a;
    *a = *b;
    *b = tmp;
}

pub fn main() i32 {
    let mut x: i32= 5;
    double_val(&x);
    if (x != 10) { return 1; }

    let mut a: i32= 3;
    let mut b: i32= 7;
    swap(&a, &b);
    if (a != 7) { return 2; }
    if (b != 3) { return 3; }
    return 0;
}
