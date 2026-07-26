// FAIL: passing ?T to a function expecting T should be a type error.
// Expected: compile error mentioning nullable argument mismatch.

fn process(x: i32) void {
}

fn main() i32 {
    ?let mut maybe: i32= 7;
    process(maybe);   // ERROR: nullable arg to non-nullable param
    return 0;
}
