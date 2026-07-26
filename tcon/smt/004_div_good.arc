// SMT claim: division by constant nonzero → interval [N,N] with N≠0 → verdict=GOOD.
// No div-zero runtime check emitted for divisions by integer literals ≠ 0.
@unsafe extern fn printf(fmt: *i8, ...) i32;

pub fn main() i32 {
    // Division by constant: SMT interval [2,2], 0 not in range → GOOD
    let mut a: i32= 100 / 2;
    if (a != 50) { printf("FAIL div constant a=%d\n", a); return 1; }

    // Multiple constant divisions
    let mut b: i32= 81 / 9;
    let mut c: i32= 77 / 7;
    if (b != 9 || c != 11) { printf("FAIL div b=%d c=%d\n", b, c); return 2; }

    // Modulo by constant nonzero → GOOD
    let mut d: i32= 17 % 5;
    if (d != 2) { printf("FAIL mod d=%d\n", d); return 3; }

    // Variable that SMT can prove nonzero through assignment
    let mut divisor: i32= 4;   // abs_int interval [4,4] → nonzero → GOOD
    let mut e: i32= 32 / divisor;
    if (e != 8) { printf("FAIL div var e=%d\n", e); return 4; }

    return 0;
}
