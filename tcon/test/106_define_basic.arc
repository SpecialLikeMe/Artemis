@define <ANSWER> <42>
@define <ONE> <1>

pub fn main() i32 {
    let mut x: i32= ANSWER;
    let mut y: i32= ONE;
    if (x != 42) { return 1; }
    if (y != 1)  { return 2; }
    return 0;
}
