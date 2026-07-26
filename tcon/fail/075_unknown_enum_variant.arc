// FAIL: using an undeclared enum variant
enum Direction { North, South, East, West }
fn main() i32 {
    let mut d: i32= Up;  // ERROR: Up is not declared
    return d;
}
