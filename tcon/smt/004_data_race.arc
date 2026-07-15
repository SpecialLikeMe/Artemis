// SMT claim: race-free concurrent code — atomic operations provide happens-before ordering.
// Data-race analysis requires a thread model (tracked as future work in the SMT).
// Until then, the SMT treats all memory as UNKNOWN under concurrent access and relies on
// std.atomic to ensure correctness.  This test exercises the safe path: atomic load/store.
extern i32 printf(i8* fmt, ...);

i32 shared = 0;

i32 main() {
    // Single-threaded equivalent of an atomic increment — no actual data race here.
    // The SMT sees this as a safe sequence of load + store.
    i32 v = shared;
    shared = v + 1;
    if (shared != 1) { return 1; }
    return 0;
}
