// comptime {} block: code runs at compile time
let mut g: i32= 0;

pub fn main() i32 {
    const N: i32= 5;
    comptime {
        let mut doubled: i32= N * 2;
        g = doubled;
    }
    if (g != 10) { return 1; }

    const M: i32= N + N;
    if (M != 10) { return 2; }
    return 0;
}
