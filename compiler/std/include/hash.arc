// std.hash — Fast non-cryptographic hashes and cryptographic primitives.

namespace std {
namespace hash {

// --- Wyhash (fast, high-quality) ---

namespace wyhash {

constexpr u64 SECRET0 = 0xa0761d6478bd642fu;
constexpr u64 SECRET1 = 0xe7037ed1a0b428dbu;
constexpr u64 SECRET2 = 0x8ebc6af09c88c6e3u;
constexpr u64 SECRET3 = 0x589965cc75374cc3u;

private u64 wymix(u64 a, u64 b) {
    u64 lo; u64 hi;
    // 128-bit multiply via two 64-bit halves
    u64 ah = a >> 32; u64 al = a & 0xFFFFFFFFu;
    u64 bh = b >> 32; u64 bl = b & 0xFFFFFFFFu;
    u64 mid = ah * bl + al * bh;
    lo = al * bl + ((mid & 0xFFFFFFFFu) << 32);
    hi = ah * bh + (mid >> 32) + (lo < al * bl ? 1 : 0);
    return lo ^ hi;
}

u64 hash_bytes(u8* data, u64 len, u64 seed) {
    seed = seed ^ SECRET0;
    u64 a = 0; u64 b = 0;
    if (len <= 16) {
        if (len >= 4) {
            u32* p = (u32*)data;
            a = ((u64)(*p) << 32) | (u64)(*((u32*)(data + len - 4)));
            u32* q = (u32*)(data + (len >> 3 << 2));
            b = ((u64)(*q) << 32) | (u64)(*((u32*)(data + len - 4 - (len >> 3 << 2))));
        } else if (len > 0) {
            a = ((u64)data[0] << 16) | ((u64)data[len>>1] << 8) | (u64)data[len-1];
            b = 0;
        }
    } else {
        u64 i = len;
        u64 p = (u64)(void*)data;
        if (i > 48) {
            u64 s1 = seed; u64 s2 = seed;
            while (i > 48) {
                seed = wymix(*(u64*)(void*)p ^ SECRET1, *(u64*)(void*)(p+8) ^ seed);
                s1   = wymix(*(u64*)(void*)(p+16) ^ SECRET2, *(u64*)(void*)(p+24) ^ s1);
                s2   = wymix(*(u64*)(void*)(p+32) ^ SECRET3, *(u64*)(void*)(p+40) ^ s2);
                p = p + 48; i = i - 48;
            }
            seed = seed ^ s1 ^ s2;
        }
        while (i > 16) {
            seed = wymix(*(u64*)(void*)p ^ SECRET1, *(u64*)(void*)(p+8) ^ seed);
            p = p + 16; i = i - 16;
        }
        a = *(u64*)(void*)(p + i - 16);
        b = *(u64*)(void*)(p + i - 8);
    }
    return wymix(SECRET1 ^ len, wymix(a ^ SECRET1, b ^ seed));
}

u64 hash_str(i8* s, u64 seed) {
    u64 n = 0;
    while (s[n] != 0) { n = n + 1; }
    return hash_bytes((u8*)s, n, seed);
}

u64 hash_i64(i64 v, u64 seed)   { return hash_bytes((u8*)&v, 8, seed); }
u64 hash_u64(u64 v, u64 seed)   { return hash_bytes((u8*)&v, 8, seed); }
u64 hash_f64(f64 v, u64 seed)   { return hash_bytes((u8*)&v, 8, seed); }

} // wyhash

// --- FNV-1a ---

namespace fnv {

constexpr u64 OFFSET = 14695981039346656037u;
constexpr u64 PRIME  = 1099511628211u;

u64 hash_bytes(u8* data, u64 len) {
    u64 h = OFFSET;
    for (u64 i = 0; i < len; i = i + 1)
        h = (h ^ (u64)data[i]) * PRIME;
    return h;
}

u64 hash_str(i8* s) {
    u64 h = OFFSET;
    i32 i = 0;
    while (s[i] != 0) { h = (h ^ (u64)(u8)s[i]) * PRIME; i = i + 1; }
    return h;
}

u32 hash32_bytes(u8* data, u64 len) {
    u32 h = 2166136261u;
    for (u64 i = 0; i < len; i = i + 1)
        h = (h ^ (u32)data[i]) * 16777619u;
    return h;
}

} // fnv

// --- SHA-256 ---

namespace sha256 {

struct digest { u8 bytes[32]; }

constexpr u32 K[64] = {
    0x428a2f98u,0x71374491u,0xb5c0fbcfu,0xe9b5dba5u,
    0x3956c25bu,0x59f111f1u,0x923f82a4u,0xab1c5ed5u,
    0xd807aa98u,0x12835b01u,0x243185beu,0x550c7dc3u,
    0x72be5d74u,0x80deb1feu,0x9bdc06a7u,0xc19bf174u,
    0xe49b69c1u,0xefbe4786u,0x0fc19dc6u,0x240ca1ccu,
    0x2de92c6fu,0x4a7484aau,0x5cb0a9dcu,0x76f988dau,
    0x983e5152u,0xa831c66du,0xb00327c8u,0xbf597fc7u,
    0xc6e00bf3u,0xd5a79147u,0x06ca6351u,0x14292967u,
    0x27b70a85u,0x2e1b2138u,0x4d2c6dfcu,0x53380d13u,
    0x650a7354u,0x766a0abbu,0x81c2c92eu,0x92722c85u,
    0xa2bfe8a1u,0xa81a664bu,0xc24b8b70u,0xc76c51a3u,
    0xd192e819u,0xd6990624u,0xf40e3585u,0x106aa070u,
    0x19a4c116u,0x1e376c08u,0x2748774cu,0x34b0bcb5u,
    0x391c0cb3u,0x4ed8aa4au,0x5b9cca4fu,0x682e6ff3u,
    0x748f82eeu,0x78a5636fu,0x84c87814u,0x8cc70208u,
    0x90befffau,0xa4506cebu,0xbef9a3f7u,0xc67178f2u
};

private u32 rotr32(u32 x, i32 n) { return (x >> n) | (x << (32 - n)); }
private u32 ch(u32 e,u32 f,u32 g)  { return (e&f)^(~e&g); }
private u32 maj(u32 a,u32 b,u32 c) { return (a&b)^(a&c)^(b&c); }
private u32 ep0(u32 a) { return rotr32(a,2)^rotr32(a,13)^rotr32(a,22); }
private u32 ep1(u32 e) { return rotr32(e,6)^rotr32(e,11)^rotr32(e,25); }
private u32 sig0(u32 x){ return rotr32(x,7)^rotr32(x,18)^(x>>3); }
private u32 sig1(u32 x){ return rotr32(x,17)^rotr32(x,19)^(x>>10); }

istruc ctx {
    u32 state[8];
    u8  buf[64];
    u64 count;

    void __construct__(&self) {
        self.state[0]=0x6a09e667u; self.state[1]=0xbb67ae85u;
        self.state[2]=0x3c6ef372u; self.state[3]=0xa54ff53au;
        self.state[4]=0x510e527fu; self.state[5]=0x9b05688cu;
        self.state[6]=0x1f83d9abu; self.state[7]=0x5be0cd19u;
        self.count = 0;
        for (i32 i = 0; i < 64; i = i + 1) self.buf[i] = 0;
    }

    private void transform(&self) {
        u32 w[64];
        for (i32 i = 0; i < 16; i = i + 1)
            w[i] = ((u32)self.buf[i*4]<<24)|((u32)self.buf[i*4+1]<<16)|
                   ((u32)self.buf[i*4+2]<<8)|(u32)self.buf[i*4+3];
        for (i32 i = 16; i < 64; i = i + 1)
            w[i] = sig1(w[i-2])+w[i-7]+sig0(w[i-15])+w[i-16];
        u32 a=self.state[0]; u32 b=self.state[1]; u32 c=self.state[2]; u32 d=self.state[3];
        u32 e=self.state[4]; u32 f=self.state[5]; u32 g=self.state[6]; u32 h=self.state[7];
        for (i32 i = 0; i < 64; i = i + 1) {
            u32 t1 = h + ep1(e) + ch(e,f,g) + K[i] + w[i];
            u32 t2 = ep0(a) + maj(a,b,c);
            h=g; g=f; f=e; e=d+t1; d=c; c=b; b=a; a=t1+t2;
        }
        self.state[0]=self.state[0]+a; self.state[1]=self.state[1]+b;
        self.state[2]=self.state[2]+c; self.state[3]=self.state[3]+d;
        self.state[4]=self.state[4]+e; self.state[5]=self.state[5]+f;
        self.state[6]=self.state[6]+g; self.state[7]=self.state[7]+h;
    }

    void update(&self, u8* data, u64 len) {
        u64 i = 0;
        while (i < len) {
            self.buf[self.count % 64] = data[i];
            self.count = self.count + 1;
            if (self.count % 64 == 0) { self.transform(); }
            i = i + 1;
        }
    }

    digest finalize(&self) {
        u64 bit_len = self.count * 8;
        u8 pad = 0x80;
        self.update(&pad, 1);
        while (self.count % 64 != 56) { u8 z = 0; self.update(&z, 1); }
        for (i32 i = 7; i >= 0; i = i - 1) {
            u8 b = (u8)(bit_len >> ((u64)i * 8));
            self.update(&b, 1);
        }
        digest d;
        for (i32 i = 0; i < 8; i = i + 1) {
            d.bytes[i*4]   = (u8)(self.state[i] >> 24);
            d.bytes[i*4+1] = (u8)(self.state[i] >> 16);
            d.bytes[i*4+2] = (u8)(self.state[i] >> 8);
            d.bytes[i*4+3] = (u8)(self.state[i]);
        }
        return d;
    }
}

digest hash_bytes(u8* data, u64 len) {
    ctx c;
    c.update(data, len);
    return c.finalize();
}

digest hash_str(i8* s) {
    u64 n = 0;
    while (s[n] != 0) { n = n + 1; }
    return hash_bytes((u8*)s, n);
}

} // sha256

} // hash
} // std
