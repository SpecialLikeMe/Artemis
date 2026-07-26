struct Inner {
    let a: i32;
    let b: i32;
}

struct Outer {
    let in: Inner;
    let c: i32;
}

pub fn main() i32 {
    let mut o: Outer;
    o.in.a = 1;
    o.in.b = 2;
    o.c    = 3;
    let mut sum: i32= o.in.a + o.in.b + o.c;
    if (sum != 6) { return 1; }
    o.in.b = o.in.a + o.c;
    if (o.in.b != 4) { return 2; }
    return 0;
}
