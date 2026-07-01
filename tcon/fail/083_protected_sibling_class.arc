// FAIL: accessing private field from a completely external context
istruc Token {
    private i32 id;
    public void __construct__(Token* self, i32 v) { self.id = v; }
}
i32 main() {
    Token t(42);
    i32 x = t.id;  // ERROR: id is private
    return x;
}
