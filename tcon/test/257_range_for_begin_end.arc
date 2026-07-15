// Range-for with istruc begin()/end() protocol
istruc IntArray {
    i32 data[8];
    i32 size;
    void __construct__(IntArray* self) { self.size = 0; }
    void push(IntArray* self, i32 v) {
        self.data[self.size] = v;
        self.size = self.size + 1;
    }
    i32* begin(IntArray* self) { return &self.data[0]; }
    i32* end(IntArray* self)   { return &self.data[self.size]; }
}

i32 main() {
    IntArray arr;
    arr.push(10);
    arr.push(20);
    arr.push(30);
    arr.push(40);

    i32 sum = 0;
    for (i32 x : arr) {
        sum = sum + x;
    }
    if (sum != 100) { return 1; }

    // Count elements
    i32 count = 0;
    for (i32 x : arr) {
        count = count + 1;
    }
    if (count != 4) { return 2; }

    return 0;
}
