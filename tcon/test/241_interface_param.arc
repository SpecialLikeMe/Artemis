// Test: interface as function parameter type (parsed as void*)
// PASS PASS PASS
int puts(i8* s);

interface Animal {
    void speak(Animal* self);
}

istruc Dog : Animal {
    int id;
    void speak(Dog* self) { puts("Dog"); }
}

istruc Cat : Animal {
    int id;
    void speak(Cat* self) { puts("Cat"); }
}

// Function accepting interface Animal* as void*
void dispatch_dog(interface Animal* a) {
    Dog* d = (Dog*)a;
    d.speak();
}

int main() {
    Dog d;
    d.id = 1;

    // Pass concrete struct pointer as interface*
    dispatch_dog((void*)&d);
    puts("PASS dispatch");

    // Interface pointer variable
    void* p = (void*)&d;
    Dog* dd = (Dog*)p;
    if (dd.id == 1) { puts("PASS id"); }

    // Interface parameter used for null check
    interface Animal* q = (void*)0;
    if (q == (void*)0) { puts("PASS null"); }

    return 0;
}
