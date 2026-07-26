pub fn main() i32 {
    const N: i32= 6;
    const M: i32= N + 1;
    let mut arr: [7]i32;
    arr[0] = M;
    if (M != 7) { return 1; }
    if (arr[0] != 7) { return 2; }
    return 0;
}
