fn pick<T>(a: T, b: T) T { return a + b; }
pub fn main() i32 {
    let mut a: i32= pick(40, 2);
    if (a != 42) { return 1; }
    let mut b: i64= pick((i64)100, (i64)23);
    if (b != 123) { return 2; }
    return 0;
}
