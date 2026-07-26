@define <MAX\(([^,]+),([^)]+)\)> <%1 > %2 ? %1 : %2>

pub fn main() i32 {
    let mut a: i32= 10;
    let mut b: i32= 20;
    let mut m: i32= MAX(a,b);
    if (m != 20) { return 1; }
    let mut c: i32= 99;
    let mut d: i32= 3;
    let mut n: i32= MAX(c,d);
    if (n != 99) { return 2; }
    return 0;
}
