// FAIL: consteval declaration cannot also pass constructor arguments at declaration site
istruc Pt { i32 x; void __construct__(&self, i32 v) { self.x = v; } }
i32 main() {
    consteval Pt p(5);  // ERROR: consteval means user calls __construct__ explicitly
    return p.x;
}
