// FAIL: assigning ?T to T without unwrapping should be a type error.
// Expected: compile error "nullable (?T) but the parameter expects a non-nullable value"
//           or similar nullable mismatch message.

i32 add_one(i32 x) {
    return x + 1;
}

i32 main() {
    ?i32 maybe = 42;
    i32 val = maybe;    // ERROR: ?i32 cannot be assigned to i32
    return add_one(val);
}
