// Namespace: basic function declarations and dot-syntax access
namespace Math {
    i32 add(i32 a, i32 b) { return a + b; }
    i32 mul(i32 a, i32 b) { return a * b; }
    i32 abs_val(i32 x) { return x < 0 ? -x : x; }
    i32 max_val(i32 a, i32 b) { return a > b ? a : b; }
}

namespace Str {
    i32 length(i8* s) {
        i32 n = 0;
        while (s[n] != 0) { n = n + 1; }
        return n;
    }
}

i32 main() {
    if (Math.add(3, 4) != 7)         { return 1; }
    if (Math.mul(6, 7) != 42)        { return 2; }
    if (Math.abs_val(-9) != 9)       { return 3; }
    if (Math.max_val(10, 20) != 20)  { return 4; }

    i8* hello = "hello";
    if (Str.length(hello) != 5)      { return 5; }

    // Namespace functions usable as expressions
    i32 x = Math.add(Math.mul(2, 3), Math.abs_val(-1));
    if (x != 7)                      { return 6; }

    return 0;
}
