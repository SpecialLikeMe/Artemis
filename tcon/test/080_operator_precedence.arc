pub fn main() i32 {
    let mut r1: i32= 2 + 3 * 4;
    if (r1 != 14) { return 1; }

    let mut r2: i32= (2 + 3) * 4;
    if (r2 != 20) { return 2; }

    let mut r3: i32= 10 - 3 - 2;
    if (r3 != 5)  { return 3; }

    let mut r4: i32= 8 / 2 * 4;
    if (r4 != 16) { return 4; }

    let mut r5: i32= 1 + 2 == 3;
    if (r5 != 1)  { return 5; }

    let mut r6: i32= 0 || 1 && 0;
    if (r6 != 0)  { return 6; }
    return 0;
}
