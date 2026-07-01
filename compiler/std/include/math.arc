// std.math — Complete mathematics library.

// C math functions (libm)
extern f64 sin(f64 x);
extern f64 cos(f64 x);
extern f64 tan(f64 x);
extern f64 asin(f64 x);
extern f64 acos(f64 x);
extern f64 atan(f64 x);
extern f64 atan2(f64 y, f64 x);
extern f64 sinh(f64 x);
extern f64 cosh(f64 x);
extern f64 tanh(f64 x);
extern f64 exp(f64 x);
extern f64 exp2(f64 x);
extern f64 log(f64 x);
extern f64 log2(f64 x);
extern f64 log10(f64 x);
extern f64 pow(f64 base, f64 exp);
extern f64 sqrt(f64 x);
extern f64 cbrt(f64 x);
extern f64 ceil(f64 x);
extern f64 floor(f64 x);
extern f64 round(f64 x);
extern f64 trunc(f64 x);
extern f64 fabs(f64 x);
extern f64 fmod(f64 x, f64 y);
extern f64 hypot(f64 x, f64 y);
extern f64 ldexp(f64 x, i32 exp);
extern f64 frexp(f64 x, i32* exp);
extern f64 modf(f64 x, f64* iptr);
extern f32 sinf(f32 x);
extern f32 cosf(f32 x);
extern f32 tanf(f32 x);
extern f32 sqrtf(f32 x);
extern f32 fabsf(f32 x);
extern f32 floorf(f32 x);
extern f32 ceilf(f32 x);
extern f32 roundf(f32 x);
extern f32 powf(f32 b, f32 e);
extern f32 logf(f32 x);
extern f32 expf(f32 x);

constexpr f64 PI     = 3.14159265358979323846;
constexpr f64 TAU    = 6.28318530717958647692;
constexpr f64 E      = 2.71828182845904523536;
constexpr f64 PHI    = 1.61803398874989484820;
constexpr f64 SQRT2  = 1.41421356237309504880;
constexpr f64 LN2    = 0.69314718055994530941;
constexpr f64 LN10   = 2.30258509299404568401;
constexpr f64 INF    = 1.0 / 0.0;
constexpr f64 NAN_V  = 0.0 / 0.0;

// --- basic ---
i32 abs_i32(i32 x)   { return x < 0 ? -x : x; }
i64 abs_i64(i64 x)   { return x < 0 ? -x : x; }
f32 abs_f32(f32 x)   { return fabsf(x); }
f64 abs_f64(f64 x)   { return fabs(x); }

i32 min_i32(i32 a, i32 b)   { return a < b ? a : b; }
i32 max_i32(i32 a, i32 b)   { return a > b ? a : b; }
i64 min_i64(i64 a, i64 b)   { return a < b ? a : b; }
i64 max_i64(i64 a, i64 b)   { return a > b ? a : b; }
f32 min_f32(f32 a, f32 b)   { return a < b ? a : b; }
f32 max_f32(f32 a, f32 b)   { return a > b ? a : b; }
f64 min_f64(f64 a, f64 b)   { return a < b ? a : b; }
f64 max_f64(f64 a, f64 b)   { return a > b ? a : b; }

i32 clamp_i32(i32 v, i32 lo, i32 hi) { return v < lo ? lo : v > hi ? hi : v; }
f32 clamp_f32(f32 v, f32 lo, f32 hi) { return v < lo ? lo : v > hi ? hi : v; }
f64 clamp_f64(f64 v, f64 lo, f64 hi) { return v < lo ? lo : v > hi ? hi : v; }

i32 sign_i32(i32 x)  { return x < 0 ? -1 : x > 0 ? 1 : 0; }
f64 sign_f64(f64 x)  { return x < 0.0 ? -1.0 : x > 0.0 ? 1.0 : 0.0; }

f64 lerp(f64 a, f64 b, f64 t) { return a + t * (b - a); }
f32 lerp_f32(f32 a, f32 b, f32 t) { return a + t * (b - a); }

// --- trig ---
f64 deg_to_rad(f64 d) { return d * PI / 180.0; }
f64 rad_to_deg(f64 r) { return r * 180.0 / PI; }

// --- rounding ---
f64 snap(f64 v, f64 step) { return floor(v / step + 0.5) * step; }

