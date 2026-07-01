istruc Timer {
    i32 start;
    i32 ticks;
    void __construct__(Timer* self, i32 s) { self.start = s; self.ticks = 0; }
    void tick(Timer* self) { self.ticks = self.ticks + 1; }
    i32 elapsed(const Timer* self) { return self.ticks; }
}
i32 main() {
    // implicit ctor (normal)
    Timer t(10);
    t.tick();
    if (t.elapsed() != 1) { return 1; }
    if (t.start != 10) { return 2; }

    // consteval: manual ctor call
    consteval Timer u;
    u.__construct__(20);
    u.tick();
    u.tick();
    if (u.elapsed() != 2) { return 3; }
    if (u.start != 20) { return 4; }
    return 0;
}
