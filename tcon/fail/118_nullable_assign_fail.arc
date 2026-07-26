// FAIL: assigning ?T to T without unwrapping should be a type error.
// Expected: compile error "nullable (?T) but the parameter expects a non-nullable value"
//           or similar nullable mismatch message.

fn add_one(x: i32) i32 {
    return x + 1;
}

fn main() i32 {
    ?let mut maybe: i32= 42;
    let mut val: i32= maybe;    // ERROR: ?i32 cannot be assigned to i32
    return add_one(val);
}
