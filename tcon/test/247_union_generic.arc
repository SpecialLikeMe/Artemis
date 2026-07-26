// PASS: generic union — fields share memory after monomorphization
union Pair<T> {
    let a: T;
    let b: i32;
}

pub fn main() i32 {
    let mut p: Pair<i32>;
    p.a = 0x12345678;
    if (p.b != 0x12345678) { return 1; }

    let mut q: Pair<f32>;
    q.b = 0x3f800000; // IEEE 754 1.0f
    if (q.b != 0x3f800000) { return 2; }

    return 0;
}
