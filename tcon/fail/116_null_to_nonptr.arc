// FAIL: null is not assignable to a plain non-nullable, non-pointer type
fn main() i32 {
    let mut x: i32= null;  // must error: i32 is neither a pointer nor nullable
    return x;
}
