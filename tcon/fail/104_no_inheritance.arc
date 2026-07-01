istruc Animal {
    i32 legs;

    void __construct__(Animal* self, i32 n) {
        self.legs = n;
    }

    i32 get_legs(const Animal* self) {
        return self.legs;
    }
}

istruc Dog : Animal {
    i32 tail;

    void __construct__(Dog* self, i32 t) {
        self.legs = 4;
        self.tail = t;
    }

    i32 describe(const Dog* self) {
        return self.legs * 10 + self.tail;
    }
}

i32 main() {
    Animal a(6);
    if (a.get_legs() != 6) { return 1; }

    Dog d(1);
    if (d.legs != 4)       { return 2; }
    if (d.tail != 1)       { return 3; }
    if (d.get_legs() != 4) { return 4; }
    if (d.describe() != 41){ return 5; }

    return 0;
}
