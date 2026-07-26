struct _Pair {
    let first: i32;
    let second: i32;
}

using Pair = _Pair;

fn make_pair(a: i32, b: i32) Pair {
    let mut p: Pair;
    p.first  = a;
    p.second = b;
    return p;
}

pub fn main() i32 {
    let mut p: Pair= make_pair(3, 7);
    if (p.first  != 3) { return 1; }
    if (p.second != 7) { return 2; }
    return 0;
}
