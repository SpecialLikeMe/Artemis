pub fn main() i32 {
    let mut count: i32= 0;
    for (let mut i: i32 = 0; i < 5; i++) {
        for (let mut j: i32 = 0; j < 5; j++) {
            count = count + 1;
        }
    }
    if (count != 25) { return 1; }
    return 0;
}
