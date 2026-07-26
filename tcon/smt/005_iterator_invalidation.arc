// SMT claim: safe iteration — range-for with read-only body, no container mutation.
// Iterator-invalidation detection is active for range-for loops: any call to a mutation
// method (push/pop/insert/erase/clear/resize) on the range variable while iterating → BAD.
// This test exercises the GOOD path: no mutation occurs inside the loop.
@unsafe extern fn printf(fmt: *i8, ...) i32;

istruc IntArray {
    let mut data: [8]i32;
    let mut size: i32;
    fn __construct__(self: *IntArray) void { self.size = 0; }
    fn push(self: *IntArray, v: i32) void {
        self.data[self.size] = v;
        self.size = self.size + 1;
    }
    fn begin(self: *IntArray) *i32 { return &self.data[0]; }
    fn end(self: *IntArray) *i32   { return &self.data[self.size]; }
}

pub fn main() i32 {
    let mut arr: IntArray;
    arr.push(10); arr.push(20); arr.push(30); arr.push(40); arr.push(50);

    // GOOD: read-only range-for — no mutation of arr while iterating.
    let mut sum: i32= 0;
    for (let x: i32 : arr) {
        sum = sum + x;   // read only, never mutates arr
    }
    if (sum != 150) { return 1; }
    return 0;
}
