using Score = i32;
using Real = f64;

fn triple(s: Score) Score { return s * 3; }

pub fn main() i32 {
    let mut s: Score= 10;
    if (triple(s) != 30) { return 1; }

    let mut r: Real= 2.5;
    let mut r2: Real= r * r;
    if (r2 != 6.25) { return 2; }
    return 0;
}
