// FAIL: calling an enum variant as if it were a function
enum Status { OK, Error }
i32 main() { return OK(); }  // ERROR: OK is not callable
