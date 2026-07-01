// FAIL: 'break' used outside a loop or switch must be rejected
i32 main() {
    i32 x = 0;
    break;  // ERROR: break outside loop/switch
    return x;
}
