// FAIL: 'continue' used outside a loop must be rejected
i32 main() {
    continue;  // ERROR: continue outside loop
    return 0;
}
