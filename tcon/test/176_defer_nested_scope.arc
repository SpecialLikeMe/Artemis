// defer runs at scope exit; nested scopes have independent defer queues
// Use a helper function so we can check the log after all defers have fired.
i32 log[16];
i32 idx = 0;

void record(i32 v) { log[idx] = v; idx = idx + 1; }

void run_test() {
    defer record(99);           // outermost defer in run_test scope
    {
        defer record(20);       // inner scope defer
        record(1);
        {
            defer record(11);   // innermost scope defer
            record(2);
        }
        // innermost defers ran: [1, 2, 11]
        record(3);
    }
    // inner defer ran: [1, 2, 11, 3, 20]
    record(4);
    // on return from run_test: [1, 2, 11, 3, 20, 4, 99]
}

i32 main() {
    idx = 0;
    run_test();
    // All defers have now fired
    if (log[0] != 1)  { return 1; }
    if (log[1] != 2)  { return 2; }
    if (log[2] != 11) { return 3; }
    if (log[3] != 3)  { return 4; }
    if (log[4] != 20) { return 5; }
    if (log[5] != 4)  { return 6; }
    if (log[6] != 99) { return 7; }
    return 0;
}
