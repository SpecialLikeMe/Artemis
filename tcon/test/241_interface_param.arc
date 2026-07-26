// Test: interface as function parameter type (parsed as void*)
// PASS PASS PASS
fn puts(s: *i8) int;

interface Animal {
    fn speak(self: *Animal) void;
}

istruc Dog : Animal {
    let mut id: int;
    fn speak(self: *Dog) void { puts("Dog"); }
}

istruc Cat : Animal {
    let mut id: int;
    fn speak(self: *Cat) void { puts("Cat"); }
}

// Function accepting interface Animal* as void*
fn dispatch_dog(a: interface Animal*) void {
    let mut d: *Dog= (Dog*)a;
    d.speak();
}

pub fn main() int {
    let mut d: Dog;
    d.id = 1;

    // Pass concrete struct pointer as interface*
    dispatch_dog((void*)&d);
    puts("PASS dispatch");

    // Interface pointer variable
    let mut p: *void= (void*)&d;
    let mut dd: *Dog= (Dog*)p;
    if (dd.id == 1) { puts("PASS id"); }

    // Interface parameter used for null check
    let mut q: interface Animal* = (void*)0;
    if (q == (void*)0) { puts("PASS null"); }

    return 0;
}
