istruc Animal {
    let mut legs: i32;
    virtual i32 speak(const Animal* self) { return 1; }
    fn nonvirtual(self: *const Animal) i32 { return 7; }
}
istruc Dog : Animal {
    fn speak(self: *const Dog) i32 override { return 2; }
}
fn main() i32 {
    let mut d: Dog;
    d.legs = 4;
    if (d.speak() != 2) { return 1; }
    if (d.nonvirtual() != 7) { return 2; }
    if (d.legs != 4) { return 3; }
    return 0;
}
