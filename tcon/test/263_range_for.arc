// Test integer range-for loops: 0..N (exclusive) and 0..=N (inclusive)
pub fn main() i32 {
    // Exclusive range: 0..5 yields 0,1,2,3,4
    let mut sum: i32 = 0;
    for (let x: i32 : 0..5) {
        sum = sum + x;
    }
    // sum should be 0+1+2+3+4 = 10
    if (sum != 10) { return 1; }

    // Inclusive range: 1..=5 yields 1,2,3,4,5
    let mut sum2: i32 = 0;
    for (let x: i32 : 1..=5) {
        sum2 = sum2 + x;
    }
    // sum should be 1+2+3+4+5 = 15
    if (sum2 != 15) { return 2; }

    // Range with non-zero start
    let mut count: i32 = 0;
    for (let x: i32 : 10..15) {
        count = count + 1;
    }
    if (count != 5) { return 3; }

    return 0;
}
