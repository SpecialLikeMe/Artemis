istruc Animal {
    i32 legs;
    virtual i32 speak(&const self) { return 1; }
    i32 nonvirtual(&const self) { return 7; }
}
istruc Dog : Animal {
    i32 speak(&const self) override { return 2; }
}
i32 main() {
    Dog d;
    d.legs = 4;
    if (d.speak() != 2) { return 1; }
    if (d.nonvirtual() != 7) { return 2; }
    if (d.legs != 4) { return 3; }
    return 0;
}
