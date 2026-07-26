// std.hash — Fast non-cryptographic hashes and cryptographic primitives.
// Access as: std.hash.wyhash_hash_str(...), std.hash.fnv_hash_bytes(...), etc.

// --- Wyhash ---

namespace std {
namespace hash {
comptime u64 WYHASH_SECRET0 = 0xa0761d6478bd642fu;
comptime u64 WYHASH_SECRET1 = 0xe7037ed1a0b428dbu;
comptime u64 WYHASH_SECRET2 = 0x8ebc6af09c88c6e3u;
comptime u64 WYHASH_SECRET3 = 0x589965cc75374cc3u;

fn wyhash_wymix(a: u64, b: u64) u64 {
    let mut lo: u64; let mut hi: u64;
    let mut ah: u64= a >> 32; let mut al: u64= a & 0xFFFFFFFFu;
    let mut bh: u64= b >> 32; let mut bl: u64= b & 0xFFFFFFFFu;
    let mut mid: u64= ah * bl + al * bh;
    lo = al * bl + ((mid & 0xFFFFFFFFu) << 32);
    hi = ah * bh + (mid >> 32) + (lo < al * bl ? (u64)1 : (u64)0);
    return lo ^ hi;
}

fn wyhash_hash_bytes(data: *u8, len: u64, seed: u64) u64 {
    seed = seed ^ WYHASH_SECRET0;
    let mut a: u64= 0; let mut b: u64= 0;
    if (len <= 16) {
        if (len >= 4) {
            let mut p: *u32= (u32*)data;
            a = ((u64)(*p) << 32) | (u64)(*((u32*)(data + len - 4)));
            let mut q: *u32= (u32*)(data + (len >> 3 << 2));
            b = ((u64)(*q) << 32) | (u64)(*((u32*)(data + len - 4 - (len >> 3 << 2))));
        } else if (len > 0) {
            a = ((u64)data[0] << 16) | ((u64)data[len>>(u64)1] << 8) | (u64)data[len-(u64)1];
            b = 0;
        }
    } else {
        let mut i: u64= len;
        let mut p: u64= (u64)(void*)data;
        if (i > 48) {
            let mut s1: u64= seed; let mut s2: u64= seed;
            while (i > 48) {
                seed = wyhash_wymix(*(u64*)(void*)p ^ WYHASH_SECRET1, *(u64*)(void*)(p+8) ^ seed);
                s1   = wyhash_wymix(*(u64*)(void*)(p+16) ^ WYHASH_SECRET2, *(u64*)(void*)(p+24) ^ s1);
                s2   = wyhash_wymix(*(u64*)(void*)(p+32) ^ WYHASH_SECRET3, *(u64*)(void*)(p+40) ^ s2);
                p = p + (u64)48; i = i - (u64)48;
            }
            seed = seed ^ s1 ^ s2;
        }
        while (i > 16) {
            seed = wyhash_wymix(*(u64*)(void*)p ^ WYHASH_SECRET1, *(u64*)(void*)(p+8) ^ seed);
            p = p + (u64)16; i = i - (u64)16;
        }
        a = *(u64*)(void*)(p + i - 16);
        b = *(u64*)(void*)(p + i - 8);
    }
    return wyhash_wymix(WYHASH_SECRET1 ^ len, wyhash_wymix(a ^ WYHASH_SECRET1, b ^ seed));
}

fn wyhash_hash_str(s: *i8, seed: u64) u64 {
    let mut n: u64= 0;
    while (s[n] != 0) { n = n + 1; }
    return wyhash_hash_bytes((u8*)s, n, seed);
}

fn wyhash_hash_i64(v: i64, seed: u64) u64 { return wyhash_hash_bytes((u8*)&v, (u64)8, seed); }
fn wyhash_hash_u64(v: u64, seed: u64) u64 { return wyhash_hash_bytes((u8*)&v, (u64)8, seed); }
fn wyhash_hash_f64(v: f64, seed: u64) u64 { return wyhash_hash_bytes((u8*)&v, (u64)8, seed); }

// --- FNV-1a ---

comptime u64 FNV_OFFSET = 14695981039346656037u;
comptime u64 FNV_PRIME  = 1099511628211u;

fn fnv_hash_bytes(data: *u8, len: u64) u64 {
    let mut h: u64= FNV_OFFSET;
    for (let mut i: u64 = 0; i < len; i = i + 1)
        h = (h ^ (u64)data[i]) * FNV_PRIME;
    return h;
}

fn fnv_hash_str(s: *i8) u64 {
    let mut h: u64= FNV_OFFSET;
    let mut i: i32= 0;
    while (s[i] != 0) { h = (h ^ (u64)(u8)s[i]) * FNV_PRIME; i = i + 1; }
    return h;
}

fn fnv_hash32_bytes(data: *u8, len: u64) u32 {
    let mut h: u32= 2166136261u;
    for (let mut i: u64 = 0; i < len; i = i + 1)
        h = (h ^ (u32)data[i]) * 16777619u;
    return h;
}

// --- SHA-256 ---

struct sha256_digest { let bytes: [32]u8; }

istruc sha256_ctx {
    let mut state: [8]u32;
    let mut buf: [64]u8;
    let mut count: u64;

    fn __construct__(self: *sha256_ctx) void {
        self.state[0]=0x6a09e667u; self.state[1]=0xbb67ae85u;
        self.state[2]=0x3c6ef372u; self.state[3]=0xa54ff53au;
        self.state[4]=0x510e527fu; self.state[5]=0x9b05688cu;
        self.state[6]=0x1f83d9abu; self.state[7]=0x5be0cd19u;
        self.count = 0;
        for (let mut i: i32 = 0; i < 64; i = i + 1) self.buf[i] = 0;
    }

    fn rotr32(self: *sha256_ctx, x: u32, n: i32) u32 { return (x >> n) | (x << (32 - n)); }
    fn ch_fn(self: *sha256_ctx, e: u32, f: u32, g: u32) u32 { return (e&f)^(~e&g); }
    fn maj_fn(self: *sha256_ctx, a: u32, b: u32, c: u32) u32 { return (a&b)^(a&c)^(b&c); }
    fn ep0(self: *sha256_ctx, a: u32) u32 { return self.rotr32(a,2)^self.rotr32(a,13)^self.rotr32(a,22); }
    fn ep1(self: *sha256_ctx, e: u32) u32 { return self.rotr32(e,6)^self.rotr32(e,11)^self.rotr32(e,25); }
    fn sig0(self: *sha256_ctx, x: u32) u32{ return self.rotr32(x,7)^self.rotr32(x,18)^(x>>3); }
    fn sig1(self: *sha256_ctx, x: u32) u32{ return self.rotr32(x,17)^self.rotr32(x,19)^(x>>10); }

    fn transform(self: *sha256_ctx) void {
        let mut K: [64]u32;
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
        let mut w: [64]u32;
        for (let mut i: i32 = 0; i < 16; i = i + 1)
            w[i] = ((u32)self.buf[i*4]<<24)|((u32)self.buf[i*4+1]<<16)|
                   ((u32)self.buf[i*4+2]<<8)|(u32)self.buf[i*4+3];
        for (let mut i: i32 = 16; i < 64; i = i + 1)
            w[i] = self.sig1(w[i-2])+w[i-7]+self.sig0(w[i-15])+w[i-16];
        let mut a: u32=self.state[0]; let mut b: u32=self.state[1]; let mut c: u32=self.state[2]; let mut d: u32=self.state[3];
        let mut e: u32=self.state[4]; let mut f: u32=self.state[5]; let mut g: u32=self.state[6]; let mut h: u32=self.state[7];
        for (let mut i: i32 = 0; i < 64; i = i + 1) {
            let mut t1: u32= h + self.ep1(e) + self.ch_fn(e,f,g) + K[i] + w[i];
            let mut t2: u32= self.ep0(a) + self.maj_fn(a,b,c);
            h=g; g=f; f=e; e=d+t1; d=c; c=b; b=a; a=t1+t2;
        }
        self.state[0]=self.state[0]+a; self.state[1]=self.state[1]+b;
        self.state[2]=self.state[2]+c; self.state[3]=self.state[3]+d;
        self.state[4]=self.state[4]+e; self.state[5]=self.state[5]+f;
        self.state[6]=self.state[6]+g; self.state[7]=self.state[7]+h;
    }

    fn update(self: *sha256_ctx, data: *u8, len: u64) void {
        let mut i: u64= 0;
        while (i < len) {
            self.buf[self.count % 64] = data[i];
            self.count = self.count + 1;
            if (self.count % 64 == 0) { self.transform(); }
            i = i + 1;
        }
    }

    fn finalize(self: *sha256_ctx) sha256_digest {
        let mut bit_len: u64= self.count * 8;
        let mut pad: u8= 0x80u;
        self.update(&pad, (u64)1);
        while (self.count % 64 != 56) { let mut z: u8= 0; self.update(&z, (u64)1); }
        for (let mut i: i32 = 7; i >= 0; i = i - 1) {
            let mut bv: u8= (u8)(bit_len >> ((u64)i * 8));
            self.update(&bv, (u64)1);
        }
        let mut d: sha256_digest;
        for (let mut i: i32 = 0; i < 8; i = i + 1) {
            d.bytes[i*4]   = (u8)(self.state[i] >> 24);
            d.bytes[i*4+1] = (u8)(self.state[i] >> 16);
            d.bytes[i*4+2] = (u8)(self.state[i] >> 8);
            d.bytes[i*4+3] = (u8)(self.state[i]);
        }
        return d;
    }
}

fn sha256_hash_bytes(data: *u8, len: u64) sha256_digest {
    let mut c: sha256_ctx();
    c.update(data, len);
    return c.finalize();
}

fn sha256_hash_str(s: *i8) sha256_digest {
    let mut n: u64= 0;
    while (s[n] != 0) { n = n + 1; }
    return sha256_hash_bytes((u8*)s, n);
}

} // namespace hash
} // namespace std