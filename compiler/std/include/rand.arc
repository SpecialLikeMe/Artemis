// std.rand — Pseudo-random number generation (Xoshiro256**, PCG32).

extern f64 log(f64 x);
extern f64 cos(f64 x);
extern f64 sqrt(f64 x);

namespace std {
namespace rand {

// --- xoshiro256** ---

istruc xoshiro_state {
    u64 s[4];

    void __construct__(xoshiro_state* self, u64 seed) {
        for (i32 i = 0; i < 4; i = i + 1) {
            seed = seed + 0x9e3779b97f4a7c15u;
            u64 z = seed;
            z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9u;
            z = (z ^ (z >> 27)) * 0x94d049bb133111ebu;
            self.s[i] = z ^ (z >> 31);
        }
    }

    u64 next_u64(xoshiro_state* self) {
        u64 r1  = self.s[1] * 5;
        u64 res = ((r1 << 7) | (r1 >> 57)) * 9;
        u64 t   = self.s[1] << 17;
        self.s[2] = self.s[2] ^ self.s[0];
        self.s[3] = self.s[3] ^ self.s[1];
        self.s[1] = self.s[1] ^ self.s[2];
        self.s[0] = self.s[0] ^ self.s[3];
        self.s[2] = self.s[2] ^ t;
        u64 s3 = self.s[3];
        self.s[3] = (s3 << 45) | (s3 >> 19);
        return res;
    }

    u32  next_u32(xoshiro_state* self)          { return (u32)(self.next_u64() >> 32); }
    f64  next_f64(xoshiro_state* self)          { return (f64)(self.next_u64() >> 11) * (1.0 / 9007199254740992.0); }
    f32  next_f32(xoshiro_state* self)          { return (f32)(self.next_u32() >> 8) * (1.0 / 16777216.0); }

    i32 range_i32(xoshiro_state* self, i32 lo, i32 hi) {
        u32 span = (u32)(hi - lo + 1);
        u32 r    = self.next_u32();
        return lo + (i32)(r % span);
    }

    f64 range_f64(xoshiro_state* self, f64 lo, f64 hi) {
        return lo + self.next_f64() * (hi - lo);
    }

    bool next_bool(xoshiro_state* self) { return (self.next_u64() & 1u) != 0; }

    void fill_bytes(xoshiro_state* self, u8* buf, u64 n) {
        u64 i = 0;
        while (i + 8 <= n) {
            u64 v = self.next_u64();
            for (i32 j = 0; j < 8; j = j + 1) { buf[i] = (u8)(v >> (j * 8)); i = i + 1; }
        }
        if (i < n) {
            u64 v = self.next_u64();
            while (i < n) { buf[i] = (u8)v; v = v >> 8; i = i + 1; }
        }
    }
}

// --- PCG32 ---

istruc pcg_state {
    u64 pcg_s;
    u64 inc;

    void __construct__(pcg_state* self, u64 seed, u64 seq) {
        self.pcg_s = 0;
        self.inc   = (seq << 1) | 1u;
        self.next_u32();
        self.pcg_s = self.pcg_s + seed;
        self.next_u32();
    }

    u32 next_u32(pcg_state* self) {
        u64 old = self.pcg_s;
        self.pcg_s = old * 6364136223846793005u + self.inc;
        u32 xsh = (u32)(((old >> 18) ^ old) >> 27);
        u32 rot = (u32)(old >> 59);
        return (xsh >> rot) | (xsh << ((-(i32)rot) & 31));
    }

    f64  next_f64(pcg_state* self) { return (f64)(self.next_u32() >> 1) * (1.0 / 2147483648.0); }
    bool next_bool(pcg_state* self) { return (self.next_u32() & 1u) != 0; }

    i32 range_i32(pcg_state* self, i32 lo, i32 hi) {
        u32 span = (u32)(hi - lo + 1);
        return lo + (i32)(self.next_u32() % span);
    }
}

// --- Gaussian (Box-Muller) ---

f64 gaussian(xoshiro_state* rng, f64 mean, f64 std_dev) {
    f64 u1 = (*rng).next_f64();
    f64 u2 = (*rng).next_f64();
    if (u1 <= 0.0) { u1 = 1e-300; }
    f64 z = sqrt(-2.0 * log(u1)) * cos(6.28318530717958647 * u2);
    return mean + z * std_dev;
}

} // rand
} // std
