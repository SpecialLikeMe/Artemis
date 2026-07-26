istruc Timer {
    let mut start: i32;
    let mut ticks: i32;
    fn __construct__(self: *Timer, s: i32) void { self.start = s; self.ticks = 0; }
    fn tick(self: *Timer) void { self.ticks = self.ticks + 1; }
    fn elapsed(self: *const Timer) i32 { return self.ticks; }
}
pub fn main() i32 {
    // implicit ctor (normal)
    let mut t: Timer(10);
    t.tick();
    if (t.elapsed() != 1) { return 1; }
    if (t.start != 10) { return 2; }

    // comptime: manual ctor call
    const u: Timer;
    u.__construct__(20);
    u.tick();
    u.tick();
    if (u.elapsed() != 2) { return 3; }
    if (u.start != 20) { return 4; }
    return 0;
}
