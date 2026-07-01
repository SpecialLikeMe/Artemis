// FAIL: break not in a loop or switch
void f() { break; }
i32 main() { f(); return 0; }
