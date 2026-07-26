// std.rand — xoshiro256** basic RNG test
extern  std.rand;

pub fn main() i32 {
    let mut rng: std.rand.xoshiro_state(42u);
    let mut a: u64= rng.next_u64();
    let mut b: u64= rng.next_u64();
    if (a == 0u) { return 1; }
    if (a == b)  { return 2; }

    let mut r: u32= rng.next_u32();
    if (r == 0u) { return 3; }

    // next_bool just has to not crash
    let mut rng_bool: bool= rng.next_bool();

    // PCG32
    let mut pcg: std.rand.pcg_state(1u, 1u);
    let mut p1: u32= pcg.next_u32();
    let mut p2: u32= pcg.next_u32();
    if (p1 == p2) { return 6; }

    return 0;
}
