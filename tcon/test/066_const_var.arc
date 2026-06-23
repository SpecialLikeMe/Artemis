const i32 MAX = 100;
const f64 PI  = 3.14159;

i32 main() {
    if (MAX != 100) { return 1; }
    i32 x = MAX / 4;
    if (x != 25) { return 2; }
    i32 result = 0;
    if (result > MAX) { return 3; }
    return 0;
}
