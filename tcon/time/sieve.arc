// Sieve of Eratosthenes — array/memory bound.
// Prints the prime count so nothing can be optimised away.
extern std.fmt;

comptime i32 N = 10000000;

let mut flags: [10000000]u8;

fn sieve() i32 {
    let mut i: i32= 0;
    while (i < N) { flags[i] = (u8)1; i = i + 1; }
    let mut count: i32= 0;
    let mut p: i32= 2;
    while (p < N) {
        if (flags[p] != (u8)0) {
            count = count + 1;
            let mut m: i32= p + p;
            while (m < N) { flags[m] = (u8)0; m = m + p; }
        }
        p = p + 1;
    }
    return count;
}

pub fn main() i32 {
    let mut c: i32= 0;
    let mut r: i32= 0;
    while (r < 8) { c = c + sieve(); r = r + 1; }
    std.fmt.out_print_i32(c);
    std.fmt.out_println("");
    return 0;
}
