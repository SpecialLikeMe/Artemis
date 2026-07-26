pub fn main() i32 {
    let mut a: i32= 10;
    let mut b: i32= 20;
    let mut pa: *i32= &a;
    let mut pb: *i32= &b;
    let mut sum: i32= *pa + *pb;
    if (sum != 30) { return 1; }
    *pa = *pb + 5;
    if (a != 25)   { return 2; }
    return 0;
}
