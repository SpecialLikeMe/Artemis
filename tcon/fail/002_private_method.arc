// FAIL: calling a private method from outside the class must be rejected
istruc Engine {
    private void start_internal(Engine* self) {}
    public i32 x;
}

fn main() i32 {
    let mut e: Engine;
    e.x = 0;
    e.start_internal();  // ERROR: 'start_internal' is private
    return 0;
}
