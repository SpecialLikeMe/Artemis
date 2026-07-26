pub fn main() i32 {
    let mut arr: [5]i32;
    for (let mut i: i32 = 0; i < 5; i++) { arr[i] = i * 2; }

    let mut p: *i32= arr;
    if (*p != 0)       { return 1; }
    p = p + 1;
    if (*p != 2)       { return 2; }
    p = p + 2;
    if (*p != 6)       { return 3; }
    p = p - 1;
    if (*p != 4)       { return 4; }
    return 0;
}
