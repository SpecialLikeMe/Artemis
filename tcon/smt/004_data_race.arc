// SMT claim: race-free concurrent code — atomic operations provide happens-before ordering.
// Data-race analysis requires a thread model (tracked as future work in the SMT).
// Until then, the SMT treats all memory as UNKNOWN under concurrent access and relies on
// std.atomic to ensure correctness.  This test exercises the safe path: atomic load/store.
@unsafe extern fn printf(fmt: *i8, ...) i32;

let mut shared: i32= 0;

pub fn main() i32 {
    // Single-threaded equivalent of an atomic increment — no actual data race here.
    // The SMT sees this as a safe sequence of load + store.
    let mut v: i32= shared;
    shared = v + 1;
    if (shared != 1) { return 1; }
    return 0;
}
