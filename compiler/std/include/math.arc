// std.math — Complete mathematics library.

// C math functions (libm)
@unsafe extern fn sin(x: f64) f64;
@unsafe extern fn cos(x: f64) f64;
@unsafe extern fn tan(x: f64) f64;
@unsafe extern fn asin(x: f64) f64;
@unsafe extern fn acos(x: f64) f64;
@unsafe extern fn atan(x: f64) f64;
@unsafe extern fn atan2(y: f64, x: f64) f64;
@unsafe extern fn sinh(x: f64) f64;
@unsafe extern fn cosh(x: f64) f64;
@unsafe extern fn tanh(x: f64) f64;
@unsafe extern fn exp(x: f64) f64;
@unsafe extern fn exp2(x: f64) f64;
@unsafe extern fn log(x: f64) f64;
@unsafe extern fn log2(x: f64) f64;
@unsafe extern fn log10(x: f64) f64;
@unsafe extern fn pow(base: f64, exp: f64) f64;
@unsafe extern fn sqrt(x: f64) f64;
@unsafe extern fn cbrt(x: f64) f64;
@unsafe extern fn ceil(x: f64) f64;
@unsafe extern fn floor(x: f64) f64;
@unsafe extern fn round(x: f64) f64;
@unsafe extern fn trunc(x: f64) f64;
@unsafe extern fn fabs(x: f64) f64;
@unsafe extern fn fmod(x: f64, y: f64) f64;
@unsafe extern fn hypot(x: f64, y: f64) f64;
@unsafe extern fn ldexp(x: f64, exp: i32) f64;
@unsafe extern fn frexp(x: f64, exp: *i32) f64;
@unsafe extern fn modf(x: f64, iptr: *f64) f64;
@unsafe extern fn sinf(x: f32) f32;
@unsafe extern fn cosf(x: f32) f32;
@unsafe extern fn tanf(x: f32) f32;
@unsafe extern fn sqrtf(x: f32) f32;
@unsafe extern fn fabsf(x: f32) f32;
@unsafe extern fn floorf(x: f32) f32;
@unsafe extern fn ceilf(x: f32) f32;
@unsafe extern fn roundf(x: f32) f32;
@unsafe extern fn powf(b: f32, e: f32) f32;
@unsafe extern fn logf(x: f32) f32;
@unsafe extern fn expf(x: f32) f32;

