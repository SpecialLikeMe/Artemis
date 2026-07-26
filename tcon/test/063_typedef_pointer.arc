using IntPtr = *i32;

fn zero(p: IntPtr) void { *p = 0; }

pub fn main() i32 {
    let mut x: i32= 55;
    let mut p: IntPtr= &x;
    if (*p != 55) { return 1; }
    zero(p);
    if (x != 0)   { return 2; }
    return 0;
}
