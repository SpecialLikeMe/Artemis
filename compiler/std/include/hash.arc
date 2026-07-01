// std.hash — Fast non-cryptographic hashes and cryptographic primitives.
// All functions are at global scope after extern std.hash; — use prefixed names:
//   wyhash_hash_bytes / wyhash_hash_str / wyhash_hash_i64 etc.
//   fnv_hash_bytes / fnv_hash_str / fnv_hash32_bytes
//   sha256_ctx / sha256_hash_bytes / sha256_hash_str

// --- Wyhash ---

namespace hash {
constexpr u64 WYHASH_SECRET0 = 0xa0761d6478bd642fu;
constexpr u64 WYHASH_SECRET1 = 0xe7037ed1a0b428dbu;
constexpr u64 WYHASH_SECRET2 = 0x8ebc6af09c88c6e3u;
constexpr u64 WYHASH_SECRET3 = 0x589965cc75374cc3u;

u64 wyhash_wymix(u64 a, u64 b) {
    u64 lo; u64 hi;
    u64 ah = a >> 32; u64 al = a & 0xFFFFFFFFu;
    u64 bh = b >> 32; u64 bl = b & 0xFFFFFFFFu;
    u64 mid = ah * bl + al * bh;
    lo = al * bl + ((mid & 0xFFFFFFFFu) << 32);
    hi = ah * bh + (mid >> 32) + (lo < al * bl ? 1u : 0u);
    return lo ^ hi;
}

u64 wyhash_hash_bytes(u8* data, u64 len, u64 seed) {
    seed = seed ^ WYHASH_SECRET0;
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
                seed = wyhash_wymix(*(u64*)(void*)p ^ WYHASH_SECRET1, *(u64*)(void*)(p+8) ^ seed);
                s1   = wyhash_wymix(*(u64*)(void*)(p+16) ^ WYHASH_SECRET2, *(u64*)(void*)(p+24) ^ s1);
                s2   = wyhash_wymix(*(u64*)(void*)(p+32) ^ WYHASH_SECRET3, *(u64*)(void*)(p+40) ^ s2);
                p = p + 48; i = i - 48;
            }
            seed = seed ^ s1 ^ s2;
        }
        while (i > 16) {
            seed = wyhash_wymix(*(u64*)(void*)p ^ WYHASH_SECRET1, *(u64*)(void*)(p+8) ^ seed);
            p = p + 16; i = i - 16;
        }
        a = *(u64*)(void*)(p + i - 16);
        b = *(u64*)(void*)(p + i - 8);
    }
    return wyhash_wymix(WYHASH_SECRET1 ^ len, wyhash_wymix(a ^ WYHASH_SECRET1, b ^ seed));
}

u64 wyhash_hash_str(i8* s, u64 seed) {
    u64 n = 0;
    while (s[n] != 0) { n = n + 1; }
    return wyhash_hash_bytes((u8*)s, n, seed);
}

u64 wyhash_hash_i64(i64 v, u64 seed) { return wyhash_hash_bytes((u8*)&v, (u64)8, seed); }
u64 wyhash_hash_u64(u64 v, u64 seed) { return wyhash_hash_bytes((u8*)&v, (u64)8, seed); }
u64 wyhash_hash_f64(f64 v, u64 seed) { return wyhash_hash_bytes((u8*)&v, (u64)8, seed); }

// --- FNV-1a ---

constexpr u64 FNV_OFFSET = 14695981039346656037u;
constexpr u64 FNV_PRIME  = 1099511628211u;

u64 fnv_hash_bytes(u8* data, u64 len) {
    u64 h = FNV_OFFSET;
    for (u64 i = 0; i < len; i = i + 1)
        h = (h ^ (u64)data[i]) * FNV_PRIME;
    return h;
}

u64 fnv_hash_str(i8* s) {
    u64 h = FNV_OFFSET;
    i32 i = 0;
    while (s[i] != 0) { h = (h ^ (u64)(u8)s[i]) * FNV_PRIME; i = i + 1; }
    return h;
}

u32 fnv_hash32_bytes(u8* data, u64 len) {
    u32 h = 2166136261u;
    for (u64 i = 0; i < len; i = i + 1)
        h = (h ^ (u32)data[i]) * 16777619u;
    return h;
}

// --- SHA-256 ---

struct sha256_digest { u8 bytes[32]; }

