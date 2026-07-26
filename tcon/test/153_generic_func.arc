fn identity<T>(x: T) T { return x; }
pub fn main() i32 {
    let mut a: i32= identity<i32>(42);
    if (a != 42) { return 1; }
    return 0;
}
