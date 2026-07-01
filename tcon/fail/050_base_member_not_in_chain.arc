// FAIL: accessing a member that exists in neither the class nor any base class
istruc A { i32 x; }
istruc B : A { i32 y; }
i32 main() {
    B b;
    b.x = 1;
    b.y = 2;
    i32 z = b.zzz;  // ERROR: zzz not in B or A
    return z;
}
