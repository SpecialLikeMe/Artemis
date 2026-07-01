// std.rand — xoshiro256** basic RNG test
extern std.rand;

i32 main() {
    xoshiro_state rng(42u);
    u64 a = rng.next_u64();
    u64 b = rng.next_u64();
    if (a == 0u) { return 1; }
    if (a == b)  { return 2; }

    u32 r = rng.next_u32();
    if (r == 0u) { return 3; }

    // next_bool just has to not crash
    bool b2 = rng.next_bool();

    // PCG32
    pcg_state pcg(1u, 1u);
    u32 p1 = pcg.next_u32();
    u32 p2 = pcg.next_u32();
    if (p1 == p2) { return 6; }

    return 0;
}
