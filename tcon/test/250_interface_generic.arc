// PASS: generic interface — interface with type parameter, concrete istruc implementing it
interface Getter<T> {
    T get();
}

istruc IntGetter : Getter<i32> {
    i32 val;
    void __construct__(IntGetter* self, i32 v) { self.val = v; }
    i32 get(IntGetter* self) { return self.val; }
}

istruc StrGetter : Getter<i8*> {
    i8* s;
    void __construct__(StrGetter* self, i8* v) { self.s = v; }
    i8* get(StrGetter* self) { return self.s; }
}

i32 main() {
    IntGetter ig(42);
    if (ig.get() != 42) { return 1; }

    StrGetter sg("hello");
    if (sg.get() == (i8*)0) { return 2; }

    return 0;
}
