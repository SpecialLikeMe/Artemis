// PASS: anytype parameters should monomorphize at call sites

fn type_size(foo: anytype) usize {
    return @srsizeof(foo);
}

fn double_val(x: anytype) i64 {
    return (i64)x + (i64)x;
}

pub fn main() i32 {
    let a: i32 = 0;
    let b: f64 = 0.0;
    let c: i64 = 0;

    // @srsizeof should reflect the concrete type
    if (type_size(a) != 4)  { return 1; }
    if (type_size(b) != 8)  { return 2; }
    if (type_size(c) != 8)  { return 3; }

    // double_val should work with integer types
    let x: i32 = 5;
    let y: i64 = 10;
    if (double_val(x) != 10) { return 4; }
    if (double_val(y) != 20) { return 5; }

    return 0;
}
