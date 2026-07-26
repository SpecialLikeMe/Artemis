pub fn main() i32 {
    let mut i: i32= 0;
    let mut sum: i32= 0;
    for (; i < 5; ) {
        sum = sum + i;
        i++;
    }
    if (sum != 10) { return 1; }
    if (i != 5)    { return 2; }
    return 0;
}
