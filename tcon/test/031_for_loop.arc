pub fn main() i32 {
    let mut sum: i32= 0;
    for (let mut i: i32 = 0; i < 10; i++) {
        sum = sum + i;
    }
    if (sum != 45) { return 1; }
    return 0;
}
