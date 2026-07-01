// protected members: accessible in derived class, not outside
istruc Animal {
    protected i32 legs;
    public void __construct__(Animal* self, i32 n) { self.legs = n; }
}

istruc Dog : Animal {
    public i32 leg_count(const Dog* self) { return self.legs; }
    public void set_legs(Dog* self, i32 n) { self.legs = n; }
}

i32 main() {
    Dog d(4);
    if (d.leg_count() != 4) { return 1; }
    d.set_legs(3);
    if (d.leg_count() != 3) { return 2; }
    return 0;
}
