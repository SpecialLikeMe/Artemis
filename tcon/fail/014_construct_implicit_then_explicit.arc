// FAIL: calling __construct__ on an implicitly-constructed variable
istruc Box { i32 v; void __construct__(Box* self, i32 x) { self.v = x; } }
i32 main() {
    Box b(10);
    b.__construct__(20);  // ERROR: b was not declared consteval
    return b.v;
}
