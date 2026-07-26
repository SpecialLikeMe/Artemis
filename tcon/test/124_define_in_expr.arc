@define <WIDTH> <8>
@define <HEIGHT> <4>

fn area() i32 { return WIDTH * HEIGHT; }

pub fn main() i32 {
    if (area() != 32) { return 1; }
    let mut w: i32= WIDTH;
    let mut h: i32= HEIGHT;
    if (w != 8) { return 2; }
    if (h != 4) { return 3; }
    return 0;
}
