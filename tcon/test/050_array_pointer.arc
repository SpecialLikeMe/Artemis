fn sum_array(arr: *i32, n: i32) i32 {
    let mut s: i32= 0;
    for (let mut i: i32 = 0; i < n; i++) {
        s = s + arr[i];
    }
    return s;
}

pub fn main() i32 {
    let mut a: [5]i32;
    a[0] = 1; a[1] = 2; a[2] = 3; a[3] = 4; a[4] = 5;
    let mut s: i32= sum_array(a, 5);
    if (s != 15) { return 1; }
    return 0;
}
