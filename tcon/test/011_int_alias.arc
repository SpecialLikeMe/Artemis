fn add(a: int, b: int) int { return a + b; }

pub fn main() int {
    let mut x: int= add(7, 8);
    if (x != 15) { return 1; }
    return 0;
}
