// FAIL: accessing a protected field from global (non-class) scope must be rejected
istruc Node {
    protected i32 value;
    public void __construct__(Node* self, i32 v) { self.value = v; }
}

i32 main() {
    Node n;
    n.__construct__(5);
    return n.value;  // ERROR: 'value' is protected and we are not in a derived class
}