// --- power / log ---
f64 log_base(f64 x, f64 base) { return log(x) / log(base); }

bool is_power_of_two(u64 n) { return n != 0 && (n & (n - 1)) == 0; }
u64 next_power_of_two(u64 n) {
    n = n - 1;
    n = n | (n >> 1);
    n = n | (n >> 2);
    n = n | (n >> 4);
    n = n | (n >> 8);
    n = n | (n >> 16);
    n = n | (n >> 32);
    return n + 1;
}

// --- integer arithmetic ---
i32 gcd(i32 a, i32 b) {
    if (a < 0) { a = -a; }
    if (b < 0) { b = -b; }
    while (b != 0) { i32 t = b; b = a % b; a = t; }
    return a;
}
i32 lcm(i32 a, i32 b) {
    // inline gcd to avoid same-namespace bare-name call limitation
    i32 g = a < 0 ? -a : a;
    i32 t = b < 0 ? -b : b;
    while (t != 0) { i32 r = g % t; g = t; t = r; }
    return (a / g) * b;
}
i32 div_ceil(i32 a, i32 b) { return (a + b - 1) / b; }
i32 div_floor(i32 a, i32 b){ return a / b; }
bool is_even(i64 n) { return (n & 1) == 0; }
bool is_odd(i64 n)  { return (n & 1) != 0; }

// --- 2D vector ---
istruc vec2 {
    f64 x; f64 y;

    void __construct__(&self, f64 vx, f64 vy) { self.x = vx; self.y = vy; }

    vec2 add(&self, vec2 o)   { vec2 r(self.x+o.x, self.y+o.y); return r; }
    vec2 sub(&self, vec2 o)   { vec2 r(self.x-o.x, self.y-o.y); return r; }
    vec2 scale(&self, f64 s)  { vec2 r(self.x*s,   self.y*s);   return r; }
    f64  dot(&self, vec2 o)   { return self.x*o.x + self.y*o.y; }
    f64  len_sq(&self)        { return self.x*self.x + self.y*self.y; }
    f64  len(&self)           { return sqrt(self.len_sq()); }
    vec2 normalize(&self) {
        f64 l = self.len();
        if (l == 0.0) { vec2 z(0.0, 0.0); return z; }
        vec2 r(self.x/l, self.y/l); return r;
    }
    f64  cross(&self, vec2 o) { return self.x*o.y - self.y*o.x; }
    vec2 perp(&self)          { vec2 r(-self.y, self.x); return r; }
    f64  angle(&self)         { return atan2(self.y, self.x); }
    vec2 rotate(&self, f64 a) {
        f64 c = cos(a); f64 s = sin(a);
        vec2 r(self.x*c - self.y*s, self.x*s + self.y*c); return r;
    }
    bool operator==(&self, vec2 o) { return self.x == o.x && self.y == o.y; }
    vec2 operator+(&self, vec2 o)  { return self.add(o); }
    vec2 operator-(&self, vec2 o)  { return self.sub(o); }
    vec2 operator*(&self, f64 s)   { return self.scale(s); }
}

// --- 3D vector ---
istruc vec3 {
    f64 x; f64 y; f64 z;

    void __construct__(&self, f64 vx, f64 vy, f64 vz) { self.x=vx; self.y=vy; self.z=vz; }

    vec3 add(&self, vec3 o)  { vec3 r(self.x+o.x,self.y+o.y,self.z+o.z); return r; }
    vec3 sub(&self, vec3 o)  { vec3 r(self.x-o.x,self.y-o.y,self.z-o.z); return r; }
    vec3 scale(&self, f64 s) { vec3 r(self.x*s,self.y*s,self.z*s); return r; }
    f64  dot(&self, vec3 o)  { return self.x*o.x+self.y*o.y+self.z*o.z; }
    f64  len_sq(&self)       { return self.x*self.x+self.y*self.y+self.z*self.z; }
    f64  len(&self)          { return sqrt(self.len_sq()); }
    vec3 cross(&self, vec3 o) {
        vec3 r(self.y*o.z - self.z*o.y,
               self.z*o.x - self.x*o.z,
               self.x*o.y - self.y*o.x);
        return r;
    }
    vec3 normalize(&self) {
        f64 l = self.len();
        if (l == 0.0) { vec3 z(0.0,0.0,0.0); return z; }
        vec3 r(self.x/l,self.y/l,self.z/l); return r;
    }
    vec3 reflect(&self, vec3 n) { return self.sub(n.scale(2.0*self.dot(n))); }
    vec3 operator+(&self, vec3 o) { return self.add(o); }
    vec3 operator-(&self, vec3 o) { return self.sub(o); }
    vec3 operator*(&self, f64 s)  { return self.scale(s); }
}

