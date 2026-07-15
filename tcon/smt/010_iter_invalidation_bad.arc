// FAIL: SMT detects iterator invalidation — push to container during range-for iteration.
// Expected outcome: BAD (compile error emitted by smt.smt_analyze).
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
    arr.push(10); arr.push(20);

    for (i32 x : arr) {
        arr.push(x);   // BAD: mutation of container during range-for → iterator invalidation
    }
    return 0;
}
