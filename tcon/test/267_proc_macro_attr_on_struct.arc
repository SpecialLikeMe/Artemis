// PASS: attribute proc macro applied to an istruc.
// Macros inject functions that USE the decorated struct's methods,
// proving the injected code interacts with the decorated type.

fn repr_c(&memstr alloc, tokenstream* input) *tokenstream attr {
    return quote {
        fn make_zero_vec3() Vec3 {
            let mut v: Vec3(0.0, 0.0, 0.0);
            return v;
        }
    };
}

fn align16(&memstr alloc, tokenstream* input) *tokenstream attr verify {
    return quote {
        fn vec3_self_dot(v: *Vec3) f32 {
            return v.dot(v);
        }
    };
}

#[repr_c]
#[align16]
istruc Vec3 {
    let mut x: f32;
    let mut y: f32;
    let mut z: f32;
    fn __construct__(self: *Vec3, x: f32, y: f32, z: f32) void {
        self.x = x; self.y = y; self.z = z;
    }
    fn dot(self: *Vec3, b: *Vec3) f32 {
        return self.x * b.x + self.y * b.y + self.z * b.z;
    }
}

pub fn main() i32 {
    let mut a: Vec3(1.0, 0.0, 0.0);
    let mut b: Vec3(0.0, 1.0, 0.0);
    let mut d: f32= a.dot(&b);
    if (d < -0.001 || d > 0.001) { return 1; }
    let mut c: Vec3(1.0, 1.0, 0.0);
    let mut d2: f32= a.dot(&c);
    if (d2 < 0.999 || d2 > 1.001) { return 2; }
    let mut z: Vec3 = make_zero_vec3();
    if (z.x > 0.001 || z.y > 0.001 || z.z > 0.001) { return 3; }
    let mut unit_x: Vec3(1.0, 0.0, 0.0);
    let mut sd: f32 = vec3_self_dot(&unit_x);
    if (sd < 0.999 || sd > 1.001) { return 4; }
    return 0;
}
