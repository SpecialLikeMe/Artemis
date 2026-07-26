// FAIL: member access on a void-returning function call
fn noop() void { return; }
fn main() i32 {
    let mut x: i32= noop().field;  // ERROR: void has no members
    return x;
}
