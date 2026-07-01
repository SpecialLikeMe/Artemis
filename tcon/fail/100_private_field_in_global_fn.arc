// FAIL: global function reads private field of an istruc instance
istruc Wallet {
    private i32 balance;
    public void __construct__(Wallet* self, i32 b) { self.balance = b; }
}
i32 steal(Wallet* w) { return w->balance; }  // ERROR: balance is private
i32 main() {
    Wallet w(500);
    return steal(&w);
}
