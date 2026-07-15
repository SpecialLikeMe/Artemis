// FAIL: calling __construct__ explicitly without comptime must be rejected
istruc Pt { i32 x; void __construct__(Pt* self, i32 v) { self.x = v; } }
i32 main() {
    Pt p;
    p.__construct__(5);  // ERROR: need comptime Pt p;
    return p.x;
}
