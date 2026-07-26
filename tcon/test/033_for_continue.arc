pub fn main() i32 {
    let mut count: i32= 0;
    for (let mut i: i32 = 0; i < 20; i++) {
        if (i % 3 != 0) { continue; }
        count = count + 1;
    }
    if (count != 7) { return 1; }
    return 0;
}
