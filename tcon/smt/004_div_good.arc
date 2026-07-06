// SMT claim: division by constant nonzero → interval [N,N] with N≠0 → verdict=GOOD.
// No div-zero runtime check emitted for divisions by integer literals ≠ 0.
extern i32 printf(i8* fmt, ...);

i32 main() {
    // Division by constant: SMT interval [2,2], 0 not in range → GOOD
    i32 a = 100 / 2;
    if (a != 50) { printf("FAIL div constant a=%d\n", a); return 1; }

    // Multiple constant divisions
    i32 b = 81 / 9;
    i32 c = 77 / 7;
    if (b != 9 || c != 11) { printf("FAIL div b=%d c=%d\n", b, c); return 2; }

    // Modulo by constant nonzero → GOOD
    i32 d = 17 % 5;
    if (d != 2) { printf("FAIL mod d=%d\n", d); return 3; }

    // Variable that SMT can prove nonzero through assignment
    i32 divisor = 4;   // abs_int interval [4,4] → nonzero → GOOD
    i32 e = 32 / divisor;
    if (e != 8) { printf("FAIL div var e=%d\n", e); return 4; }

    return 0;
}
