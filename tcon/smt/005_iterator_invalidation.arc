// SMT claim: safe iteration — range-for with read-only body, no container mutation.
// Iterator-invalidation detection is active for range-for loops: any call to a mutation
// method (push/pop/insert/erase/clear/resize) on the range variable while iterating → BAD.
// This test exercises the GOOD path: no mutation occurs inside the loop.
extern i32 printf(i8* fmt, ...);

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
    arr.push(10); arr.push(20); arr.push(30); arr.push(40); arr.push(50);

    // GOOD: read-only range-for — no mutation of arr while iterating.
    i32 sum = 0;
    for (i32 x : arr) {
        sum = sum + x;   // read only, never mutates arr
    }
    if (sum != 150) { return 1; }
    return 0;
}
