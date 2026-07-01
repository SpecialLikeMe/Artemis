// FAIL: calling a private method from outside the class must be rejected
istruc Engine {
    private void start_internal(Engine* self) {}
    public i32 x;
}

i32 main() {
    Engine e;
    e.x = 0;
    e.start_internal();  // ERROR: 'start_internal' is private
    return 0;
}
