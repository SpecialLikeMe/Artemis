pub fn main() i32 {
    let mut arr: [10]i32;
    for (let mut i: i32 = 0; i < 10; i++) {
        arr[i] = i * i;
    }
    let mut sum: i32= 0;
    for (let mut i: i32 = 0; i < 10; i++) {
        sum = sum + arr[i];
    }
    if (sum != 285) { return 1; }
    return 0;
}
