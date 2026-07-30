extern std.fmt;
fn str_hash32(s: *i8) u32 {
    if (s == (i8*)0) { return 0u; }
    let mut h: u32= 2166136261u;
    let mut i: i32= 0;
    while (s[i] != 0) {
        h = h ^ (u32)(u8)s[i];
        h = h * 16777619u;
        i = i + 1;
    }
    return h;
}
fn hash_cap_for(n: i32) i32 { let mut c: i32= 64; while (c < n) { c = c * 2; } return c; }
namespace demo {
fn probe() i32 {
    let mut a: u32= str_hash32("hello");
    let mut b: u32= str_hash32("hello");
    let mut c: u32= str_hash32("world");
    if (a != b) { return 1; }
    if (a == c) { return 2; }
    let mut nb: i32= hash_cap_for(300);
    if (nb != 512) { return 3; }
    let mut mask: u32= (u32)(nb - 1);
    let mut bkt: i32= (i32)(a & mask);
    if (bkt < 0 || bkt >= nb) { return 4; }
    std.fmt.out_print_i32(bkt); std.fmt.out_println("");
    return 0;
}
}
pub fn main() i32 { return demo.probe(); }
