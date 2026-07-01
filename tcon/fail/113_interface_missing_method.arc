// FAIL: istruc that claims to implement an interface but is missing a required method
interface Drawable {
    void draw(Drawable* self);
}

istruc Circle : Drawable {
    i32 radius;
    // Missing: draw() method — should fail
}

i32 main() { return 0; }
