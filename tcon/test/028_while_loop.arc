pub fn main() i32 {
    let mut i: i32= 0;
    let mut sum: i32= 0;
    while (i < 10) {
        sum = sum + i;
        i = i + 1;
    }
    if (sum != 45) { return 1; }
    if (i != 10)   { return 2; }
    return 0;
}
