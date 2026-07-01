// FAIL: typedef referencing an undeclared type
typedef Phantom Alias;  // ERROR: Phantom undeclared
i32 main() { return 0; }
