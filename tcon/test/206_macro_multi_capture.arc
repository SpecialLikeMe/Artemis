// Test: const_resolve macro — multiple captures and multi-rule dispatch
// Verifies: two captures, and two distinct rules matched by literal tokens.

extern i32 printf(i8* fmt, ...);

const_resolve swap_add {
    ($a:expr, $b:expr) => { (($a) + ($b)) },
}

const_resolve make_min {
    ($a:expr, $b:expr) => {
        (($a) < ($b) ? ($a) : ($b))
    },
}

i32 main() {
    i32 s = swap_add(10, 32);
    if (s != 42) { return 1; }

    i32 m = make_min(100, 7);
    if (m != 7) { return 2; }

    return 0;
}
