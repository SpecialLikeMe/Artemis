// PASS: generic enum — type-parameterized enum declaration and instantiation
enum Status<T> {
    ok,
    fail,
    pending,
}

enum Maybe<T> {
    nothing,
    something,
}

pub fn main() i32 {
    // Different instantiations of the same generic enum
    let mut s1: Status<i32>;
    s1 = ok;
    if (s1 != 0) { return 1; }

    let mut s2: Status<f32>;
    s2 = fail;
    if (s2 != 1) { return 2; }

    let mut s3: Status<i64>;
    s3 = pending;
    if (s3 != 2) { return 3; }

    let mut m: Maybe<i32>;
    m = something;
    if (m != 1) { return 4; }

    let mut n: Maybe<i8*>;
    n = nothing;
    if (n != 0) { return 5; }

    return 0;
}
