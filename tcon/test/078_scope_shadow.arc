let mut x: i32= 10;

pub fn main() i32 {
    if (x != 10) { return 1; }
    {
        let mut x: i32= 20;
        if (x != 20) { return 2; }
    }
    if (x != 10) { return 3; }
    {
        let mut x: i32= 30;
        x = x + 1;
        if (x != 31) { return 4; }
    }
    if (x != 10) { return 5; }
    return 0;
}
