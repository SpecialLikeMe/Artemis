// FAIL: passing ?T to a function expecting T should be a type error.
// Expected: compile error mentioning nullable argument mismatch.

void process(i32 x) {
}

i32 main() {
    ?i32 maybe = 7;
    process(maybe);   // ERROR: nullable arg to non-nullable param
    return 0;
}
