i32 log[8];
i32 log_idx = 0;

void push(i32 v) {
    log[log_idx] = v;
    log_idx = log_idx + 1;
}

void inner() {
    defer push(10);
    defer push(11);
    push(1);
    push(2);
}

i32 with_return(i32 x) {
    defer push(99);
    if (x > 0) {
        defer push(88);
        push(50);
        return x;
    }
    push(60);
    return 0;
}

i32 main() {
    inner();
    if (log[0] != 1)  { return 1; }
    if (log[1] != 2)  { return 2; }
    if (log[2] != 11) { return 3; }
    if (log[3] != 10) { return 4; }

    log_idx = 0;
    with_return(5);
    if (log[0] != 50) { return 5; }
    if (log[1] != 88) { return 6; }
    if (log[2] != 99) { return 7; }

    return 0;
}
