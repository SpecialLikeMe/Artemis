// FAIL: derived class calls a private method of base
istruc Engine {
    private void ignite(&self) {}
}
istruc TurboEngine : Engine {
    void boost(&self) { self.ignite(); }  // ERROR: ignite is private in Engine
}
i32 main() { return 0; }
