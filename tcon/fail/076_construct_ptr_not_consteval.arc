// FAIL: calling __construct__ via pointer on a non-consteval variable
istruc Node { i32 v; void __construct__(&self, i32 x) { self.v = x; } }
i32 main() {
    Node n(1);
    Node* p = &n;
    p->__construct__(2);  // ERROR: n is not declared consteval
    return n.v;
}