// --- 4x4 matrix (column-major) ---
istruc mat4 {
    f64 m[16]; // [col*4 + row]

    void __construct__(&self) {
        for (i32 i = 0; i < 16; i = i + 1) { self.m[i] = 0.0; }
    }

    static mat4 identity() {
        mat4 r;
        r.m[0]=1.0; r.m[5]=1.0; r.m[10]=1.0; r.m[15]=1.0;
        return r;
    }

    f64 at(&self, i32 row, i32 col) { return self.m[col*4 + row]; }

    mat4 mul(&self, mat4 b) {
        mat4 r;
        for (i32 row = 0; row < 4; row = row + 1) {
            for (i32 col = 0; col < 4; col = col + 1) {
                f64 s = 0.0;
                for (i32 k = 0; k < 4; k = k + 1)
                    s = s + self.m[k*4+row] * b.m[col*4+k];
                r.m[col*4+row] = s;
            }
        }
        return r;
    }

    mat4 transpose(&self) {
        mat4 r;
        for (i32 i = 0; i < 4; i = i + 1)
            for (i32 j = 0; j < 4; j = j + 1)
                r.m[i*4+j] = self.m[j*4+i];
        return r;
    }

    static mat4 translate(f64 tx, f64 ty, f64 tz) {
        mat4 r = mat4.identity();
        r.m[12]=tx; r.m[13]=ty; r.m[14]=tz;
        return r;
    }

    static mat4 scale_m(f64 sx, f64 sy, f64 sz) {
        mat4 r;
        r.m[0]=sx; r.m[5]=sy; r.m[10]=sz; r.m[15]=1.0;
        return r;
    }

    static mat4 rotate_x(f64 a) {
        mat4 r = mat4.identity();
        r.m[5]=cos(a); r.m[6]=sin(a); r.m[9]=-sin(a); r.m[10]=cos(a);
        return r;
    }

    static mat4 rotate_y(f64 a) {
        mat4 r = mat4.identity();
        r.m[0]=cos(a); r.m[2]=-sin(a); r.m[8]=sin(a); r.m[10]=cos(a);
        return r;
    }

    static mat4 rotate_z(f64 a) {
        mat4 r = mat4.identity();
        r.m[0]=cos(a); r.m[1]=sin(a); r.m[4]=-sin(a); r.m[5]=cos(a);
        return r;
    }

    static mat4 perspective(f64 fov_y, f64 aspect, f64 near, f64 far) {
        mat4 r;
        f64 f = 1.0 / tan(fov_y * 0.5);
        r.m[0]  = f / aspect;
        r.m[5]  = f;
        r.m[10] = (far + near) / (near - far);
        r.m[11] = -1.0;
        r.m[14] = (2.0 * far * near) / (near - far);
        return r;
    }
}

