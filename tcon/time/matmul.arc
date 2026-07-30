// Dense 320x320 matrix multiply — nested loops and array indexing.
extern std.fmt;

comptime i32 SZ = 600;

let mut a: [360000]f64;
let mut b: [360000]f64;
let mut c: [360000]f64;

pub fn main() i32 {
    let mut i: i32= 0;
    while (i < SZ) {
        let mut j: i32= 0;
        while (j < SZ) {
            a[i * SZ + j] = (f64)(i + j);
            b[i * SZ + j] = (f64)(i - j);
            c[i * SZ + j] = 0.0;
            j = j + 1;
        }
        i = i + 1;
    }
    i = 0;
    while (i < SZ) {
        let mut k: i32= 0;
        while (k < SZ) {
            let mut aik: f64= a[i * SZ + k];
            let mut j2: i32= 0;
            while (j2 < SZ) {
                c[i * SZ + j2] = c[i * SZ + j2] + aik * b[k * SZ + j2];
                j2 = j2 + 1;
            }
            k = k + 1;
        }
        i = i + 1;
    }
    // Sum every element: observing one cell would let the optimiser skip the rest.
    let mut sum: f64= 0.0;
    let mut q: i32= 0;
    while (q < SZ * SZ) { sum = sum + c[q]; q = q + 1; }
    std.fmt.out_print_f64(sum);
    std.fmt.out_println("");
    return 0;
}
