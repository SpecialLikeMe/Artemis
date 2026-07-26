pub fn main() i32 {
    let mut arr: [5]i32;
    arr[0] = 10;
    arr[1] = 20;
    arr[2] = 30;
    arr[3] = 40;
    arr[4] = 50;
    let mut sum: i32= arr[0] + arr[1] + arr[2] + arr[3] + arr[4];
    if (sum != 150) { return 1; }
    arr[2] = 99;
    if (arr[2] != 99) { return 2; }
    return 0;
}