// --- quaternion ---
istruc quat {
    f64 w; f64 x; f64 y; f64 z;

    void __construct__(&self, f64 vw, f64 vx, f64 vy, f64 vz) {
        self.w=vw; self.x=vx; self.y=vy; self.z=vz;
    }

    static quat identity() { quat q(1.0,0.0,0.0,0.0); return q; }

    quat mul(&self, quat o) {
        quat r(
            self.w*o.w - self.x*o.x - self.y*o.y - self.z*o.z,
            self.w*o.x + self.x*o.w + self.y*o.z - self.z*o.y,
            self.w*o.y - self.x*o.z + self.y*o.w + self.z*o.x,
            self.w*o.z + self.x*o.y - self.y*o.x + self.z*o.w
        );
        return r;
    }

    f64  norm(&self) { return sqrt(self.w*self.w+self.x*self.x+self.y*self.y+self.z*self.z); }

    quat normalize(&self) {
        f64 n = self.norm();
        if (n == 0.0) { return quat.identity(); }
        quat r(self.w/n,self.x/n,self.y/n,self.z/n); return r;
    }

    quat conjugate(&self) { quat r(self.w,-self.x,-self.y,-self.z); return r; }

    static quat from_axis_angle(vec3 axis, f64 angle) {
        f64 s = sin(angle * 0.5);
        vec3 na = axis.normalize();
        quat q(cos(angle*0.5), na.x*s, na.y*s, na.z*s);
        return q;
    }

    mat4 to_mat4(&self) {
        mat4 r = mat4.identity();
        f64 xx=self.x*self.x; f64 yy=self.y*self.y; f64 zz=self.z*self.z;
        f64 xy=self.x*self.y; f64 xz=self.x*self.z; f64 yz=self.y*self.z;
        f64 wx=self.w*self.x; f64 wy=self.w*self.y; f64 wz=self.w*self.z;
        r.m[0]  = 1.0-2.0*(yy+zz);
        r.m[1]  = 2.0*(xy+wz);
        r.m[2]  = 2.0*(xz-wy);
        r.m[4]  = 2.0*(xy-wz);
        r.m[5]  = 1.0-2.0*(xx+zz);
        r.m[6]  = 2.0*(yz+wx);
        r.m[8]  = 2.0*(xz+wy);
        r.m[9]  = 2.0*(yz-wx);
        r.m[10] = 1.0-2.0*(xx+yy);
        return r;
    }
}

// --- statistics ---
f64 mean(f64* arr, i32 n) {
    f64 s = 0.0;
    for (i32 i = 0; i < n; i = i + 1) s = s + arr[i];
    return s / (f64)n;
}
f64 variance(f64* arr, i32 n) {
    f64 m = 0.0;
    for (i32 i = 0; i < n; i = i + 1) m = m + arr[i];
    m = m / (f64)n;
    f64 s = 0.0;
    for (i32 i = 0; i < n; i = i + 1) { f64 d = arr[i]-m; s = s + d*d; }
    return s / (f64)n;
}
f64 std_dev(f64* arr, i32 n) {
    f64 m = 0.0;
    for (i32 i = 0; i < n; i = i + 1) m = m + arr[i];
    m = m / (f64)n;
    f64 s = 0.0;
    for (i32 i = 0; i < n; i = i + 1) { f64 d = arr[i]-m; s = s + d*d; }
    return sqrt(s / (f64)n);
}

// --- bit operations ---
u32 popcount_u32(u32 x) {
    x = x - ((x >> 1) & 0x55555555u);
    x = (x & 0x33333333u) + ((x >> 2) & 0x33333333u);
    x = (x + (x >> 4)) & 0x0F0F0F0Fu;
    return (x * 0x01010101u) >> 24;
}
u32 clz_u32(u32 x) {
    if (x == 0) { return 32; }
    u32 n = 0;
    if ((x & 0xFFFF0000u) == 0) { n = n + 16; x = x << 16; }
    if ((x & 0xFF000000u) == 0) { n = n + 8;  x = x << 8;  }
    if ((x & 0xF0000000u) == 0) { n = n + 4;  x = x << 4;  }
    if ((x & 0xC0000000u) == 0) { n = n + 2;  x = x << 2;  }
    if ((x & 0x80000000u) == 0) { n = n + 1; }
    return n;
}
u32 ctz_u32(u32 x) {
    if (x == 0) { return 32; }
    u32 n = 0;
    if ((x & 0xFFFFu) == 0) { n = n + 16; x = x >> 16; }
    if ((x & 0xFFu)   == 0) { n = n + 8;  x = x >> 8;  }
    if ((x & 0xFu)    == 0) { n = n + 4;  x = x >> 4;  }
    if ((x & 0x3u)    == 0) { n = n + 2;  x = x >> 2;  }
    if ((x & 0x1u)    == 0) { n = n + 1; }
    return n;
}
u32 bit_reverse_u32(u32 x) {
    x = ((x & 0xAAAAAAAAu) >> 1)  | ((x & 0x55555555u) << 1);
    x = ((x & 0xCCCCCCCCu) >> 2)  | ((x & 0x33333333u) << 2);
    x = ((x & 0xF0F0F0F0u) >> 4)  | ((x & 0x0F0F0F0Fu) << 4);
    x = ((x & 0xFF00FF00u) >> 8)  | ((x & 0x00FF00FFu) << 8);
    return (x >> 16) | (x << 16);
}

