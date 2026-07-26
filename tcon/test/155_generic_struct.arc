istruc Box<T> {
    let mut value: T;
}
pub fn main() i32 {
    let mut b: Box<i32>;
    b.value = 77;
    if (b.value != 77) { return 1; }
    return 0;
}