namespace std {
namespace math {
comptime f64 PI     = 3.14159265358979323846;
comptime f64 TAU    = 6.28318530717958647692;
comptime f64 E      = 2.71828182845904523536;
comptime f64 PHI    = 1.61803398874989484820;
comptime f64 SQRT2  = 1.41421356237309504880;
comptime f64 LN2    = 0.69314718055994530941;
comptime f64 LN10   = 2.30258509299404568401;
comptime f64 INF    = 1.0 / 0.0;
comptime f64 NAN_V  = 0.0 / 0.0;

// --- basic ---
fn abs_i32(x: i32) i32   { return x < 0 ? -x : x; }
fn abs_i64(x: i64) i64   { return x < 0 ? -x : x; }
fn abs_f32(x: f32) f32   { return fabsf(x); }
fn abs_f64(x: f64) f64   { return fabs(x); }

fn min_i32(a: i32, b: i32) i32   { return a < b ? a : b; }
fn max_i32(a: i32, b: i32) i32   { return a > b ? a : b; }
fn min_i64(a: i64, b: i64) i64   { return a < b ? a : b; }
fn max_i64(a: i64, b: i64) i64   { return a > b ? a : b; }
fn min_f32(a: f32, b: f32) f32   { return a < b ? a : b; }
fn max_f32(a: f32, b: f32) f32   { return a > b ? a : b; }
fn min_f64(a: f64, b: f64) f64   { return a < b ? a : b; }
fn max_f64(a: f64, b: f64) f64   { return a > b ? a : b; }

fn clamp_i32(v: i32, lo: i32, hi: i32) i32 { return v < lo ? lo : v > hi ? hi : v; }
fn clamp_f32(v: f32, lo: f32, hi: f32) f32 { return v < lo ? lo : v > hi ? hi : v; }
fn clamp_f64(v: f64, lo: f64, hi: f64) f64 { return v < lo ? lo : v > hi ? hi : v; }

fn sign_i32(x: i32) i32  { return x < 0 ? -1 : x > 0 ? 1 : 0; }
fn sign_f64(x: f64) f64  { return x < 0.0 ? -1.0 : x > 0.0 ? 1.0 : 0.0; }

fn lerp(a: f64, b: f64, t: f64) f64 { return a + t * (b - a); }
fn lerp_f32(a: f32, b: f32, t: f32) f32 { return a + t * (b - a); }

// --- trig ---
fn deg_to_rad(d: f64) f64 { return d * PI / 180.0; }
fn rad_to_deg(r: f64) f64 { return r * 180.0 / PI; }

// --- rounding ---
fn snap(v: f64, step: f64) f64 { return floor(v / step + 0.5) * step; }

// --- power / log ---
fn log_base(x: f64, base: f64) f64 { return log(x) / log(base); }

fn is_power_of_two(n: u64) bool { return n != 0 && (n & (n - 1)) == 0; }
fn next_power_of_two(n: u64) u64 {
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
fn gcd(a: i32, b: i32) i32 {
    if (a < 0) { a = -a; }
    if (b < 0) { b = -b; }
    while (b != 0) { let mut t: i32= b; b = a % b; a = t; }
    return a;
}
fn lcm(a: i32, b: i32) i32 {
    // inline gcd to avoid same-namespace bare-name call limitation
    let mut g: i32= a < 0 ? -a : a;
    let mut t: i32= b < 0 ? -b : b;
    while (t != 0) { let mut r: i32= g % t; g = t; t = r; }
    return (a / g) * b;
}
fn div_ceil(a: i32, b: i32) i32 { return (a + b - 1) / b; }
fn div_floor(a: i32, b: i32) i32{ return a / b; }
fn is_even(n: i64) bool { return (n & 1) == 0; }
fn is_odd(n: i64) bool  { return (n & 1) != 0; }

// --- 2D vector ---
istruc vec2 {
    let mut x: f64; let mut y: f64;

    fn __construct__(self: *vec2, vx: f64, vy: f64) void { self.x = vx; self.y = vy; }

    fn add(self: *vec2, o: vec2) vec2   { let mut r: vec2(self.x+o.x, self.y+o.y); return r; }
    fn sub(self: *vec2, o: vec2) vec2   { let mut r: vec2(self.x-o.x, self.y-o.y); return r; }
    fn scale(self: *vec2, s: f64) vec2  { let mut r: vec2(s*self.x, s*self.y); return r; }
    fn dot(self: *vec2, o: vec2) f64   { return self.x*o.x + self.y*o.y; }
    fn len_sq(self: *vec2) f64        { return self.x*self.x + self.y*self.y; }
    fn len(self: *vec2) f64           { return sqrt(self.len_sq()); }
    fn normalize(self: *vec2) vec2 {
        let mut l: f64= self.len();
        if (l == 0.0) { let mut z: vec2(0.0, 0.0); return z; }
        let mut r: vec2(self.x/l, self.y/l); return r;
    }
    fn cross(self: *vec2, o: vec2) f64 { return self.x*o.y - self.y*o.x; }
    fn perp(self: *vec2) vec2          { let mut r: vec2(-self.y, self.x); return r; }
    fn angle(self: *vec2) f64         { return atan2(self.y, self.x); }
    fn rotate(self: *vec2, a: f64) vec2 {
        let mut c: f64= cos(a); let mut s: f64= sin(a);
        let mut r: vec2(self.x*c - self.y*s, self.x*s + self.y*c); return r;
    }
    bool operator==(vec2* self, vec2 o) { return self.x == o.x && self.y == o.y; }
    vec2 operator+(vec2* self, vec2 o)  { return self.add(o); }
    vec2 operator-(vec2* self, vec2 o)  { return self.sub(o); }
    vec2 operator*(vec2* self, f64 s)   { return self.scale(s); }
}

// --- 3D vector ---
istruc vec3 {
    let mut x: f64; let mut y: f64; let mut z: f64;

    fn __construct__(self: *vec3, vx: f64, vy: f64, vz: f64) void { self.x=vx; self.y=vy; self.z=vz; }

    fn add(self: *vec3, o: vec3) vec3  { let mut r: vec3(self.x+o.x,self.y+o.y,self.z+o.z); return r; }
    fn sub(self: *vec3, o: vec3) vec3  { let mut r: vec3(self.x-o.x,self.y-o.y,self.z-o.z); return r; }
    fn scale(self: *vec3, s: f64) vec3 { let mut r: vec3(s*self.x, s*self.y, s*self.z); return r; }
    fn dot(self: *vec3, o: vec3) f64  { return self.x*o.x+self.y*o.y+self.z*o.z; }
    fn len_sq(self: *vec3) f64       { return self.x*self.x+self.y*self.y+self.z*self.z; }
    fn len(self: *vec3) f64          { return sqrt(self.len_sq()); }
    fn cross(self: *vec3, o: vec3) vec3 {
        let mut r: vec3(self.y*o.z - self.z*o.y,
                        self.z*o.x - self.x*o.z,
                        self.x*o.y - self.y*o.x);
        return r;
    }
    fn normalize(self: *vec3) vec3 {
        let mut l: f64= self.len();
        if (l == 0.0) { let mut z: vec3(0.0,0.0,0.0); return z; }
        let mut r: vec3(self.x/l,self.y/l,self.z/l); return r;
    }
    fn reflect(self: *vec3, n: vec3) vec3 { return self.sub(n.scale(2.0*self.dot(n))); }
    vec3 operator+(vec3* self, vec3 o) { return self.add(o); }
    vec3 operator-(vec3* self, vec3 o) { return self.sub(o); }
    vec3 operator*(vec3* self, f64 s)  { return self.scale(s); }
}

// --- 4x4 matrix (column-major) ---
istruc mat4 {
    let mut m: [16]f64; // [col*4 + row]

    fn __construct__(self: *mat4) void {
        for (let mut i: i32 = 0; i < 16; i = i + 1) { self.m[i] = 0.0; }
    }

    static mat4 identity() {
        let mut r: mat4;
        r.m[0]=1.0; r.m[5]=1.0; r.m[10]=1.0; r.m[15]=1.0;
        return r;
    }

    fn at(self: *mat4, row: i32, col: i32) f64 { return self.m[col*4 + row]; }

    fn mul(self: *mat4, b: mat4) mat4 {
        let mut r: mat4;
        for (let mut row: i32 = 0; row < 4; row = row + 1) {
            for (let mut col: i32 = 0; col < 4; col = col + 1) {
                let mut s: f64= 0.0;
                for (let mut k: i32 = 0; k < 4; k = k + 1)
                    s = s + self.m[k*4+row] * b.m[col*4+k];
                r.m[col*4+row] = s;
            }
        }
        return r;
    }

    fn transpose(self: *mat4) mat4 {
        let mut r: mat4;
        for (let mut i: i32 = 0; i < 4; i = i + 1)
            for (let mut j: i32 = 0; j < 4; j = j + 1)
                r.m[i*4+j] = self.m[j*4+i];
        return r;
    }

    static mat4 translate(f64 tx, f64 ty, f64 tz) {
        let mut r: mat4= mat4.identity();
        r.m[12]=tx; r.m[13]=ty; r.m[14]=tz;
        return r;
    }

    static mat4 scale_m(f64 sx, f64 sy, f64 sz) {
        let mut r: mat4;
        r.m[0]=sx; r.m[5]=sy; r.m[10]=sz; r.m[15]=1.0;
        return r;
    }

    static mat4 rotate_x(f64 a) {
        let mut r: mat4= mat4.identity();
        r.m[5]=cos(a); r.m[6]=sin(a); r.m[9]=-sin(a); r.m[10]=cos(a);
        return r;
    }

    static mat4 rotate_y(f64 a) {
        let mut r: mat4= mat4.identity();
        r.m[0]=cos(a); r.m[2]=-sin(a); r.m[8]=sin(a); r.m[10]=cos(a);
        return r;
    }

    static mat4 rotate_z(f64 a) {
        let mut r: mat4= mat4.identity();
        r.m[0]=cos(a); r.m[1]=sin(a); r.m[4]=-sin(a); r.m[5]=cos(a);
        return r;
    }

    static mat4 perspective(f64 fov_y, f64 aspect, f64 near, f64 far) {
        let mut r: mat4;
        let mut f: f64= 1.0 / tan(fov_y * 0.5);
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
    let mut w: f64; let mut x: f64; let mut y: f64; let mut z: f64;

    fn __construct__(self: *quat, vw: f64, vx: f64, vy: f64, vz: f64) void {
        self.w=vw; self.x=vx; self.y=vy; self.z=vz;
    }

    static quat identity() { let mut q: quat(1.0,0.0,0.0,0.0); return q; }

    fn mul(self: *quat, o: quat) quat {
        let mut r: quat(
            self.w*o.w - self.x*o.x - self.y*o.y - self.z*o.z,
            self.w*o.x + self.x*o.w + self.y*o.z - self.z*o.y,
            self.w*o.y - self.x*o.z + self.y*o.w + self.z*o.x,
            self.w*o.z + self.x*o.y - self.y*o.x + self.z*o.w
        );
        return r;
    }

    fn norm(self: *quat) f64 { return sqrt(self.w*self.w+self.x*self.x+self.y*self.y+self.z*self.z); }

    fn normalize(self: *quat) quat {
        let mut n: f64= self.norm();
        if (n == 0.0) { return quat.identity(); }
        let mut r: quat(self.w/n,self.x/n,self.y/n,self.z/n); return r;
    }

    fn conjugate(self: *quat) quat { let mut r: quat(self.w,-self.x,-self.y,-self.z); return r; }

    static quat from_axis_angle(vec3 axis, f64 angle) {
        let mut s: f64= sin(angle * 0.5);
        let mut na: vec3= axis.normalize();
        let mut q: quat(cos(angle*0.5), na.x*s, na.y*s, na.z*s);
        return q;
    }

    fn to_mat4(self: *quat) mat4 {
        let mut r: mat4= mat4.identity();
        let mut xx: f64=self.x*self.x; let mut yy: f64=self.y*self.y; let mut zz: f64=self.z*self.z;
        let mut xy: f64=self.x*self.y; let mut xz: f64=self.x*self.z; let mut yz: f64=self.y*self.z;
        let mut wx: f64=self.w*self.x; let mut wy: f64=self.w*self.y; let mut wz: f64=self.w*self.z;
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
fn mean(arr: *f64, n: i32) f64 {
    let mut s: f64= 0.0;
    for (let mut i: i32 = 0; i < n; i = i + 1) s = s + arr[i];
    return s / (f64)n;
}
fn variance(arr: *f64, n: i32) f64 {
    let mut m: f64= 0.0;
    for (let mut i: i32 = 0; i < n; i = i + 1) m = m + arr[i];
    m = m / (f64)n;
    let mut s: f64= 0.0;
    for (let mut i: i32 = 0; i < n; i = i + 1) { let mut d: f64= arr[i]-m; s = s + d*d; }
    return s / (f64)n;
}
fn std_dev(arr: *f64, n: i32) f64 {
    let mut m: f64= 0.0;
    for (let mut i: i32 = 0; i < n; i = i + 1) m = m + arr[i];
    m = m / (f64)n;
    let mut s: f64= 0.0;
    for (let mut i: i32 = 0; i < n; i = i + 1) { let mut d: f64= arr[i]-m; s = s + d*d; }
    return sqrt(s / (f64)n);
}

// --- bit operations ---
fn popcount_u32(x: u32) u32 {
    x = x - ((x >> 1) & 0x55555555u);
    x = (x & 0x33333333u) + ((x >> 2) & 0x33333333u);
    x = (x + (x >> 4)) & 0x0F0F0F0Fu;
    return (x * 0x01010101u) >> 24;
}
fn clz_u32(x: u32) u32 {
    if (x == 0) { return 32; }
    let mut n: u32= 0;
    if ((x & 0xFFFF0000u) == 0) { n = n + 16; x = x << 16; }
    if ((x & 0xFF000000u) == 0) { n = n + 8;  x = x << 8;  }
    if ((x & 0xF0000000u) == 0) { n = n + 4;  x = x << 4;  }
    if ((x & 0xC0000000u) == 0) { n = n + 2;  x = x << 2;  }
    if ((x & 0x80000000u) == 0) { n = n + 1; }
    return n;
}
fn ctz_u32(x: u32) u32 {
    if (x == 0) { return 32; }
    let mut n: u32= 0;
    if ((x & 0xFFFFu) == 0) { n = n + 16; x = x >> 16; }
    if ((x & 0xFFu)   == 0) { n = n + 8;  x = x >> 8;  }
    if ((x & 0xFu)    == 0) { n = n + 4;  x = x >> 4;  }
    if ((x & 0x3u)    == 0) { n = n + 2;  x = x >> 2;  }
    if ((x & 0x1u)    == 0) { n = n + 1; }
    return n;
}
fn bit_reverse_u32(x: u32) u32 {
    x = ((x & 0xAAAAAAAAu) >> 1)  | ((x & 0x55555555u) << 1);
    x = ((x & 0xCCCCCCCCu) >> 2)  | ((x & 0x33333333u) << 2);
    x = ((x & 0xF0F0F0F0u) >> 4)  | ((x & 0x0F0F0F0Fu) << 4);
    x = ((x & 0xFF00FF00u) >> 8)  | ((x & 0x00FF00FFu) << 8);
    return (x >> 16) | (x << 16);
}


} // namespace math
} // namespace std