// FAIL: static method call via dot on an undeclared class
i32 main() { return Phantom.compute(); }  // ERROR: Phantom undeclared
