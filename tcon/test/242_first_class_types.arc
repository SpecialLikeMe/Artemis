// PASS: first-class type aliases via comptime type
const MyInt: type= i32;
const MyFloat: type= f64;

istruc Pair {
    let mut x: i32;
    let mut y: i32;
}
const PairAlias: type= Pair;

pub fn main() i32 {
    let mut a: MyInt= 100;
    if (a != 100) { return 1; }

    let mut f: MyFloat= 3.14;
    if (f < 3.0) { return 2; }

    let mut p: PairAlias;
    p.x = 10;
    p.y = 20;
    if (p.x + p.y != 30) { return 3; }

    return 0;
}
