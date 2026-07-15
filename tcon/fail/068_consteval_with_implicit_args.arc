// FAIL: comptime declaration cannot also pass constructor arguments at declaration site
istruc Pt { i32 x; void __construct__(Pt* self, i32 v) { self.x = v; } }
i32 main() {
    comptime Pt p(5);  // ERROR: comptime means user calls __construct__ explicitly
    return p.x;
}
