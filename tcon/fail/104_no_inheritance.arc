istruc Animal {
    let mut legs: i32;

    fn __construct__(self: *Animal, n: i32) void {
        self.legs = n;
    }

    fn get_legs(self: *const Animal) i32 {
        return self.legs;
    }
}

istruc Dog : Animal {
    let mut tail: i32;

    fn __construct__(self: *Dog, t: i32) void {
        self.legs = 4;
        self.tail = t;
    }

    fn describe(self: *const Dog) i32 {
        return self.legs * 10 + self.tail;
    }
}

fn main() i32 {
    fn a(6) Animal;
    if (a.get_legs() != 6) { return 1; }

    fn d(1) Dog;
    if (d.legs != 4)       { return 2; }
    if (d.tail != 1)       { return 3; }
    if (d.get_legs() != 4) { return 4; }
    if (d.describe() != 41){ return 5; }

    return 0;
}
