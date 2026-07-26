// FAIL: SMT detects iterator invalidation — push to container during range-for iteration.
// Expected outcome: BAD (compile error emitted by smt.smt_analyze).
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
    arr.push(10); arr.push(20);

    for (let x: i32 : arr) {
        arr.push(x);   // BAD: mutation of container during range-for → iterator invalidation
    }
    return 0;
}