istruc sha256_ctx {
    u32 state[8];
    u8  buf[64];
    u64 count;

    void __construct__(sha256_ctx* self) {
        self.state[0]=0x6a09e667u; self.state[1]=0xbb67ae85u;
        self.state[2]=0x3c6ef372u; self.state[3]=0xa54ff53au;
        self.state[4]=0x510e527fu; self.state[5]=0x9b05688cu;
        self.state[6]=0x1f83d9abu; self.state[7]=0x5be0cd19u;
        self.count = 0;
        for (i32 i = 0; i < 64; i = i + 1) self.buf[i] = 0;
    }

    private u32 rotr32(sha256_ctx* self, u32 x, i32 n) { return (x >> n) | (x << (32 - n)); }
    private u32 ch_fn(sha256_ctx* self, u32 e, u32 f, u32 g) { return (e&f)^(~e&g); }
    private u32 maj_fn(sha256_ctx* self, u32 a, u32 b, u32 c) { return (a&b)^(a&c)^(b&c); }
    private u32 ep0(sha256_ctx* self, u32 a) { return self.rotr32(a,2)^self.rotr32(a,13)^self.rotr32(a,22); }
    private u32 ep1(sha256_ctx* self, u32 e) { return self.rotr32(e,6)^self.rotr32(e,11)^self.rotr32(e,25); }
    private u32 sig0(sha256_ctx* self, u32 x){ return self.rotr32(x,7)^self.rotr32(x,18)^(x>>3); }
    private u32 sig1(sha256_ctx* self, u32 x){ return self.rotr32(x,17)^self.rotr32(x,19)^(x>>10); }

    private void transform(sha256_ctx* self) {
        u32 K[64];
        K[0]=0x428a2f98u; K[1]=0x71374491u; K[2]=0xb5c0fbcfu; K[3]=0xe9b5dba5u;
        K[4]=0x3956c25bu; K[5]=0x59f111f1u; K[6]=0x923f82a4u; K[7]=0xab1c5ed5u;
        K[8]=0xd807aa98u; K[9]=0x12835b01u; K[10]=0x243185beu; K[11]=0x550c7dc3u;
        K[12]=0x72be5d74u; K[13]=0x80deb1feu; K[14]=0x9bdc06a7u; K[15]=0xc19bf174u;
        K[16]=0xe49b69c1u; K[17]=0xefbe4786u; K[18]=0x0fc19dc6u; K[19]=0x240ca1ccu;
        K[20]=0x2de92c6fu; K[21]=0x4a7484aau; K[22]=0x5cb0a9dcu; K[23]=0x76f988dau;
        K[24]=0x983e5152u; K[25]=0xa831c66du; K[26]=0xb00327c8u; K[27]=0xbf597fc7u;
        K[28]=0xc6e00bf3u; K[29]=0xd5a79147u; K[30]=0x06ca6351u; K[31]=0x14292967u;
        K[32]=0x27b70a85u; K[33]=0x2e1b2138u; K[34]=0x4d2c6dfcu; K[35]=0x53380d13u;
        K[36]=0x650a7354u; K[37]=0x766a0abbu; K[38]=0x81c2c92eu; K[39]=0x92722c85u;
        K[40]=0xa2bfe8a1u; K[41]=0xa81a664bu; K[42]=0xc24b8b70u; K[43]=0xc76c51a3u;
        K[44]=0xd192e819u; K[45]=0xd6990624u; K[46]=0xf40e3585u; K[47]=0x106aa070u;
        K[48]=0x19a4c116u; K[49]=0x1e376c08u; K[50]=0x2748774cu; K[51]=0x34b0bcb5u;
        K[52]=0x391c0cb3u; K[53]=0x4ed8aa4au; K[54]=0x5b9cca4fu; K[55]=0x682e6ff3u;
        K[56]=0x748f82eeu; K[57]=0x78a5636fu; K[58]=0x84c87814u; K[59]=0x8cc70208u;
        K[60]=0x90befffau; K[61]=0xa4506cebu; K[62]=0xbef9a3f7u; K[63]=0xc67178f2u;
        u32 w[64];
        for (i32 i = 0; i < 16; i = i + 1)
            w[i] = ((u32)self.buf[i*4]<<24)|((u32)self.buf[i*4+1]<<16)|
                   ((u32)self.buf[i*4+2]<<8)|(u32)self.buf[i*4+3];
        for (i32 i = 16; i < 64; i = i + 1)
            w[i] = self.sig1(w[i-2])+w[i-7]+self.sig0(w[i-15])+w[i-16];
        u32 a=self.state[0]; u32 b=self.state[1]; u32 c=self.state[2]; u32 d=self.state[3];
        u32 e=self.state[4]; u32 f=self.state[5]; u32 g=self.state[6]; u32 h=self.state[7];
        for (i32 i = 0; i < 64; i = i + 1) {
            u32 t1 = h + self.ep1(e) + self.ch_fn(e,f,g) + K[i] + w[i];
            u32 t2 = self.ep0(a) + self.maj_fn(a,b,c);
            h=g; g=f; f=e; e=d+t1; d=c; c=b; b=a; a=t1+t2;
        }
        self.state[0]=self.state[0]+a; self.state[1]=self.state[1]+b;
        self.state[2]=self.state[2]+c; self.state[3]=self.state[3]+d;
        self.state[4]=self.state[4]+e; self.state[5]=self.state[5]+f;
        self.state[6]=self.state[6]+g; self.state[7]=self.state[7]+h;
    }

    void update(sha256_ctx* self, u8* data, u64 len) {
        u64 i = 0;
        while (i < len) {
            self.buf[self.count % 64] = data[i];
            self.count = self.count + 1;
            if (self.count % 64 == 0) { self.transform(); }
            i = i + 1;
        }
    }

    sha256_digest finalize(sha256_ctx* self) {
        u64 bit_len = self.count * 8;
        u8 pad = 0x80u;
        self.update(&pad, (u64)1);
        while (self.count % 64 != 56) { u8 z = 0; self.update(&z, (u64)1); }
        for (i32 i = 7; i >= 0; i = i - 1) {
            u8 bv = (u8)(bit_len >> ((u64)i * 8));
            self.update(&bv, (u64)1);
        }
        sha256_digest d;
        for (i32 i = 0; i < 8; i = i + 1) {
            d.bytes[i*4]   = (u8)(self.state[i] >> 24);
            d.bytes[i*4+1] = (u8)(self.state[i] >> 16);
            d.bytes[i*4+2] = (u8)(self.state[i] >> 8);
            d.bytes[i*4+3] = (u8)(self.state[i]);
        }
        return d;
    }
}

sha256_digest sha256_hash_bytes(u8* data, u64 len) {
    sha256_ctx c;
    c.update(data, len);
    return c.finalize();
}

sha256_digest sha256_hash_str(i8* s) {
    u64 n = 0;
    while (s[n] != 0) { n = n + 1; }
    return sha256_hash_bytes((u8*)s, n);
}

} // namespace hash