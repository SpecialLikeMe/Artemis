// std.rand — Pseudo-random number generation (Xoshiro256**, PCG32).

@unsafe extern fn log(x: f64) f64;
@unsafe extern fn cos(x: f64) f64;
@unsafe extern fn sqrt(x: f64) f64;

namespace std {
namespace rand {

// --- xoshiro256** ---

istruc xoshiro_state {
    let mut s: [4]u64;

    fn __construct__(self: *xoshiro_state, seed: u64) void {
        for (let mut i: i32 = 0; i < 4; i = i + 1) {
            seed = seed + 0x9e3779b97f4a7c15u;
            let mut z: u64= seed;
            z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9u;
            z = (z ^ (z >> 27)) * 0x94d049bb133111ebu;
            self.s[i] = z ^ (z >> 31);
        }
    }

    fn next_u64(self: *xoshiro_state) u64 {
        let mut r1: u64= self.s[1] * 5;
        let mut result: u64= ((r1 << 7) | (r1 >> 57)) * 9;
        let mut t: u64= self.s[1] << 17;
        self.s[2] = self.s[2] ^ self.s[0];
        self.s[3] = self.s[3] ^ self.s[1];
        self.s[1] = self.s[1] ^ self.s[2];
        self.s[0] = self.s[0] ^ self.s[3];
        self.s[2] = self.s[2] ^ t;
        let mut s3: u64= self.s[3];
        self.s[3] = (s3 << 45) | (s3 >> 19);
        return result;
    }

    fn next_u32(self: *xoshiro_state) u32          { return (u32)(self.next_u64() >> 32); }
    fn next_f64(self: *xoshiro_state) f64          { return (f64)(self.next_u64() >> 11) * (1.0 / 9007199254740992.0); }
    fn next_f32(self: *xoshiro_state) f32          { return (f32)(self.next_u32() >> 8) * (1.0 / 16777216.0); }

    fn range_i32(self: *xoshiro_state, lo: i32, hi: i32) i32 {
        let mut span: u32= (u32)(hi - lo + 1);
        let mut r: u32= self.next_u32();
        return lo + (i32)(r % span);
    }

    fn range_f64(self: *xoshiro_state, lo: f64, hi: f64) f64 {
        return lo + self.next_f64() * (hi - lo);
    }

    fn next_bool(self: *xoshiro_state) bool { return (self.next_u64() & 1u) != 0; }

    fn fill_bytes(self: *xoshiro_state, buf: *u8, n: u64) void {
        let mut i: u64= 0;
        while (i + 8 <= n) {
            let mut v: u64= self.next_u64();
            for (let mut j: i32 = 0; j < 8; j = j + 1) { buf[i] = (u8)(v >> (j * 8)); i = i + 1; }
        }
        if (i < n) {
            let mut v: u64= self.next_u64();
            while (i < n) { buf[i] = (u8)v; v = v >> 8; i = i + 1; }
        }
    }
}

// --- PCG32 ---

istruc pcg_state {
    let mut pcg_s: u64;
    let mut inc: u64;

    fn __construct__(self: *pcg_state, seed: u64, seq: u64) void {
        self.pcg_s = 0;
        self.inc   = (seq << 1) | 1u;
        self.next_u32();
        self.pcg_s = self.pcg_s + seed;
        self.next_u32();
    }

    fn next_u32(self: *pcg_state) u32 {
        let mut old: u64= self.pcg_s;
        self.pcg_s = old * 6364136223846793005u + self.inc;
        let mut xsh: u32= (u32)(((old >> 18) ^ old) >> 27);
        let mut rot: u32= (u32)(old >> 59);
        return (xsh >> rot) | (xsh << ((-(i32)rot) & 31));
    }

    fn next_f64(self: *pcg_state) f64 { return (f64)(self.next_u32() >> 1) * (1.0 / 2147483648.0); }
    fn next_bool(self: *pcg_state) bool { return (self.next_u32() & 1u) != 0; }

    fn range_i32(self: *pcg_state, lo: i32, hi: i32) i32 {
        let mut span: u32= (u32)(hi - lo + 1);
        return lo + (i32)(self.next_u32() % span);
    }
}

// --- Gaussian (Box-Muller) ---

fn gaussian(rng: *xoshiro_state, mean: f64, std_dev: f64) f64 {
    @unsafe {
        let mut uu1: f64= (*rng).next_f64();
        let mut uu2: f64= (*rng).next_f64();
        if (uu1 <= 0.0) { uu1 = 1e-300; }
        let mut z: f64= sqrt(-2.0 * log(uu1)) * cos(6.28318530717958647 * uu2);
        return mean + z * std_dev;
    }
}

} // rand
} // std
