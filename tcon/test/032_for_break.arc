pub fn main() i32 {
    let mut found: i32= -1;
    for (let mut i: i32 = 0; i < 100; i++) {
        if (i * i == 49) {
            found = i;
            break;
        }
    }
    if (found != 7) { return 1; }
    return 0;
}
