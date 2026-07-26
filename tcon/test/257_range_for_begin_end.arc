// Range-for with istruc begin()/end() protocol
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
    arr.push(10);
    arr.push(20);
    arr.push(30);
    arr.push(40);

    let mut sum: i32= 0;
    for (let x: i32 : arr) {
        sum = sum + x;
    }
    if (sum != 100) { return 1; }

    // Count elements
    let mut count: i32= 0;
    for (let x: i32 : arr) {
        count = count + 1;
    }
    if (count != 4) { return 2; }

    return 0;
}
