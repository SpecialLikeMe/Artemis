// FAIL: break inside a function body (even if that function is called from a loop)
void inner() { break; }  // ERROR: break not in a loop or switch
i32 main() {
    for (i32 i = 0; i < 5; i = i + 1) inner();
    return 0;
}
