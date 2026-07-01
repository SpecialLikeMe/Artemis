// FAIL: derived class calls a private method of base
istruc Engine {
    private void ignite(Engine* self) {}
}
istruc TurboEngine : Engine {
    void boost(TurboEngine* self) { self.ignite(); }  // ERROR: ignite is private in Engine
}
i32 main() { return 0; }
