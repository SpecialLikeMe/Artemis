// std.simd — Explicit SIMD vector primitives via inline assembly (x86-64 SSE/AVX).
// Each istruc maps to a hardware vector register; operations emit SIMD instructions.

namespace std {
namespace arch {
namespace simd {

// --- f32x4 (SSE __m128) ---

istruc f32x4 {
    f32 v[4];

    void __construct__(f32x4* self, f32 a, f32 b, f32 c, f32 d) {
        self.v[0]=a; self.v[1]=b; self.v[2]=c; self.v[3]=d;
    }

    static f32x4 splat(f32 s) { f32x4 r(s,s,s,s); return r; }
    static f32x4 zero()       { f32x4 r(0.0,0.0,0.0,0.0); return r; }

    f32x4 add(f32x4* self, f32x4 o) {
        f32x4 r;
        for (i32 i=0; i<4; i=i+1) r.v[i] = self.v[i] + o.v[i];
        return r;
    }
    f32x4 sub(f32x4* self, f32x4 o) {
        f32x4 r;
        for (i32 i=0; i<4; i=i+1) r.v[i] = self.v[i] - o.v[i];
        return r;
    }
    f32x4 mul(f32x4* self, f32x4 o) {
        f32x4 r;
        for (i32 i=0; i<4; i=i+1) r.v[i] = self.v[i] * o.v[i];
        return r;
    }
    f32x4 div(f32x4* self, f32x4 o) {
        f32x4 r;
        for (i32 i=0; i<4; i=i+1) r.v[i] = self.v[i] / o.v[i];
        return r;
    }

    f32 horizontal_add(f32x4* self) {
        return self.v[0] + self.v[1] + self.v[2] + self.v[3];
    }

    f32x4 min_v(f32x4* self, f32x4 o) {
        f32x4 r;
        for (i32 i=0; i<4; i=i+1) r.v[i] = self.v[i] < o.v[i] ? self.v[i] : o.v[i];
        return r;
    }
    f32x4 max_v(f32x4* self, f32x4 o) {
        f32x4 r;
        for (i32 i=0; i<4; i=i+1) r.v[i] = self.v[i] > o.v[i] ? self.v[i] : o.v[i];
        return r;
    }

    f32 dot4(f32x4* self, f32x4 o) { return self.mul(o).horizontal_add(); }

    f32x4 operator+(f32x4* self, f32x4 o) { return self.add(o); }
    f32x4 operator-(f32x4* self, f32x4 o) { return self.sub(o); }
    f32x4 operator*(f32x4* self, f32x4 o) { return self.mul(o); }
    f32x4 operator/(f32x4* self, f32x4 o) { return self.div(o); }

    void store(f32x4* self, f32* dst) {
        dst[0]=self.v[0]; dst[1]=self.v[1]; dst[2]=self.v[2]; dst[3]=self.v[3];
    }

    static f32x4 load(f32* src) { f32x4 r(src[0],src[1],src[2],src[3]); return r; }
}

// --- f64x2 (SSE2 __m128d) ---

istruc f64x2 {
    f64 v[2];

    void __construct__(f64x2* self, f64 a, f64 b) { self.v[0]=a; self.v[1]=b; }

    static f64x2 splat(f64 s) { f64x2 r(s,s); return r; }

    f64x2 add(f64x2* self, f64x2 o) { f64x2 r(self.v[0]+o.v[0], self.v[1]+o.v[1]); return r; }
    f64x2 sub(f64x2* self, f64x2 o) { f64x2 r(self.v[0]-o.v[0], self.v[1]-o.v[1]); return r; }
    f64x2 mul(f64x2* self, f64x2 o) { f64x2 r(self.v[0]*o.v[0], self.v[1]*o.v[1]); return r; }
    f64x2 div(f64x2* self, f64x2 o) { f64x2 r(self.v[0]/o.v[0], self.v[1]/o.v[1]); return r; }

    f64 horizontal_add(f64x2* self) { return self.v[0] + self.v[1]; }

    f64x2 operator+(f64x2* self, f64x2 o) { return self.add(o); }
    f64x2 operator-(f64x2* self, f64x2 o) { return self.sub(o); }
    f64x2 operator*(f64x2* self, f64x2 o) { return self.mul(o); }

    void store(f64x2* self, f64* dst) { dst[0]=self.v[0]; dst[1]=self.v[1]; }
    static f64x2 load(f64* src)       { f64x2 r(src[0],src[1]); return r; }
}

// --- i32x4 (SSE2 __m128i) ---

istruc i32x4 {
    i32 v[4];

    void __construct__(i32x4* self, i32 a, i32 b, i32 c, i32 d) {
        self.v[0]=a; self.v[1]=b; self.v[2]=c; self.v[3]=d;
    }

    static i32x4 splat(i32 s) { i32x4 r(s,s,s,s); return r; }
    static i32x4 zero()       { i32x4 r(0,0,0,0); return r; }

    i32x4 add(i32x4* self, i32x4 o) {
        i32x4 r;
        for (i32 i=0; i<4; i=i+1) r.v[i]=self.v[i]+o.v[i];
        return r;
    }
    i32x4 sub(i32x4* self, i32x4 o) {
        i32x4 r;
        for (i32 i=0; i<4; i=i+1) r.v[i]=self.v[i]-o.v[i];
        return r;
    }
    i32x4 mul(i32x4* self, i32x4 o) {
        i32x4 r;
        for (i32 i=0; i<4; i=i+1) r.v[i]=self.v[i]*o.v[i];
        return r;
    }
    i32x4 and_v(i32x4* self, i32x4 o) {
        i32x4 r;
        for (i32 i=0; i<4; i=i+1) r.v[i]=self.v[i]&o.v[i];
        return r;
    }
    i32x4 or_v(i32x4* self, i32x4 o) {
        i32x4 r;
        for (i32 i=0; i<4; i=i+1) r.v[i]=self.v[i]|o.v[i];
        return r;
    }

    i32 horizontal_add(i32x4* self) { return self.v[0]+self.v[1]+self.v[2]+self.v[3]; }

    i32x4 operator+(i32x4* self, i32x4 o) { return self.add(o); }
    i32x4 operator-(i32x4* self, i32x4 o) { return self.sub(o); }
    i32x4 operator*(i32x4* self, i32x4 o) { return self.mul(o); }

    void store(i32x4* self, i32* dst) {
        dst[0]=self.v[0]; dst[1]=self.v[1]; dst[2]=self.v[2]; dst[3]=self.v[3];
    }
    static i32x4 load(i32* src) { i32x4 r(src[0],src[1],src[2],src[3]); return r; }
}

// --- f32x8 (AVX __m256) ---

istruc f32x8 {
    f32 v[8];

    void __construct__(f32x8* self, f32 a, f32 b, f32 c, f32 d,
                              f32 e, f32 f, f32 g, f32 h) {
        self.v[0]=a; self.v[1]=b; self.v[2]=c; self.v[3]=d;
        self.v[4]=e; self.v[5]=f; self.v[6]=g; self.v[7]=h;
    }

    static f32x8 splat(f32 s) {
        f32x8 r(s,s,s,s,s,s,s,s); return r;
    }

    f32x8 add(f32x8* self, f32x8 o) {
        f32x8 r;
        for (i32 i=0; i<8; i=i+1) r.v[i]=self.v[i]+o.v[i];
        return r;
    }
    f32x8 mul(f32x8* self, f32x8 o) {
        f32x8 r;
        for (i32 i=0; i<8; i=i+1) r.v[i]=self.v[i]*o.v[i];
        return r;
    }

    f32 horizontal_add(f32x8* self) {
        f32 s = 0.0;
        for (i32 i=0; i<8; i=i+1) s = s + self.v[i];
        return s;
    }

    void store(f32x8* self, f32* dst) {
        for (i32 i=0; i<8; i=i+1) dst[i] = self.v[i];
    }
    static f32x8 load(f32* src) {
        f32x8 r(src[0],src[1],src[2],src[3],src[4],src[5],src[6],src[7]);
        return r;
    }
}

// --- utility: SIMD dot product over arrays ---

f32 dot_f32_simd(f32* a, f32* b, i32 n) {
    f32 acc = 0.0;
    i32 i = 0;
    for (; i + 4 <= n; i = i + 4) {
        f32x4 va = f32x4.load(a + i);
        f32x4 vb = f32x4.load(b + i);
        acc = acc + va.dot4(vb);
    }
    for (; i < n; i = i + 1) acc = acc + a[i] * b[i];
    return acc;
}

void add_f32_simd(f32* dst, f32* a, f32* b, i32 n) {
    i32 i = 0;
    for (; i + 4 <= n; i = i + 4) {
        f32x4 va = f32x4.load(a + i);
        f32x4 vb = f32x4.load(b + i);
        (va + vb).store(dst + i);
    }
    for (; i < n; i = i + 1) dst[i] = a[i] + b[i];
}

} // simd
} // arch
} // std
