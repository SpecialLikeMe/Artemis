// FAIL: derived class calls a private method of base
istruc Engine {
    private void ignite(Engine* self) {}
}
istruc TurboEngine : Engine {
    fn boost(self: *TurboEngine) void { self.ignite(); }  // ERROR: ignite is private in Engine
}
fn main() i32 { return 0; }
