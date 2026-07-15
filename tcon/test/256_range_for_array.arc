// PASS: range-for over a fixed-size C array.
i32 main() {
    i32 arr[5];
    arr[0] = 10; arr[1] = 20; arr[2] = 30; arr[3] = 40; arr[4] = 50;

    i32 sum = 0;
    for (i32 x : arr) { sum = sum + x; }
    if (sum != 150) { return 1; }

    // Nested range-for
    i32 mat[3];
    mat[0] = 1; mat[1] = 2; mat[2] = 3;
    i32 prod = 1;
    for (i32 v : mat) { prod = prod * v; }
    if (prod != 6) { return 2; }

    return 0;
}
