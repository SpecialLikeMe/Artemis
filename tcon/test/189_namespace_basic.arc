// Namespace: basic function declarations and dot-syntax access
namespace Math {
    fn add(a: i32, b: i32) i32 { return a + b; }
    fn mul(a: i32, b: i32) i32 { return a * b; }
    fn abs_val(x: i32) i32 { return x < 0 ? -x : x; }
    fn max_val(a: i32, b: i32) i32 { return a > b ? a : b; }
}

namespace Str {
    fn length(s: *i8) i32 {
        let mut n: i32= 0;
        while (s[n] != 0) { n = n + 1; }
        return n;
    }
}

pub fn main() i32 {
    if (Math.add(3, 4) != 7)         { return 1; }
    if (Math.mul(6, 7) != 42)        { return 2; }
    if (Math.abs_val(-9) != 9)       { return 3; }
    if (Math.max_val(10, 20) != 20)  { return 4; }

    let mut hello: *i8= "hello";
    if (Str.length(hello) != 5)      { return 5; }

    // Namespace functions usable as expressions
    let mut x: i32= Math.add(Math.mul(2, 3), Math.abs_val(-1));
    if (x != 7)                      { return 6; }

    return 0;
}
